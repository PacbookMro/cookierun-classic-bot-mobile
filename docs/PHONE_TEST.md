# Phone test checklist

## First run

1. Extract the release ZIP; open `main.lua` in AnkuLua 8.2+.
2. Open the game main menu in landscape. Keep Calibration only enabled.
3. Check the game-area outline and Start marker. No game button should be pressed.
4. Record the printed X/Y/width/height and calibration stage. Expect `MAINMENU` when on the normal main menu.
5. Open the purchase/items screen manually, then run calibration again. Check Play and Random boost markers; expect `PURCHASE_ITEM`.
6. If necessary, correct the navigation-bar setting or specify the actual 16:9 game rectangle in physical screenshot pixels.

## Two-round check

1. Return to the main menu and uncheck Calibration only.
2. Select Simple mode, one random boost, and a five-minute interval.
3. Watch the first round: Start → buy boost → Play → results → main menu.
4. Confirm one purchase per round, correct taps, and a second round after at least five minutes from the first Play. Runs longer than five minutes finish before restarting.
5. Stop with AnkuLua's Stop control.

## Useful reports

- Phone model, Android version, landscape screenshot resolution, and AnkuLua version.
- Whether the game uses black bars, fullscreen controls, a cutout, or a visible navigation bar.
- The printed game rectangle and any manual values.
- Full landscape screenshot plus `templates/debug_screen_<timestamp>.png` from calibration. The latter is a grayscale crop in the bot's reference coordinate space.
- Which marker is off and whether the error is a constant shift, a size difference, or controls moving independently.
- Exact error/log text if the script stops.

No physical devices have been verified for this first mobile release. Automated tests cover geometry for 960×540, 1280×720, 1920×1080, 2560×1440, 2160×1080, 2340×1080, 2400×1080, 3200×1440, and 2048×1536, plus inset examples. These are simulated sizes, not a list of certified phones.
