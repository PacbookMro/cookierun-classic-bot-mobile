# CookieRun on top, manga/chat below — Samsung MultiStar

Available in **v1.1.0-mobile.4**. The phone stays portrait; CookieRun occupies a landscape pane at the top. AnkuLua runs the script through its floating control. You do not need to put AnkuLua itself in one of the two panes.

## 1. Arrange the apps with Samsung

1. Keep the existing **Good Lock → MultiStar** configuration that lets both apps remain active on your phone. MultiStar settings depend on its version and One UI; the bot does not change them.
2. Open CookieRun, then open **Recents**. Tap CookieRun's app icon and choose **Open in split screen view**.
3. Put CookieRun in the **top** pane and your manga reader/chat app in the **bottom** pane.
4. Adjust the divider so the game is a short, wide rectangle and all needed controls remain visible. Check that the game keeps animating when you interact with the lower app.

Samsung documents the Recents menu, window resizing, and saving app pairs in its [Multi window guide](https://www.samsung.com/us/support/answer/ANS10002022/). It describes MultiStar's additional multi-window controls in its [Good Lock article](https://news.samsung.com/global/4-features-of-the-user-beloved-app-good-lock-2021-to-enhance-your-galaxy-tab-s7-and-s7plus-experiences). Available options differ by model/software; keep the working MultiStar setup from your device.

If opening chat pauses the game, resolve that in Samsung/MultiStar first. The Lua script cannot force another app to continue rendering.

## 2. Select the game pane once

1. Extract the release ZIP into a writable folder and select its `main.lua` in AnkuLua.
2. With the split-screen arrangement already visible, start the script using AnkuLua's floating control.
3. In **Where is CookieRun running?**, choose **Select game window**. Leave **Calibration only** checked initially.
4. Close the first instruction and tap just inside the **top-left corner of the game content**.
5. Close the next instruction and tap just inside the **bottom-right corner of the game content**, above the divider. Exclude Samsung title bars, divider handles, and the lower app.
6. Review the selected X/Y/width/height. You can adjust the numbers if the corner taps missed by a few pixels.
7. Check the calibration outline and Play markers. The outer outline should follow only CookieRun, not chat or the whole phone.

The two corner taps are intercepted by AnkuLua's `getTouchEvent()` and are not forwarded as game/chat clicks. The profile is saved as `window-profile.txt` beside the scripts. It records the physical display size and selected rectangle, not chat content.

Fullscreen/manual immersive, cutout, and Legacy crop settings are ignored in selected-window mode. The selected content rectangle is authoritative.

## 3. Run using the saved pane

Run `main.lua` again, choose **Reuse saved game window**, and **uncheck Calibration only**. Select your usual buff/repeat options. Read manga or use chat below while the bot operates in the visible game pane.

The bot still uses different Play actions: the episode menu opens the buff lobby, and the lobby starts the run. Searches, card crops, diagnostic images, reference-coordinate taps, and scrolls are bounded to the selected pane. Native image matches come from that pane as well.

## Scaling and limits

- Window mode scales the game by **height**, preserving UI proportions. If the pane is narrower than 16:9, the reference UI can extend past the left/right edges, matching the supplied narrow-pane example. Off-screen searches are skipped and off-screen taps stop with an explanation.
- If buttons are clipped, reduce the top pane's height or make it wider. Around 16:9 is the easiest shape for keeping every original control visible.
- **Stop before moving/resizing the pane. Select it again afterward.** A saved rectangle does not follow the split-screen divider or a moving pop-up automatically.
- Opening the keyboard may resize the game pane. If it does, stop and recalibrate; a fixed keyboard/pane arrangement is necessary while automating.
- A physical display-size/orientation change is detected and stops further mapped taps/searches. Divider movement without a display-size change cannot be detected by this profile.
- The game must stay visible and rendering. Small-window scaling can affect image recognition; this is a phone-test release, not a claim of verified S20 FE support.

A screenshot like the supplied example demonstrates the desired arrangement; it is not used as a hard-coded device preset. Select the actual game pane on your phone.

## Troubleshooting

If the outline includes chat or skips part of CookieRun, choose **Select game window** again. If the outline is correct but a stage is not recognized, share `templates/debug_unrecognized.png` and `.txt`. The PNG is cropped to the configured game pane; avoid capturing it with a wrong selection or an unrelated overlay covering the game.

After extracting a new release into a fresh folder, select the game pane again. Saved profiles are deliberately not included in downloadable releases.

## Portrait settings in mobile.7

You can keep the phone portrait throughout setup. Select/reuse-window modes now skip fullscreen-only options. The bot uses native full-screen settings pages with one control per row; window coordinates have separate position and size review pages. This affects dialogs only, so reuse the game rectangle that already works.

The dedicated **Repeat delay after stage ends** page takes minimum/maximum minutes after results. Use `0.1 / 0.3` for 6–18 seconds, or `0 / 0` to repeat immediately after result/reward clearing. The default `5 / 5` now means five minutes after results.
