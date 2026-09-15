-- Optional variation, in logical game coordinates (never display pixels).
local interaction = {}
local settings = {enabled=false}

function interaction.configure(options)
    settings = options or {enabled=false}
    if settings.enabled then
        assert(manualTouch, "Tap variation needs AnkuLua manualTouch support")
    end
end

function interaction.enabled() return settings.enabled end

function interaction.tap(location, area, targetRadius, checkDisplay)
    local x, y = location:getX(), location:getY()
    assert(x >= 0 and y >= 0 and x < area:getW() and y < area:getH(),
        "Action outside game area; recalibrate the game window.")
    if not settings.enabled then click(location); return location end
    local radius = math.min(settings.radius, targetRadius or settings.radius)
    local left, right = math.max(0, math.ceil(x-radius)), math.min(area:getW()-1, math.floor(x+radius))
    local top, bottom = math.max(0, math.ceil(y-radius)), math.min(area:getH()-1, math.floor(y+radius))
    local target = Location(math.random(left, right), math.random(top, bottom))
    sleep(math.random() * settings.pause)
    if checkDisplay then checkDisplay() end
    local duration = settings.press_min + math.random() * (settings.press_max-settings.press_min)
    manualTouch({
        {action="touchDown", target=target},
        {action="wait", target=duration},
        {action="touchUp", target=target},
    })
    return target
end

return interaction
