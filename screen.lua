-- AnkuLua reserves type() for text entry.
local valueType = typeOf or type
local screen = { WIDTH = 1280, HEIGHT = 720 }
local logicalWidth, logicalHeight, offsetX, offsetY = 1280, 720, 0, 0

local function integer(value, name)
    assert(valueType(value) == "number" and value == math.floor(value), name .. " must be an integer")
end

-- Rectangles here are physical screenshot pixels. Full area is the default:
-- decorative side content is not evidence of black bars or unused UI space.
function screen.viewport(area, manual, centered)
    local v = manual or area
    for _, key in ipairs({"x", "y", "w", "h"}) do integer(v[key], "Game area " .. key) end
    assert(v.x >= 0 and v.y >= 0 and v.w > 0 and v.h > 0, "Invalid game area")
    assert(v.w > v.h, "Open CookieRun in a landscape window, then restart the script.")
    assert(v.x >= area.x and v.y >= area.y and v.x + v.w <= area.x + area.w
        and v.y + v.h <= area.y + area.h, "Manual game area is outside the usable screen")
    local x, y, w, h = v.x, v.y, v.w, v.h
    if centered then
        local scale = math.min(w / screen.WIDTH, h / screen.HEIGHT)
        local fitW = math.floor(screen.WIDTH * scale + 0.5)
        local fitH = math.floor(screen.HEIGHT * scale + 0.5)
        x, y = x + math.floor((w - fitW) / 2), y + math.floor((h - fitH) / 2)
        w, h = fitW, fitH
    end
    return {x=x, y=y, w=w, h=h}
end

function screen.setup(options)
    options = options or {}
    assert(setImmersiveMode and autoGameArea and getGameArea and setGameArea,
        "This script requires AnkuLua 8.2 or newer with game-area support.")
    setImmersiveMode(options.immersive ~= false)
    autoGameArea(options.cutouts ~= false)
    local region = getGameArea()
    local area = {x=region:getX(), y=region:getY(), w=region:getW(), h=region:getH()}
    local viewport = screen.viewport(area, options.manual, options.centered)
    setGameArea(Region(viewport.x, viewport.y, viewport.w, viewport.h))
    -- Preserve image proportions, including tall landscape tablet windows.
    local byWidth = viewport.w / viewport.h < screen.WIDTH / screen.HEIGHT
    local dimension = byWidth and screen.WIDTH or screen.HEIGHT
    Settings:setScriptDimension(byWidth, dimension)
    Settings:setCompareDimension(byWidth, dimension)
    local scale = byWidth and viewport.w / screen.WIDTH or viewport.h / screen.HEIGHT
    logicalWidth, logicalHeight = viewport.w / scale, viewport.h / scale
    offsetX, offsetY = (logicalWidth - screen.WIDTH) / 2, (logicalHeight - screen.HEIGHT) / 2
    screen.current = viewport
    screen.last_action = nil
    print(screen.describe())
    return viewport
end

function screen.describe()
    local v = screen.current or {x=0,y=0,w=1280,h=720}
    return string.format("Game area x=%d y=%d width=%d height=%d; logical %.1fx%.1f; UI offset %.1f,%.1f",
        v.x, v.y, v.w, v.h, logicalWidth, logicalHeight, offsetX, offsetY)
end

function screen.fullRegion()
    return Region(0, 0, math.floor(logicalWidth), math.floor(logicalHeight))
end

-- Translate reference UI coordinates into the expanded logical canvas.
-- AnkuLua handles the physical scale and window offset exactly once.
function screen.location(x, y)
    local px, py = math.floor(x + offsetX + 0.5), math.floor(y + offsetY + 0.5)
    assert(px >= 0 and py >= 0 and px < logicalWidth and py < logicalHeight,
        "Action outside game area; recalibrate the game window.")
    return Location(px, py)
end

function screen.tap(point)
    assert(point, "Missing action coordinate")
    local location = screen.location(point[1], point[2])
    screen.last_action = string.format("Tap reference=(%d,%d), logical=(%d,%d)",
        point[1], point[2], location:getX(), location:getY())
    print(screen.last_action)
    click(location)
end

function screen.region(bounds)
    if not bounds then return screen.fullRegion() end
    local x = math.max(0, math.floor(bounds[1] + offsetX))
    local y = math.max(0, math.floor(bounds[2] + offsetY))
    local right = math.min(math.floor(logicalWidth), math.ceil(bounds[3] + offsetX))
    local bottom = math.min(math.floor(logicalHeight), math.ceil(bounds[4] + offsetY))
    return Region(x, y, right - x, bottom - y)
end

function screen.preview()
    local config = require("config")
    local region = screen.fullRegion()
    region:highlight("Search area: includes the game sides", 3)
    region:highlightOff()
    local points = {
        {"Main menu: Play", config.START_BUTTON},
        {"Items screen: Play", config.PLAY_BUTTON},
        {"Items screen: Random boost", config.RANDOM_BOOST_ITEM},
    }
    for _, entry in ipairs(points) do
        local point = entry[2]
        local marker = screen.region({point[1]-15, point[2]-15, point[1]+15, point[2]+15})
        marker:highlight(entry[1], 3)
        marker:highlightOff()
    end
end

return screen
