# Phone test checklist — mobile.6

## MultiStar window test

Follow [Samsung MultiStar setup](SAMSUNG_MULTI_WINDOW.md). Put CookieRun above another app on a portrait display, select its two corners, and verify the calibration outline covers only the game. Reuse the saved window for an automation run. Test the two distinct Play buttons, buying, and result clearing while the lower app is visible.

Confirm a physical rotation stops automation and that reselecting a moved/resized pane restores alignment. Stop before a divider or keyboard changes the game rectangle. Profiles do not automatically follow those changes.


## Focus for this build

Keep the fullscreen/MultiStar rectangle that worked. Extract mobile.6 into a fresh folder, select its main.lua and calibrate.

1. In the game's Multi screen, select the boost(s) wanted. In the bot, enable Desired Random Boost and leave verification on **Any completed boost (game target)**. Start with **180 seconds maximum wait / 5 seconds initial delay**.
2. Test Double Coins, then a different in-game target. Confirm the bot sends Multi-Buy once and does not tap Play while the rolling-history panel is visible, even when the target banner is already shown.
3. Let a purchase run beyond 30 seconds. It should continue waiting, logging progress every ten seconds, then start after the panel closes and the matching banner/ready controls remain stable for about three seconds.
4. Test specific verification by setting the same name in the game and bot. A different target must not be silently accepted in this mode.
5. If the bot times out despite a visible final boost, share `templates/debug_unrecognized.png`, `.txt`, the selected verification name and wait settings. The report includes last matched banner and completion color counts. Check whether the game is still buying before restarting; stopping the bot does not stop game rerolls.
6. Confirm ordinary one-random-boost mode, owned-only Fast Start/Relay, result clearing and a second round still work. With dimming on, timeout errors should restore brightness.

The banner crop was widened using the supplied screenshot layout. Automated tests simulate a banner extending past the old edge and a rolling panel that stays open for 40 seconds. They do not measure native image-match scores from the user's screenshots. Actual template matching and color checks need phone verification.

Tap and timing variation remains optional. It is not a verified way to prevent CAPTCHA prompts.

## Calibration

1. Extract the new release into a fresh folder and open that folder's `main.lua` in AnkuLua 8.2+.
2. Open the game main menu in landscape. Leave Legacy crop off and Calibration only on.
3. The outer highlight should cover the game including its side artwork. The Main menu: Play marker should stay on Play. No game button should be pressed.
4. Record the printed physical game area, logical canvas, UI offsets, and calibration stage. Expect `MAINMENU` on the normal main menu.
5. Open the item/buff screen manually, then run calibration again. Check its Play and Random boost markers. Expect `PURCHASE_ITEM` if the bundled label is present and recognizable.
6. Match the navigation-bar and cutout settings to the game. For a Samsung split-screen/pop-up window, enter its actual landscape client rectangle as manual X/Y/width/height in physical screenshot pixels. Arbitrary landscape ratios are accepted.

## Two-round check

1. Return to the main menu and uncheck Calibration only.
2. Start with item modes Off and random boosts unchecked to isolate screen transitions. Then test with Simple mode, one random boost, and a 5 / 5 minute interval.
3. Watch main menu Play → item screen Play → run → results → main menu.
4. Confirm one purchase per round and a second round after at least five minutes from the first run Play. Longer runs finish normally.
5. Stop using AnkuLua's Stop control. Recalibrate if the window moves, resizes, rotates, or switches fullscreen mode.

## If it gets lost

After three seconds without a match, the bot widens the search for the expected stages. After ten seconds, it checks all stage types over the entire game area. After twenty seconds, it saves:

- `templates/debug_unrecognized.png`: full logical game-area screenshot, including sides.
- `templates/debug_unrecognized.txt`: dimensions, UI offsets, detection group, last recognized stage, and last action.

These files overwrite previous stall diagnostics. A gameplay screen can legitimately have no menu match; saving does not stop the bot.

Share those two files, a full screenshot after the initial Play tap with overlays dismissed, the exact log/error, phone model, AnkuLua version, and window mode. Explain whether it stopped on the items screen, during a run, or at results. The main-menu calibration image alone is insufficient to diagnose the post-Play screen.

## Validation limits

The supplied six-screen flow was inspected visually. Automated tests use synthetic color/layout fixtures based on those screens; they are not captured-image replays. Tests check that the fallback works without a Friends template match, rejects the purchase/multi-buy layouts and dimmed controls, and rechecks after waiting before a tap. The user reports the previous screen/window fixes working on the phone. The mobile.6 options above still require physical testing.
