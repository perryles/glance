#!/usr/bin/env python3
"""Validate Glance's Sparkle feed and release artifacts."""

import base64
import plistlib
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

FEED_URL = "https://github.com/perryles/glance/releases/latest/download/appcast.xml"
DOWNLOAD_URL = "https://github.com/perryles/glance/releases/latest/download/Glance-1.2.1.dmg"
ARCHIVE_NAME = "Glance-1.2.1.dmg"


def sparkle_child_text(element, local_name):
    return next(
        (child.text for child in element if child.tag.split("}")[-1] == local_name),
        None,
    )


def main():
    root = Path.cwd()
    info = plistlib.loads((root / "glance/Info.plist").read_bytes())
    assert info["SUFeedURL"] == FEED_URL, info["SUFeedURL"]
    assert len(base64.b64decode(info["SUPublicEDKey"], validate=True)) == 32

    project = (root / "glance.xcodeproj/project.pbxproj").read_text()
    short_versions = re.findall(r"^\t*MARKETING_VERSION = ([^;]+);", project, re.MULTILINE)
    bundle_versions = re.findall(r"^\t*CURRENT_PROJECT_VERSION = ([^;]+);", project, re.MULTILINE)
    assert short_versions == ["1.2.1", "1.2.1"], short_versions
    assert bundle_versions == ["5", "5"], bundle_versions

    archive = root / "release" / ARCHIVE_NAME
    appcast = root / "release/appcast.xml"
    assert archive.is_file(), f"release/{ARCHIVE_NAME} is missing"
    assert appcast.is_file(), "release/appcast.xml is missing"

    tree = ET.parse(appcast)
    item = tree.find(".//item")
    enclosure = tree.find(".//item/enclosure")
    assert item is not None and enclosure is not None, "appcast has no update item"
    signature = next((value for key, value in enclosure.attrib.items() if key.endswith("}edSignature")), None)
    assert signature, "update archive is unsigned"
    assert enclosure.attrib.get("url") == DOWNLOAD_URL, enclosure.attrib.get("url")
    assert sparkle_child_text(item, "version") == "5"
    assert sparkle_child_text(item, "shortVersionString") == "1.2.1"
    print("release selftest: passed")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as error:
        print(f"release selftest: failed: {error}", file=sys.stderr)
        raise
