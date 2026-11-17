#!/usr/bin/env python3
"""Validate Chinese and Turkish catalogs, placeholders, and built resources."""

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import subprocess

LANGUAGES = ("zh-Hans", "tr")
REQUIRED_KEYS = {
    "Localizable": {"Settings", "Permissions", "Session locked", "Check for Updates"},
    "InfoPlist": {"NSCameraUsageDescription"},
}


def load_catalog(root: Path, name: str) -> dict:
    data = json.loads((root / "glance" / f"{name}.xcstrings").read_text())
    assert data["sourceLanguage"] == "en"
    return data["strings"]


def placeholders(value: str) -> Counter:
    tokens = re.findall(r"%(?:(\d+)\$)?[-+#0 ]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(@|lld|ld|d|u|f|%)", value)
    arguments = (token for token in tokens if token[1] != "%")
    return Counter((int(position) if position else index, kind)
                   for index, (position, kind) in enumerate(arguments, start=1))


def validate_catalog(root: Path, name: str) -> None:
    strings = load_catalog(root, name)
    assert REQUIRED_KEYS[name] <= strings.keys()
    for key, entry in strings.items():
        if not key or entry.get("shouldTranslate") is False:
            continue
        assert "\\n" not in key, f"{key!r} uses a literal newline escape"
        for language in LANGUAGES:
            unit = entry.get("localizations", {}).get(language, {}).get("stringUnit", {})
            value = unit.get("value", "")
            assert unit.get("state") == "translated" and value, f"{name}: {key!r} lacks {language}"
            assert "\\n" not in value, f"{key!r} displays a literal newline escape"
            if name != "InfoPlist":
                assert placeholders(key) == placeholders(value), (
                    f"{language}: {key!r} has incompatible placeholders: {value!r}"
                )


def validate_app(root: Path, app: Path) -> None:
    resources = app / "Contents" / "Resources"
    for language in LANGUAGES:
        for name in REQUIRED_KEYS:
            path = resources / f"{language}.lproj" / f"{name}.strings"
            assert path.is_file(), f"Built app lacks {path}"
            result = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(path)],
                                    check=True, capture_output=True, text=True)
            compiled = json.loads(result.stdout)
            for key, entry in load_catalog(root, name).items():
                if not key or entry.get("shouldTranslate") is False:
                    continue
                expected = entry["localizations"][language]["stringUnit"]["value"]
                assert compiled.get(key) == expected, f"{language}: {key!r} missing or stale in app"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default=Path.cwd(), type=Path)
    parser.add_argument("--app", type=Path)
    args = parser.parse_args()
    for catalog in REQUIRED_KEYS:
        validate_catalog(args.root, catalog)
    if args.app:
        validate_app(args.root, args.app)
    print("i18n selftest: passed")


if __name__ == "__main__":
    main()
