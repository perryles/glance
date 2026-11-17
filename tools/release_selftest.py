#!/usr/bin/env python3
"""Validate Glance's Sparkle feed and release artifacts."""

import base64
import argparse
import plistlib
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

FEED_URL = "https://github.com/perryles/glance/releases/latest/download/appcast.xml"
DOWNLOAD_URL_PREFIX = "https://github.com/perryles/glance/releases/latest/download/"


def sparkle_child_text(element, local_name):
    return next(
        (child.text for child in element if child.tag.split("}")[-1] == local_name),
        None,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app", type=Path)
    args = parser.parse_args()
    root = Path.cwd()
    info_path = root / "glance/Info.plist"
    keys = [key.text for key in ET.parse(info_path).findall("./dict/key")]
    assert len(keys) == len(set(keys)), "Info.plist has duplicate keys"
    info = plistlib.loads(info_path.read_bytes())
    assert info["SUFeedURL"] == FEED_URL, info["SUFeedURL"]
    public_key = base64.b64decode(info["SUPublicEDKey"], validate=True)
    assert len(public_key) == 32, len(public_key)

    project = (root / "glance.xcodeproj/project.pbxproj").read_text()
    short_version = re.findall(r"^\t*MARKETING_VERSION = ([^;]+);", project, re.MULTILINE)[-1]
    bundle_version = re.findall(r"^\t*CURRENT_PROJECT_VERSION = ([^;]+);", project, re.MULTILINE)[-1]

    appcast_path = root / "release/appcast.xml"
    assert appcast_path.is_file(), "release/appcast.xml is missing"
    tree = ET.parse(appcast_path)
    item = tree.find(".//item")
    enclosure = tree.find(".//item/enclosure")
    assert item is not None and enclosure is not None, "appcast has no update item"
    attrs = enclosure.attrib
    signature = next((value for key, value in attrs.items() if key.endswith("}edSignature")), None)
    assert signature, "update archive is unsigned"
    assert enclosure.attrib.get("url", "").startswith(DOWNLOAD_URL_PREFIX), enclosure.attrib.get("url")
    assert sparkle_child_text(item, "version") == bundle_version
    assert sparkle_child_text(item, "shortVersionString") == short_version
    archive_name = attrs["url"].removeprefix(DOWNLOAD_URL_PREFIX)
    assert archive_name == f"Glance-{short_version}.dmg", archive_name
    archive = root / "release" / archive_name
    assert archive.is_file(), f"Missing release archive: {archive}"
    assert int(attrs["length"]) == archive.stat().st_size, "Archive length is stale"
    assert len(base64.b64decode(signature, validate=True)) == 64, "Invalid EdDSA signature"
    if args.app:
        app_info = plistlib.loads((args.app / "Contents/Info.plist").read_bytes())
        assert app_info["CFBundleShortVersionString"] == short_version
        assert str(app_info["CFBundleVersion"]) == bundle_version
        assert app_info["SUFeedURL"] == FEED_URL
        assert app_info["SUPublicEDKey"] == info["SUPublicEDKey"]
        icon_file = app_info.get("CFBundleIconFile")
        assert icon_file, "Built app does not declare an application icon"
        icon_path = args.app / "Contents/Resources" / icon_file
        if not icon_path.suffix:
            icon_path = icon_path.with_suffix(".icns")
        assert icon_path.is_file(), f"Built app icon is missing: {icon_path}"
        assert icon_path.read_bytes().startswith(b"icns"), "Built app icon is not an ICNS file"
    print("release selftest: passed")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as error:
        print(f"release selftest: failed: {error}", file=sys.stderr)
        raise
