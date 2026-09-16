-- AnkuLua uses global type() for typing text; keep its binding intact.
local valueType = typeOf or type
local config = require("config")
local screen = require("screen")
local main_menu = require("main_menu")
local templateCache = {}

local function getPattern(filename, wide)
    assert(valueType(filename) == "string", "Template filename must be a string")
    local key = filename .. (wide and ":wide" or ":normal")
    if not templateCache[key] then
        templateCache[key] = Pattern(filename):similar(wide and config.WIDE_MATCH_THRESHOLD or config.MATCH_THRESHOLD)
    end
    return templateCache[key]
end

local function load_templates()
    for _, template_files in pairs(config.STAGE_TEMPLATES) do
        for _, filename in ipairs(template_files) do getPattern(filename) end
    end
    for _, template_files in ipairs(config.BOOST_TEMPLATES) do
        for _, filename in ipairs(template_files) do getPattern(filename) end
    end
end

local function detect_templates(template_files, region)
    local searchReg = screen.region(region)
    local matches = {}
    if not searchReg then return matches end
    snapshot()
    usePreviousSnap(true)
    for _, filename in ipairs(template_files) do
        local match = searchReg:exists(getPattern(filename), 0)
        if match then
            -- Preserve the native Match for clicks; don't rescale it manually.
            table.insert(matches, {match = match, filename = filename, x = match:getX(), y = match:getY(),
                w = match:getW(), h = match:getH()})
        end
    end
    usePreviousSnap(false)
    return matches
end

local function detect_stage(stage_names, exclude, wide)
    if not stage_names then
        stage_names = {}
        for name in pairs(config.STAGE_TEMPLATES) do table.insert(stage_names, name) end
        table.sort(stage_names)
    end
    local excludeSet = {}
    for key, value in pairs(exclude or {}) do
        if valueType(key) == "number" then excludeSet[value] = true
        elseif value then excludeSet[key] = true end
    end
    -- One frame per scan, not one new screenshot per possible stage.
    snapshot()
    usePreviousSnap(true)
    for _, stage_name in ipairs(stage_names) do
        if not excludeSet[stage_name] then
            local template_files = config.STAGE_TEMPLATES[stage_name]
            if template_files then
                local searchReg = screen.region(config.STAGE_REGIONS[stage_name])
                for _, filename in ipairs(template_files) do
                    if searchReg and searchReg:exists(getPattern(filename), 0) then
                        usePreviousSnap(false)
                        return stage_name
                    end
                end
            end
        end
    end
    if wide then
        -- Recovery must widen the search rectangle, not merely the stage list.
        -- Keep the stricter threshold: these labels may occur elsewhere on screen.
        local full = screen.fullRegion()
        for _, stage_name in ipairs(stage_names) do
            if not excludeSet[stage_name] then
                for _, filename in ipairs(config.STAGE_TEMPLATES[stage_name] or {}) do
                    local match = full:exists(getPattern(filename, true), 0)
                    if match then
                        print(string.format("Wide search found %s at %.0f,%.0f (score %.2f)",
                            stage_name, match:getX(), match:getY(), match:getScore()))
                        usePreviousSnap(false)
                        return stage_name
                    end
                end
            end
        end
    end
    -- Only try the main-menu controls when this scan actually allows MAINMENU.
    -- All ordinary stage matches retain priority over the color fallback.
    if not excludeSet.MAINMENU then
        for _, name in ipairs(stage_names) do
            if name == "MAINMENU" then
                local evidence = main_menu.findPlay()
                if evidence then
                    print("MAINMENU recognized by Play button and cyan tabs")
                    return "MAINMENU", evidence
                end
                break
            end
        end
    end
    usePreviousSnap(false)
    return nil
end

local function detect_anti_bot_odd_cards()
    local card_coords = {
        config.ANTI_BOT_CARD_POS_1,
        config.ANTI_BOT_CARD_POS_2,
        config.ANTI_BOT_CARD_POS_3,
        config.ANTI_BOT_CARD_POS_4,
        config.ANTI_BOT_CARD_POS_5,
        config.ANTI_BOT_CARD_POS_6,
    }

    local cardRegions = {}
    for i, pos in ipairs(card_coords) do
        cardRegions[i] = assert(screen.region({pos[1], pos[2], pos[1] + config.ANTI_BOT_CARD_WIDTH, pos[2] + config.ANTI_BOT_CARD_HEIGHT}), "Card is outside the game pane; resize and recalibrate.")
    end

    local n = #cardRegions
    local sim = {}
    for i = 1, n do
        sim[i] = {}
        for j = 1, n do sim[i][j] = 0 end
    end

    -- Compare regions using dynamic screen snapshots
    snapshot()
    usePreviousSnap(true)
    for i = 1, n do
        local snapshotPath = string.format("temp_card_%d.png", i)
        cardRegions[i]:save(snapshotPath)
        
        for j = 1, n do
            if i ~= j then
                local match = cardRegions[j]:exists(Pattern(snapshotPath):similar(0.5), 1)
                sim[i][j] = match and match:getScore() or 0.0
            end
        end
    end

    local avg_sim = {}
    print("Analyzing card similarity...")
    for i = 1, n do
        local sum = 0
        for j = 1, n do
            if i ~= j then sum = sum + sim[i][j] end
        end
        avg_sim[i] = { index = i - 1, score = sum / (n - 1) }
        print(string.format("  Card %d: similarity score %.2f", i, avg_sim[i].score))
    end

    table.sort(avg_sim, function(a, b) return a.score < b.score end)
    usePreviousSnap(false)
    return { avg_sim[1].index, avg_sim[2].index }
end


return {
    detect_stage = detect_stage,
    detect_templates = detect_templates,
    load_templates = load_templates,
    detect_anti_bot_odd_cards = detect_anti_bot_odd_cards,
}
