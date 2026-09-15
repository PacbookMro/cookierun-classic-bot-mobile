-- Pick a landscape game pane inside a portrait (or landscape) display.
-- Touches are intercepted by AnkuLua's getTouchEvent, not sent to either app.
local profile = {}
local screen = require("screen")
local FILE = "window-profile.txt"

local function displaySize()
    assert(getRealScreenSize, "Game-window selection needs getRealScreenSize()")
    local size = getRealScreenSize()
    return size:getX(), size:getY()
end

local function path() return scriptPath() .. FILE end

function profile.validate(rect, width, height)
    return screen.viewport({x=0,y=0,w=width,h=height}, rect)
end

local function instruction(text)
    dialogInit()
    addTextView(text)
    dialogShow("Select CookieRun game window")
end

local function corner(text)
    instruction(text)
    local action, point = getTouchEvent()
    assert(action == "click" or action == "longClick", "Tap a corner; do not drag. Restart selection.")
    return math.floor(point:getX() + 0.5), math.floor(point:getY() + 0.5)
end

function profile.select()
    assert(getTouchEvent, "This AnkuLua version does not support window selection")
    local width, height = displaySize()
    setImmersiveMode(true)
    autoGameArea(false)
    setGameArea(Region(0,0,width,height))
    -- Identity mapping while selecting: a touch returns full screenshot pixels.
    Settings:setScriptDimension(true,width)
    Settings:setCompareDimension(true,width)
    local x1,y1 = corner("After closing this message, tap the TOP-LEFT corner of the game content. Exclude any window title bar.")
    local x2,y2 = corner("Now tap the BOTTOM-RIGHT corner of the game content, just above the split-screen divider. Exclude chat and window controls.")
    local currentW,currentH = displaySize()
    assert(currentW == width and currentH == height, "Display changed during selection; select the window again.")
    assert(x2 > x1 and y2 > y1, "Select top-left first, then bottom-right.")
    local rect = profile.validate({x=x1,y=y1,w=x2-x1,h=y2-y1},width,height)
    -- Allow exact corrections without requiring another pair of touches.
    dialogInit()
    addTextView("Game rectangle in screenshot pixels: X, Y, width, height. Adjust if needed.")
    newRow(); addEditNumber("window_pick_x",rect.x); addEditNumber("window_pick_y",rect.y)
    newRow(); addEditNumber("window_pick_w",rect.w); addEditNumber("window_pick_h",rect.h)
    dialogShow("Review game window")
    rect = profile.validate({x=window_pick_x,y=window_pick_y,w=window_pick_w,h=window_pick_h},width,height)
    currentW,currentH = displaySize()
    assert(currentW == width and currentH == height, "Display changed during review; select the window again.")
    local file = assert(io.open(path(), "w"), "Cannot save window-profile.txt in the script folder")
    file:write(string.format("1 %d %d %d %d %d %d\n",width,height,rect.x,rect.y,rect.w,rect.h))
    file:close()
    return rect
end

function profile.load()
    local file = assert(io.open(path(), "r"), "No saved window. Choose Select game window first.")
    local text = file:read(256) or ""
    file:close()
    local w,h,x,y,rw,rh = text:match("^1 (%d+) (%d+) (%d+) (%d+) (%d+) (%d+)%s*$")
    assert(w, "Invalid window-profile.txt. Select the game window again.")
    local width,height = displaySize()
    assert(tonumber(w)==width and tonumber(h)==height,
        "Display size/orientation changed. Select the game window again.")
    return profile.validate({x=tonumber(x),y=tonumber(y),w=tonumber(rw),h=tonumber(rh)},width,height)
end

return profile
