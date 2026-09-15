# CookieRun Classic Bot — mobile screen fix

An Android [AnkuLua](https://ankulua.boards.net/thread/2/ankulua-introduction) bot based on [AnkuLua's Lua port](https://github.com/AnkuLua/cookierun-classic-bot), originally [max180643's Python bot](https://github.com/max180643/cookierun-classic-bot).

**v1.1.0-mobile.2 is a phone-test build.** It fixes the first build's restricted search area and slow recovery after Play. Automated tests pass; the reported phone's post-Play screen has not yet been verified against this build.

## Updating from mobile.1

Extract the new release into a **fresh folder** and select its `main.lua` in AnkuLua. Do not mix versions or rely on a previous script selection.

- Leave **Legacy: crop to centered 16:9** unchecked. The default search area now includes the game sides.
- Set **Game hides Android navigation bar** to match the game. A temporarily visible system bar over the game does not necessarily mean the game has resized.
- **Exclude camera cutout area** can be unchecked if the game actually draws into that area.
- Run calibration on the main menu, then manually open the item/buff screen and run calibration there too. The log reports whether that screen was recognized.

The first build could tap the main-menu Play button, then search forever in a small misplaced rectangle. Recovery now widens the search after three seconds and checks all stage types after ten seconds. If nothing matches for twenty seconds, it saves diagnostic files automatically. It does not blindly tap an unrecognized screen.

## Download and run

1. Download `cookierun-classic-bot-mobile-v1.1.0-mobile.2.zip` from [Releases](https://github.com/PacbookMro/cookierun-classic-bot-mobile/releases).
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

## If it still stops after Play

The screenshot from the first test shows the main menu during calibration. It does not establish the item-screen layout or whether its bundled **Shapes** label still exists.

If the updated bot remains stuck, share:

- `templates/debug_unrecognized.png` and `templates/debug_unrecognized.txt`, saved after twenty seconds without a menu match. They contain the full search area, window dimensions, last recognized stage, and last tap.
- A full landscape screenshot **after the first Play tap**, with calibration highlights dismissed.
- Phone model, AnkuLua version, fullscreen versus split-screen/pop-up mode, and whether the run actually started.

These diagnostics overwrite fixed filenames, so long runs cannot accumulate unlimited files. No recognized menu during active gameplay is normal: a diagnostic by itself does not mean the run failed, and the bot continues watching for results.

A whole-area search can find a matching label that moved; it cannot identify missing or changed artwork, or infer every independently rearranged button. Those cases need updated templates or a device layout. Report them in an [issue](https://github.com/PacbookMro/cookierun-classic-bot-mobile/issues).

## Development

With Lua 5.1 and Python 3, from the repository root:

```sh
lua tests/run.lua
python3 tools/build_release.py
```

Tests cover common dimensions, window offsets, all coordinate paths, module wiring, a no-tap calibration run, wide-search recovery, diagnostic timing, and a simulated two-round loop. AnkuLua APIs are mocked; actual Android touch delivery and visual recognition still need phone testing. See [phone test instructions](docs/PHONE_TEST.md) and [investigation notes](docs/INVESTIGATION.md).

Release ZIPs contain runtime scripts, bundled templates, and documentation. Git metadata, development tools, and personal diagnostic screenshots are excluded.
