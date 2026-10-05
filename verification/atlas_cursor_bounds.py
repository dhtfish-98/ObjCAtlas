#!/usr/bin/env python3
# Copyright (c) 2026 dhtfish98
"""Build and run malformed-input cursor checks with a guard page."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
output = root / "Build" / "验证" / "cursor-bounds"
output.mkdir(parents=True, exist_ok=True)
binary = output / "atlas-cursor-bounds"
subprocess.run(
    [
        "clang", "-fobjc-arc", "-fblocks", "-framework", "Foundation",
        "-include", str(root / "atlas_MachObjC_Prefix.pch"),
        "-I", str(root / "Core"),
        str(root / "Core" / "atlas_CDDataCursor.m"),
        str(root / "verification" / "atlas_cursor_bounds.m"),
        "-o", str(binary),
    ],
    check=True,
)
subprocess.run([str(binary)], check=True)
