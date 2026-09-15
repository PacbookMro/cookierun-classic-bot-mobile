-- Persist the previous value before dimming so a forced stop is recoverable.
local brightness = {}
local function path() return scriptPath() .. "brightness-restore.txt" end
local function valid(value)
    return value and value >= 0 and value <= 255 and value == math.floor(value)
end

function brightness.restore()
    local file = io.open(path(), "r")
    if not file then return false end
    local text = file:read("*a")
    file:close()
    local value = tonumber(text)
    assert(valid(value), "Invalid brightness-restore.txt; restore brightness in Android settings")
    assert(setBrightness, "AnkuLua setBrightness is unavailable; restore brightness in Android settings")
    setBrightness(value)
    assert(os.remove(path()), "Brightness restored, but could not remove brightness-restore.txt")
    print("Restored screen brightness to " .. value)
    return true
end

function brightness.dim(percent)
    assert(getBrightness and setBrightness, "This AnkuLua version does not expose brightness controls")
    -- Do not replace an outstanding restoration value on a second invocation.
    brightness.restore()
    local value = tonumber(getBrightness())
    assert(valid(value), "AnkuLua returned an invalid brightness value")
    local file = assert(io.open(path(), "w"), "Cannot save brightness-restore.txt; dimming cancelled")
    local written, err = file:write(tostring(value) .. "\n")
    local closed, closeErr = file:close()
    assert(written and closed, "Cannot save brightness: " .. tostring(err or closeErr))
    -- Never brighten a screen that is already below the requested level.
    setBrightness(math.min(value, math.floor(percent * 255 / 100 + 0.5)))
end

function brightness.run(fn)
    local ok, err = pcall(fn)
    local restored, restoreErr = pcall(brightness.restore)
    if not restored then print("Brightness restore failed: " .. tostring(restoreErr)) end
    if not ok then error(err, 0) end
    if not restored then error(restoreErr, 0) end
end

return brightness
