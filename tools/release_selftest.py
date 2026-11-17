#!/usr/bin/env python3
"""Validate Glance's Sparkle feed and release artifacts."""

import base64
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
    root = Path.cwd()
    info = plistlib.loads((root / "glance/Info.plist").read_bytes())
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
    item_attrs = item.attrib
    attrs = enclosure.attrib
    signature = next((value for key, value in attrs.items() if key.endswith("}edSignature")), None)
    assert signature, "update archive is unsigned"
    assert enclosure.attrib.get("url", "").startswith(DOWNLOAD_URL_PREFIX), enclosure.attrib.get("url")
    assert sparkle_child_text(item, "version") == bundle_version
    assert sparkle_child_text(item, "shortVersionString") == short_version
    print("release selftest: passed")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as error:
        print(f"release selftest: failed: {error}", file=sys.stderr)
        raise
