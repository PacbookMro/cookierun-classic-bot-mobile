# Phone test checklist — mobile.5

## MultiStar window test

Follow [Samsung MultiStar setup](SAMSUNG_MULTI_WINDOW.md). Put CookieRun above another app on a portrait display, select its two corners, and verify the calibration outline covers only the game. Reuse the saved window for an automation run. Test the two distinct Play buttons, buying, and result clearing while the lower app is visible.

Confirm a physical rotation stops automation and that reselecting a moved/resized pane restores alignment. Stop before a divider or keyboard changes the game rectangle. Profiles do not automatically follow those changes.


## Focus for this build

The tester reports the previous screen and MultiStar issues resolved. Keep the working game rectangle. Extract mobile.5 into a new folder (restore any outstanding brightness from an older folder first). Select the new `main.lua` and calibrate before enabling automation.

1. Choose **Use owned only** for Fast Start and Relay. Confirm the lobby makes no purchases, but existing in-run item icons are used. With zero stock, confirm it continues to results without trying to buy.
2. Choose **Buy one each round + use** only for items you want to purchase. Confirm a failed Play attempt does not buy again.
3. Test timer ranges **1 / 2** and **6 / 8**. Check the logged interval once per round. A run exceeding the chosen interval must finish normally.
4. Enable tap variation at the default 3-pixel radius, 40–100 ms press and 0–0.25 second extra pause. Check both Play buttons, boost buying and result clearing in fullscreen and the saved Samsung pane. Disable it if the device's native touch service does not register these presses reliably.
5. Test dimming separately. Confirm the entire phone dims while screenshot recognition still works. Stop the script; if it stays dim, run `restore_brightness.lua` in the same folder and confirm the original brightness returns. Also test restoration by relaunching `main.lua` after a forced stop.
6. Run two complete rounds with your preferred options. Leave dimming off when reading the lower app.

See [the settings guide](QUALITY_OF_LIFE.md) for timer semantics, item modes and brightness recovery. Automatic buy-at-zero and bulk stock purchases are not part of this build.

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

The supplied six-screen flow was inspected visually. Automated tests use synthetic color/layout fixtures based on those screens; they are not captured-image replays. Tests check that the fallback works without a Friends template match, rejects the purchase/multi-buy layouts and dimmed controls, and rechecks after waiting before a tap. The user reports the previous screen/window fixes working on the phone. The mobile.5 options above still require physical testing.
