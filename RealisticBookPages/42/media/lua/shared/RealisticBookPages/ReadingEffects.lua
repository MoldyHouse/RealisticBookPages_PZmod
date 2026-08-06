require("TimedActions/ISReadABook")

local Config = require("RealisticBookPages/Config")
local API = require("RealisticBookPages/Applicator")
local Progress = require("RealisticBookPages/Progress")

local ReadingEffects = {}
local COMMAND_MODULE = "RealisticBookPages"
local COMMAND_COMPLETE = "completeLiteratureWithoutMood"

local function getMoodData(item)
    if not item or not item:hasModData() then
        return nil
    end

    local data = item:getModData()
    if data.RBP_GradualMoodEffects ~= true then
        return nil
    end

    return data
end

local function hasSkillBook(item)
    if not item or not SkillBook then
        return false
    end

    local skill = item:getSkillTrained()
    return skill and skill ~= "" and SkillBook[skill] ~= nil
end

local function isReadDuringCooldown(action, data)
    if action.rbpMoodAlreadyRead ~= nil then
        return action.rbpMoodAlreadyRead
    end

    local title = data and data.literatureTitle
    if title and action.character:isLiteratureRead(title) then
        return true
    end

    return false
end

local function isGradualAction(action)
    if not action or not action.item or hasSkillBook(action.item) then
        return false, nil
    end

    local data = getMoodData(action.item)
    local settings = Config.resolveMoodSettings()
    if not data or not settings.applyWhileReading then
        return false, data, settings
    end

    return true, data, settings
end

local function applyStat(character, stat, totalChange, fraction)
    if totalChange and totalChange ~= 0 and fraction > 0 then
        character:getStats():add(stat, totalChange * fraction)
    end
end

local function earnedMilestonePercent(page, totalPages, stepPercent, complete)
    if complete then
        return 100
    end

    local readPercent = math.max(0, math.min(100, page * 100 / totalPages))
    return math.min(
        100,
        math.floor((readPercent + 0.000001) / stepPercent) * stepPercent
    )
end

local function applyThroughPage(action, page, complete)
    local enabled, data, settings = isGradualAction(action)
    if not enabled then
        return false
    end
    if isReadDuringCooldown(action, data) then
        return true
    end

    local totalPages = action.item:getNumberOfPages()
    if not totalPages or totalPages <= 0 then
        return false
    end

    local currentPage = math.max(0, math.min(totalPages, math.floor(page)))
    local stepPercent = settings.stepPercent
    local firstPage = tonumber(action.startPage) or 0
    local previousPercent = tonumber(action.rbpLastMoodPercent)
        or earnedMilestonePercent(
            firstPage,
            totalPages,
            stepPercent,
            false
        )
    local currentPercent = earnedMilestonePercent(
        currentPage,
        totalPages,
        stepPercent,
        complete == true
    )

    if currentPercent <= previousPercent then
        return true
    end

    local fraction = (currentPercent - previousPercent) / 100
    applyStat(
        action.character,
        CharacterStat.BOREDOM,
        tonumber(data.RBP_BoredomChange) or action.item:getBoredomChange(),
        fraction
    )
    applyStat(
        action.character,
        CharacterStat.STRESS,
        tonumber(data.RBP_StressChange) or action.item:getStressChange(),
        fraction
    )
    applyStat(
        action.character,
        CharacterStat.UNHAPPINESS,
        tonumber(data.RBP_UnhappyChange) or action.item:getUnhappyChange(),
        fraction
    )

    action.rbpLastMoodPercent = currentPercent
    return true
end

local function currentPageForAction(action)
    local totalPages = action.item:getNumberOfPages()
    local page = action.item:getAlreadyReadPages()

    local jobDelta = action:getJobDelta()
    if jobDelta then
        page = math.max(page, math.floor(totalPages * jobDelta))
    end

    if action.netAction then
        local progress = action.netAction:getProgress()
        if progress then
            local fromProgress = math.floor(totalPages * progress)
                + (tonumber(action.startPage) or 0)
            page = math.max(page, fromProgress)
        end
    end

    return math.min(totalPages, page)
end

local function withNeutralMood(character, item)
    local data = getMoodData(item)
    if not data then
        character:ReadLiterature(item)
        return
    end

    local boredom = item:getBoredomChange()
    local stress = item:getStressChange()
    local unhappiness = item:getUnhappyChange()

    item:setBoredomChange(0)
    item:setStressChange(0)
    item:setUnhappyChange(0)
    local ok, message = pcall(function()
        character:ReadLiterature(item)
    end)

    item:setBoredomChange(tonumber(data.RBP_BoredomChange) or boredom)
    item:setStressChange(tonumber(data.RBP_StressChange) or stress)
    item:setUnhappyChange(tonumber(data.RBP_UnhappyChange) or unhappiness)

    if not ok then
        print(
            "Realistic Book Pages: neutral literature completion failed: "
                .. tostring(message)
        )
    end
end

local originalStart = ISReadABook.start
function ISReadABook:start()
    API.prepareLiteratureMoodEffects(self.item)
    originalStart(self)

    local data = getMoodData(self.item)
    self.rbpMoodAlreadyRead = false

    local totalPages = self.item:getNumberOfPages()
    if totalPages and totalPages > 0 then
        self.rbpLastMoodPercent = earnedMilestonePercent(
            tonumber(self.startPage) or 0,
            totalPages,
            Config.resolveMoodSettings().stepPercent,
            false
        )
    end

    if data and data.literatureTitle then
        self.rbpMoodAlreadyRead =
            self.character:isLiteratureRead(data.literatureTitle)
    end
end


local originalGetDuration = ISReadABook.getDuration
function ISReadABook:getDuration()
    API.prepareLiteratureMoodEffects(self.item)
    return Progress.withItemProgress(self.character, self.item, function()
        return originalGetDuration(self)
    end)
end


local originalUpdate = ISReadABook.update
function ISReadABook:update()
    originalUpdate(self)
    Progress.clearShared(self.character, self.item)
    applyThroughPage(self, currentPageForAction(self), false)
end

local originalAnimEvent = ISReadABook.animEvent
function ISReadABook:animEvent(event, parameter)
    originalAnimEvent(self, event, parameter)
    Progress.clearShared(self.character, self.item)

    if event == "ReadAPage" then
        applyThroughPage(self, currentPageForAction(self), false)
    end
end


local originalStop = ISReadABook.stop
function ISReadABook:stop()
    local result = originalStop(self)
    Progress.clearShared(self.character, self.item)
    return result
end

local originalComplete = ISReadABook.complete
local function completeAndClearShared(action)
    local result = originalComplete(action)
    Progress.clearShared(action.character, action.item)
    return result
end

function ISReadABook:complete()
    local enabled, data = isGradualAction(self)
    if not enabled then
        return completeAndClearShared(self)
    end

    if isReadDuringCooldown(self, data) then
        self.isLiteratureRead = true
        return completeAndClearShared(self)
    end

    applyThroughPage(self, self.item:getNumberOfPages(), true)

    -- Preserve every non-mood consequence of ReadLiterature (recipes and
    -- consume-on-read) while preventing vanilla from awarding the full mood
    -- effect after it has already been distributed page by page.
    if not (isClient and isClient()) then
        withNeutralMood(self.character, self.item)
    end
    if isServer and isServer() then
        sendServerCommand(self.character, COMMAND_MODULE, COMMAND_COMPLETE, {
            itemId = self.item:getID(),
        })
    end

    self.isLiteratureRead = true
    return completeAndClearShared(self)
end

local function onServerCommand(module, command, args)
    if module ~= COMMAND_MODULE or command ~= COMMAND_COMPLETE then
        return
    end
    if not args or not args.itemId then
        return
    end

    local player = getPlayer()
    local item = player and player:getInventory():getItemWithID(args.itemId)
    if item then
        withNeutralMood(player, item)
    end
end

if isClient and isClient() and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end

ReadingEffects.applyThroughPage = applyThroughPage
ReadingEffects.withNeutralMood = withNeutralMood

return ReadingEffects
