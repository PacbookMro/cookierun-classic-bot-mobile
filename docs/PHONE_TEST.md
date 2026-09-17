# Phone test checklist — mobile.7

## MultiStar window test

Follow [Samsung MultiStar setup](SAMSUNG_MULTI_WINDOW.md). Put CookieRun above another app on a portrait display, select its two corners, and verify the calibration outline covers only the game. Reuse the saved window for an automation run. Test the two distinct Play buttons, buying, and result clearing while the lower app is visible.

Confirm a physical rotation stops automation and that reselecting a moved/resized pane restores alignment. Stop before a divider or keyboard changes the game rectangle. Profiles do not automatically follow those changes.


## Focus for this build

Keep the working fullscreen/MultiStar game rectangle. Extract mobile.7 into a fresh folder and select its main.lua. Restore any outstanding brightness from the older folder first.

1. Keep the phone portrait with CookieRun in the top landscape pane. Test **Select game window** and **Reuse saved game window**. Their startup page should show the mode dropdown and calibration checkbox, without fullscreen/manual settings. Window review has separate position and size pages.
2. Disable calibration for automation. The first bot options page should be **Repeat delay after stage ends**, with clearly visible **Minimum wait (minutes)** and **Maximum wait (minutes)** inputs below their labels. Enter **0.1 / 0.3** for a short test. Check the printed range is 0.10–0.30 minutes.
3. Verify item/boost dropdowns and the radius, minimum/maximum press duration, extra-pause and brightness fields are accessible. Each control should have its own row. Check in landscape too; scroll vertically if needed.
4. Finish a run. The timer should start at the first Result screen. The bot should clear Result OK, Mystery Box Open all and Confirm without waiting for the countdown. On the main menu, it should wait only for any remaining part of the chosen 6–18 second delay.
5. Confirm that a slow/failed Result OK or repeated reward screen does not restart the timer. A run longer than the configured delay must still receive a fresh delay after results. The first run from the main menu should start without an initial repeat delay.
6. Set **0 / 0** to verify immediate repeat after normal result-clearing/transition waits. Set **1 / 2** to verify a longer randomized wait after results.
7. Confirm the existing Multi-Buy completion, owned-only items, result clearing and dimming still work. For Multi-Buy, choose **Use game Multi-Buy each round**, configure target(s) in the game and use **Any completed boost (game target)** unless verifying a specific target.

The old minimum-start-interval fields have been replaced with new after-results fields. Their default is **5 / 5 minutes**, now measured from results, so select the intended delay explicitly.

Automated tests check dialog rows and API selection, not Android-rendered pixels. Share a screenshot of any field still clipped, including orientation, font/display size and AnkuLua version.

## Calibration

1. Extract the new release into a fresh folder and open that folder's `main.lua` in AnkuLua 8.2+.
2. Open the game main menu in landscape. Leave Legacy crop off and Calibration only on.
3. The outer highlight should cover the game including its side artwork. The Main menu: Play marker should stay on Play. No game button should be pressed.
4. Record the printed physical game area, logical canvas, UI offsets, and calibration stage. Expect `MAINMENU` on the normal main menu.
5. Open the item/buff screen manually, then run calibration again. Check its Play and Random boost markers. Expect `PURCHASE_ITEM` if the bundled label is present and recognizable.
6. Match the navigation-bar and cutout settings to the game. For a Samsung split-screen/pop-up window, enter its actual landscape client rectangle as manual X/Y/width/height in physical screenshot pixels. Arbitrary landscape ratios are accepted.

## Two-round check

1. Return to the main menu and uncheck Calibration only.
2. Start with item modes Off and random boosts unchecked to isolate screen transitions. Then test with Simple mode, one random boost, and a 5 / 5 minute repeat delay.
3. Watch main menu Play → item screen Play → run → results → main menu.
4. Confirm one purchase per round and a second round after at least five minutes from the first detected Result screen. Longer runs also receive this delay after finishing.
5. Stop using AnkuLua's Stop control. Recalibrate if the window moves, resizes, rotates, or switches fullscreen mode.

## If it gets lost

After three seconds without a match, the bot widens the search for the expected stages. After ten seconds, it checks all stage types over the entire game area. After twenty seconds, it saves:

- `templates/debug_unrecognized.png`: full logical game-area screenshot, including sides.
- `templates/debug_unrecognized.txt`: dimensions, UI offsets, detection group, last recognized stage, and last action.

These files overwrite previous stall diagnostics. A gameplay screen can legitimately have no menu match; saving does not stop the bot.

Share those two files, a full screenshot after the initial Play tap with overlays dismissed, the exact log/error, phone model, AnkuLua version, and window mode. Explain whether it stopped on the items screen, during a run, or at results. The main-menu calibration image alone is insufficient to diagnose the post-Play screen.

## Validation limits

The supplied six-screen flow was inspected visually. Automated tests use synthetic color/layout fixtures based on those screens; they are not captured-image replays. Tests check that the fallback works without a Friends template match, rejects the purchase/multi-buy layouts and dimmed controls, and rechecks after waiting before a tap. The user reports the previous screen/window fixes working on the phone. The mobile.7 options above still require physical testing.
