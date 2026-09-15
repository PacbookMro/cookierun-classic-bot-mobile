# Changelog

## v1.1.0-mobile.1

First phone-test release of the Lua port's mobile screen fix.

- Scale the original 16:9 game layout within phone/tablet game areas, with cutout support and optional manual calibration.
- Add a no-tap calibration preview and saved normalized diagnostic screenshot.
- Add simple buff + repeat with a configurable minimum interval (five minutes by default).
- Repair configuration exports, template-list arguments, detection exports/exclusions, repeated purchasing, and off-screen scrolling.
- Preserve native sleep/type, remove screen overlays during detection, and share snapshots within stage scans.
- Replace the empty app-restart path with in-game reconnect handling; bound helper loops.

Automated Lua tests pass. Physical phone testing is pending; wide layouts that rearrange controls need a separate profile.
