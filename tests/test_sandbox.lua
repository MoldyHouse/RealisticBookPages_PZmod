local root = arg[1] or "."
package.path = root
    .. "/RealisticBookPages/42/media/lua/shared/?.lua;"
    .. package.path

local Defaults = require("RealisticBookPages/Defaults")
local Config = require("RealisticBookPages/Config")
local sandboxPath = root .. "/RealisticBookPages/42/media/sandbox-options.txt"
local translationPath = root
    .. "/RealisticBookPages/42/media/lua/shared/Translate/EN/Sandbox.json"

local sandboxFile = assert(io.open(sandboxPath, "r"))
local sandbox = sandboxFile:read("*a")
sandboxFile:close()

local translationFile = assert(io.open(translationPath, "r"))
local translations = translationFile:read("*a")
translationFile:close()

local options = {}
for name, body in sandbox:gmatch(
    "option%s+RealisticBookPages%.([%w_]+)%s*(%b{})"
) do
    options[name] = {
        default = body:match("default%s*=%s*([^,]-)%s*,"),
        page = body:match("page%s*=%s*([^,]-)%s*,"),
        translation = body:match("translation%s*=%s*([^,]-)%s*,"),
    }
end

assert(options.Enabled, "general sandbox options were not parsed")
assert(options.FallbackPages.default == "120/220/280/360/440")

local baseOptions = {
    Enabled = true,
    MinimumPages = true,
    MaximumPages = true,
    ReferencePages = true,
    ReferenceWeight = true,
    BindingWeight = true,
}
local literatureOptions = {
    VaryOrdinaryBooks = true,
    ScaleMoodEffectsByWeight = true,
    ApplyMoodEffectsWhileReading = true,
    MoodEffectStepPercent = true,
    OrdinaryBookPages = true,
    VaryMagazines = true,
    MagazinePages = true,
    VaryRecipeMagazines = true,
    RecipeMagazineBasePages = true,
    RecipeMagazinePagesPerRecipe = true,
    VaryNewspapers = true,
    NewspaperPages = true,
}

for name, option in pairs(options) do
    local expectedPage = "RealisticBookPages_Skills"
    if baseOptions[name] then
        expectedPage = "RealisticBookPages_Base"
    elseif literatureOptions[name] then
        expectedPage = "RealisticBookPages_Literature"
    end

    assert(
        option.page == expectedPage,
        name .. " must be displayed on " .. expectedPage
    )

    local key = "Sandbox_" .. option.translation
    assert(
        translations:find('"' .. key .. '"%s*:'),
        "missing English translation " .. key
    )
    assert(
        translations:find('"' .. key .. '_tooltip"%s*:'),
        "missing English tooltip " .. key .. "_tooltip"
    )
end

for _, page in ipairs({ "Base", "Skills", "Literature" }) do
    local key = "Sandbox_RealisticBookPages_" .. page
    assert(
        translations:find('"' .. key .. '"%s*:'),
        "missing translation for Sandbox page " .. page
    )
end

for _, skill in ipairs(Defaults.skills) do
    local option = assert(options[skill.option], "missing option " .. skill.option)
    local curve = Config.resolveCurve(
        option.default,
        Defaults.fallbackPages,
        Defaults.minimumPages,
        Defaults.maximumPages,
        skill.id
    )

    for tier = 1, 5 do
        assert(
            curve[tier] == skill.pages[tier],
            skill.id .. " tier " .. tier .. " differs from its sandbox default"
        )
    end

end

print("Realistic Book Pages sandbox schema passed: " .. #Defaults.skills .. " skills")
