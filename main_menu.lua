-- Fallback for the English Friends-tab template failing on mobile rendering.
-- Inspect the colored main-menu controls; the items screen also has a green
-- Play button, so green alone must never identify the main menu.
local screen = require("screen")
local config = require("config")
local menu = {}

local function green(r, g, b)
    return r >= 65 and g >= 150 and b <= 95 and g > r * 1.04 and r > b * 1.6
end

local function cyan(r, g, b)
    return r <= 115 and g >= 125 and b >= 115 and g > r * 1.35 and b > r * 1.35
end

local function countSamples(x, ys, predicate)
    local count = 0
    -- Samples sit away from the white Play lettering and tab separators.
    for _, dx in ipairs({-140, -100, 100, 140}) do
        for _, y in ipairs(ys) do
            local r, g, b = getColor(screen.location(x + dx, y))
            if predicate(r, g, b) then count = count + 1 end
        end
    end
    return count
end

function menu.findPlay()
    if not getColor or not snapshotColor then
        menu.last_probe = "Main-menu color check unavailable; using template detection"
        return nil
    end
    -- getColor requires a color snapshot, not the grayscale detection frame.
    -- Explicitly release reuse even when the bridge raises an error.
    usePreviousSnap(false)
    local ok, result = pcall(function()
        snapshotColor()
        usePreviousSnap(true)
        local x, y = config.START_BUTTON[1], config.START_BUTTON[2]
        local play = countSamples(x, {y - 12, y + 10}, green)
        local tabs = countSamples(x, {y - 83, y - 77}, cyan)
        menu.last_probe = string.format("Main-menu controls: green Play %d/8, cyan tabs %d/8", play, tabs)
        if play >= 6 and tabs >= 6 then
            return {source = "main-menu Play + cyan tabs", target = screen.location(x, y)}
        end
    end)
    usePreviousSnap(false)
    if not ok then
        menu.last_probe = "Main-menu color check failed: " .. tostring(result)
        return nil
    end
    return result
end

return menu
