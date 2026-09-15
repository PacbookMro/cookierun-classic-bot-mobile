#!/usr/bin/env python3
"""Build an allowlisted phone bundle; never include local tools or diagnostics."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "v1.1.0-mobile.5"
NAME = f"cookierun-classic-bot-mobile-{VERSION}"
RUNTIME = (
    "main.lua", "actions.lua", "bot.lua", "config.lua", "cycle.lua",
    "detection.lua", "diagnostics.lua", "screen.lua", "recovery.lua", "main_menu.lua", "window_profile.lua",
    "options.lua", "interaction.lua", "brightness.lua", "restore_brightness.lua",
    "README.md", "CHANGELOG.md", "docs/PHONE_TEST.md", "docs/SAMSUNG_MULTI_WINDOW.md", "docs/INVESTIGATION.md",
    "docs/QUALITY_OF_LIFE.md",
)


def build():
    files = [ROOT / name for name in RUNTIME]
    # Supplied assets use uppercase names; runtime diagnostics use lowercase.
    files += sorted((ROOT / "templates").glob("[A-Z]*.png"))
    assert len(files) > len(RUNTIME), "No templates found"
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    archive = dist / f"{NAME}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        for path in files:
            info = zipfile.ZipInfo(f"{NAME}/{path.relative_to(ROOT).as_posix()}")
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            bundle.writestr(info, path.read_bytes())
    with zipfile.ZipFile(archive) as bundle:
        assert bundle.testzip() is None
        assert len(bundle.namelist()) == len(files)
        for path in files:
            assert bundle.read(f"{NAME}/{path.relative_to(ROOT).as_posix()}") == path.read_bytes()
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    checksum = dist / "SHA256SUMS.txt"
    checksum.write_text(f"{digest}  {archive.name}\n")
    print(f"Built and verified {archive.name}: {len(files)} files, {archive.stat().st_size} bytes")
    print(checksum.read_text(), end="")


if __name__ == "__main__":
    build()
