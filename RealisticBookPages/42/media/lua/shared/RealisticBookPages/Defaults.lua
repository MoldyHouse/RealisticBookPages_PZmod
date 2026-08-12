local Defaults = {}

Defaults.minimumPages = 16
Defaults.maximumPages = 1000
Defaults.fallbackPages = { 120, 220, 280, 360, 440 }

Defaults.weight = {
    enabled = true,
    referencePages = 220,
    referenceWeight = 1.0,
    bindingWeight = 0.25,
}

Defaults.mood = {
    scaleByWeight = true,
    applyWhileReading = true,
    stepPercent = 10,
}

Defaults.ordinaryBooks = {
    enabled = true,
    pages = ">80<550",
}

Defaults.magazines = {
    enabled = true,
    pages = ">16<72",
}

Defaults.recipeMagazines = {
    enabled = true,
    basePages = ">10<20",
    pagesPerRecipe = 4,
}

Defaults.newspapers = {
    enabled = true,
    pages = ">16<48",
}

Defaults.literatureKinds = {
    ordinaryBook = {
        enabledOption = "VaryOrdinaryBooks",
        pagesOption = "OrdinaryBookPages",
        defaults = Defaults.ordinaryBooks,
    },
    magazine = {
        enabledOption = "VaryMagazines",
        pagesOption = "MagazinePages",
        defaults = Defaults.magazines,
    },
    recipeMagazine = {
        enabledOption = "VaryRecipeMagazines",
        basePagesOption = "RecipeMagazineBasePages",
        pagesPerRecipeOption = "RecipeMagazinePagesPerRecipe",
        defaults = Defaults.recipeMagazines,
    },
    newspaper = {
        enabledOption = "VaryNewspapers",
        pagesOption = "NewspaperPages",
        defaults = Defaults.newspapers,
    },
}

Defaults.tierByStartingLevel = {
    [1] = 1,
    [3] = 2,
    [5] = 3,
    [7] = 4,
    [9] = 5,
}

Defaults.tierNames = {
    "Beginner",
    "Intermediate",
    "Advanced",
    "Expert",
    "Master",
}

-- The option name is deliberately kept separate from the skill identifier.
-- This lets a future game rename a perk while preserving existing server INIs.
Defaults.skills = {
    { id = "Carving",       option = "CarvingPages",       pages = { 56, 104, 192, 304, 416 } },
    { id = "FlintKnapping", option = "FlintKnappingPages", pages = { 56, 112, 176, 232, 304 } },
    { id = "Trapping",      option = "TrappingPages",      pages = { 72, 112, 176, 256, 372 } },
    { id = "Butchering",    option = "ButcheringPages",    pages = { 80, 104, 160, 256, 384 } },
    { id = "Fishing",       option = "FishingPages",       pages = { 80, 128, 192, 272, 368 } },
    { id = "Foraging",      option = "ForagingPages",      pages = { 88, 160, 248, 352, 480 } },
    { id = "FirstAid",      option = "FirstAidPages",      pages = { 96, 168, 272, 432, 592 } },

    { id = "Maintenance",   option = "MaintenancePages",   pages = { 72, 128, 192, 304, 416 } },
    { id = "Tailoring",     option = "TailoringPages",     pages = { 80, 160, 256, 384, 544 } },
    { id = "Pottery",       option = "PotteryPages",       pages = { 88, 128, 208, 320, 448 } },
    { id = "Cooking",       option = "CookingPages",       pages = { 96, 144, 240, 400, 608 } },
    { id = "Tracking",      option = "TrackingPages",      pages = { 104, 144, 224, 336, 480 } },
    { id = "MetalWelding",  option = "MetalworkingPages",  pages = { 112, 216, 304, 480, 656 } },
    { id = "Mechanics",     option = "MechanicsPages",     pages = { 136, 240, 336, 504, 672 } },
    { id = "Electricity",   option = "ElectricityPages",   pages = { 152, 224, 352, 456, 640 } },

    { id = "Farming",       option = "FarmingPages",       pages = { 104, 184, 288, 448, 608 } },
    { id = "Glassmaking",   option = "GlassmakingPages",   pages = { 96, 176, 288, 456, 640 } },
    { id = "Husbandry",     option = "HusbandryPages",     pages = { 112, 192, 320, 488, 648 } },
    { id = "Blacksmith",    option = "BlacksmithingPages", pages = { 120, 176, 298, 464, 656 } },
    { id = "Carpentry",     option = "CarpentryPages",     pages = { 96, 176, 288, 448, 608 } },
    { id = "Masonry",       option = "MasonryPages",       pages = { 80, 160, 256, 400, 576 } },

    { id = "Spear",         option = "SpearPages",         pages = { 64, 88, 144, 208, 288 } },
    { id = "ShortBlunt",    option = "ShortBluntPages",    pages = { 64, 80, 112, 160, 208 } },
    { id = "LongBlunt",     option = "LongBluntPages",     pages = { 72, 96, 128, 176, 256 } },
    { id = "Axe",           option = "AxePages",           pages = { 72, 104, 128, 176, 256 } },
    { id = "ShortBlade",    option = "ShortBladePages",    pages = { 80, 104, 144, 208, 304 } },
    { id = "Aiming",        option = "AimingPages",        pages = { 80, 120, 176, 248, 352 } },
    { id = "Reloading",     option = "ReloadingPages",     pages = { 64, 96, 128, 176, 256 } },
    { id = "LongBlade",     option = "LongBladePages",     pages = { 96, 136, 192, 304, 416 } },

    { id = "Strength",      option = "StrengthPages",      pages = { 96, 128, 168, 272, 416 } },
    { id = "Fitness",       option = "FitnessPages",       pages = { 104, 136, 184, 304, 464 } },
    { id = "Running",       option = "RunningPages",       pages = { 72, 112, 176, 248, 352 } },
    { id = "Nimble",        option = "NimblePages",        pages = { 80, 136, 184, 280, 416 } },
    { id = "Lightfooted",   option = "LightfootedPages",   pages = { 88, 112, 152, 192, 272 } },
    { id = "Sneaking",      option = "SneakingPages",      pages = { 96, 120, 176, 256, 352 } },
}

Defaults.pagesBySkill = {}
Defaults.optionBySkill = {}

for _, skill in ipairs(Defaults.skills) do
    Defaults.pagesBySkill[skill.id] = skill.pages
    Defaults.optionBySkill[skill.id] = skill.option
end

Defaults.skillAliases = {
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

return Defaults
