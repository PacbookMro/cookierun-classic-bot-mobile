-- Run with CookieRun visible, either fullscreen or in a landscape game pane.
package.path = scriptPath() .. "?.lua;" .. package.path
setImagePath(scriptPath() .. "templates/")
-- A previous run may have been stopped without Lua cleanup being called.
local brightness = require("brightness")
brightness.restore()

local screen = require("screen")
dialogInit()
addTextView("Where is CookieRun running?")
newRow()
addSpinner("screen_mode", {"Full screen / manual", "Select game window", "Reuse saved game window"}, "Full screen / manual")
newRow()
addTextView("Window modes use your selected pane. Settings below apply to fullscreen/manual mode.")
newRow()
addCheckBox("screen_immersive", "Game hides Android navigation bar", true)
newRow()
addCheckBox("screen_cutouts", "Exclude camera cutout area (uncheck if game draws there)", true)
newRow()
addCheckBox("screen_centered", "Legacy: crop to centered 16:9 (only for actual black bars)", false)
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

if screen_mode == "Select game window" or screen_mode == "Reuse saved game window" then
    local profile = require("window_profile")
    local rect = screen_mode == "Select game window" and profile.select() or profile.load()
    screen.setup({window=true, manual=rect})
else
    screen.setup({
        immersive = screen_immersive,
        cutouts = screen_cutouts,
        centered = screen_centered,
        manual = screen_manual and {x = screen_x, y = screen_y, w = screen_width, h = screen_height} or nil,
    })
end

print("CookieRun v1.1.0-mobile.5 | " .. (screen_preview and "CALIBRATION ONLY (no taps)" or "AUTOMATION"))

if screen_preview then
    screen.preview()
    local detection = require("detection")
    local stage = detection.detect_stage(nil, nil, true)
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
brightness.run(function() require("bot").main() end)
