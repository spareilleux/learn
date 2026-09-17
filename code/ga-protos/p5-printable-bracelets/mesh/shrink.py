"""Cut a render down to a size that belongs in a repository.

Blender writes 24-bit PNGs of half a megabyte for a picture that is a pale object on a flat background. Quantising to
128 colours halves them and nothing visible changes. The meshes stay outside the repository; only these do not.

    python mesh/shrink.py public/ga-lab/p5/*.png --colors 128
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("images", nargs="+", type=Path)
    parser.add_argument("--colors", type=int, default=128)
    args = parser.parse_args()
    for path in args.images:
        before = path.stat().st_size
        image = Image.open(path).convert("RGB").quantize(colors=args.colors, method=Image.MEDIANCUT,
                                                         dither=Image.FLOYDSTEINBERG)
        image.save(path, optimize=True)
        print(f"{path.name}: {before} -> {path.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
