local Defaults = require("RealisticBookPages/Defaults")
local Config = require("RealisticBookPages/Config")

RealisticBookPages = RealisticBookPages or {}
local API = RealisticBookPages
local baselineByItem = {}
local originalOnCreateByType = {}
local literatureTypeByFullType = {}
local ON_CREATE_CALLBACK = "RealisticBookPages.onBookCreated"
local MOOD_DATA_VERSION = 2
local LITERATURE_KINDS = {
    ordinaryBook = true,
    magazine = true,
    recipeMagazine = true,
    newspaper = true,
}

API.VERSION = "2.0.0"
API.pagesBySkill = API.pagesBySkill or {}
API.skillAliases = API.skillAliases or {}
API.pageOverrides = API.pageOverrides or {}
API.ordinaryBookTypes = API.ordinaryBookTypes or {}
API.literatureTypes = API.literatureTypes or {}
API.literatureWeightOverrides = API.literatureWeightOverrides or {}

for skill, pages in pairs(Defaults.pagesBySkill) do
    if API.pagesBySkill[skill] == nil then
        API.pagesBySkill[skill] = pages
    end
end

for alias, skill in pairs(Defaults.skillAliases) do
    if API.skillAliases[alias] == nil then
        API.skillAliases[alias] = skill
    end
end

local function validateCurve(curve)
    if type(curve) == "number" or type(curve) == "string" then
        return true
    end

    return type(curve) == "table" and #curve == 5
end

-- Public pre-initialisation API for expansion mods and server-side code.
-- Curves accept five numbers/page-spec strings, or a /, ;, or comma-separated
-- string. Slash is recommended in sandbox-options.txt.
function API.registerSkill(skill, curve, aliases)
    if type(skill) ~= "string" or skill == "" or not validateCurve(curve) then
        return false, "skill must be named and curve must contain five tiers"
    end

    API.pagesBySkill[skill] = curve

    if type(aliases) == "table" then
        for _, alias in ipairs(aliases) do
            if type(alias) == "string" and alias ~= "" then
                API.skillAliases[alias] = skill
            end
        end
    end

    return true
end

function API.setPageCurve(skill, curve)
    if type(skill) ~= "string" or skill == "" or not validateCurve(curve) then
        return false, "skill must be named and curve must contain five tiers"
    end

    API.pageOverrides[skill] = curve
    return true
end

function API.setPageSpec(skill, tier, spec)
    if type(skill) ~= "string" or skill == "" then
        return false, "skill must be named"
    end
    if type(tier) ~= "number" or tier < 1 or tier > 5 then
        return false, "tier must be an integer from 1 to 5"
    end
    if type(spec) ~= "number" and type(spec) ~= "string" then
        return false, "page value must be a number or range string"
    end

    tier = math.floor(tier)

    local curve = API.pageOverrides[skill]
    if type(curve) ~= "table" then
        local fallback = API.pagesBySkill[skill] or Defaults.fallbackPages
        curve = {
            fallback[1],
            fallback[2],
            fallback[3],
            fallback[4],
            fallback[5],
        }
        API.pageOverrides[skill] = curve
    end

    curve[tier] = spec
    return true
end

function API.setFallbackCurve(curve)
    if not validateCurve(curve) then
        return false, "fallback curve must contain five tiers"
    end

    API.fallbackOverride = curve
    return true
end

-- Literature mods can opt in explicitly. Correctly tagged books, magazines,
-- recipe magazines, and newspapers are discovered automatically during boot.
function API.registerLiterature(fullType, kind)
    if type(fullType) ~= "string" or fullType == "" then
        return false, "literature type must be a non-empty full item type"
    end
    if not LITERATURE_KINDS[kind] then
        return false, "unsupported literature kind " .. tostring(kind)
    end

    API.literatureTypes[fullType] = kind
    return true
end

function API.registerOrdinaryBook(fullType)
    local ok, message = API.registerLiterature(fullType, "ordinaryBook")
    if ok then
        API.ordinaryBookTypes[fullType] = true
    end
    return ok, message
end

function API.setLiteratureWeightRange(kind, minimum, maximum)
    if not LITERATURE_KINDS[kind] then
        return false, "unsupported literature kind " .. tostring(kind)
    end

    minimum = tonumber(minimum)
    maximum = tonumber(maximum)
    if not minimum or not maximum or minimum <= 0 or maximum <= 0 then
        return false, "literature weights must be positive numbers"
    end

    if minimum > maximum then
        minimum, maximum = maximum, minimum
    end

    API.literatureWeightOverrides[kind] = {
        minimum = minimum,
        maximum = maximum,
    }
    return true
end

function API.setOrdinaryBookWeightRange(minimum, maximum)
    local ok, message = API.setLiteratureWeightRange(
        "ordinaryBook",
        minimum,
        maximum
    )
    if ok then
        API.ordinaryBookWeightOverride =
            API.literatureWeightOverrides.ordinaryBook
    end
    return ok, message
end

local function getBookWeight(pageCount, weightConfig)
    local bindingWeight = math.min(
        weightConfig.bindingWeight,
        weightConfig.referenceWeight
    )
    local paperAtReference = weightConfig.referenceWeight - bindingWeight
    local weight = bindingWeight
        + paperAtReference * pageCount / weightConfig.referencePages

    return math.max(0.01, math.floor(weight * 100 + 0.5) / 100)
end

local function findGlobalFunction(path)
    local value = _G

    for part in path:gmatch("[^%.]+") do
        if type(value) ~= "table" then
            return nil
        end
        value = value[part]
    end

    return type(value) == "function" and value or nil
end

local function callOriginalOnCreate(fullType, item)
    local name = originalOnCreateByType[fullType]
    if not name then
        return
    end

    local callback = findGlobalFunction(name)
    if not callback then
        print(
            "Realistic Book Pages: could not find chained OnCreate callback "
                .. name .. " for " .. fullType
        )
        return
    end

    local ok, message = pcall(callback, item)
    if not ok then
        print(
            "Realistic Book Pages: chained OnCreate callback failed for "
                .. fullType .. ": " .. tostring(message)
        )
    end
end

local function readBookMetadata(item)
    local ok, skill, startingLevel, levelsTrained = pcall(function()
        return item:getSkillTrained(),
            item:getLevelSkillTrained(),
            item:getNumLevelsTrained()
    end)

    if not ok then
        return nil
    end

    return skill, startingLevel, levelsTrained
end

local function getBaseline(item)
    if baselineByItem[item] then
        return baselineByItem[item]
    end

    local ok, pages, weight, boredom, stress, unhappiness = pcall(function()
        return item:getNumberOfPages(),
            item:getActualWeight(),
            item:getBoredomChange(),
            item:getStressChange(),
            item:getUnhappyChange()
    end)

    if not ok then
        return nil
    end

    local baseline = {
        pages = pages,
        weight = weight,
        boredom = boredom,
        stress = stress,
        unhappiness = unhappiness,
    }
    baselineByItem[item] = baseline
    return baseline
end

local function installOnCreate(item)
    local ok, fullType, current = pcall(function()
        return item:getFullName(), item:getLuaCreate()
    end)

    if not ok or not fullType then
        return false
    end

    if current and current ~= "" and current ~= ON_CREATE_CALLBACK then
        originalOnCreateByType[fullType] = current
    end

    item:setLuaCreate(ON_CREATE_CALLBACK)
    return true
end

local function hasItemTag(item, tag)
    if not ItemTag or not tag then
        return false
    end

    local ok, result = pcall(function()
        return item:hasTag(tag)
    end)
    return ok and result or false
end

local function hasLearnedRecipes(item)
    local ok, recipes = pcall(function()
        return item:getLearnedRecipes()
    end)
    if not ok or not recipes then
        return false
    end
    if type(recipes) == "table" then
        return #recipes > 0
    end

    local sizeOk, size = pcall(function()
        return recipes:size()
    end)
    return sizeOk and size > 0 or false
end

local function isWritable(item)
    local ok, writable = pcall(function()
        return item.canBeWrite
    end)
    return ok and writable == true
end

local function isOriginalHalfWeight(item)
    local ok, weight = pcall(function()
        return item:getActualWeight()
    end)
    return ok and math.abs(weight - 0.5) < 0.0001
end

local function classifyLiterature(item, fullType)
    local explicit = literatureTypeByFullType[fullType]
        or API.literatureTypes[fullType]
    if explicit then
        return explicit
    end
    if API.ordinaryBookTypes[fullType] then
        return "ordinaryBook"
    end

    if hasItemTag(item, ItemTag and ItemTag.HARDCOVER)
        or hasItemTag(item, ItemTag and ItemTag.SOFTCOVER) then
        return "ordinaryBook"
    end
    if hasItemTag(item, ItemTag and ItemTag.NEWSPAPER) then
        return "newspaper"
    end
    if hasItemTag(item, ItemTag and ItemTag.MAGAZINE) then
        if hasLearnedRecipes(item) then
            return "recipeMagazine"
        end
        if isOriginalHalfWeight(item) and not isWritable(item) then
            return "magazine"
        end
    end

    return nil
end

local function setInstanceWeight(item, weight, custom)
    item:setActualWeight(weight)
    item:setCustomWeight(custom)
end

local function setLiteratureMoodEffects(item, baseline, spawnedWeight)
    if not baseline or not baseline.weight or baseline.weight <= 0 then
        return
    end

    local settings = Config.resolveMoodSettings()
    local multiplier = settings.scaleByWeight
        and spawnedWeight / baseline.weight or 1
    local boredom, stress, unhappiness = Config.resolveRuntimeMoodChanges(
        baseline.boredom,
        baseline.stress,
        baseline.unhappiness,
        multiplier
    )

    item:setBoredomChange(boredom)
    item:setStressChange(stress)
    item:setUnhappyChange(unhappiness)

    local data = item:getModData()
    data.RBP_GradualMoodEffects = true
    data.RBP_MoodDataVersion = MOOD_DATA_VERSION
    data.RBP_BoredomChange = boredom
    data.RBP_StressChange = stress
    data.RBP_UnhappyChange = unhappiness
    data.RBP_OriginalLiteratureWeight = baseline.weight
    data.RBP_MoodEffectMultiplier = multiplier
end

-- Lazily prepares literature from saves created before mood scaling existed.
-- New instances are prepared by onBookCreated; this path also makes upgrades
-- safe for persistent multiplayer worlds without rescanning every container.
function API.prepareLiteratureMoodEffects(item)
    if not item then
        return false
    end

    local data = item:getModData()
    if data.RBP_GradualMoodEffects == true
        and data.RBP_MoodDataVersion == MOOD_DATA_VERSION then
        return true
    end

    local skill, startingLevel, levelsTrained = readBookMetadata(item)
    if skill and skill ~= ""
        and Defaults.tierByStartingLevel[startingLevel]
        and levelsTrained == 2 then
        return false
    end

    local scriptItem = item:getScriptItem()
    if not scriptItem then
        return false
    end

    local fullType = scriptItem:getFullName()
    if not classifyLiterature(scriptItem, fullType) then
        return false
    end
    if item:getNumberOfPages() <= 0 then
        return false
    end

    local baseline = getBaseline(scriptItem)
    if not baseline then
        return false
    end

    setLiteratureMoodEffects(item, baseline, item:getActualWeight())
    return true
end

-- Called by the game's item OnCreate hook for every newly spawned qualifying
-- item. The server (or singleplayer) rolls; MP clients keep synchronized data.
function API.onBookCreated(item)
    if not item then
        return
    end

    local ok, scriptItem, fullType = pcall(function()
        local script = item:getScriptItem()
        return script, script and script:getFullName()
    end)

    if not ok or not scriptItem or not fullType then
        return
    end

    callOriginalOnCreate(fullType, item)

    if isClient and isClient() then
        return
    end

    local metadataOk, skill, startingLevel, levelsTrained = pcall(function()
        return item:getSkillTrained(),
            item:getLvlSkillTrained(),
            item:getNumLevelsTrained()
    end)
    local tier = metadataOk and Defaults.tierByStartingLevel[startingLevel]

    local baseline = getBaseline(scriptItem)

    if not skill or skill == "" or not tier or levelsTrained ~= 2 then
        local kind = classifyLiterature(scriptItem, fullType)
        if not kind then
            return
        end

        local literature = Config.resolveLiteratureSpawn(API, kind)
        if not literature.enabled then
            if baseline then
                item:setNumberOfPages(baseline.pages)
                setInstanceWeight(item, baseline.weight, false)
            end
            return
        end

        item:setNumberOfPages(literature.pageCount)
        setInstanceWeight(item, literature.weight, true)
        setLiteratureMoodEffects(item, baseline, literature.weight)
        return
    end

    local canonicalSkill = API.skillAliases[skill] or skill
    local runtime = Config.resolveSpawn(API, canonicalSkill, tier)

    if not runtime.enabled then
        if baseline then
            item:setNumberOfPages(baseline.pages)
            setInstanceWeight(item, baseline.weight, false)
        end
        return
    end

    item:setNumberOfPages(runtime.pageCount)

    if runtime.weight.enabled then
        setInstanceWeight(
            item,
            getBookWeight(runtime.pageCount, runtime.weight),
            true
        )
    elseif baseline then
        setInstanceWeight(item, baseline.weight, false)
    end
end

function API.applyPageCounts(reason)
    if not ScriptManager or not ScriptManager.instance then
        print("Realistic Book Pages: ScriptManager is unavailable; skipped")
        return 0
    end

    local config = Config.build(API)
    local items = ScriptManager.instance:getAllItems()
    local changed = 0
    local skipped = 0
    local literatureInstalled = 0

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local skill, startingLevel, levelsTrained = readBookMetadata(item)
        local tier = Defaults.tierByStartingLevel[startingLevel]

        -- Skill books remain page-first; other literature is weight-first.
        if skill and skill ~= "" and tier and levelsTrained == 2 then
            local baseline = getBaseline(item)
            installOnCreate(item)
            local canonicalSkill = API.skillAliases[skill] or skill
            local curve = config.pagesBySkill[canonicalSkill]
                or config.fallbackPages
            local pageCount = curve[tier]

            local ok = pcall(function()
                if config.enabled then
                    item:DoParam("NumberOfPages = " .. pageCount)
                elseif baseline then
                    item:DoParam("NumberOfPages = " .. baseline.pages)
                end

                if config.enabled and config.weight.enabled then
                    local weight = getBookWeight(pageCount, config.weight)
                    item:DoParam("Weight = " .. weight)
                elseif baseline then
                    item:DoParam("Weight = " .. baseline.weight)
                end
            end)

            if ok then
                changed = changed + 1
            else
                skipped = skipped + 1
            end
        else
            local fullType = item:getFullName()
            local kind = classifyLiterature(item, fullType)
            if kind then
                literatureTypeByFullType[fullType] = kind
                if installOnCreate(item) then
                    literatureInstalled = literatureInstalled + 1
                end
            end
        end
    end

    local suffix = skipped > 0 and (", skipped " .. skipped .. " invalid items") or ""
    print(
        "Realistic Book Pages: "
            .. (config.enabled and "updated " or "restored ")
            .. changed .. " skill books"
            .. ", hooked " .. literatureInstalled .. " literature types"
            .. suffix .. (reason and (" [" .. reason .. "]") or "")
    )

    return changed
end

API.apply = API.applyPageCounts
API.resolvePageSpec = Config.resolvePageSpec
API.resolveCurve = Config.resolveCurve

return API
