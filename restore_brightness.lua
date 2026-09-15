-- Run this in AnkuLua after a forced stop if the display is still dim.
package.path = scriptPath() .. "?.lua;" .. package.path
if require("brightness").restore() then
    scriptExit("Original brightness restored.")
else
    scriptExit("No saved brightness. Use Android brightness settings if needed.")
end
