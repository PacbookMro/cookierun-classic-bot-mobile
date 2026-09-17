-- Run with CookieRun visible, either fullscreen or in a landscape game pane.
package.path = scriptPath() .. "?.lua;" .. package.path
setImagePath(scriptPath() .. "templates/")
-- A previous run may have been stopped without Lua cleanup being called.
local brightness = require("brightness")
brightness.restore()

local screen = require("screen")
local ui = require("ui")
dialogInit()
ui.choice("Where is CookieRun running?", "screen_mode",
    {"Full screen / manual", "Select game window", "Reuse saved game window"}, "Full screen / manual")
ui.check("screen_preview", "Calibration only (no game taps)", true)
ui.show("CookieRun screen setup")

if screen_mode == "Full screen / manual" then
    dialogInit()
    ui.check("screen_immersive", "Game hides navigation bar", true)
    ui.check("screen_cutouts", "Exclude camera cutout area", true)
    ui.check("screen_centered", "Legacy 16:9 crop (actual black bars only)", false)
    ui.check("screen_manual", "Enter game rectangle manually", false)
    ui.show("Fullscreen options")
    if screen_manual then
        dialogInit()
        ui.number("Left X (screenshot pixels)", "screen_x", 0)
        ui.number("Top Y (screenshot pixels)", "screen_y", 0)
        ui.show("Game rectangle: position")
        dialogInit()
        ui.number("Width (screenshot pixels)", "screen_width", 1920)
        ui.number("Height (screenshot pixels)", "screen_height", 1080)
        ui.show("Game rectangle: size")
    end
end

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

print("CookieRun v1.1.0-mobile.7 | " .. (screen_preview and "CALIBRATION ONLY (no taps)" or "AUTOMATION"))

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
