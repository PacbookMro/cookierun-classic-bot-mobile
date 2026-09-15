-- AnkuLua uses global type() for typing text; keep its binding intact.
local valueType = typeOf or type
-- Round timing is measured from Play, with purchases once per menu visit.
local cycle = {}

function cycle.new(interval, maximum)
    assert(valueType(interval) == "number" and interval >= 0, "Invalid round interval")
    maximum = maximum or interval
    assert(valueType(maximum) == "number" and maximum >= interval, "Invalid maximum round interval")
    local state = {interval = interval, last_start = nil, bought = false}
    function state:remaining(now)
        if not self.last_start then return 0 end
        return math.max(0, self.last_start + self.interval - now)
    end
    function state:can_purchase() return not self.bought end
    function state:purchased() self.bought = true end
    function state:started(now)
        -- Retrying Play while still on the purchase screen must not move the timer.
        if not self.last_start or self.prepared_start then
            self.last_start = now
            -- Pick once per round, never again on a retry or timer poll.
            self.interval = interval + math.random() * (maximum - interval)
            print(string.format("Next round interval: %.1f seconds", self.interval))
        end
        self.prepared_start = false
    end
    function state:prepare()
        self.bought = false
        self.prepared_start = true
    end
    return state
end

return cycle
