-- Run this entry point from AnkuLua with CookieRun open in landscape.
package.path = scriptPath() .. "?.lua;" .. package.path
setImagePath(scriptPath() .. "templates/")

local screen = require("screen")
dialogInit()
addCheckBox("screen_immersive", "Game hides Android navigation bar", true)
newRow()
addCheckBox("screen_manual", "Use manual game area (physical screenshot pixels)", false)
newRow()
addTextView("Manual X / Y / width / height (only used if checked):")
newRow()
addEditNumber("screen_x", 0)
addEditNumber("screen_y", 0)
addEditNumber("screen_width", 1920)
addEditNumber("screen_height", 1080)
newRow()
addCheckBox("screen_preview", "Calibration only: highlight positions without tapping", true)
dialogShow("CookieRun screen setup")

screen.setup({
    immersive = screen_immersive,
    manual = screen_manual and {x = screen_x, y = screen_y, w = screen_width, h = screen_height} or nil,
})

if screen_preview then
    screen.preview()
    local detection = require("detection")
    local stage = detection.detect_stage()
    print("Calibration stage: " .. tostring(stage or "not detected"))
    require("diagnostics").save_debug_screen()
    scriptExit("Calibration finished. Check highlights and templates/debug_screen_*.png. Run again with Calibration only unchecked to start.")
    return
end

-- Keep AnkuLua's real sleep and text-entry type binding intact. Highlights can contaminate
-- screenshots, and an overlay duration is not a replacement for sleep().
local originalPrint = print
function print(...)
    local args = {...}
    for i, value in ipairs(args) do args[i] = tostring(value) end
    originalPrint("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. table.concat(args, " "))
end

math.randomseed(os.time())
require("bot").main()
