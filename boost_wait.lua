local screen = require("screen")
local config = require("config")
local detection = require("detection")
local boost = {}

-- A target banner may already be visible while Multi-Buy is rolling. Check
-- the green Play and absence of its large pale rolling-history panel too.
-- Coordinates are reference pixels, translated by the existing window mapping.
function boost.ready()
    if not getColor or not snapshotColor then return false, "Color API unavailable" end
    usePreviousSnap(false)
    local ok, ready, detail = pcall(function()
        snapshotColor()
        usePreviousSnap(true)
        local green, pale = 0, 0
        for _, x in ipairs({795, 825, 995, 1025}) do
            for _, y in ipairs({600, 630}) do
                local r,g,b = getColor(screen.location(x,y))
                if r>=65 and g>=150 and b<=95 and g>r*1.04 and r>b*1.6 then green=green+1 end
            end
        end
        for _, x in ipairs({750, 790, 1080, 1120}) do
            for _, y in ipairs({360, 400, 440}) do
                local r,g,b = getColor(screen.location(x,y))
                if math.min(r,g,b)>=190 and math.max(r,g,b)-math.min(r,g,b)<=35 then pale=pale+1 end
            end
        end
        return green>=6 and pale<=2,
            string.format("Play green %d/8; rolling-panel pale %d/12",green,pale)
    end)
    usePreviousSnap(false)
    if not ok then return false, "Completion color check failed: " .. tostring(ready) end
    return ready, detail
end

function boost.wait(templates, name, timeout, settle)
    timeout, settle = timeout or 180, settle or 5
    local started = os.time()
    local stableSince, stableFile, lastSeen, probe
    local nextLog = 0
    print(string.format("Game Multi-Buy is rerolling. Verify: %s; wait up to %.0fs; settle %.0fs.",
        tostring(name),timeout,settle))
    while os.time()-started <= timeout do
        local elapsed = os.time()-started
        if elapsed >= settle then
            local ready
            ready, probe = boost.ready()
            local matches = detection.detect_templates(templates,config.RANDOM_BOOST_REGION)
            local match = matches[1]
            local filename = match and match.filename
            if filename then lastSeen=filename end
            if ready and filename then
                if filename~=stableFile then stableFile,stableSince=filename,os.time() end
                if os.time()-stableSince>=3 then
                    print("Boost ready: " .. filename .. "; stable banner, Play visible, rolling panel closed.")
                    return
                end
            else
                stableFile,stableSince=nil,nil
            end
        end
        if elapsed>=nextLog then
            print(string.format("Boost wait %.0f/%.0fs; last matching banner: %s; %s",
                elapsed,timeout,tostring(lastSeen or "none"),tostring(probe or "initial settle")))
            nextLog=elapsed+10
        end
        sleep(0.5)
    end
    require("diagnostics").save_unrecognized(
        "BOOST_WAIT target=" .. tostring(name) .. "; last matching banner=" .. tostring(lastSeen)
            .. "; " .. tostring(probe), "PURCHASE_ITEM",os.time()-started)
    error("Desired boost not detected as ready within " .. timeout
        .. " seconds. Game may still be buying, target may differ, or recognition failed. "
        .. "Check templates/debug_unrecognized.png and .txt before restarting; no extra purchase was sent.")
end

return boost
