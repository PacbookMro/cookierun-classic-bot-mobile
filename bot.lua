-- AnkuLua uses global type() for typing text; keep its binding intact.
local valueType = typeOf or type
local actions = require("actions")
local config = require("config")
local cycle = require("cycle")
local detection = require("detection")
local recovery = require("recovery")
local diagnostics = require("diagnostics")

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

local function random_uniform(min_val, max_val)
    return min_val + math.random() * (max_val - min_val)
end

local function get_detection_stage_names(group_name, exclude)
    local stage_names = {}
    local seen = {}

    local function add_stage(name)
        if not seen[name] then
            seen[name] = true
            table.insert(stage_names, name)
        end
    end

    if group_name ~= "IN_GAME" then
        for _, stage_name in ipairs(config.DETECTION_ALWAYS_STAGES or {}) do
            add_stage(stage_name)
        end
    end

    if config.DETECTION_GROUPS and config.DETECTION_GROUPS[group_name] then
        for _, stage_name in ipairs(config.DETECTION_GROUPS[group_name]) do
            add_stage(stage_name)
        end
    end

    if group_name == "IN_GAME" then
        for _, stage_name in ipairs(config.DETECTION_ALWAYS_STAGES or {}) do
            --print("IN_GAME" .. stage_name)
            add_stage(stage_name)
        end
    end

    if exclude then
        local filtered = {}
        for _, s in ipairs(stage_names) do
            if not exclude[s] then
                table.insert(filtered, s)
            end
        end
        return filtered
    end

    return stage_names
end

local function prompt_user_options()
    print("⚙️ --- Bot Options ---")

    local boost_names = {}
    for _, choice in ipairs(BOOST_CHOICES) do
        table.insert(boost_names, choice[1])
    end

    dialogInit()
    addCheckBox("simple_mode", "Simple buff + repeat (skip relics and friend lives)", true)
    newRow()
    addTextView("Minimum minutes between round starts (waits for results):")
    addEditNumber("round_minutes", 5)
    newRow()
    addCheckBox("use_random_boost", "Buy one random boost each round", false)
    newRow()
    addCheckBox("use_fast_start", "⚡ Use Fast Start (buy + use)", false)
    newRow()
    addCheckBox("use_cookie_relay", "🍪 Use Cookie Relay (buy + use)", false)
    newRow()
    addCheckBox("use_desired_random_boost", "🎲 Use Desired Random Boost (buy + use)", false)
    newRow()
    addTextView("Desired boost: configure the same target in the game multi-buy screen first.")
    --newRow()
    addSpinner("selected_boost_name", boost_names, boost_names[1])
    newRow()
    addCheckBox("detect_relic", "🏺 Detect Relic (open + claim)", true)
    newRow()
    addCheckBox("send_friend_lives", "Receive/send friend lives (full mode only)", false)
    dialogShow("CookieRun Classic Bot Options")
    assert(valueType(round_minutes) == "number" and round_minutes >= 0 and round_minutes <= 1440,
        "Round interval must be between 0 and 1440 minutes")
    assert(not (use_random_boost and use_desired_random_boost),
        "Choose either one random boost or desired boost, not both")

    local chosen_boost = BOOST_CHOICES[1]
    for _, choice in ipairs(BOOST_CHOICES) do
        if choice[1] == selected_boost_name then
            chosen_boost = choice
            break
        end
    end

    return {
        simple_mode = simple_mode,
        round_interval = round_minutes * 60,
        send_friend_lives = not simple_mode and send_friend_lives,
        use_random_boost = use_random_boost,
        use_fast_start = use_fast_start,
        use_cookie_relay = use_cookie_relay,
        use_desired_random_boost = use_desired_random_boost,
        desired_boost_template = chosen_boost[2],
        desired_boost_name = use_desired_random_boost and chosen_boost[1] or nil,
        detect_relic = not simple_mode and detect_relic,
    }
end

local function main()
    print("🚀 CookieRun Classic Bot Started")
    print("Screen scaling configured; keep the game in landscape.")

    detection.load_templates()

    local options = prompt_user_options()
    local relic_exclude = nil
    if not options.detect_relic then
        relic_exclude = { RELIC_COMPLETE = true, RELIC_CLAIM = true }
    end

    local last_stage = nil
    local round = cycle.new(options.round_interval)
    local detection_group = "PRE_GAME"
    --local detection_group = "IN_GAME"
    local recovery_state = recovery.new(os.time())
    local last_recognized_stage = nil
    local last_lives_time = os.time()
    local lives_interval = random_uniform(25 * 60, 35 * 60)

    while true do
        local stage = detection.detect_stage(get_detection_stage_names(detection_group, relic_exclude))
        usePreviousSnap(false)

        if stage == nil then
            local scan = recovery_state:poll(os.time(), config.WIDE_SCAN_INTERVAL,
                config.DETECTION_RECOVERY_SCAN_INTERVAL[detection_group], config.STALL_DIAGNOSTIC_SECONDS)
            if scan.all then
                stage = detection.detect_stage(nil, relic_exclude, true)
            elseif scan.wide then
                stage = detection.detect_stage(get_detection_stage_names(detection_group, relic_exclude), nil, true)
            end
            if not stage and scan.diagnostic then
                diagnostics.save_unrecognized(detection_group, last_recognized_stage, scan.elapsed)
            end
        end
        if stage then
            recovery_state:detected(os.time())
            last_recognized_stage = stage
            print("Detected stage: " .. stage)
        end

        if stage == last_stage then
            sleep(1)
            last_stage = nil
        else
            last_stage = stage

            if stage == "MAINMENU" then
                print("🎮 Detected Stage: MAINMENU")
                print("⏳ Waiting 5 seconds for screen refresh...")
                sleep(5)

                local lives_elapsed = os.time() - last_lives_time
                if options.send_friend_lives and lives_elapsed >= lives_interval then
                    actions.handle_quick_receive_and_send_lives()
                    last_lives_time = os.time()
                    lives_interval = random_uniform(25 * 60, 35 * 60)
                    last_stage = nil
                else
                    local delay = round:remaining(os.time())
                    if delay > 0 then
                        print(string.format("Waiting %.0f seconds before the next round", delay))
                        sleep(delay)
                    end
                    -- The screen may have changed during the wait.
                    if detection.detect_stage({"MAINMENU"}, nil, true) == "MAINMENU" then
                        actions.start_game()
                        round:prepare()
                        detection_group = "PRE_GAME"
                        recovery_state:detected(os.time())
                        print("Play tapped; looking for the item/buff screen.")
                    end
                    last_stage = nil
                end

            elseif stage == "PURCHASE_ITEM" then
                print("🛒 Detected Stage: PURCHASE_ITEM")
                if round:can_purchase() then
                    if options.use_fast_start then actions.purchase_fast_start() end
                    if options.use_cookie_relay then actions.purchase_cookie_relay() end
                    if options.use_random_boost then actions.purchase_random_boost() end
                    if options.use_desired_random_boost then
                        actions.purchase_desired_random_boost(options.desired_boost_template, options.desired_boost_name)
                    end
                    round:purchased()
                end
                actions.play_game()
                round:started(os.time())
                recovery_state:detected(os.time())
                print("Run Play tapped; waiting for run/result screens. Quiet detection during a run is normal.")
                detection_group = "IN_GAME"
                sleep(0.2)
                last_stage = nil

            elseif stage == "GAME_START" then
                print("🏁 Detected Stage: GAME_START")
                if options.use_fast_start then actions.using_fast_start() end
                detection_group = "IN_GAME"

            elseif stage == "GAME_RELAY" then
                print("🔄 Detected Stage: GAME_RELAY")
                if options.use_cookie_relay then actions.using_cookie_relay() end
                detection_group = "IN_GAME"

            elseif stage == "GAME_COMPLETE" then
                print("✅ Detected Stage: GAME_COMPLETE")
                actions.complete_finish()
                detection_group = "POST_GAME"

            elseif stage == "MYSTERY_BOX" then
                print("🎁 Detected Stage: MYSTERY_BOX")
                actions.accept_mystery_box()
                sleep(3)
                detection_group = "POST_GAME"
                last_stage = nil

            elseif stage == "CONGRATULATIONS" then
                print("🎉 Detected Stage: CONGRATULATIONS")
                actions.accept_congratulations()
                detection_group = "POST_GAME"
                last_stage = nil

            elseif stage == "LEVEL_UP" then
                print("⬆️ Detected Stage: LEVEL_UP")
                actions.accept_level_up()
                detection_group = "PRE_GAME"

            elseif stage == "DAILY_CHECKIN" then
                print("📅 Detected Stage: DAILY_CHECKIN")
                actions.accept_daily_checkin()
                detection_group = "PRE_GAME"

            elseif stage == "DAILY_CHECKIN_BOOST_SET" then
                print("📅 Detected Stage: DAILY_CHECKIN_BOOST_SET")
                actions.accept_daily_checkin_boost_set()
                detection_group = "PRE_GAME"

            elseif stage == "DAILY_TREASURE" then
                print("💎 Detected Stage: DAILY_TREASURE")
                actions.accept_daily_treasure()
                detection_group = "PRE_GAME"

            elseif stage == "DAILY_NEW" then
                print("📰 Detected Stage: DAILY_NEW")
                actions.accept_daily_new()
                detection_group = "PRE_GAME"

            elseif stage == "ENTER_LEAGUE" then
                print("🏆 Detected Stage: ENTER_LEAGUE")
                actions.accept_enter_league()
                detection_group = "PRE_GAME"

            elseif stage == "LEAGUE_RESULTS" then
                print("🏆 Detected Stage: LEAGUE_RESULTS")
                actions.accept_league_results()
                detection_group = "PRE_GAME"

            elseif stage == "PREVIOUS_RANK_RESULTS" then
                print("🏆 Detected Stage: PREVIOUS_RANK_RESULTS")
                actions.accept_previous_rank_results()
                detection_group = "PRE_GAME"

            elseif stage == "OVERTAKE_BREAK_SCORE" then
                print("🏆 Detected Stage: OVERTAKE_BREAK_SCORE")
                actions.accept_overtake_break_score()
                detection_group = "POST_GAME"
                last_stage = nil

            elseif stage == "TOO_MANY_TREASURES" then
                print("💎 Detected Stage: TOO_MANY_TREASURES")
                actions.accept_too_many_treasures()
                detection_group = "PRE_GAME"

            elseif stage == "RELIC_COMPLETE" then
                print("🏺 Detected Stage: RELIC_COMPLETE")
                actions.open_relic_complete()
                detection_group = "PRE_GAME"

            elseif stage == "RELIC_CLAIM" then
                print("🏺 Detected Stage: RELIC_CLAIM")
                actions.accept_relic_claim()
                detection_group = "PRE_GAME"

            elseif stage == "ANTI_BOT" then
                print("⚠️ Detected Stage: ANTI_BOT")
                snapshot()
                actions.handle_anti_bot()
                usePreviousSnap(false)
                last_stage = nil

            elseif stage == "CONNECTION_LOST" then
                print("🔌 Detected Stage: CONNECTION_LOST")
                actions.handle_connection_lost()
                last_lives_time = os.time()
                lives_interval = random_uniform(25 * 60, 35 * 60)
                detection_group = "PRE_GAME"
                last_stage = nil
                round:prepare()

            elseif stage == "PARTY_RUN" then
                actions.close_party_run_mode()
                detection_group = "PRE_GAME"
                last_stage = nil

            elseif stage == "GAME_SETTINGS" then
                actions.close_game_settings()
                detection_group = "PRE_GAME"
                last_stage = nil

            elseif stage == "INACTIVE" then
                print("💤 Detected Stage: INACTIVE")
                actions.handle_inactive()
                last_stage = nil
            end
        end

        sleep(0.25)
    end
end

return {main = main}
