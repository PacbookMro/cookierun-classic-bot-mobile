# Phone test checklist — mobile.2

## Calibration

1. Extract the new release into a fresh folder and open that folder's `main.lua` in AnkuLua 8.2+.
2. Open the game main menu in landscape. Leave Legacy crop off and Calibration only on.
3. The outer highlight should cover the game including its side artwork. The Main menu: Play marker should stay on Play. No game button should be pressed.
4. Record the printed physical game area, logical canvas, UI offsets, and calibration stage. Expect `MAINMENU` on the normal main menu.
5. Open the item/buff screen manually, then run calibration again. Check its Play and Random boost markers. Expect `PURCHASE_ITEM` if the bundled label is present and recognizable.
6. Match the navigation-bar and cutout settings to the game. For a Samsung split-screen/pop-up window, enter its actual landscape client rectangle as manual X/Y/width/height in physical screenshot pixels. Arbitrary landscape ratios are accepted.

## Two-round check

1. Return to the main menu and uncheck Calibration only.
2. Start with buffs unchecked to isolate screen transitions. Then test with Simple mode, one random boost, and a five-minute interval.
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

The first phone report confirms the initial Play tap works but reports a later stall. It includes a 2400×1080 main-menu calibration screenshot. The post-Play screen was not supplied with that report. Automated tests simulate the original and wider layouts; this release still needs testing on the actual phone.
