-- AnkuLua uses global type() for typing text; keep its binding intact.
local valueType = typeOf or type
-- Repeat delay starts at the first result/reward screen, not at run Play.
local cycle = {}

function cycle.new(interval, maximum)
    assert(valueType(interval) == "number" and interval >= 0, "Invalid round interval")
    maximum = maximum or interval
    assert(valueType(maximum) == "number" and maximum >= interval, "Invalid maximum round interval")
    local state = {interval = interval, last_start = nil, finished_at = nil, active = false, bought = false}
    function state:remaining(now)
        if not self.finished_at then return 0 end
        return math.max(0, self.finished_at + self.interval - now)
    end
    function state:can_purchase() return not self.bought end
    function state:purchased() self.bought = true end
    function state:started(now)
        -- Only a new run clears the previous result deadline.
        if not self.last_start or self.prepared_start or self.finished_at then
            self.last_start = now
            self.finished_at = nil
        end
        self.active = true
        self.prepared_start = false
    end
    function state:observed_run() self.active = true end
    function state:finished(now)
        -- Result OK retries and the two mystery-box screens share one deadline.
        if self.finished_at then return end
        self.finished_at = now
        self.active = false
        self.bought = false
        self.interval = interval + math.random() * (maximum - interval)
        print(string.format("Stage ended: repeat delay %.1f seconds from results", self.interval))
    end
    function state:returned(now)
        -- Fallback when result recognition was missed, but this session saw a run.
        -- Starting the script on the main menu must not incur a repeat delay.
        if self.active then self:finished(now) end
    end
    function state:prepare()
        self.bought = false
        self.prepared_start = true
    end
    return state
end

return cycle
