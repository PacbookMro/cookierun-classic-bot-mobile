-- Detection recovery has its own clocks; a failed scan is not a detection.
local recovery = {}
function recovery.new(now)
    local state = {}
    function state:detected(time)
        self.last_seen, self.last_wide, self.last_all = time, time, time
        self.saved = false
    end
    function state:poll(time, wide_interval, all_interval, diagnostic_after)
        local result = {elapsed = time - self.last_seen}
        result.wide = time - self.last_wide >= wide_interval
        result.all = time - self.last_all >= all_interval
        result.diagnostic = not self.saved and result.elapsed >= diagnostic_after
        if result.wide then self.last_wide = time end
        if result.all then self.last_all = time end
        if result.diagnostic then self.saved = true end
        return result
    end
    state:detected(now)
    return state
end
return recovery
