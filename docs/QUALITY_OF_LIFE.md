# Timing, item use, taps and brightness

These options appear after screen setup when **Calibration only** is unchecked. Keep your working fullscreen or Samsung MultiStar window settings.

## Portrait-friendly settings

Settings use AnkuLua's native full-screen dialogs, with one control per row and labels above number inputs and dropdowns. Pages are separated into repeat delay, items, random boost, optional chores, boost completion, tap variation/timing, and brightness. Only relevant pages are shown. Scroll vertically if needed with a large Android font or the keyboard open.

**Select game window** and **Reuse saved game window** skip the fullscreen/manual-only settings. Picking a rectangle has separate position and size review pages. The phone can stay portrait while the game runs in a landscape pane; this changes settings layout, not the working game-coordinate mapping.

## Repeat delay after stage ends

The first automation settings page is **Repeat delay after stage ends**. Set the minimum and maximum **wait in minutes after results are detected**. Decimals are accepted; both values must be between 0 and 1440, with maximum at least minimum. Each input has its own row.

| Minimum | Maximum | Behavior after results |
| --- | --- | --- |
| 0 | 0 | Replay as soon as results/rewards are cleared |
| 0.1 | 0.3 | Choose a random 6–18 second delay |
| 1 | 2 | Choose a random 1–2 minute delay |
| 5 | 5 | Wait five minutes (default) |
| 6 | 8 | Choose a random 6–8 minute delay |

**Changed in mobile.7:** the previous timer measured from the start of the run. This timer begins when the bot first detects the Result screen. A long stage no longer uses up the repeat delay. Set these new fields when upgrading; the old start-interval preferences are not reused.

The bot clears Result OK, Mystery Box Open all, and Confirm while the countdown runs. Repeated results/reward detections do not reset it. On the main menu, the bot waits only for the remaining time, then checks the screen again before opening the next lobby. Lobby purchases and normal transition waits can make the next run start later than the deadline. The same deadline applies if the game goes directly to the lobby.

If the first result screen is missed, a recognized reward screen starts the delay. Returning to the main menu after an observed run is a final fallback. Starting the bot on the main menu does not add an initial repeat wait; starting on results does. There is no timer that interrupts or restarts an active stage.

The log shows the configured range and the chosen delay at each stage end. Failed Play retries still do not buy items again for that round.

## Fast Start and Cookie Relay

Choose each item independently:

- **Off:** no purchases and no use taps.
- **Use owned only (never buy):** use the item when its in-run icon is detected. No icon means no tap and no replacement purchase; the bot continues watching for results.
- **Buy one each round + use:** preserve the previous purchase behavior, buying one during each new lobby visit and using the visible in-run icon. This can buy even when inventory remains.

For the requested no-spending setup, select **Use owned only** for both items. Buy a stock of items manually beforehand if desired. Automatic stock counting, buying only at zero, and batch restocking are not implemented. The existing templates do not include the inventory digits required by AnkuLua's `numberOCR`; a missing in-run icon is not used as evidence that a purchase is needed.

Random Boost remains separate: leave both random-boost purchase boxes unchecked to avoid buying it. Existing owned boosts apply through the game's own behavior. Multi-buy rerolls random boosts; it does not stock up Fast Start or Relay.

### Random Boost Multi-Buy completion

The **game** runs the rerolls using the target(s) selected in its Multi screen. The bot clicks Multi-Buy once and then watches the result. It does not buy its way through the bot's dropdown list or configure the game's targets.

- **Any completed boost (game target)** is the default verification choice. The bot searches the 11 bundled boost banner images, accepts a matching banner with ready controls, and waits for the rolling-history panel to disappear. It does not restrict the game to Double Coins.
- Selecting **Double Coins** or another specific name restricts verification to that banner. Select the same target in the game; otherwise the bot will keep waiting and eventually stop, even if a different boost was purchased successfully.
- **Maximum Multi-Buy wait:** default 180 seconds; allowed 10–1800.
- **Initial animation delay:** default 5 seconds; allowed 0–60, leaving at least three seconds before the maximum wait.
- After the initial delay, the bot checks twice per second. It requires the same accepted banner and ready controls for about three continuous seconds. An open rolling panel resets this stability check, even if the target banner is already visible.

The banner search is wider than mobile.5 to include banners extending beyond the old right edge. It remains restricted to the lower-right banner area inside the game pane. Completion also requires a green Play button and absence of the pale rolling-history panel, based on the supplied screenshots. These color checks need testing on other game themes/layouts.

Progress is logged every ten seconds. On timeout, the bot saves `templates/debug_unrecognized.png` and `.txt`, reporting the verification target, last matched banner, and color counts. It stops without retrying Multi-Buy or tapping Play. Stopping the bot does **not** cancel the game's own rerolling; check the game before restarting.

**Buy one random boost each round** is separate from Multi-Buy. It makes one purchase and does not insist on Double Coins or any other specific result.

## Optional tap variation

Enable **Vary tap positions and timing** on the **Tap variation** page, then configure the **Tap timing** page:

- **Radius:** default 3, allowed 0–6 pixels on the logical reference canvas. AnkuLua scales this with the game, including in split screen.
- **Press duration:** default 40–100 milliseconds, allowed 20–200. Set equal values for a fixed duration.
- **Maximum extra pause:** default 0.25 seconds, allowed 0–2. Each tap gets a random delay from zero up to this value, in addition to existing screen-settling waits.

Targets stay close to the configured button center and within the game rectangle. Small image-matched buttons get a smaller radius. Both Play buttons use their own positions. Native matched coordinates are not scaled again. Presses use a single AnkuLua `manualTouch` sequence containing down, wait and up. If the API is unavailable, the script stops with an explanation.

Turning this option off retains normal AnkuLua clicks. Existing short randomized waits between screen transitions remain. Drag gestures keep their existing paths and native timing. Variation changes repeated tap coordinates and timing, but the cause of the game's CAPTCHA prompts has not been verified. It does not guarantee fewer prompts or prevent them. The repeat delay is sampled after results, so a long run no longer removes that pause. Time spent clearing rewards counts toward the delay.

## Screen dimming

On the **Screen brightness** page, enable **Dim entire phone while running**, then choose 1–100 percent (default 5). This uses AnkuLua's 0–255 brightness API. A screen already below the requested level is left at its lower brightness. AnkuLua documents dimming as time-limited in its trial version.

**Dimming affects both Samsung windows**, including chat/manga. Leave it disabled when you want to read the lower app comfortably.

Before dimming, the bot saves the original numeric brightness in `brightness-restore.txt` inside the script folder. It restores that value on a caught error or normal return, and on the next launch of `main.lua` before any dialogs. Only the numeric brightness value is saved; Android adaptive-brightness mode is not recorded.

A forced stop can terminate Lua before cleanup runs; immediate restoration cannot be guaranteed. If the screen remains dim, run **`restore_brightness.lua` from the same extracted folder**, or adjust Android brightness manually. The helper needs no game calibration and makes no game taps. Keep the old folder until you have restored brightness before upgrading. If you deliberately adjust brightness manually and do not want the saved value restored later, delete `brightness-restore.txt` from that folder.

## API references

- [User interface methods: newRow and dialogShowFullScreen](https://ankulua.boards.net/thread/12/user-interface-methods)

- [AnkuLua API quick reference](https://ankulua.boards.net/thread/181/api-quick-reference)
- [Advanced methods: brightness and numberOCR](https://ankulua.boards.net/thread/13/advanced-methods)
- [Basic objects and methods: manualTouch and Match targets](https://ankulua.boards.net/thread/6/objects-methods-introduction-sikuli-compatible)

These features have automated tests with mocked native APIs. Real touch delivery, screen brightness, and manual-stop behavior still need phone testing.
