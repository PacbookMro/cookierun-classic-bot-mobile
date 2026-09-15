# CookieRun Classic Bot — mobile screen fix

An Android [AnkuLua](https://ankulua.boards.net/thread/2/ankulua-introduction) bot based on [AnkuLua's Lua port](https://github.com/AnkuLua/cookierun-classic-bot), originally [max180643's Python bot](https://github.com/max180643/cookierun-classic-bot).

**v1.1.0-mobile.5 adds configurable timer ranges, use-owned-only Fast Start/Relay, optional tap variation, and screen dimming.** The Samsung MultiStar setup and the two Play positions retain the working mobile.4 behavior. See the [settings guide](docs/QUALITY_OF_LIFE.md).

## Samsung MultiStar: game on top, chat/manga below

1. Use Samsung's split-screen controls with your existing **Good Lock → MultiStar** settings to keep both apps running. CookieRun belongs in the top pane; AnkuLua controls the bot through its floating button.
2. In the bot's startup dialog, choose **Select game window** and leave **Calibration only** checked.
3. Tap the top-left and bottom-right corners of **the game content only**, then review the rectangle. Exclude the divider and lower app.
4. Check the calibration outline. Run again with **Reuse saved game window** and **Calibration only unchecked**.

The phone can stay portrait. A short landscape game pane is required. Stop and reselect after changing the divider, moving a pop-up, or a keyboard resize. See the [complete MultiStar guide](docs/SAMSUNG_MULTI_WINDOW.md), including Samsung setup links and limitations.

For fullscreen use, choose **Full screen / manual** and keep the screen/buff settings that worked in mobile.3. The first-menu Play fallback, buff buying, and result-clearing flow are retained.

## Download and run

1. Download `cookierun-classic-bot-mobile-v1.1.0-mobile.5.zip` from [Releases](https://github.com/PacbookMro/cookierun-classic-bot-mobile/releases).
2. Extract the entire ZIP into a writable folder on the phone. Keep every `.lua` file and `templates/` together. This is a script bundle, not an APK.
3. Use **AnkuLua 8.2+** with its screen capture and tap service working. No Python, PC emulator, or phone-resolution change is needed.
4. Open CookieRun in a **landscape game window**, on the main menu. Select the extracted `main.lua` in AnkuLua.
5. Keep **Calibration only** checked for the first run. The outer highlight shows the entire search area, including side artwork. Check the **Main menu: Play** marker. The other markers belong to the item/buff screen. Calibration makes no taps and saves `templates/debug_screen_<timestamp>.png`.
6. Run again and uncheck **Calibration only** when alignment is correct. Stop with AnkuLua's Stop control.

The bot preserves the original UI proportions and centers its 1280×720 reference layout within the visible area. On a 2400×1080 game area, it searches a 1600×720 logical canvas and offsets the reference UI horizontally by 160. AnkuLua then maps logical coordinates to physical pixels. It does not stretch images or discard the side content.

For actual 16:9 letterboxed content, the optional Legacy crop reproduces the first build's viewport. For taller landscape tablets, the default keeps the full area and centers the UI vertically.

## Simple buff + repeat

- Leave **Simple buff + repeat** enabled to skip relic collection and friend-life chores.
- Choose Fast Start and Cookie Relay independently: **Off**, **Use owned only (never buy)**, or **Buy one each round + use**. Owned-only skips absent icons without buying replacements. Automatic buy-at-zero and batch restocking are not implemented.
- Enable **Buy one random boost each round** only if wanted. Purchases use in-game currency; all purchasing is disabled by default.
- Set minimum/maximum minutes between round starts, e.g. **1 / 2** or **6 / 8**. The default **5 / 5** preserves the fixed five-minute minimum. Longer rounds finish normally. Set **0 / 0** to replay as soon as results are cleared.
- The second options dialog adds optional tap-position/press-duration variation and screen dimming. Dimming affects the **whole phone**, including the lower app. After a forced stop, use `restore_brightness.lua` from the same folder if still dim. Full details and limits are in the [settings guide](docs/QUALITY_OF_LIFE.md).
- Failed Play transitions can be retried without buying buffs again for that round.

**Desired Random Boost** uses the game's multi-buy workflow. Configure the target in CookieRun's multi-buy screen first, then choose the same target in the bot. The dropdown does not configure the game. The bot stops if the selected boost is not detected within thirty seconds. Choose either one random boost or desired boost.

Turn Simple mode off to enable optional relic collection and friend-life handling. Normal results and connection/inactive dialogs are handled in both modes. The bot uses the in-game reload button; it does not force-stop and relaunch CookieRun.

## Window profiles

**Select game window** measures two corners in physical screenshot pixels and saves `window-profile.txt` in the script folder. **Reuse saved game window** reloads it after checking the display size/orientation. Both modes use height-based game scaling; fullscreen uses the existing fit-and-center mapping.

The saved rectangle remains fixed. Stop before moving/resizing it or opening a keyboard that changes the game pane. Physical display rotation/size changes are detected; divider movement alone is not. For complete instructions, see [Samsung MultiStar setup](docs/SAMSUNG_MULTI_WINDOW.md).

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
