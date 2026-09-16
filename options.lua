-- AnkuLua reserves type() for text entry.
local valueType = typeOf or type
local config = require("config")
local options = {}
local ANY_BOOST = "Any completed boost (game target)"

local BOOST_CHOICES = {
    { "Double Coins", config.BOOST_DOUBLE_COINS_TEMPLATE },
    { "+15% Score Bonus", config.BOOST_15P_SCORE_BONUS_TEMPLATE },
    { "-15% HP Drain", config.BOOST_M15P_HP_DRAIN_TEMPLATE },
    { "Revive Once with 80 HP", config.BOOST_REVIVE_ONCE_WITH_80HP_TEMPLATE },
    { "70% Crush Chance", config.BOOST_70P_CRUSH_CHANCE_TEMPLATE },
    { "+17% Base Speed", config.BOOST_17P_BASE_SPEED_TEMPLATE },
    { "Gold Coin Magic", config.BOOST_GOLD_COIN_MAGIC_TEMPLATE },
    { "-30% Collision Damage", config.BOOST_M30P_COLLISION_DAMAGE_TEMPLATE },
    { "+20% HP from Potions", config.BOOST_20P_HP_FROM_POTIONS_TEMPLATE },
    { "Magnetic Aura", config.BOOST_MAGNETIC_AURA_TEMPLATE },
    { "2 Pit Lifts", config.BOOST_2PIT_LIFTS_TEMPLATE },
}

local ITEM_MODES = {"Off", "Use owned only (never buy)", "Buy one each round + use"}
local function validMode(mode)
    for _, item in ipairs(ITEM_MODES) do if mode == item then return true end end
    return false
end
local function range(low, high, minimum, maximum, name)
    assert(valueType(low) == "number" and valueType(high) == "number"
        and low >= minimum and high <= maximum and low <= high,
        name .. " must satisfy " .. minimum .. " <= minimum <= maximum <= " .. maximum)
end

function options.read()
    print("⚙️ --- Bot Options ---")

    local boost_names = {ANY_BOOST}
    for _, choice in ipairs(BOOST_CHOICES) do
        table.insert(boost_names, choice[1])
    end

    dialogInit()
    addCheckBox("simple_mode", "Simple buff + repeat (skip relics and friend lives)", true)
    newRow()
    addTextView("Minutes between round starts: minimum / maximum (0 = immediate)")
    addEditNumber("round_minutes", 5)
    addEditNumber("round_max_minutes", 5)
    newRow()
    addCheckBox("use_random_boost", "Buy one random boost each round", false)
    newRow()
    addTextView("Fast Start:")
    addSpinner("fast_start_mode", ITEM_MODES, ITEM_MODES[1])
    newRow()
    addTextView("Cookie Relay:")
    addSpinner("relay_mode", ITEM_MODES, ITEM_MODES[1])
    newRow()
    addCheckBox("use_desired_random_boost", "🎲 Use Desired Random Boost (buy + use)", false)
    newRow()
    addTextView("Game Multi-Buy chooses/rerolls boosts. Bot verifies the result:")
    --newRow()
    addSpinner("selected_boost_name", boost_names, boost_names[1])
    newRow()
    addCheckBox("detect_relic", "🏺 Detect Relic (open + claim)", true)
    newRow()
    addCheckBox("send_friend_lives", "Receive/send friend lives (full mode only)", false)
    dialogShow("CookieRun Classic Bot Options")
    range(round_minutes, round_max_minutes, 0, 1440, "Round interval (minutes)")
    assert(validMode(fast_start_mode) and validMode(relay_mode), "Invalid item mode")
    assert(not (use_random_boost and use_desired_random_boost),
        "Choose either one random boost or desired boost, not both")

    local chosen_boost
    if selected_boost_name == ANY_BOOST then
        local files = {}
        for _, group in ipairs(config.BOOST_TEMPLATES) do
            for _, filename in ipairs(group) do files[#files+1]=filename end
        end
        chosen_boost = {ANY_BOOST, files}
    end
    for _, choice in ipairs(BOOST_CHOICES) do
        if choice[1] == selected_boost_name then
            chosen_boost = choice
            break
        end
    end
    assert(chosen_boost, "Unknown boost verification choice")

    local boost_timeout, boost_settle = 180, 5
    if use_desired_random_boost then
        dialogInit()
        addTextView("Configure target(s) in the game's Multi screen first. The bot does not change them.")
        newRow()
        addTextView("Maximum Multi-Buy wait (seconds, 10-1800)")
        addEditNumber("boost_wait_seconds", 180)
        newRow()
        addTextView("Initial animation delay (seconds, 0-60)")
        addEditNumber("boost_settle_seconds", 5)
        newRow()
        addTextView("Waits for a stable banner and the rolling panel to close. Sends Multi-Buy once.")
        dialogShow("Random boost completion")
        range(boost_wait_seconds, boost_wait_seconds, 10, 1800, "Multi-Buy timeout")
        range(boost_settle_seconds, boost_settle_seconds, 0, 60, "Initial boost delay")
        assert(boost_settle_seconds+3 <= boost_wait_seconds,
            "Multi-Buy timeout must allow the initial delay plus 3 seconds of stable recognition")
        boost_timeout, boost_settle = boost_wait_seconds, boost_settle_seconds
    end

    dialogInit()
    addCheckBox("vary_taps", "Vary tap positions, duration and extra pause", false)
    newRow()
    addTextView("Tap radius: 0-6 pixels at reference resolution")
    addEditNumber("tap_radius", 3)
    newRow()
    addTextView("Press duration in milliseconds: minimum / maximum")
    addEditNumber("press_min_ms", 40)
    addEditNumber("press_max_ms", 100)
    newRow()
    addTextView("Maximum extra pause before each tap (seconds)")
    addEditNumber("tap_pause", 0.25)
    newRow()
    addCheckBox("dim_screen", "Dim the entire phone screen while running", false)
    newRow()
    addTextView("Brightness percent (1-100; trial has a time limit)")
    addEditNumber("dim_percent", 5)
    newRow()
    addTextView("After a forced stop, run restore_brightness.lua if still dim.")
    dialogShow("Timing, taps and brightness")
    if vary_taps then
        range(tap_radius, tap_radius, 0, 6, "Tap radius")
        assert(tap_radius == math.floor(tap_radius), "Tap radius must be an integer")
        range(press_min_ms, press_max_ms, 20, 200, "Press duration (milliseconds)")
        range(tap_pause, tap_pause, 0, 2, "Extra tap pause (seconds)")
    end
    if dim_screen then range(dim_percent, dim_percent, 1, 100, "Brightness percent") end

    return {
        simple_mode = simple_mode,
        round_interval = round_minutes * 60,
        round_max_interval = round_max_minutes * 60,
        interaction = vary_taps and {enabled=true, radius=tap_radius, press_min=press_min_ms/1000,
            press_max=press_max_ms/1000, pause=tap_pause} or {enabled=false},
        dim_percent = dim_screen and dim_percent or nil,
        send_friend_lives = not simple_mode and send_friend_lives,
        use_random_boost = use_random_boost,
        use_fast_start = fast_start_mode ~= ITEM_MODES[1],
        buy_fast_start = fast_start_mode == ITEM_MODES[3],
        use_cookie_relay = relay_mode ~= ITEM_MODES[1],
        buy_cookie_relay = relay_mode == ITEM_MODES[3],
        use_desired_random_boost = use_desired_random_boost,
        boost_timeout = boost_timeout,
        boost_settle = boost_settle,
        desired_boost_template = chosen_boost[2],
        desired_boost_name = use_desired_random_boost and chosen_boost[1] or nil,
        detect_relic = not simple_mode and detect_relic,
    }
end

return options
