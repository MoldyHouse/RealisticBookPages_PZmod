local Defaults = require("RealisticBookPages/Defaults")

local Config = {}
local warned = {}

local function trim(value)
    return (tostring(value):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function round(value)
    return math.floor(value + 0.5)
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function warnOnce(key, message)
    if warned[key] then
        return
    end

    warned[key] = true
    print("Realistic Book Pages: " .. message)
end

-- Kahlua uses Lua 5.1 numbers, so keep the hash arithmetic comfortably below
-- the exact-integer boundary. The result is stable on server and clients.
local function deterministicInteger(key, minimum, maximum)
    if minimum >= maximum then
        return minimum
    end

    local hash = 7
    for index = 1, #key do
        hash = (hash * 31 + string.byte(key, index)) % 2147483647
    end

    return minimum + (hash % (maximum - minimum + 1))
end

local function parseRange(value, minimum, maximum)
    local compact = value:gsub("%s+", "")
    local lower
    local upper

    lower, upper = compact:match("^>(%d+)<(%d+)$")
    if not lower then
        lower = compact:match("^>(%d+)$")
        if lower then
            upper = maximum
        end
    end

    if not lower then
        upper = compact:match("^<(%d+)$")
        if upper then
            lower = minimum
        end
    end

    if not lower then
        lower, upper = compact:match("^>(%d*)<(%d*)$")
        if lower ~= nil then
            lower = lower ~= "" and lower or minimum
            upper = upper ~= "" and upper or maximum
        end
    end

    if lower == nil or upper == nil then
        return nil
    end

    lower = clamp(round(tonumber(lower)), minimum, maximum)
    upper = clamp(round(tonumber(upper)), minimum, maximum)

    if lower > upper then
        lower, upper = upper, lower
    end

    return lower, upper
end

local function randomInteger(_, minimum, maximum)
    if minimum >= maximum then
        return minimum
    end

    if ZombRand then
        return ZombRand(minimum, maximum + 1)
    end

    -- Standalone test fallback. The game always provides ZombRand.
    return math.random(minimum, maximum)
end

local function randomWeight(minimum, maximum)
    local minimumHundredths = round(minimum * 100)
    local maximumHundredths = round(maximum * 100)
    return randomInteger(
        "ordinary-book-weight",
        minimumHundredths,
        maximumHundredths
    ) / 100
end

local function resolvePageSpecUsing(
    spec,
    fallback,
    minimum,
    maximum,
    key,
    rangeResolver
)
    local numeric

    if type(spec) == "number" then
        numeric = spec
    elseif type(spec) == "string" then
        local value = trim(spec)
        numeric = tonumber(value)

        if not numeric and value ~= "" then
            local lower, upper = parseRange(value, minimum, maximum)
            if lower then
                return rangeResolver(key .. ":" .. value, lower, upper)
            end
        end
    end

    if numeric then
        return clamp(round(numeric), minimum, maximum)
    end

    if spec ~= nil and trim(spec) ~= "" then
        warnOnce(
            "spec:" .. key .. ":" .. tostring(spec),
            "invalid page value '" .. tostring(spec) .. "' for " .. key
                .. "; using the mod default"
        )
    end

    return clamp(round(fallback), minimum, maximum)
end

-- Script defaults resolve ranges deterministically. Spawned InventoryItems use
-- the random resolver, which is only called by the server or singleplayer.
function Config.resolvePageSpec(spec, fallback, minimum, maximum, key)
    return resolvePageSpecUsing(
        spec,
        fallback,
        minimum,
        maximum,
        key,
        deterministicInteger
    )
end

function Config.resolveRandomPageSpec(spec, fallback, minimum, maximum, key)
    return resolvePageSpecUsing(
        spec,
        fallback,
        minimum,
        maximum,
        key,
        randomInteger
    )
end

local function splitCurve(value)
    local fields = {}
    local normalized = value:gsub("[;/]", ",")

    for field in (normalized .. ","):gmatch("(.-),") do
        fields[#fields + 1] = trim(field)
    end

    return fields
end

function Config.resolveCurve(source, fallback, minimum, maximum, skill)
    local values = source
    local resolved = {}

    if type(source) == "string" then
        values = splitCurve(source)

        -- A single page specification is also accepted by the Lua API and
        -- applies to every tier. Sandbox defaults always contain five fields.
        if #values == 1 then
            values = { source, source, source, source, source }
        end
    elseif type(source) == "number" then
        values = { source, source, source, source, source }
    end

    if type(values) ~= "table" then
        values = fallback
    end

    if #values ~= 5 then
        warnOnce(
            "curve:" .. skill .. ":" .. tostring(source),
            "the " .. skill .. " curve must contain five separated values; "
                .. "using missing tiers from the mod defaults"
        )
    end

    for tier = 1, 5 do
        resolved[tier] = Config.resolvePageSpec(
            values[tier],
            fallback[tier],
            minimum,
            maximum,
            skill .. ":" .. Defaults.tierNames[tier]
        )
    end

    return resolved
end

local function numberOption(options, name, fallback)
    local value = options and tonumber(options[name])
    return value or fallback
end

local function booleanOption(options, name, fallback)
    local value = options and options[name]
    if value == nil then
        return fallback
    end
    return value == true
end

function Config.resolveMoodSettings()
    local options = SandboxVars and SandboxVars.RealisticBookPages or {}

    return {
        scaleByWeight = booleanOption(
            options,
            "ScaleMoodEffectsByWeight",
            Defaults.mood.scaleByWeight
        ),
        applyWhileReading = booleanOption(
            options,
            "ApplyMoodEffectsWhileReading",
            Defaults.mood.applyWhileReading
        ),
        stepPercent = math.max(1, math.min(100, math.floor(
            numberOption(
                options,
                "MoodEffectStepPercent",
                Defaults.mood.stepPercent
            ) + 0.5
        ))),
    }
end

-- Item scripts store StressChange as percentage points, while the runtime
-- STRESS stat and InventoryItem field use 0..1. Boredom and unhappiness keep
-- their script-scale 0..100 values.
function Config.resolveRuntimeMoodChanges(
    boredom,
    scriptStress,
    unhappiness,
    multiplier
)
    multiplier = tonumber(multiplier) or 1

    return (tonumber(boredom) or 0) * multiplier,
        ((tonumber(scriptStress) or 0) / 100) * multiplier,
        (tonumber(unhappiness) or 0) * multiplier
end

local function getCurveValue(curve, tier)
    if type(curve) == "number" then
        return curve
    end

    if type(curve) == "string" then
        local values = splitCurve(curve)
        return #values == 1 and curve or values[tier]
    end

    if type(curve) == "table" then
        return curve[tier]
    end

    return nil
end

function Config.build(api)
    local options = SandboxVars and SandboxVars.RealisticBookPages or {}
    local minimum = math.max(1, round(numberOption(
        options,
        "MinimumPages",
        Defaults.minimumPages
    )))
    local maximum = math.max(1, round(numberOption(
        options,
        "MaximumPages",
        Defaults.maximumPages
    )))

    if minimum > maximum then
        minimum, maximum = maximum, minimum
        warnOnce(
            "reversed-global-limits",
            "Minimum Pages exceeded Maximum Pages; the limits were swapped"
        )
    end

    local runtime = {
        enabled = booleanOption(options, "Enabled", true),
        minimumPages = minimum,
        maximumPages = maximum,
        pagesBySkill = {},
        weight = {
            enabled = booleanOption(
                options,
                "AdjustWeight",
                Defaults.weight.enabled
            ),
            referencePages = math.max(1, round(numberOption(
                options,
                "ReferencePages",
                Defaults.weight.referencePages
            ))),
            referenceWeight = math.max(0.01, numberOption(
                options,
                "ReferenceWeight",
                Defaults.weight.referenceWeight
            )),
            bindingWeight = math.max(0, numberOption(
                options,
                "BindingWeight",
                Defaults.weight.bindingWeight
            )),
        },
    }

    local registeredPages = api.pagesBySkill or Defaults.pagesBySkill
    for skill, fallback in pairs(registeredPages) do
        local normalizedFallback = Config.resolveCurve(
            fallback,
            Defaults.fallbackPages,
            minimum,
            maximum,
            skill
        )
        local optionName = Defaults.optionBySkill[skill]
        local source = optionName and options[optionName] or nil

        if api.pageOverrides and api.pageOverrides[skill] ~= nil then
            source = api.pageOverrides[skill]
        end

        runtime.pagesBySkill[skill] = Config.resolveCurve(
            source or normalizedFallback,
            normalizedFallback,
            minimum,
            maximum,
            skill
        )
    end

    local fallbackSource = options.FallbackPages or Defaults.fallbackPages
    if api.fallbackOverride ~= nil then
        fallbackSource = api.fallbackOverride
    end

    runtime.fallbackPages = Config.resolveCurve(
        fallbackSource,
        Defaults.fallbackPages,
        minimum,
        maximum,
        "Fallback"
    )

    return runtime
end

-- Resolve only one spawned item. This consumes at most one game RNG value and
-- reads SandboxVars at spawn time, so live server changes affect new books.
function Config.resolveSpawn(api, skill, tier)
    local options = SandboxVars and SandboxVars.RealisticBookPages or {}
    local minimum = math.max(1, round(numberOption(
        options,
        "MinimumPages",
        Defaults.minimumPages
    )))
    local maximum = math.max(1, round(numberOption(
        options,
        "MaximumPages",
        Defaults.maximumPages
    )))

    if minimum > maximum then
        minimum, maximum = maximum, minimum
    end

    local runtime = {
        enabled = booleanOption(options, "Enabled", true),
        minimumPages = minimum,
        maximumPages = maximum,
        weight = {
            enabled = booleanOption(
                options,
                "AdjustWeight",
                Defaults.weight.enabled
            ),
            referencePages = math.max(1, round(numberOption(
                options,
                "ReferencePages",
                Defaults.weight.referencePages
            ))),
            referenceWeight = math.max(0.01, numberOption(
                options,
                "ReferenceWeight",
                Defaults.weight.referenceWeight
            )),
            bindingWeight = math.max(0, numberOption(
                options,
                "BindingWeight",
                Defaults.weight.bindingWeight
            )),
        },
    }

    local fallbackCurve = api.pagesBySkill[skill]
    local source

    if fallbackCurve then
        local optionName = Defaults.optionBySkill[skill]
        source = optionName and options[optionName] or nil
        if api.pageOverrides and api.pageOverrides[skill] ~= nil then
            source = api.pageOverrides[skill]
        end
    else
        fallbackCurve = Defaults.fallbackPages
        source = options.FallbackPages
        if api.fallbackOverride ~= nil then
            source = api.fallbackOverride
        end
    end

    source = source or fallbackCurve
    local fallback = Config.resolvePageSpec(
        getCurveValue(fallbackCurve, tier),
        Defaults.fallbackPages[tier],
        minimum,
        maximum,
        skill .. ":" .. Defaults.tierNames[tier] .. ":fallback"
    )

    runtime.pageCount = Config.resolveRandomPageSpec(
        getCurveValue(source, tier),
        fallback,
        minimum,
        maximum,
        skill .. ":" .. Defaults.tierNames[tier] .. ":spawn"
    )

    return runtime
end

-- Non-skill literature does not define NumberOfPages in vanilla. Roll its
-- weight first and translate it into pages using the shared reference ratio.
function Config.resolveLiteratureSpawn(api, kind)
    local definition = Defaults.literatureKinds[kind]
    if not definition then
        return { enabled = false }
    end

    local options = SandboxVars and SandboxVars.RealisticBookPages or {}
    local minimumPages = math.max(1, round(numberOption(
        options,
        "MinimumPages",
        Defaults.minimumPages
    )))
    local maximumPages = math.max(1, round(numberOption(
        options,
        "MaximumPages",
        Defaults.maximumPages
    )))

    if minimumPages > maximumPages then
        minimumPages, maximumPages = maximumPages, minimumPages
    end

    local minimumWeight = math.max(0.01, numberOption(
        options,
        definition.minimumOption,
        definition.defaults.minimumWeight
    ))
    local maximumWeight = math.max(0.01, numberOption(
        options,
        definition.maximumOption,
        definition.defaults.maximumWeight
    ))

    local override = api.literatureWeightOverrides
        and api.literatureWeightOverrides[kind]
    if kind == "ordinaryBook" and api.ordinaryBookWeightOverride then
        override = api.ordinaryBookWeightOverride
    end

    if override then
        minimumWeight = math.max(
            0.01,
            tonumber(override.minimum) or minimumWeight
        )
        maximumWeight = math.max(
            0.01,
            tonumber(override.maximum) or maximumWeight
        )
    end

    if minimumWeight > maximumWeight then
        minimumWeight, maximumWeight = maximumWeight, minimumWeight
    end

    local referencePages = math.max(1, round(numberOption(
        options,
        "ReferencePages",
        Defaults.weight.referencePages
    )))
    local referenceWeight = math.max(0.01, numberOption(
        options,
        "ReferenceWeight",
        Defaults.weight.referenceWeight
    ))
    local weight = randomWeight(minimumWeight, maximumWeight)
    local pages = clamp(
        round(referencePages * weight / referenceWeight),
        minimumPages,
        maximumPages
    )

    return {
        enabled = booleanOption(options, "Enabled", true)
            and booleanOption(
                options,
                definition.enabledOption,
                definition.defaults.enabled
            ),
        pageCount = pages,
        weight = weight,
        minimumWeight = minimumWeight,
        maximumWeight = maximumWeight,
    }
end

function Config.resolveOrdinaryBookSpawn(api)
    return Config.resolveLiteratureSpawn(api, "ordinaryBook")
end

return Config
