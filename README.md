# CookieRun Classic Bot — mobile screen fix

An Android [AnkuLua](https://ankulua.boards.net/thread/2/ankulua-introduction) bot with automatic scaling for the original 1280×720 game layout. Based on [AnkuLua's Lua port](https://github.com/AnkuLua/cookierun-classic-bot), originally [max180643's Python bot](https://github.com/max180643/cookierun-classic-bot).

**Phone-test release:** automated Lua tests pass; physical phone testing is still needed. Scaling supports the original **16:9 game content**, including content centered inside wider screens or tablets. If the game rearranges its buttons to fill a wider display, it needs a matching device layout/profile; cropping alone cannot fix that.

## Download and run

1. Download `cookierun-classic-bot-mobile-v1.1.0-mobile.1.zip` from [Releases](https://github.com/PacbookMro/cookierun-classic-bot-mobile/releases).
2. Extract the entire ZIP into a writable folder on the phone. Keep every `.lua` file and the `templates/` folder together. Run the extracted script, not the ZIP.
3. Use **AnkuLua 8.2 or newer**, with its screen capture and tap service working. This download is a script bundle, not an APK; it does not require Python, a PC emulator, or changing the phone resolution.
4. Open CookieRun in **landscape**, on the main menu. In AnkuLua, select `main.lua`.
5. Leave **Calibration only** checked for the first run. The highlighted outer border should follow the game content; the **Start** marker should sit on the Start button. Play and Random boost markers belong to the items screen. Calibration makes no taps and saves `templates/debug_screen_<timestamp>.png`.
6. Run again and uncheck **Calibration only** when alignment is correct. Keep landscape orientation and navigation-bar settings unchanged during a run. Restart the script after rotation, folding/unfolding, or changing the app's display mode.

Use AnkuLua's Stop control to stop the bot.

## Simple buff + repeat

For the small loop described by the phone tester:

- Leave **Simple buff + repeat** enabled. This skips relic collection and friend-life chores.
- Enable **Buy one random boost each round**, or choose Fast Start / Cookie Relay if that is the buff you want. Purchases use in-game currency; all purchase options start unchecked.
- Keep the interval at **5 minutes**, or change it. This is the minimum time between pressing Play for successive rounds. The bot clears results and restarts after the round finishes; it does not quit a live run at five minutes. Set `0` to replay as soon as results are cleared.
- A failed Play transition can be retried without purchasing the buffs again for that round.

**Desired Random Boost** retains the port's in-game multi-buy workflow. Configure the target in CookieRun's multi-buy screen first, then choose the same target in the bot. The bot verifies the result; the dropdown does not configure the game's target. It stops if the target is not detected within 30 seconds. Choose either one random boost or desired boost.

Turn Simple mode off to enable optional relic collection and friend-life handling. Normal result screens and connection/inactive dialogs are handled in both modes. The old empty app-restart placeholder has been removed; this port does not force-stop and relaunch CookieRun.

## If the positions are still wrong

- **Game hides Android navigation bar** must match the game. Uncheck it if Android's navigation bar stays visible. AnkuLua's automatic game-area detection handles supported cutouts/insets.
- The default crop is the largest centered 16:9 rectangle inside AnkuLua's usable game area. It is a geometry-based assumption, not visual black-bar detection.
- For asymmetric black bars, enable **Use manual game area** and enter the game's rectangle as **physical landscape screenshot pixels**: X, Y, width, height. X/Y are the top-left corner relative to the full screenshot. Width/height describe the content, excluding black bars. Use a 16:9 rectangle inside the usable area.
- Example: a 2400×1080 screenshot with 240 pixels of black bar on each side uses `X=240, Y=0, width=1920, height=1080` (also the automatic default).
- If the content or controls stretch/rearrange across the whole wide screen, use a 16:9 app display mode if your phone provides one. Otherwise report it for a device-specific profile. Do not enter a stretched rectangle and expect image matching to work.
- If highlights align but the calibration says `not detected`, the game language, artwork, or template capture may differ. Share the saved normalized diagnostic, a full landscape screenshot, phone model/resolution, AnkuLua version, and which screen was open in an [issue](https://github.com/PacbookMro/cookierun-classic-bot-mobile/issues).

All bot coordinates and supplied PNG templates stay in **1280×720 reference space**. Do not replace the reference dimensions with the phone's resolution or manually multiply coordinates: AnkuLua scales screenshots, regions, and taps together after the game area is set.

## Development and verification

From the repository root, with Lua 5.1 and Python 3 installed:

```sh
lua tests/run.lua
python3 tools/build_release.py
```

The test suite checks common screen sizes, cutouts, manual calibration, template bounds, module wiring, purchase actions, stage detection, a no-tap calibration run, and a simulated two-round loop. It mocks AnkuLua and does not prove real Android touch delivery or visual recognition. See [phone test instructions](docs/PHONE_TEST.md) and [investigation notes](docs/INVESTIGATION.md).

Release archives contain only the runtime scripts, bundled templates, and user documentation. Development tools, Git metadata, test screenshots, and downloaded references are excluded.
