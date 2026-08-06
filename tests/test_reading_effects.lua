local root = arg[1] or "."
package.path = root
    .. "/RealisticBookPages/42/media/lua/shared/?.lua;"
    .. package.path

local Config = require("RealisticBookPages/Config")

local function near(actual, expected, message)
    assert(
        math.abs(actual - expected) < 0.000001,
        (message or "values differ")
            .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual)
    )
end

local boredom, stress, unhappiness = Config.resolveRuntimeMoodChanges(
    -50,
    -40,
    -40,
    0.5
)
near(boredom, -25, "boredom must remain on the 0..100 scale")
near(stress, -0.2, "stress script points must convert to the 0..1 scale")
near(unhappiness, -20, "unhappiness must remain on the 0..100 scale")

package.preload["TimedActions/ISReadABook"] = function()
    ISReadABook = {
        start = function() end,
        update = function(self)
            if self.simulatedUpdatePage then
                self.item:setAlreadyReadPages(self.simulatedUpdatePage)
                self.character:setAlreadyReadPages(
                    self.item:getFullType(),
                    self.simulatedUpdatePage
                )
            end
        end,
        animEvent = function() end,
        stop = function() end,
        complete = function() return true end,
        getDuration = function(self)
            local fullType = self.item:getFullType()
            self.item:setAlreadyReadPages(
                self.character:getAlreadyReadPages(fullType)
            )
            self.startPage = self.item:getAlreadyReadPages()
            return 1
        end,
    }
    return ISReadABook
end

package.preload["RealisticBookPages/Applicator"] = function()
    return { prepareLiteratureMoodEffects = function() return true end }
end

CharacterStat = {
    BOREDOM = "boredom",
    STRESS = "stress",
    UNHAPPINESS = "unhappiness",
}
SkillBook = {}
Events = { OnServerCommand = { Add = function() end } }
isClient = function() return false end

local values = {
    boredom = 80,
    stress = 0.8,
    unhappiness = 80,
}
local stats = {}
function stats:add(stat, amount)
    local maximum = stat == CharacterStat.STRESS and 1 or 100
    values[stat] = math.max(0, math.min(maximum, values[stat] + amount))
end

local function newLiterature(properties)
    local item = {
        fullType = properties.fullType,
        pageCount = properties.pageCount,
        pagesRead = properties.pagesRead or 0,
        id = properties.id,
        data = {
            RBP_GradualMoodEffects = true,
            RBP_BoredomChange = -50,
            RBP_StressChange = -0.4,
            RBP_UnhappyChange = -40,
            literatureTitle = properties.title,
        },
    }

    function item:hasModData() return true end
    function item:getModData() return self.data end
    function item:getSkillTrained() return nil end
    function item:getNumberOfPages() return self.pageCount end
    function item:getAlreadyReadPages() return self.pagesRead end
    function item:setAlreadyReadPages(value) self.pagesRead = value end
    function item:getFullType() return self.fullType end
    function item:getID() return self.id end
    function item:getBoredomChange() return self.data.RBP_BoredomChange end
    function item:getStressChange() return self.data.RBP_StressChange end
    function item:getUnhappyChange() return self.data.RBP_UnhappyChange end

    return item
end

local readLiterature = { values = {} }
function readLiterature:containsKey(title)
    return self.values[title] ~= nil
end
function readLiterature:get(title) return self.values[title] end

local character = {
    sharedProgress = {},
    activeCooldowns = {},
}
function character:getStats() return stats end
function character:getReadLiterature() return readLiterature end
function character:isLiteratureRead(title)
    return self.activeCooldowns[title] == true
end
function character:getAlreadyReadPages(fullType)
    return self.sharedProgress[fullType] or 0
end
function character:setAlreadyReadPages(fullType, pages)
    self.sharedProgress[fullType] = pages
end

local sharedType = "Test.GeneratedLiterature"
local firstCopy = newLiterature({
    fullType = sharedType,
    pageCount = 165,
    pagesRead = 65,
    id = 1,
    title = "Generated_Title_A",
})
local secondCopy = newLiterature({
    fullType = sharedType,
    pageCount = 29,
    id = 2,
    title = "Generated_Title_B",
})

local ReadingEffects = require("RealisticBookPages/ReadingEffects")
local Progress = require("RealisticBookPages/Progress")
local action = {
    item = firstCopy,
    character = character,
    startPage = 0,
    rbpLastMoodPercent = 0,
    rbpMoodAlreadyRead = false,
    getJobDelta = function() return nil end,
}

ReadingEffects.applyThroughPage(action, 25)
near(values.boredom, 75, "only completed 10% milestones must apply")
near(values.stress, 0.76, "stress must use completed milestones")
near(values.unhappiness, 76, "unhappiness must use completed milestones")

ReadingEffects.applyThroughPage(action, 25)
near(values.boredom, 75, "the same milestone must not apply twice")
near(values.stress, 0.76, "stress must not apply twice")
near(values.unhappiness, 76, "unhappiness must not apply twice")

action.simulatedUpdatePage = 66
ISReadABook.update(action)
near(firstCopy:getAlreadyReadPages(), 66, "reading must advance only the active item")
near(
    character:getAlreadyReadPages(sharedType),
    0,
    "reading updates must not leave shared progress behind"
)
near(secondCopy:getAlreadyReadPages(), 0, "an inactive copy must remain unread")
action.simulatedUpdatePage = nil

-- Reproduce vanilla's unsafe shared-type value, then start another physical
-- copy of the same type. Its own page field must remain authoritative.
character:setAlreadyReadPages(sharedType, firstCopy:getAlreadyReadPages())
action.item = secondCopy
ISReadABook.getDuration(action)
near(secondCopy:getAlreadyReadPages(), 0, "a new physical copy must start unread")
near(action.startPage, 0, "duration must use the selected copy's progress")
near(
    character:getAlreadyReadPages(sharedType),
    0,
    "shared vanilla progress must be cleared after the compatibility call"
)
near(firstCopy:getAlreadyReadPages(), 66, "another copy must remain unchanged")

-- Tooltip and duration adapters expose only the selected item during the
-- vanilla call, and never persist that shared value afterward.
local observedProgress
Progress.withItemProgress(character, firstCopy, function()
    observedProgress = character:getAlreadyReadPages(sharedType)
end)
near(observedProgress, 66, "the adapter must expose the selected copy")
near(character:getAlreadyReadPages(sharedType), 0, "adapter state must be cleared")
near(secondCopy:getAlreadyReadPages(), 0, "inspecting one copy must not alter another")

-- Once the game's literature-title cooldown expires, each physical item's
-- progress is reset once for that completion record.
secondCopy:setAlreadyReadPages(secondCopy:getNumberOfPages())
readLiterature.values[secondCopy.data.literatureTitle] = 10
character.activeCooldowns[secondCopy.data.literatureTitle] = false
assert(Progress.resetAfterCooldown(character, secondCopy))
near(secondCopy:getAlreadyReadPages(), 0, "expired literature must become rereadable")
assert(not Progress.resetAfterCooldown(character, secondCopy))

print("Realistic Book Pages reading-effects tests passed")
