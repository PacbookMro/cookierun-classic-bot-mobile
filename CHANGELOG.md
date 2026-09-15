# Changelog

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
