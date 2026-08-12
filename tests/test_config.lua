local root = arg[1] or "."
package.path = root
    .. "/RealisticBookPages/42/media/lua/shared/?.lua;"
    .. package.path

local Config = require("RealisticBookPages/Config")
local Defaults = require("RealisticBookPages/Defaults")

local passed = 0

local function equal(actual, expected, message)
    assert(
        actual == expected,
        (message or "values differ")
            .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual)
    )
    passed = passed + 1
end

local function inRange(actual, minimum, maximum, message)
    assert(
        actual >= minimum and actual <= maximum,
        (message or "value outside range")
            .. ": expected " .. minimum .. ".." .. maximum
            .. ", got " .. tostring(actual)
    )
    passed = passed + 1
end

local function near(actual, expected, message)
    assert(
        math.abs(actual - expected) < 0.000001,
        (message or "values differ")
            .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual)
    )
    passed = passed + 1
end

equal(Config.resolvePageSpec(120, 1, 16, 1000, "fixed"), 120)
equal(Config.resolvePageSpec("120", 1, 16, 1000, "numeric-string"), 120)
equal(Config.resolvePageSpec(2000, 1, 16, 1000, "clamped"), 1000)
equal(Config.resolvePageSpec("invalid", 144, 16, 1000, "invalid"), 144)

local bounded = Config.resolvePageSpec(">80<240", 1, 16, 1000, "bounded")
inRange(bounded, 80, 240)
equal(
    Config.resolvePageSpec(">80<240", 1, 16, 1000, "bounded"),
    bounded,
    "range resolution must be deterministic"
)

inRange(Config.resolvePageSpec(">80", 1, 16, 300, "open-max"), 80, 300)
inRange(Config.resolvePageSpec("<240", 1, 16, 1000, "open-min"), 16, 240)

local curve = Config.resolveCurve(
    "60/>80<100/<120/>200/300",
    { 1, 2, 3, 4, 5 },
    16,
    500,
    "TestSkill"
)
equal(curve[1], 60)
inRange(curve[2], 80, 100)
inRange(curve[3], 16, 120)
inRange(curve[4], 200, 500)
equal(curve[5], 300)

SandboxVars = {
    RealisticBookPages = {
        MinimumPages = 50,
        MaximumPages = 400,
        CarvingPages = "60/70/80/90/100",
        FallbackPages = "55/65/75/85/95",
        AdjustWeight = false,
        VaryOrdinaryBooks = true,
        OrdinaryBookPages = ">80<550",
        VaryMagazines = true,
        MagazinePages = ">16<72",
        VaryRecipeMagazines = true,
        RecipeMagazineBasePages = ">10<20",
        RecipeMagazinePagesPerRecipe = 4,
        VaryNewspapers = true,
        NewspaperPages = ">16<48",
    },
}

local runtime = Config.build({
    pagesBySkill = Defaults.pagesBySkill,
    pageOverrides = {},
})

equal(runtime.minimumPages, 50)
equal(runtime.maximumPages, 400)
equal(runtime.pagesBySkill.Carving[3], 80)
equal(runtime.fallbackPages[5], 95)
equal(runtime.weight.enabled, false)

local API = require("RealisticBookPages/Applicator")
ItemTag = {
    HARDCOVER = "hardcover",
    SOFTCOVER = "softcover",
    MAGAZINE = "magazine",
    NEWSPAPER = "newspaper",
}
local item = {
    pages = 220,
    weight = 1.0,
    boredom = 0,
    stress = 0,
    unhappiness = 0,
    luaCreate = "TestCallbacks.onCreate",
}

function item:getFullName() return "Base.BookCarving1" end
function item:getLuaCreate() return self.luaCreate end
function item:setLuaCreate(value) self.luaCreate = value end
function item:getSkillTrained() return "Carving" end
function item:getLevelSkillTrained() return 1 end
function item:getNumLevelsTrained() return 2 end
function item:getNumberOfPages() return self.pages end
function item:getActualWeight() return self.weight end
function item:getBoredomChange() return self.boredom end
function item:getStressChange() return self.stress end
function item:getUnhappyChange() return self.unhappiness end
function item:DoParam(value)
    local name, number = value:match("^(%w+)%s*=%s*([%d%.]+)$")
    if name == "NumberOfPages" then self.pages = tonumber(number) end
    if name == "Weight" then self.weight = tonumber(number) end
end

local ordinaryScript = {
    pages = -1,
    weight = 1.0,
    boredom = -50,
    stress = -40,
    unhappiness = -40,
    luaCreate = "TestCallbacks.onCreateOrdinary",
}

function ordinaryScript:getFullName() return "Base.Book_Fiction" end
function ordinaryScript:getLuaCreate() return self.luaCreate end
function ordinaryScript:setLuaCreate(value) self.luaCreate = value end
function ordinaryScript:getSkillTrained() return nil end
function ordinaryScript:getLevelSkillTrained() return 0 end
function ordinaryScript:getNumLevelsTrained() return 0 end
function ordinaryScript:getNumberOfPages() return self.pages end
function ordinaryScript:getActualWeight() return self.weight end
function ordinaryScript:getBoredomChange() return self.boredom end
function ordinaryScript:getStressChange() return self.stress end
function ordinaryScript:getUnhappyChange() return self.unhappiness end
function ordinaryScript:hasTag(tag) return tag == ItemTag.HARDCOVER end

local function newLiteratureScript(
    fullType,
    tag,
    weight,
    recipes,
    writable
)
    local script = {
        fullType = fullType,
        tag = tag,
        pages = -1,
        weight = weight,
        boredom = -20,
        stress = -15,
        unhappiness = 0,
        recipes = recipes or {},
        canBeWrite = writable == true,
        luaCreate = "TestCallbacks.onCreateLiterature",
    }

    function script:getFullName() return self.fullType end
    function script:getLuaCreate() return self.luaCreate end
    function script:setLuaCreate(value) self.luaCreate = value end
    function script:getSkillTrained() return nil end
    function script:getLevelSkillTrained() return 0 end
    function script:getNumLevelsTrained() return 0 end
    function script:getNumberOfPages() return self.pages end
    function script:getActualWeight() return self.weight end
    function script:getBoredomChange() return self.boredom end
    function script:getStressChange() return self.stress end
    function script:getUnhappyChange() return self.unhappiness end
    function script:getLearnedRecipes() return self.recipes end
    function script:hasTag(candidate) return candidate == self.tag end

    return script
end

local magazineScript = newLiteratureScript(
    "Base.Magazine_Art",
    ItemTag.MAGAZINE,
    0.5
)
local recipeMagazineScript = newLiteratureScript(
    "Base.HerbalistMag",
    ItemTag.MAGAZINE,
    0.5,
    { "Herbalist", "Baking" }
)
local newspaperScript = newLiteratureScript(
    "Base.Newspaper_Times_New",
    ItemTag.NEWSPAPER,
    0.5
)
local notebookScript = newLiteratureScript(
    "Base.Notebook",
    ItemTag.MAGAZINE,
    0.5,
    {},
    true
)
notebookScript.luaCreate = nil
local heavyMagazineScript = newLiteratureScript(
    "TestMod.HeavyMagazine",
    ItemTag.MAGAZINE,
    0.6
)
heavyMagazineScript.luaCreate = nil

local items = {}
function items:size() return 7 end
function items:get(index)
    if index == 0 then return item end
    if index == 1 then return ordinaryScript end
    if index == 2 then return magazineScript end
    if index == 3 then return recipeMagazineScript end
    if index == 4 then return newspaperScript end
    if index == 5 then return notebookScript end
    if index == 6 then return heavyMagazineScript end
    return nil
end

ScriptManager = {
    instance = {
        getAllItems = function() return items end,
    },
}

SandboxVars.RealisticBookPages.AdjustWeight = true
equal(API.applyPageCounts("test-enabled"), 1)
equal(item.pages, 60)
equal(item.luaCreate, "RealisticBookPages.onBookCreated")
equal(ordinaryScript.luaCreate, "RealisticBookPages.onBookCreated")
equal(magazineScript.luaCreate, "RealisticBookPages.onBookCreated")
equal(recipeMagazineScript.luaCreate, "RealisticBookPages.onBookCreated")
equal(newspaperScript.luaCreate, "RealisticBookPages.onBookCreated")
equal(notebookScript.luaCreate, nil, "writable notebooks must be excluded")
equal(
    heavyMagazineScript.luaCreate,
    nil,
    "miscellaneous magazines not originally weight 0.5 must be excluded"
)

SandboxVars.RealisticBookPages.Enabled = false
equal(API.applyPageCounts("test-disabled"), 1)
equal(item.pages, 220, "disabling must restore the original pages")
equal(item.weight, 1.0, "disabling must restore the original weight")

TestCallbacks = { calls = 0 }
function TestCallbacks.onCreate()
    TestCallbacks.calls = TestCallbacks.calls + 1
end
function TestCallbacks.onCreateOrdinary()
    TestCallbacks.calls = TestCallbacks.calls + 1
end
function TestCallbacks.onCreateLiterature()
    TestCallbacks.calls = TestCallbacks.calls + 1
end

local function newSpawnedBook()
    local spawned = {
        pages = 220,
        weight = 1.0,
        customWeight = false,
    }

    function spawned:getScriptItem() return item end
    function spawned:getSkillTrained() return "Carving" end
    function spawned:getLvlSkillTrained() return 1 end
    function spawned:getNumLevelsTrained() return 2 end
    function spawned:setNumberOfPages(value) self.pages = value end
    function spawned:setActualWeight(value) self.weight = value end
    function spawned:setCustomWeight(value) self.customWeight = value end

    return spawned
end

local nextRoll = 80
ZombRand = function(minimum, maximum)
    assert(nextRoll >= minimum and nextRoll < maximum)
    local result = nextRoll
    nextRoll = nextRoll + 1
    return result
end

-- Changing SandboxVars after initialisation affects the next spawned book.
SandboxVars.RealisticBookPages.Enabled = true
SandboxVars.RealisticBookPages.CarvingPages = ">80<82/70/80/90/100"

local firstSpawn = newSpawnedBook()
local secondSpawn = newSpawnedBook()
API.onBookCreated(firstSpawn)
API.onBookCreated(secondSpawn)
equal(firstSpawn.pages, 80)
equal(secondSpawn.pages, 81)
equal(firstSpawn.customWeight, true)
equal(TestCallbacks.calls, 2, "existing OnCreate callback must be chained")

-- Clients must not reroll the server-provided instance value.
isClient = function() return true end
local clientSpawn = newSpawnedBook()
clientSpawn.pages = 777
API.onBookCreated(clientSpawn)
equal(clientSpawn.pages, 777)
equal(TestCallbacks.calls, 3, "chained callback must still run on clients")
isClient = nil

local function addMoodMethods(spawned)
    spawned.modData = {}
    function spawned:getModData() return self.modData end
    function spawned:setBoredomChange(value) self.boredom = value end
    function spawned:setStressChange(value) self.stress = value end
    function spawned:setUnhappyChange(value) self.unhappiness = value end
    function spawned:getBoredomChange() return self.boredom or 0 end
    function spawned:getStressChange() return self.stress or 0 end
    function spawned:getUnhappyChange() return self.unhappiness or 0 end
end

local ordinarySpawn = {
    pages = -1,
    weight = 1.0,
    customWeight = false,
}
function ordinarySpawn:getScriptItem() return ordinaryScript end
function ordinarySpawn:getSkillTrained() return nil end
function ordinarySpawn:getLvlSkillTrained() return 0 end
function ordinarySpawn:getNumLevelsTrained() return 0 end
function ordinarySpawn:setNumberOfPages(value) self.pages = value end
function ordinarySpawn:setActualWeight(value) self.weight = value end
function ordinarySpawn:setCustomWeight(value) self.customWeight = value end
addMoodMethods(ordinarySpawn)

SandboxVars.RealisticBookPages.OrdinaryBookPages = 44
SandboxVars.RealisticBookPages.MinimumPages = 16
API.onBookCreated(ordinarySpawn)
equal(ordinarySpawn.pages, 44, "ordinary books must roll pages directly")
equal(ordinarySpawn.weight, 0.4)
equal(ordinarySpawn.customWeight, true)
equal(ordinarySpawn.boredom, -20)
near(ordinarySpawn.stress, -0.16)
equal(ordinarySpawn.unhappiness, -16)
equal(TestCallbacks.calls, 4, "ordinary title OnCreate callback must be chained")

local rangeOk = API.setLiteraturePageSpec("ordinaryBook", 66)
equal(rangeOk, true)
local overriddenOrdinarySpawn = {
    pages = -1,
    weight = 1.0,
    customWeight = false,
}
function overriddenOrdinarySpawn:getScriptItem() return ordinaryScript end
function overriddenOrdinarySpawn:getSkillTrained() return nil end
function overriddenOrdinarySpawn:getLvlSkillTrained() return 0 end
function overriddenOrdinarySpawn:getNumLevelsTrained() return 0 end
function overriddenOrdinarySpawn:setNumberOfPages(value) self.pages = value end
function overriddenOrdinarySpawn:setActualWeight(value) self.weight = value end
function overriddenOrdinarySpawn:setCustomWeight(value) self.customWeight = value end
addMoodMethods(overriddenOrdinarySpawn)
API.onBookCreated(overriddenOrdinarySpawn)
equal(overriddenOrdinarySpawn.pages, 66)
equal(overriddenOrdinarySpawn.weight, 0.48)

local function newLiteratureSpawn(script)
    local spawned = {
        pages = -1,
        weight = script.weight,
        customWeight = false,
    }
    function spawned:getScriptItem() return script end
    function spawned:getSkillTrained() return nil end
    function spawned:getLvlSkillTrained() return 0 end
    function spawned:getNumLevelsTrained() return 0 end
    function spawned:setNumberOfPages(value) self.pages = value end
    function spawned:setActualWeight(value) self.weight = value end
    function spawned:setCustomWeight(value) self.customWeight = value end
    addMoodMethods(spawned)
    return spawned
end

SandboxVars.RealisticBookPages.MinimumPages = 1
SandboxVars.RealisticBookPages.MagazinePages = 22
SandboxVars.RealisticBookPages.RecipeMagazineBasePages = 10
SandboxVars.RealisticBookPages.RecipeMagazinePagesPerRecipe = 4
SandboxVars.RealisticBookPages.NewspaperPages = 66

local magazineSpawn = newLiteratureSpawn(magazineScript)
local recipeMagazineSpawn = newLiteratureSpawn(recipeMagazineScript)
local newspaperSpawn = newLiteratureSpawn(newspaperScript)
API.onBookCreated(magazineSpawn)
API.onBookCreated(recipeMagazineSpawn)
API.onBookCreated(newspaperSpawn)
equal(magazineSpawn.pages, 22)
equal(magazineSpawn.weight, 0.33)
equal(recipeMagazineSpawn.pages, 18)
equal(recipeMagazineSpawn.weight, 0.31)
equal(newspaperSpawn.pages, 66)
equal(newspaperSpawn.weight, 0.48)
equal(magazineSpawn.customWeight, true)
equal(recipeMagazineSpawn.customWeight, true)
equal(newspaperSpawn.customWeight, true)
equal(TestCallbacks.calls, 8, "all literature OnCreate callbacks must be chained")

local magazineRangeOk = API.setLiteraturePageSpec("magazine", 88)
equal(magazineRangeOk, true)
local overriddenMagazineSpawn = newLiteratureSpawn(magazineScript)
API.onBookCreated(overriddenMagazineSpawn)
equal(overriddenMagazineSpawn.pages, 88)
equal(overriddenMagazineSpawn.weight, 0.55)

print("Realistic Book Pages tests passed: " .. passed)
