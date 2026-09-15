-- AnkuLua uses global type() for typing text; keep its binding intact.
local valueType = typeOf or type
-- AnkuLua applies both image and touch scaling relative to this game area.
-- Never multiply Location/Region coordinates by a device scale a second time.
local screen = { WIDTH = 1280, HEIGHT = 720 }

local function integer(value, name)
    assert(valueType(value) == "number" and value == math.floor(value), name .. " must be an integer")
    return value
end

-- Pure geometry, using physical screenshot pixels, independent of AnkuLua.
function screen.viewport(area, manual)
    local x, y, w, h = area.x, area.y, area.w, area.h
    integer(x, "Area X"); integer(y, "Area Y")
    integer(w, "Area width"); integer(h, "Area height")
    assert(x >= 0 and y >= 0 and w > 0 and h > 0, "Invalid game area")
    assert(w > h, "Open CookieRun in landscape, then restart the script.")
    if manual then
        x, y, w, h = manual.x, manual.y, manual.w, manual.h
        integer(x, "Manual X"); integer(y, "Manual Y")
        integer(w, "Manual width"); integer(h, "Manual height")
        assert(w > 0 and h > 0, "Manual width and height must be positive")
        assert(x >= area.x and y >= area.y and x + w <= area.x + area.w
            and y + h <= area.y + area.h, "Manual game area is outside the usable screen")
        assert(math.abs(w - h * 16 / 9) <= 2,
            "Manual game area must be 16:9 (for example 1920 x 1080).")
    else
        local scale = math.min(w / screen.WIDTH, h / screen.HEIGHT)
        local fitW = math.floor(screen.WIDTH * scale + 0.5)
        local fitH = math.floor(screen.HEIGHT * scale + 0.5)
        x = x + math.floor((w - fitW) / 2)
        y = y + math.floor((h - fitH) / 2)
        w, h = fitW, fitH
    end
    return {x = x, y = y, w = w, h = h}
end

function screen.setup(options)
    options = options or {}
    assert(setImmersiveMode and autoGameArea and getGameArea and setGameArea,
        "This script requires AnkuLua 8.2 or newer with game-area support.")
    -- Official API order: immersive -> cutout detection -> physical game area
    -- -> reference dimensions. getGameArea returns a Region, not four numbers.
    setImmersiveMode(options.immersive ~= false)
    autoGameArea(true)
    local region = getGameArea()
    local area = {x = region:getX(), y = region:getY(), w = region:getW(), h = region:getH()}
    local viewport = screen.viewport(area, options.manual)
    setGameArea(Region(viewport.x, viewport.y, viewport.w, viewport.h))
    Settings:setScriptDimension(true, screen.WIDTH)
    Settings:setCompareDimension(true, screen.WIDTH)
    screen.current = viewport
    print(string.format("Game area: x=%d y=%d width=%d height=%d; reference: 1280x720",
        viewport.x, viewport.y, viewport.w, viewport.h))
    return viewport
end

function screen.fullRegion()
    return Region(0, 0, screen.WIDTH, screen.HEIGHT)
end

function screen.region(bounds)
    if not bounds then return screen.fullRegion() end
    return Region(bounds[1], bounds[2], bounds[3] - bounds[1], bounds[4] - bounds[2])
end

function screen.preview()
    local config = require("config")
    screen.fullRegion():highlight("Game area: border should follow the 16:9 game content", 3)
    local points = {
        {"Main menu: Start", config.START_BUTTON},
        {"Items screen: Play", config.PLAY_BUTTON},
        {"Items screen: Random boost", config.RANDOM_BOOST_ITEM},
    }
    for _, entry in ipairs(points) do
        local point = entry[2]
        Region(point[1] - 15, point[2] - 15, 30, 30):highlight(entry[1], 3)
    end
end

return screen
