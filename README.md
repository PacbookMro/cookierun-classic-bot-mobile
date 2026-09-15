# CookieRun Classic Bot — mobile screen fix

An Android [AnkuLua](https://ankulua.boards.net/thread/2/ankulua-introduction) bot based on [AnkuLua's Lua port](https://github.com/AnkuLua/cookierun-classic-bot), originally [max180643's Python bot](https://github.com/max180643/cookierun-classic-bot).

**v1.1.0-mobile.3 is a phone-test build focused on the first main-menu Play tap.** The tester reports that buff buying and clearing results work; this revision changes main-menu recognition and adds clearer diagnostics.

## Updating from mobile.1 / mobile.2

Extract the new release into a **fresh folder** and select its `main.lua`. Keep the screen settings that worked in mobile.2, including Legacy crop off for the wider game area.

1. Run calibration on the first main menu. Expect `MAINMENU` in the log.
2. Run again and **uncheck Calibration only**. The log should say **AUTOMATION**. Calibration deliberately makes no taps.
3. Select your usual buff settings. The first main-menu Play should open the item/buff screen; the existing buying and result-clearing flow then continues.

The bot previously depended entirely on a small screenshot of the **Friends** tab before it would tap the first Play button. This build expands that tab's local search area and adds a fallback using the **green main-menu Play button plus the cyan Pet/Cookie/Treasure bar directly above it**. It samples both controls on one color frame, then rechecks the screen after waiting before tapping. A green Play button on the purchase screen is insufficient to trigger the fallback.

When this fallback succeeds, the log says `MAINMENU recognized by Play button and cyan tabs`, followed by `Main-menu Play verified at logical=(...)` when tapped. Its color/layout thresholds are chosen for the supplied screenshots; actual phone confirmation is still required.

## Download and run

1. Download `cookierun-classic-bot-mobile-v1.1.0-mobile.3.zip` from [Releases](https://github.com/PacbookMro/cookierun-classic-bot-mobile/releases).
2. Extract the entire ZIP into a writable folder on the phone. Keep every `.lua` file and `templates/` together. This is a script bundle, not an APK.
3. Use **AnkuLua 8.2+** with its screen capture and tap service working. No Python, PC emulator, or phone-resolution change is needed.
4. Open CookieRun in a **landscape game window**, on the main menu. Select the extracted `main.lua` in AnkuLua.
5. Keep **Calibration only** checked for the first run. The outer highlight shows the entire search area, including side artwork. Check the **Main menu: Play** marker. The other markers belong to the item/buff screen. Calibration makes no taps and saves `templates/debug_screen_<timestamp>.png`.
6. Run again and uncheck **Calibration only** when alignment is correct. Stop with AnkuLua's Stop control.

The bot preserves the original UI proportions and centers its 1280×720 reference layout within the visible area. On a 2400×1080 game area, it searches a 1600×720 logical canvas and offsets the reference UI horizontally by 160. AnkuLua then maps logical coordinates to physical pixels. It does not stretch images or discard the side content.

For actual 16:9 letterboxed content, the optional Legacy crop reproduces the first build's viewport. For taller landscape tablets, the default keeps the full area and centers the UI vertically.

## Simple buff + repeat

- Leave **Simple buff + repeat** enabled to skip relic collection and friend-life chores.
- Enable **Buy one random boost each round**, or Fast Start / Cookie Relay as required. Purchases use in-game currency; all purchase options start unchecked.
- The default **5 minutes** is the minimum interval between successive round starts. Longer rounds finish before restarting. Set `0` to replay as soon as results are cleared.
- Failed Play transitions can be retried without buying buffs again for that round.

**Desired Random Boost** uses the game's multi-buy workflow. Configure the target in CookieRun's multi-buy screen first, then choose the same target in the bot. The dropdown does not configure the game. The bot stops if the selected boost is not detected within thirty seconds. Choose either one random boost or desired boost.

Turn Simple mode off to enable optional relic collection and friend-life handling. Normal results and connection/inactive dialogs are handled in both modes. The bot uses the in-game reload button; it does not force-stop and relaunch CookieRun.

## Samsung split-screen / pop-up windows

A manually specified game area can cover a landscape window of any aspect ratio; it no longer has to be 16:9. Enter **X, Y, width, height in physical screenshot pixels**, excluding the other app, window borders, and toolbars. The script cannot automatically discover the bounds of an arbitrary Samsung window. The game must be visible and continue rendering; this script cannot resume a game paused by Android or the game itself.

Stop and recalibrate after moving/resizing the window, changing fullscreen mode, rotating, or folding/unfolding the device. Running both apps concurrently does not itself give the bot the correct game-window coordinates.

## If the first Play still is not tapped

First check that the log says **AUTOMATION**, rather than **CALIBRATION ONLY**. After twenty seconds without a recognized menu, share:

- `templates/debug_unrecognized.png`: a color screenshot of the entire search area.
- `templates/debug_unrecognized.txt`: the dimensions, last stage/tap, and main-menu color checks (`green Play n/8, cyan tabs n/8`).
- The log around `MAINMENU` and `Play tapped`, plus a screenshot of the current screen with overlays dismissed.

The distinction matters: no recognized main menu is a detection failure; a logged tap that does not open the items screen needs touch-position/service investigation. If the first Play works, confirm the usual multi-buy and stage-clearing flow still completes.

Diagnostics overwrite fixed filenames so long runs cannot accumulate unlimited files. No recognized menu during active gameplay is normal; diagnostics do not stop the bot. A different theme, large UI rearrangement, or unusual window scaling can still require a device profile. Report results in an [issue](https://github.com/PacbookMro/cookierun-classic-bot-mobile/issues).

## Development

With Lua 5.1 and Python 3, from the repository root:

```sh
lua tests/run.lua
python3 tools/build_release.py
```

Tests cover common dimensions, window offsets, all coordinate paths, module wiring, a no-tap calibration run, wide-search recovery, diagnostic timing, and a simulated two-round loop. AnkuLua APIs are mocked; actual Android touch delivery and visual recognition still need phone testing. See [phone test instructions](docs/PHONE_TEST.md) and [investigation notes](docs/INVESTIGATION.md).

Release ZIPs contain runtime scripts, bundled templates, and documentation. Git metadata, development tools, and personal diagnostic screenshots are excluded.
