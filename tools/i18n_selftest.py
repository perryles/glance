#!/usr/bin/env python3
"""Validate Glance's Simplified Chinese localization and built resources."""

import argparse
import json
from pathlib import Path

REQUIRED_KEYS = {
    "Localizable": {
        "Settings": "设置",
        "Permissions": "权限",
        "Session locked": "会话已锁定",
        "Check for Updates": "检查更新",
    },
    "InfoPlist": {
        "NSCameraUsageDescription": "摄像头",
    },
}


def load_catalog(root: Path, name: str) -> dict:
    path = root / "glance" / f"{name}.xcstrings"
    if not path.is_file():
        raise AssertionError(f"Missing {path.relative_to(root)}")
    data = json.loads(path.read_text(encoding="utf-8"))
    assert data.get("sourceLanguage") == "en", f"{name} source language must be English"
    return data


def validate_catalog(root: Path, name: str, expected: dict[str, str]) -> None:
    strings = load_catalog(root, name).get("strings", {})
    for key, fragment in expected.items():
        assert key in strings, f"{name} is missing key: {key!r}"
        unit = strings[key].get("localizations", {}).get("zh-Hans", {}).get("stringUnit", {})
        assert unit.get("state") == "translated", f"{key!r} is not marked translated"
        value = unit.get("value", "")
        assert value and fragment in value, f"{key!r} has no usable zh-Hans translation"


def read_compiled_strings(path: Path) -> str:
    data = path.read_bytes()
    if b"\x00" in data:
        return data.decode("utf-16")
    return data.decode("utf-8", errors="ignore")


def validate_app(app: Path) -> None:
    resources = app / "Contents" / "Resources"
    localizable = resources / "zh-Hans.lproj" / "Localizable.strings"
    info = resources / "zh-Hans.lproj" / "InfoPlist.strings"
    assert localizable.is_file(), f"Built app lacks {localizable}"
    assert info.is_file(), f"Built app lacks {info}"
    assert "Settings" in read_compiled_strings(localizable)
    assert "NSCameraUsageDescription" in read_compiled_strings(info)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default=Path.cwd(), type=Path)
    parser.add_argument("--app", type=Path)
    args = parser.parse_args()

    for catalog, expected in REQUIRED_KEYS.items():
        validate_catalog(args.root, catalog, expected)
    if args.app:
        validate_app(args.app)
    print("i18n selftest: passed")


if __name__ == "__main__":
    main()
