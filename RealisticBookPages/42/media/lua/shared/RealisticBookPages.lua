-- Realistic Book Pages
--
-- Page counts follow the realistic breadth and complexity of each subject.
-- Most counts use multiples of eight, reflecting common printed-book
-- signatures without forcing unrelated skills into the same total length.

RealisticBookPages = RealisticBookPages or {}

RealisticBookPages.pagesBySkill = {
    -- Immediate Survivor Related
    Carving       = { 56, 104, 192, 304, 416 },
    FlintKnapping = { 56, 112, 176, 232, 304 },
    Trapping      = { 72, 112, 176, 256, 372 },
    Butchering    = { 80, 104, 160, 256, 384 },
    Fishing       = { 80, 128, 192, 272, 368 },
    Foraging      = { 88, 160, 248, 352, 480 },
    FirstAid      = { 96, 168, 272, 432, 592 },
    -- Mid Survivor Related
    Maintenance   = { 72, 128, 192, 304, 416 },
    Tailoring     = { 80, 160, 256, 384, 544 },
    Pottery       = { 88, 128, 208, 320, 448 },
    Cooking       = { 96, 144, 240, 400, 608 },
    Tracking      = { 104, 144, 224, 336, 480 },
    MetalWelding  = { 112, 216, 304, 480, 656 },
    Mechanics     = { 136, 240, 336, 504, 672 },
    Electricity   = { 152, 224, 352, 456, 640 },
    -- Late Survivor Related
    Glassmaking   = { 96, 176, 288, 456, 640 },
    Farming       = { 104, 184, 288, 448, 608 },
    Husbandry     = { 112, 192, 320, 488, 648 },
    Blacksmith    = { 120, 176, 298, 464, 656 },
    -- Construction Related
    Carpentry     = { 96, 176, 288, 448, 608 },
    Masonry       = { 80, 160, 256, 400, 576 },

    -- Combat -- Early game
    Spear         = { 64, 88, 144, 208, 288 },
    ShortBlunt    = { 64, 80, 112, 160, 208 },
    LongBlunt     = { 72, 96, 128, 176, 256 },
    Axe           = { 72, 104, 128, 176, 256 },
    ShortBlade    = { 80, 104, 144, 208, 304 },

    -- Combat -- Mid game
    Aiming        = { 80, 120, 176, 248, 352 },
    Reloading     = { 64, 96, 128, 176, 256 },

    -- Combat -- Late game
    LongBlade     = { 96, 136, 192, 304, 416 },

    -- Physical Related
    -- Core
    Strength      = { 96, 128, 168, 272, 416 },
    Fitness       = { 104, 136, 184, 304, 464 },

    -- Combat
    Running       = { 72, 112, 176, 248, 352 },
    Nimble        = { 80, 136, 184, 280, 416 },
    Lightfooted   = { 88, 112, 152, 192, 272 },
    Sneaking      = { 96, 120, 176, 256, 352 },

}

-- Standard five-tier books added by other mods receive the vanilla Build 42
-- curve when their SkillTrained value is unlisted or has an empty curve above.
RealisticBookPages.defaultPages = { 120, 220, 280, 360, 440 }

-- Generated vanilla books use several reader-facing skill names, while mods
-- may use the corresponding internal perk IDs. Normalize both conventions so
-- a mod-added book receives the intended canonical curve.
RealisticBookPages.skillAliases = {
    Woodwork        = "Carpentry",
    Doctor          = "FirstAid",
    PlantScavenging = "Foraging",
    SmallBlade      = "ShortBlade",
    SmallBlunt      = "ShortBlunt",
    Blunt           = "LongBlunt",
    Sprinting       = "Running",
    Lightfoot       = "Lightfooted",
    Sneak           = "Sneaking",
}

local tierByStartingLevel = {
    [1] = 1,
    [3] = 2,
    [5] = 3,
    [7] = 4,
    [9] = 5,
}

-- A 220-page book retains the vanilla weight of 1.0. The fixed 0.25 portion
-- represents the cover and binding; the remaining weight scales with paper.
local function getBookWeight(pageCount)
    local weight = 0.25 + (0.75 * pageCount / 220)
    return math.floor(weight * 100 + 0.5) / 100
end

local function applyPageCounts()
    local items = ScriptManager.instance:getAllItems()
    local changed = 0

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local skill = item:getSkillTrained()
        local tier = tierByStartingLevel[item:getLevelSkillTrained()]

        -- Restrict the change to the normal books that train two skill levels.
        -- Recipe magazines and other literature are left untouched.
        if skill and skill ~= "" and tier and item:getNumLevelsTrained() == 2 then
            local canonicalSkill = RealisticBookPages.skillAliases[skill] or skill
            local skillPages = RealisticBookPages.pagesBySkill[canonicalSkill]
            local pageCount = skillPages and skillPages[tier]
                or RealisticBookPages.defaultPages[tier]
            local weight = getBookWeight(pageCount)

            item:DoParam("NumberOfPages = " .. pageCount)
            item:DoParam("Weight = " .. weight)
            changed = changed + 1
        end
    end

    print("Realistic Book Pages: updated " .. changed .. " skill books")
end

RealisticBookPages.applyPageCounts = applyPageCounts

-- OnGameBoot is the supported point for changing loaded script items. OnLoad
-- repeats the idempotent pass after a save loads, improving mod-load-order
-- compatibility without replacing any complete vanilla item definition.
Events.OnGameBoot.Add(applyPageCounts)
Events.OnLoad.Add(applyPageCounts)
