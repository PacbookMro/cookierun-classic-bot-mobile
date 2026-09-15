# Investigation

Baseline: AnkuLua/cookierun-classic-bot commit `63186fa`.

## Coordinate problem

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
