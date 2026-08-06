-- Shared bootstrap. Script defaults are refreshed for the active world, while
-- each new book instance is rolled server-side by its chained OnCreate hook.
local API = require("RealisticBookPages/Applicator")
require("RealisticBookPages/ReadingEffects")

if not (isServer and isServer()) then
    require("RealisticBookPages/UI")
end

local function applyOnWorldInit()
    API.applyPageCounts("OnInitWorld")
end

local function applyOnConnected()
    API.applyPageCounts("OnConnected")
end

local function applyOnGameStart()
    API.applyPageCounts("OnGameStart")
end

Events.OnInitWorld.Add(applyOnWorldInit)

-- These events are client-side. Guarding them keeps the shared file safe on a
-- dedicated server while ensuring server sandbox values win over menu values.
if Events.OnConnected then
    Events.OnConnected.Add(applyOnConnected)
end

if Events.OnGameStart then
    Events.OnGameStart.Add(applyOnGameStart)
end
