-- 'debug' is a built-in Lua module; use a distinct module name.
local diagnostics = {}

function diagnostics.save_debug_screen()
    local name = "debug_screen_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
    usePreviousSnap(false)
    require("screen").fullRegion():save(name)
    print("Saved normalized game screenshot: templates/" .. name)
    return name
end

return diagnostics
