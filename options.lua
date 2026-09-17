-- AnkuLua reserves type() for text entry.
local valueType = typeOf or type
local config = require("config")
local options = {}
local ui = require("ui")
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
    ui.text("Wait after results. 0 / 0 = no repeat delay.")
    ui.number("Minimum wait (minutes)", "repeat_min_minutes", 5)
    ui.number("Maximum wait (minutes)", "repeat_max_minutes", 5)
    ui.show("Repeat delay after stage ends")
    range(repeat_min_minutes, repeat_max_minutes, 0, 1440, "Repeat delay (minutes)")

    dialogInit()
    ui.check("simple_mode", "Simple mode (skip relics/friend lives)", true)
    ui.choice("Fast Start", "fast_start_mode", ITEM_MODES, ITEM_MODES[1])
    ui.choice("Cookie Relay", "relay_mode", ITEM_MODES, ITEM_MODES[1])
    ui.show("Items and mode")
    assert(validMode(fast_start_mode) and validMode(relay_mode), "Invalid item mode")

    dialogInit()
    ui.check("use_random_boost", "Buy one random boost each round", false)
    ui.check("use_desired_random_boost", "Use game Multi-Buy each round", false)
    ui.choice("Multi-Buy result to verify", "selected_boost_name", boost_names, boost_names[1])
    ui.show("Random boost")
    assert(not (use_random_boost and use_desired_random_boost),
        "Choose either one random boost or desired boost, not both")

    if not simple_mode then
        dialogInit()
        ui.check("detect_relic", "Open and claim relics", true)
        ui.check("send_friend_lives", "Receive/send friend lives", false)
        ui.show("Optional chores")
    end

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
        ui.text("Select targets in the game's Multi screen first.")
        ui.number("Maximum wait (seconds, 10-1800)", "boost_wait_seconds", 180)
        ui.number("Initial delay (seconds, 0-60)", "boost_settle_seconds", 5)
        ui.show("Multi-Buy completion")
        range(boost_wait_seconds, boost_wait_seconds, 10, 1800, "Multi-Buy timeout")
        range(boost_settle_seconds, boost_settle_seconds, 0, 60, "Initial boost delay")
        assert(boost_settle_seconds+3 <= boost_wait_seconds,
            "Multi-Buy timeout must allow the initial delay plus 3 seconds of stable recognition")
        boost_timeout, boost_settle = boost_wait_seconds, boost_settle_seconds
    end

    dialogInit()
    ui.check("vary_taps", "Vary tap positions and timing", false)
    ui.number("Tap radius (0-6 reference pixels)", "tap_radius", 3)
    ui.show("Tap variation")
    if vary_taps then
        range(tap_radius, tap_radius, 0, 6, "Tap radius")
        assert(tap_radius == math.floor(tap_radius), "Tap radius must be an integer")
        dialogInit()
        ui.number("Minimum press (milliseconds)", "press_min_ms", 40)
        ui.number("Maximum press (milliseconds)", "press_max_ms", 100)
        ui.number("Maximum extra pause (seconds)", "tap_pause", 0.25)
        ui.show("Tap timing")
        range(press_min_ms, press_max_ms, 20, 200, "Press duration (milliseconds)")
        range(tap_pause, tap_pause, 0, 2, "Extra tap pause (seconds)")
    end

    dialogInit()
    ui.check("dim_screen", "Dim entire phone while running", false)
    ui.number("Brightness (1-100 percent)", "dim_percent", 5)
    ui.text("If left dim after Stop, run restore_brightness.lua.")
    ui.show("Screen brightness")
    if dim_screen then range(dim_percent, dim_percent, 1, 100, "Brightness percent") end

    return {
        simple_mode = simple_mode,
        round_interval = repeat_min_minutes * 60,
        round_max_interval = repeat_max_minutes * 60,
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
