#!/usr/bin/env python3
"""Trace the preserved Mingle reference; development-only Pillow/NumPy/Potrace."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def absolute_path(data, height):
    """Normalize Potrace's relative cubic paths and flipped 0.1px coordinates."""
    tokens = re.findall(r"[A-Za-z]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?", data)
    result, index, command = [], 0, None
    current, start = np.zeros(2), np.zeros(2)
    arity = {"M": 2, "L": 2, "C": 6}
    points = []

    def coord(p):
        q = [p[0] / 10, height - p[1] / 10]
        points.append(q)
        return " ".join(f"{v:.1f}" for v in q)

    while index < len(tokens):
        if tokens[index].isalpha():
            command = tokens[index]
            index += 1
        kind = command.upper()
        if kind == "Z":
            result.append("Z")
            current = start.copy()
            command = None
            continue
        if kind not in arity:
            raise ValueError(f"Unsupported Potrace command: {command}")
        count = arity[kind]
        values = np.array([float(v) for v in tokens[index:index + count]])
        if len(values) != count:
            raise ValueError("Incomplete Potrace coordinate group")
        index += count
        group = values.reshape(-1, 2)
        if command.islower():
            group = group + current
        result.append(kind + " " + " ".join(coord(p) for p in group))
        current = group[-1].copy()
        if kind == "M":
            start = current.copy()
            command = "l" if command.islower() else "L"
    return " ".join(result), min(p[0] for p in points)


def trace(mask, directory, name, binary):
    height, width = mask.shape
    pbm, svg = directory / f"{name}.pbm", directory / f"{name}.svg"
    pbm.write_bytes(f"P4\n{width} {height}\n".encode() + np.packbits(mask, axis=1).tobytes())
    subprocess.run([binary, str(pbm), "-s", "-o", str(svg), "-t", "30", "-u", "10"], check=True)
    return [absolute_path(p.attrib["d"], height)
            for p in ET.parse(svg).iter("{http://www.w3.org/2000/svg}path")]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "docs/design/references/original-mingle-logo.png")
    parser.add_argument("--output", type=Path, default=ROOT / "apps/mobile/assets/brand/mingle-mark.svg")
    args = parser.parse_args()
    binary = shutil.which("potrace")
    if not binary:
        parser.error("Potrace must be available in PATH")
    rgba = np.array(Image.open(args.source).convert("RGBA"))
    height, width = rgba.shape[:2]
    if width != height:
        parser.error("The Mingle reference must be square")
    rgb, opaque = rgba[:, :, :3].astype(int), rgba[:, :, 3] > 128
    palette = np.array([[202, 49, 109], [253, 211, 226], [253, 172, 200]])
    distances = np.abs(rgb[:, :, None, :] - palette).sum(axis=3)
    # Complementary dark/light regions avoid a dark silhouette beneath the folds.
    light = opaque & (distances[:, :, 1] < distances[:, :, 0])
    dark = opaque & ~light
    fold = light & (distances.argmin(axis=2) == 2)
    with tempfile.TemporaryDirectory(prefix="mingle-logo-") as temporary:
        directory = Path(temporary)
        dark_paths = sorted(trace(dark, directory, "dark", binary), key=lambda p: p[1])
        light_paths = trace(light, directory, "light", binary)
        fold_paths = trace(fold, directory, "fold", binary)
    if len(dark_paths) != 2 or len(light_paths) != 1 or len(fold_paths) != 1:
        raise ValueError("Expected two dark regions and one region for each fold")
    gradients = """    <linearGradient id="primary-gradient" x1="0" y1="0" x2="1" y2="1">
      <stop id="primary-start" offset="0" stop-color="#CD3470"/>
      <stop id="primary-end" offset="1" stop-color="#C72F6A"/>
    </linearGradient>
    <linearGradient id="highlight-gradient" x1="0" y1="0" x2="1" y2="1">
      <stop id="highlight-start" offset="0" stop-color="#FDD3E1"/>
      <stop id="highlight-end" offset="1" stop-color="#FDD7E4"/>
    </linearGradient>
    <linearGradient id="fold-gradient" x1="0" y1="0" x2="1" y2="1">
      <stop id="fold-start" offset="0" stop-color="#FDACC9"/>
      <stop id="fold-end" offset="1" stop-color="#F7A5C2"/>
    </linearGradient>
    <clipPath id="fold-clip"><use href="#highlight"/></clipPath>"""
    layers = [("bubble", "primary", dark_paths[0][0]),
              ("plane", "primary", dark_paths[1][0]),
              ("highlight", "highlight", light_paths[0][0]),
              ("fold", "fold", fold_paths[0][0])]
    paths = []
    for name, gradient, data in layers:
        clip = ' clip-path="url(#fold-clip)"' if name == "fold" else ""
        paths.append(f'  <path id="{name}" fill="url(#{gradient}-gradient)"{clip} d="{data}"/>')
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}">
  <title>Mingle paper plane and conversation mark</title>
  <desc>Potrace cubic geometry; complementary color regions; preserved pink fold.</desc>
  <defs>
{gradients}
  </defs>
''' + "\n".join(paths) + "\n</svg>\n"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(svg)
    print(f"Traced Mingle reference to {args.output}")


if __name__ == "__main__":
    main()
