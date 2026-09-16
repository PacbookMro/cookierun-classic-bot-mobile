local config = require("config")
local detection = require("detection")

local actions = {}
local screen = require("screen")

local function randomSleep(minSec, maxSec)
    local delay = minSec + math.random() * (maxSec - minSec)
    sleep(delay)
end

local tap = screen.tap

function actions.start_game(verifiedTarget)
    print("🏁 Starting the game...")
    if verifiedTarget then
        screen.checkDisplay()
        screen.last_action = string.format("Main-menu Play verified at logical=(%d,%d)",
            verifiedTarget:getX(), verifiedTarget:getY())
        print(screen.last_action)
        screen.tapLogical(verifiedTarget)
    else
        tap(config.START_BUTTON)
    end
    randomSleep(0.8, 1.4)
end

function actions.play_game()
    print("🎮 Playing the game...")
    tap(config.PLAY_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.purchase_fast_start()
    print("🛒 Purchasing Fast Start...")
    tap(config.FAST_START_ITEM)
    randomSleep(0.8, 1.4)
    tap(config.PURCHASE_BUTTON)
    randomSleep(1.0, 2.0)
end

function actions.purchase_cookie_relay()
    print("🛒 Purchasing Cookie Relay...")
    tap(config.COOKIE_RELAY_ITEM)
    randomSleep(0.8, 1.4)
    tap(config.PURCHASE_BUTTON)
    randomSleep(1.0, 2.0)
end

function actions.purchase_random_boost()
    print("🛒 Purchasing Random Boost...")
    tap(config.RANDOM_BOOST_ITEM)
    randomSleep(0.8, 1.4)
    tap(config.PURCHASE_BUTTON)
    randomSleep(1.0, 2.0)
end

function actions.purchase_desired_random_boost(desired_template, desired_name, timeout, settle)
    print("🛒 Purchasing Desired Random Boost...")
    assert(getColor and snapshotColor, "Multi-Buy completion requires AnkuLua color capture support")
    tap(config.RANDOM_BOOST_ITEM)
    randomSleep(0.8, 1.4)
    tap(config.MULTI_PURCHASE_BUTTON)
    randomSleep(1.0, 2.0)
    tap(config.MULTI_BUY_BUTTON)
    randomSleep(0.8, 1.4)

    require("boost_wait").wait(desired_template, desired_name, timeout, settle)
end

function actions.using_fast_start()
    print("⚡ Using Fast Start...")
    tap(config.FAST_START_USE_BUTTON)
    randomSleep(0.8, 1.2)
end

function actions.using_cookie_relay()
    print("🍪 Using Cookie Relay...")
    tap(config.COOKIE_RELAY_USE_BUTTON)
    randomSleep(0.8, 1.2)
end

function actions.complete_finish()
    print("🏆 Completing the game...")
    tap(config.COMPLETE_FINISH_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_mystery_box()
    print("🎁 Accepting Mystery Box...")
    tap(config.ACCEPT_MYSTERY_BOX_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_congratulations()
    print("🎉 Accepting Congratulations...")
    tap(config.ACCEPT_CONGRATULATIONS_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_level_up()
    print("⬆️ Accepting Level Up...")
    tap(config.ACCEPT_LEVEL_UP_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_daily_checkin()
    print("📅 Accepting Daily Check-in...")
    tap(config.ACCEPT_DAILY_CHECKIN_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_daily_checkin_boost_set()
    print("📅 Accepting Daily Check-in Boost Set...")
    tap(config.ACCEPT_DAILY_CHECKIN_BOOST_SET_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_daily_treasure()
    print("💎 Accepting Daily Treasure...")
    tap(config.ACCEPT_DAILY_TREASURE_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_daily_new()
    print("📰 Accepting Daily New...")
    tap(config.ACCEPT_DAILY_NEW_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_enter_league()
    print("🏆 Accepting Enter League...")
    tap(config.ACCEPT_ENTER_LEAGUE_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_league_results()
    print("🏆 Accepting League Results...")
    tap(config.ACCEPT_LEAGUE_RESULTS_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_previous_rank_results()
    print("🏆 Accepting Previous Rank Results...")
    tap(config.ACCEPT_PREVIOUS_RANK_RESULTS_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_too_many_treasures()
    print("💎 Accepting Too Many Treasures...")
    tap(config.ACCEPT_TOO_MANY_TREASURES_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_overtake_break_score()
    print("🏆 Accepting Overtake Break Score...")
    tap(config.ACCEPT_OVERTAKE_BREAK_SCORE_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.open_relic_complete()
    print("🏺 Opening Relic Complete...")
    tap(config.RELIC_COMPLETE_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.accept_relic_claim()
    print("🏺 Accepting Relic Claim...")
    tap(config.RELIC_CLAIM_BUTTON)
    randomSleep(0.8, 1.4)
    tap(config.RELIC_CLOSE_BUTTON)
    randomSleep(10.0, 15.0)
end

function actions.handle_anti_bot()
    print("🤖 Solving Anti-Bot captcha...")
    local card_coords = {
        config.ANTI_BOT_CARD_POS_1, config.ANTI_BOT_CARD_POS_2, config.ANTI_BOT_CARD_POS_3,
        config.ANTI_BOT_CARD_POS_4, config.ANTI_BOT_CARD_POS_5, config.ANTI_BOT_CARD_POS_6,
    }

    local attempts = 0
    repeat
        attempts = attempts + 1
        if attempts > 3 then error("Card challenge needs manual attention.") end
        local odd_indices = detection.detect_anti_bot_odd_cards()
        print(string.format("🃏 Found odd cards: Card %d and Card %d", odd_indices[1] + 1, odd_indices[2] + 1))

        for _, zero_idx in ipairs(odd_indices) do
            local idx = zero_idx + 1
            print(idx)
            local cx, cy = card_coords[idx][1], card_coords[idx][2]
            local margin = 20
            local tx = math.random(cx + margin, cx + config.ANTI_BOT_CARD_WIDTH - margin)
            local ty = math.random(cy + margin, cy + config.ANTI_BOT_CARD_HEIGHT - margin)

            print(string.format("  👆 Tapping Card %d at (%d, %d)", idx, tx, ty))
            tap({tx, ty})
            randomSleep(1.0, 1.0)
        end

    until (not exists(config.STAGE_ANTI_BOT_TEMPLATE[1], 1))

    print("✅ Anti-Bot captcha solved!")
    randomSleep(0.8, 1.4)
end

function actions.handle_connection_lost()
    print("🔌 Handling Connection Lost...")
    tap(config.CONNECTION_LOST_RELOAD_BUTTON)
    randomSleep(10.0, 15.0)
end

function actions.handle_inactive()
    print("💤 Handling Inactive state...")
    tap(config.INACTIVE_RELOAD_BUTTON)
    randomSleep(10.0, 15.0)
end

function actions.handle_send_friend_life()
    print("💌 Handling Send Friend Life...")
    local deadline = os.time() + 120
    while true do
        if os.time() >= deadline then error("Friend leaderboard timed out; check calibration.") end
        local topMatches = detection.detect_templates(config.FRIEND_TOP_LEADERBOARD_TEMPLATE, config.FRIEND_TOP_LEADERBOARD_REGION)
        if #topMatches > 0 then
            print("✅ Top of Friend Leaderboard reached.")
            break
        end
        print("🔄 Scrolling up to find Send Friend Life...")
        local startLoc = screen.location(config.LEADERBOARD_TOP_POSITION[1], config.LEADERBOARD_TOP_POSITION[2])
        local endLoc = screen.location(config.LEADERBOARD_BOTTOM_POSITION[1], config.LEADERBOARD_BOTTOM_POSITION[2])
        dragDrop(startLoc, endLoc)
        randomSleep(0.8, 1.4)
    end

    local no_button_scroll_count = 0
    deadline = os.time() + 120
    while true do
        if os.time() >= deadline then error("Sending lives timed out.") end
        local bottomMatches = detection.detect_templates(config.FRIEND_BOTTOM_LEADERBOARD_TEMPLATE, config.FRIEND_BOTTOM_LEADERBOARD_REGION)
        if #bottomMatches > 0 then
            print("✅ Bottom of Friend Leaderboard reached. Done sending lives.")
            break
        end

        local sendButtons = detection.detect_templates(config.FRIEND_SEND_LIFE_TEMPLATE, config.FRIEND_SEND_LIFE_REGION)
        if #sendButtons > 0 then
            no_button_scroll_count = 0
            for _, btn in ipairs(sendButtons) do
                print("💌 Sending life to friend...")
                screen.checkDisplay()
                screen.tapMatch(btn.match)
                randomSleep(0.8, 1.4)
                print("💌 Confirming send life...")
                tap(config.CONFIRM_SEND_LIFE_BUTTON)
                randomSleep(0.8, 1.4)
                print("💌 Closing send life dialog...")
                tap(config.CLOSE_SEND_LIFE_DIALOG_BUTTON)
                randomSleep(0.8, 1.4)
            end
        else
            no_button_scroll_count = no_button_scroll_count + 1
            if no_button_scroll_count >= 30 then
                print("⚠️ No send life buttons found for 30 consecutive scrolls. Giving up.")
                break
            end
            print(string.format("🔄 No send life buttons found, scrolling down... (%d/30)", no_button_scroll_count))
            local startLoc = screen.location(config.LEADERBOARD_BOTTOM_POSITION[1], config.LEADERBOARD_BOTTOM_POSITION[2])
            local endLoc = screen.location(config.LEADERBOARD_TOP_POSITION[1], config.LEADERBOARD_TOP_POSITION[2])
            dragDrop(startLoc, endLoc)
            randomSleep(0.8, 1.4)
        end
    end
end

function actions.handle_quick_receive_and_send_lives()
    print("✉️ Handling Quick Receive and Send Lives...")
    randomSleep(0.8, 1.4)
    tap(config.MAIL_BOX_BUTTON)
    randomSleep(0.8, 1.4)
    tap(config.MAIL_BOX_LIVES_TAB_BUTTON)
    randomSleep(0.8, 1.4)

    local noLives = detection.detect_templates(config.NO_LIVES_TO_RECEIVE_TEMPLATE, config.NO_LIVES_TO_RECEIVE_REGION)
    if #noLives > 0 then
        print("✉️ No lives to receive. Proceeding to send lives...")
        tap(config.MAIL_BOX_CLOSE_BUTTON)
        return
    end

    print("✉️ Receiving all lives...")
    tap(config.QUICK_RECEIVE_AND_SEND_LIVES_BUTTON)
    randomSleep(0.8, 1.4)

    local deadline = os.time() + 120
    while true do
        if os.time() >= deadline then error("Receiving lives timed out.") end
        local allSent = detection.detect_templates(config.ALL_LIVES_RECEIVED_AND_SENT_TEMPLATE, config.ALL_LIVES_RECEIVED_AND_SENT_REGION)
        if #allSent > 0 then
            print("✉️ All lives received and sent. Done!")
            tap(config.ACCEPT_ALL_LIVES_RECEIVED_AND_SENT_BUTTON)
            randomSleep(0.8, 1.4)
            tap(config.MAIL_BOX_CLOSE_BUTTON)
            randomSleep(0.8, 1.4)
            break
        end

        local confirmButtons = detection.detect_templates(config.CONFIRM_SEND_LIFE_TEMPLATE, config.CONFIRM_SEND_LIFE_REGION)
        if #confirmButtons > 0 then
            print("✉️ Sending lives to friends...")
            tap(config.CONFIRM_SEND_LIFE_BUTTON)
            randomSleep(0.8, 1.4)
        end
        sleep(0.5)
    end
    print("✉️ Quick Receive and Send Lives completed.")
end

function actions.close_announcement_dialog()
    print("🖱️ Closing announcement dialog...")
    for i = 1, 5 do
        print(string.format("🖱️ Tapping close announcement dialog button %d/5", i))
        tap(config.CLOSE_ANNOUNCEMENT_DIALOG_BUTTON)
        randomSleep(0.8, 1.4)
    end
    randomSleep(0.8, 1.4)

    local stage = detection.detect_stage({ "PARTY_RUN", "GAME_SETTINGS" })
    if stage == "PARTY_RUN" then
        actions.close_party_run_mode()
    elseif stage == "GAME_SETTINGS" then
        actions.close_game_settings()
    end
end

function actions.close_party_run_mode()
    print("🖱️ Closing Party Run mode...")
    tap(config.EXIT_PARTY_RUN_MODE_BUTTON)
    randomSleep(0.8, 1.4)
end

function actions.close_game_settings()
    print("🖱️ Closing Game Settings...")
    tap(config.EXIT_GAME_SETTINGS_BUTTON)
    randomSleep(0.8, 1.4)
end

return actions
