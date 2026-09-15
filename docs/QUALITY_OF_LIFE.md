# Timing, item use, taps and brightness

These options appear after screen setup when **Calibration only** is unchecked. Keep your working fullscreen or Samsung MultiStar window settings.

## Round timer

Set the minimum and maximum **minutes between round starts**. Decimals are accepted; both values must be between 0 and 1440, with maximum at least minimum.

| Minimum | Maximum | Behavior |
| --- | --- | --- |
| 0 | 0 | Replay once results are cleared |
| 1 | 2 | Choose a new 60–120 second minimum interval each round |
| 5 | 5 | Fixed five-minute minimum, the previous default |
| 6 | 8 | Choose a new 6–8 minute minimum interval each round |

The timer starts at the run's Play attempt. A failed Play retry does not restart it or trigger another purchase. The bot waits on the main menu if time remains, then checks the screen again before clicking. Menu transitions and purchases can make the actual interval longer. A six-minute run is never cut short by a two-minute setting; it finishes and clears results normally. This is not a delay added after every run.

## Fast Start and Cookie Relay

Choose each item independently:

- **Off:** no purchases and no use taps.
- **Use owned only (never buy):** use the item when its in-run icon is detected. No icon means no tap and no replacement purchase; the bot continues watching for results.
- **Buy one each round + use:** preserve the previous purchase behavior, buying one during each new lobby visit and using the visible in-run icon. This can buy even when inventory remains.

For the requested no-spending setup, select **Use owned only** for both items. Buy a stock of items manually beforehand if desired. Automatic stock counting, buying only at zero, and batch restocking are not implemented. The existing templates do not include the inventory digits required by AnkuLua's `numberOCR`; a missing in-run icon is not used as evidence that a purchase is needed.

Random Boost remains separate: leave both random-boost purchase boxes unchecked to avoid buying it. Existing owned boosts apply through the game's own behavior. The desired-boost multi-buy flow is unchanged: configure the game's target first, then select the same target in the bot. This multi-buy rerolls random boosts; it does not stock up Fast Start or Relay.

## Optional tap variation

Enable **Vary tap positions, duration and extra pause** in the second options dialog:

- **Radius:** default 3, allowed 0–6 pixels on the logical reference canvas. AnkuLua scales this with the game, including in split screen.
- **Press duration:** default 40–100 milliseconds, allowed 20–200. Set equal values for a fixed duration.
- **Maximum extra pause:** default 0.25 seconds, allowed 0–2. Each tap gets a random delay from zero up to this value, in addition to existing screen-settling waits.

Targets stay close to the configured button center and within the game rectangle. Small image-matched buttons get a smaller radius. Both Play buttons use their own positions. Native matched coordinates are not scaled again. Presses use a single AnkuLua `manualTouch` sequence containing down, wait and up. If the API is unavailable, the script stops with an explanation.

Turning this option off retains normal AnkuLua clicks. Existing short randomized waits between screen transitions remain. Drag gestures keep their existing paths and native timing. Variation does not guarantee that a game will treat automation as human input.

## Screen dimming

Enable **Dim the entire phone screen while running**, then choose 1–100 percent (default 5). This uses AnkuLua's 0–255 brightness API. A screen already below the requested level is left at its lower brightness. AnkuLua documents dimming as time-limited in its trial version.

**Dimming affects both Samsung windows**, including chat/manga. Leave it disabled when you want to read the lower app comfortably.

Before dimming, the bot saves the original numeric brightness in `brightness-restore.txt` inside the script folder. It restores that value on a caught error or normal return, and on the next launch of `main.lua` before any dialogs. Only the numeric brightness value is saved; Android adaptive-brightness mode is not recorded.

A forced stop can terminate Lua before cleanup runs; immediate restoration cannot be guaranteed. If the screen remains dim, run **`restore_brightness.lua` from the same extracted folder**, or adjust Android brightness manually. The helper needs no game calibration and makes no game taps. Keep the old folder until you have restored brightness before upgrading. If you deliberately adjust brightness manually and do not want the saved value restored later, delete `brightness-restore.txt` from that folder.

## API references

- [AnkuLua API quick reference](https://ankulua.boards.net/thread/181/api-quick-reference)
- [Advanced methods: brightness and numberOCR](https://ankulua.boards.net/thread/13/advanced-methods)
- [Basic objects and methods: manualTouch and Match targets](https://ankulua.boards.net/thread/6/objects-methods-introduction-sikuli-compatible)

These features have automated tests with mocked native APIs. Real touch delivery, screen brightness, and manual-stop behavior still need phone testing.
