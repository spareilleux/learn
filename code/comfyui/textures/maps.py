"""Texture maps for lesson 13, from a color (albedo) image, with NumPy and Pillow only.

    python maps.py pattern <out.png> [size]                  a tileable test pattern
    python maps.py normal <albedo.png> <out.png> [strength] [blur]
    python maps.py roughness <albedo.png> <out.png> [min] [max]
    python maps.py seam <image.png>                          jumps across the middle and the wrap edge
    python maps.py preview <albedo.png> <normal.png> <out.png>

Every neighbour lookup wraps around the image (np.roll), so a tileable albedo gives tileable maps.
The normal map is tangent space with green pointing up (the OpenGL convention).
"""
import sys

import numpy as np
from PIL import Image


def load(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float64) / 255.0


def save(array, path):
    Image.fromarray(np.clip(np.rint(array * 255.0), 0, 255).astype(np.uint8)).save(path)


def save_normal(normal, path):
    # 0 must map to 128 on every machine: (0 + 1) / 2 * 255 is exactly 127.5, and rounding a tie
    # went up on Linux and Windows and down on macOS. Floor after adding 128 and a margin far above
    # floating-point noise.
    n = normal * 2.0 - 1.0
    Image.fromarray(np.clip(np.floor(n * 127.5 + 128.0 + 1e-9), 0, 255).astype(np.uint8)).save(path)


def luminance(rgb):
    # Rec. 709 weights on the encoded values: a height guess, not a measurement
    return rgb @ np.array([0.2126, 0.7152, 0.0722])


def box_blur(height, radius):
    # a square blur of (2 radius + 1) pixels, wrapping at the edges
    out = height.copy()
    for axis in (0, 1):
        total = np.zeros_like(out)
        for offset in range(-radius, radius + 1):
            total += np.roll(out, offset, axis=axis)
        out = total / (2 * radius + 1)
    return out


def normal_map(rgb, strength=4.0, blur=1):
    h = box_blur(luminance(rgb), blur)
    # central differences; rows grow downwards, so the upward slope is minus the row slope
    dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) / 2.0
    dy_up = -(np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) / 2.0
    n = np.stack([-strength * dx, -strength * dy_up, np.ones_like(h)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return (n + 1.0) / 2.0


def roughness_map(rgb, low=0.45, high=0.9):
    # dark grain reads as rough, light wood as smoother: a convention for the look, not a measurement
    lum = luminance(rgb)
    span = lum.max() - lum.min()
    t = (lum - lum.min()) / span if span > 0 else np.zeros_like(lum)
    r = high - (high - low) * t
    return np.repeat(r[..., None], 3, axis=-1)  # three.js reads the green channel


def seam_report(rgb):
    a = rgb * 255.0
    h, w = a.shape[:2]
    jump = lambda u, v: np.abs(u - v).mean()
    rows = np.mean([jump(a[y], a[y + 1]) for y in range(h // 10, h - h // 10, max(1, h // 20))])
    cols = np.mean([jump(a[:, x], a[:, x + 1]) for x in range(w // 10, w - w // 10, max(1, w // 20))])
    return {
        "middle row": jump(a[h // 2 - 1], a[h // 2]),
        "middle column": jump(a[:, w // 2 - 1], a[:, w // 2]),
        "wrap row": jump(a[-1], a[0]),
        "wrap column": jump(a[:, -1], a[:, 0]),
        "typical row": rows,
        "typical column": cols,
    }


def preview(rgb, normal, light=(-0.5, 0.5, 0.7), ambient=0.25):
    n = normal * 2.0 - 1.0
    l = np.array(light) / np.linalg.norm(light)
    shade = ambient + (1 - ambient) * np.clip(n @ l, 0.0, 1.0)
    lit = rgb * shade[..., None]
    return np.tile(lit, (2, 2, 1))


def pattern(size=64):
    # grain along y with a wavy offset; every period divides the size, so it tiles
    y, x = np.mgrid[0:size, 0:size] / size
    wave = np.sin(2 * np.pi * (6 * x + 0.3 * np.sin(2 * np.pi * y)))
    base = 0.45 + 0.15 * wave
    return np.stack([base * 1.0, base * 0.62, base * 0.4], axis=-1)


def main(args):
    command = args[0]
    if command == "pattern":
        save(pattern(int(args[2]) if len(args) > 2 else 64), args[1])
    elif command == "normal":
        strength = float(args[3]) if len(args) > 3 else 4.0
        blur = int(args[4]) if len(args) > 4 else 1
        save_normal(normal_map(load(args[1]), strength, blur), args[2])
    elif command == "roughness":
        low = float(args[3]) if len(args) > 3 else 0.45
        high = float(args[4]) if len(args) > 4 else 0.9
        save(roughness_map(load(args[1]), low, high), args[2])
    elif command == "seam":
        for name, value in seam_report(load(args[1])).items():
            print(f"{name}: {value:.2f}")
    elif command == "preview":
        save(preview(load(args[1]), load(args[2])), args[3])
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
