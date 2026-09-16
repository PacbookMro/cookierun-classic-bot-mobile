# Changelog

## v1.1.0-mobile.6

- Widen the Random Boost banner search so mobile banners are not clipped at the previous right edge.
- Add configurable Multi-Buy maximum wait (180 seconds by default) and initial animation delay (5 seconds).
- Default to verifying any completed game-selected boost; retain explicit single-target verification. The game performs rerolls and target selection remains in-game.
- Require a stable matching banner, green Play, and a closed rolling-history panel before starting.
- Log progress and save diagnostics on timeout without retrying the purchase.

89 mocked API tests pass. Completion color checks are based on the supplied screenshots; physical phone verification is still required.

## v1.1.0-mobile.5

- Add minimum/maximum round intervals, sampled once per round without moving the deadline on Play retries. Long runs still finish normally.
- Separate Fast Start/Relay use from purchases: Off, use owned only, or buy one each round. Skip missing in-run icons without restocking.
- Add optional bounded tap-position, press-duration, and extra-pause variation across coordinate and matched-button taps.
- Add whole-screen dimming, saved brightness restoration on caught errors/next startup, and a standalone restore helper for forced stops.
- Preserve the user-confirmed working fullscreen and Samsung MultiStar setup.

Stock-aware and batch buying are not included. Native tap timing and dimming require phone testing; immediate brightness restoration after a forced stop is not guaranteed.

## v1.1.0-mobile.4

- Add Select game window: intercepted top-left/bottom-right corner taps and editable rectangle review.
- Save/reuse a window profile tied to physical display dimensions.
- Support a landscape top pane inside a portrait phone, including height-scaled layouts with cropped sides.
- Restrict searches/taps to the pane, skip wholly off-screen regions, and reject changed display dimensions.
- Add a Samsung Good Lock / MultiStar setup guide for game above manga/chat.

Profiles do not track divider movement or keyboard-driven pane resizing. Actual phone testing is still needed.

## v1.1.0-mobile.3

Target the initial main-menu Play, now reported as the remaining failure.

- Expand the local Friends-tab search rectangle.
- Add main-menu detection using both the green Play button and cyan Pet/Cookie/Treasure bar, independent of the Friends template.
- Recheck the controls after waiting and use the verified logical Play target.
- Save color diagnostics with sample counts; explicitly log calibration versus automation mode.
- Preserve the existing buff buying and result-clearing flow.

Automated checks use synthetic controls based on the supplied screenshots. Actual S20 FE verification of this build is pending.

## v1.1.0-mobile.2

Follow-up to the first phone report: initial Play works, then detection stalls.

- Search the full game area by default, including side artwork, while preserving centered UI coordinates and image proportions.
- Accept wide manual game-window rectangles for split-screen/pop-up calibration, with a configurable cutout setting.
- Widen detection after three seconds; scan all stage types after ten. Recovery now widens actual regions as well as the stage list.
- Save a bounded screenshot/report after twenty seconds without a menu match, including dimensions, last stage, and last tap.
- Keep optional legacy 16:9 cropping for actual letterboxed content.

The supplied screenshot shows only the main menu; the post-Play layout remains unverified on the phone. Missing/changed labels or independently rearranged buttons may still need a profile.

## v1.1.0-mobile.1

First phone-test release of the Lua port's mobile screen fix.

- Scale the original 16:9 game layout within phone/tablet game areas, with cutout support and optional manual calibration.
- Add a no-tap calibration preview and saved normalized diagnostic screenshot.
- Add simple buff + repeat with a configurable minimum interval (five minutes by default).
- Repair configuration exports, template-list arguments, detection exports/exclusions, repeated purchasing, and off-screen scrolling.
- Preserve native sleep/type, remove screen overlays during detection, and share snapshots within stage scans.
- Replace the empty app-restart path with in-game reconnect handling; bound helper loops.

Automated Lua tests pass. Physical phone testing is pending; wide layouts that rearrange controls need a separate profile.
