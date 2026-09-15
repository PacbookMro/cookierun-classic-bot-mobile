# Investigation

Baseline: AnkuLua/cookierun-classic-bot commit `63186fa`.

## mobile.4: Samsung MultiStar game pane

The supplied example shows a portrait display with a landscape game pane above chat. Its game pane appears to use height-based UI scaling, cropping the sides when narrower than 16:9. The previous fullscreen fit-and-center geometry cannot represent that behavior reliably.

The new Select game window mode temporarily maps the full physical display 1:1, then uses AnkuLua's intercepted getTouchEvent() clicks for the two corners. After an editable review, it saves a numeric profile without executing Lua from that file. Reuse validates display dimensions and rectangle bounds. It sets the selected rectangle as the game area and normalizes height to 720, allowing a negative horizontal UI offset in narrow panes. Fullscreen mapping is unchanged.

Region intersections can now be empty: local detection skips those areas instead of accidentally searching elsewhere. Taps outside the selected logical canvas are rejected. Mapped calls and native main-menu/friend Match clicks check physical display dimensions before acting. This does not discover arbitrary Android app bounds or track divider/keyboard changes; reselection is required when the pane moves or resizes.

Tests cover portrait top panes, offset pop-ups, the narrow screenshot-like aspect ratio, physical tap containment, exclusion of matching text in the bottom app, intercepted selection, profile validation, and display rotation. Real MultiStar/AnkuLua integration and simultaneous rendering still require phone verification.

## mobile.3 follow-up: initial main-menu Play

The latest report clarifies that buying and result clearing work, but the first main-menu Play is not clicked. Six screenshots show the intended flow. They narrow the issue to the MAINMENU step, although no runtime log was supplied to prove whether recognition or the touch action fails.

MAINMENU recognition depended on one small `Friends` tab template. The tap branch and its post-wait recheck both required that recognition. This revision increases the local Friends search rectangle and adds a fallback independent of the tab's text rendering: at least six of eight green Play-body samples and six of eight cyan menu-bar samples must match on the same color frame. The menu bar sits directly above main-menu Play and is absent from the supplied purchase/multi-buy screens. Sampling avoids the controls' white text. This is a targeted layout/color heuristic, not general OCR or a new template made from the user's screenshot.

The fallback runs only when MAINMENU is allowed in the stage list, honors exclusions, and comes after regular stage matches. The bot rechecks after its wait, then uses the freshly verified logical target without applying the screen offset again. The purchasing and result-clearing algorithms are unchanged. Diagnostics now save color images and report sample counts, and startup explicitly logs CALIBRATION ONLY or AUTOMATION.

Color sampling follows AnkuLua's [advanced methods](https://ankulua.boards.net/thread/13/advanced-methods#getColor) and [snapshotColor documentation](https://ankulua.boards.net/thread/7/settings#snapshotColor). Ordinary snapshot() frames are grayscale; snapshotColor() plus usePreviousSnap(true) ensures all RGB samples come from one frame. Snapshot reuse is cleared on both success and bridge error.

Tests exercise template-free initial entry, rejection of the other supplied layouts using synthetic fixtures, dimmed controls, partial sample occlusion, snapshot cleanup, group/exclusion behavior, and a screen change during the wait. The tests do not establish actual match scores or color values from the attached image files, which are not available as local capture fixtures. Phone verification of this build remains pending.

## mobile.2 follow-up: first phone feedback

The tester supplied a 2400×1080 main-menu screenshot with calibration active and reported a successful initial Play tap followed by a stall. The picture shows artwork beyond the cropped area. It does not show the subsequent item/buff screen, so a resolution-only diagnosis is not established.

Two concrete code defects could prevent recovery: the first release restricted all searches to a centered 16:9 crop, and its recovery scan changed the stage list while retaining exactly the same small search rectangles. PRE_GAME recovery waited sixty seconds and IN_GAME recovery waited five minutes. The purchase-screen template is a small English `Shapes` label, so a moved or missing label can explain a stall even with buying disabled.

The new default retains AnkuLua's full game area. Images and coordinates scale uniformly by height on wide phones and by width on taller landscape windows. The old 1280×720 reference UI is centered in the expanded logical canvas. This preserves the initial Play position while making side content searchable. `screen.location`, `screen.region`, card crops, and drag endpoints all share that translation; native Match clicks remain unchanged. Manual window rectangles accept any landscape aspect ratio. An explicit legacy crop is available for real letterboxing.

Recovery searches the whole area for the current group every three seconds, then all stage types every ten seconds. Wide searches use a stricter similarity threshold. A twenty-second absence of recognized menus saves bounded diagnostics, including the last stage/action and window mapping. Failed scans do not reset the last-recognized time. Gameplay may legitimately have no menu matches; the bot does not treat that alone as a failure or issue blind taps.

Samsung multi-window does not imply automatic knowledge of app bounds. Android supports [multi-resume](https://developer.android.com/develop/ui/views/layout/support-multi-window-mode#multi-resume), with behavior depending on platform/app/window state. This script accepts a manually measured visible game window; it cannot control the other app's lifecycle or automatically track window resizing.

Regression tests exercise a purchase marker outside the old crop, unchanged physical Play placement, wide/manual/tablet mapping, recovery clocks, exclusions, and bounded diagnostics. No post-Play screenshot or live device was available for this revision. Missing artwork or independent button reflow may still require a specific profile.

## mobile.1 investigation (historical)

### Coordinate problem


The original Python bot explicitly requires 1280×720, captures raw ADB screenshots, searches fixed rectangles, and taps fixed coordinates. The Lua port keeps those coordinates and uses `setScriptDimension(false, 720)` / `setCompareDimension(false, 720)`. Those settings already support uniform height-based resizing on matching layouts. The missing part is defining the real game area before scaling: wider screens, cutouts, and black bars can shift the game's origin or change its usable dimensions.

The fix sets immersive behavior, enables AnkuLua's cutout handling, obtains the physical `getGameArea()` Region, and chooses a centered 16:9 viewport or a validated manual rectangle. It passes that Region to `setGameArea`, then sets both reference dimensions to width 1280. AnkuLua performs the crop and uniform scaling. Hard-coded action points, search Regions, card crops, and image Matches therefore share the same coordinate system. Native Match objects are clicked directly.

This follows the [official settings documentation](https://ankulua.boards.net/thread/7/settings) and the initialization order in [AnkuLua's recorder](https://github.com/AnkuLua/snapAndPlay/blob/main/src/snapAndPlay.lua). The API is `setGameArea(Region(...))`, and `getGameArea()` returns a Region. Some third-party summaries incorrectly describe a four-number setter/return value.

Automatic cutout handling does not visually detect the game's black bars. Centering is a default assumption with manual correction. Independently rearranged controls require new layout calibration/templates. This release does not claim to solve arbitrary UI reflow.

## Other conversion defects repaired

- `config.lua` returned an empty table even though callers used `config.FAST_START_ITEM` and other fields. Configuration now lives in and is exported from the module table.
- `detect_templates` was defined but missing from the detection module exports.
- Callers wrapped template lists inside a second list, passing tables to `Pattern` instead of filenames.
- Recovery scans ignored map-style relic exclusions because they iterated them with `ipairs`.
- The bot started as a side effect of `require`, with an additional startup path in `main.lua`.
- Global `type`, `print` helpers, and `sleep` were overwritten inconsistently. Sleep was replaced with an overlay duration, and normal logging painted on the screen used for recognition. The fix keeps native sleep and the text-entry `type` binding, uses a local `typeOf` alias for introspection, and logs without overlays.
- Friend scrolling could end at reference Y=920, outside the 720-high screen. Both drag endpoints now stay inside the leaderboard.
- The too-many-treasures search region was smaller than its supplied PNG, making matching impossible.
- Repeated purchase-screen detections could rebuy buffs. Round state now permits one purchase sequence per round and retries Play without repurchasing.
- App restart was an empty function. The placeholder/session-reset path is removed; the connection-lost dialog uses its reload button.
- Diagnostic saving used an unsupported global fallback and a module name colliding with Lua's `debug` library. Diagnostics now use the documented Region save API and save under the script's templates directory.
- Long friend/boost/card loops now have explicit failure bounds. Party/settings detection now has corresponding close actions in the main loop.

## Validation limits

The Lua 5.1 suite verifies geometry, documented API call order, module loading, assets, action points, exclusions, snapshot reuse, timeouts, and the simple repeat loop using mock APIs. Syntax checks run over every runtime and test file. No Android device or real game screenshots were available, so real rendering, touch injection, and recognition remain phone-test work.
