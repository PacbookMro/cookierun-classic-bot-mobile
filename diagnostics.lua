-- 'debug' is a built-in Lua module; use a distinct module name.
local diagnostics = {}

function diagnostics.save_debug_screen()
    local name = "debug_screen_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
    usePreviousSnap(false)
    require("screen").fullRegion():saveColor(name)
    print("Saved game screenshot: templates/" .. name)
    return name
end

-- Overwrite a fixed pair of files so normal gameplay without visible menu
-- templates cannot fill the phone's storage. Failures to save don't stop play.
function diagnostics.save_unrecognized(group, last_stage, elapsed)
    local screen = require("screen")
    local report = string.format("No menu template matched for %.0fs\nGroup: %s\nLast stage: %s\n%s\n%s\n",
        elapsed, tostring(group), tostring(last_stage), screen.describe(), screen.last_action or "No tap yet")
    report = report .. (require("main_menu").last_probe or "Main-menu color check not attempted") .. "\n"
    local ok, err = pcall(function()
        usePreviousSnap(false)
        screen.fullRegion():saveColor("debug_unrecognized.png")
        local file = assert(io.open(scriptPath() .. "templates/debug_unrecognized.txt", "w"))
        file:write(report)
        file:close()
    end)
    if ok then
        print(report .. "Saved templates/debug_unrecognized.png and .txt. If stuck, share these files.")
    else
        print(report .. "Could not save diagnostic: " .. tostring(err))
    end
end

return diagnostics
