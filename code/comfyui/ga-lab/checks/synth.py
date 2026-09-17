"""A synthetic labelled set for the dot detector: necks drawn with dots at known positions, then degraded.

Each sample uses GA Fretboard Control Map's geometry (geometry.Layout) for a random voicing and fret range, draws a
wooden board, fret wires, strings, a nut, inlays (distractors, labelled as "ignore") and the chord's dots in a
random style, then applies the condition's degradations: Gaussian noise, blur, perspective jitter (the labels go
through the same homography) and low contrast between dots and wood. Everything comes from one seed.
"""
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from .geometry import Layout

WOODS = [(58, 36, 26), (92, 60, 38), (200, 160, 110), (32, 28, 26), (130, 84, 50)]
DOT_STYLES = ["white", "black", "amber_glow", "red", "ring"]

CONDITIONS = {
    "clean": dict(noise=0, blur=0, perspective=0, low_contrast=False),
    "noise": dict(noise=18, blur=0, perspective=0, low_contrast=False),
    "blur": dict(noise=0, blur=2.5, perspective=0, low_contrast=False),
    "perspective": dict(noise=0, blur=0, perspective=0.05, low_contrast=False),
    "combined": dict(noise=12, blur=1.5, perspective=0.04, low_contrast=False),
    "low_contrast": dict(noise=6, blur=1.0, perspective=0.02, low_contrast=True),
}


def _random_voicing(rng, fret_start, fret_end):
    frets = []
    for _ in range(6):
        roll = rng.random()
        if roll < 0.2:
            frets.append(None)
        elif roll < 0.35 and fret_start == 0:
            frets.append(0)
        else:
            frets.append(rng.randint(max(1, fret_start), fret_end))
    if all(f is None or f == 0 for f in frets):
        frets[rng.randrange(6)] = rng.randint(max(1, fret_start), fret_end)
    return tuple(frets)


def _homography(src, dst):
    """3x3 H with dst ~ H src, from 4 point pairs."""
    a, b = [], []
    for (x, y), (u, v) in zip(src, dst):
        a.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        b.append(u)
        a.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        b.append(v)
    h = np.linalg.solve(np.array(a, dtype=float), np.array(b, dtype=float))
    return np.append(h, 1).reshape(3, 3)


def _apply(h, pts):
    out = []
    for x, y in pts:
        u, v, w = h @ np.array([x, y, 1.0])
        out.append((u / w, v / w))
    return out


def sample(seed, condition, width=768, height=432):
    rng = random.Random(seed)
    c = CONDITIONS[condition]
    fret_start = rng.choice([0, 0, 0, 1, 3, 5])
    fret_end = fret_start + rng.choice([4, 5, 5, 7, 12 - fret_start if fret_start < 7 else 5])
    layout = Layout(fret_start, fret_end, width, height)
    frets = _random_voicing(rng, fret_start, fret_end)

    wood = rng.choice(WOODS)
    image = Image.new("RGB", (width, height), tuple(rng.randint(10, 60) for _ in range(3)))
    board = np.zeros((layout.bottom - layout.top, layout.right - layout.left + 40, 3))
    grain = np.cumsum(np.random.default_rng(seed).normal(0, 1, board.shape[0]))
    grain = (grain - grain.mean()) / (grain.std() + 1e-9)
    streak = np.random.default_rng(seed + 1).normal(0, 1, board.shape[:2])
    shade = 1 + 0.08 * grain[:, None] + 0.05 * streak
    board[:] = np.array(wood)[None, None, :] * shade[:, :, None]
    image.paste(Image.fromarray(np.clip(board, 0, 255).astype(np.uint8)), (layout.left, layout.top))
    draw = ImageDraw.Draw(image)

    fret_w = max(2, round(width * 0.004))
    for f in range(layout.first_wire, fret_end + 1):
        x = round(layout.wire_x(f))
        if f == 0:
            draw.rectangle([x - 3 * fret_w, layout.top, x, layout.bottom], fill=(225, 215, 190))
        else:
            draw.rectangle([x - fret_w // 2, layout.top, x - fret_w // 2 + fret_w, layout.bottom], fill=(185, 185, 180))

    ignore = []
    inlay_color = (235, 230, 215) if sum(wood) < 400 else (40, 35, 30)
    for x, y, r in layout.inlays():
        rr = layout.radius * rng.uniform(0.6, 1.0)
        draw.ellipse([x - rr, y - rr, x + rr, y + rr], fill=inlay_color)
        ignore.append((x, y))

    for s in range(6):
        y = layout.string_y(s)
        w = 1 + (5 - s) // 2
        draw.rectangle([layout.left, y - w // 2, layout.right, y - w // 2 + w], fill=(205, 200, 190))

    expected = []
    style = rng.choice(DOT_STYLES)
    if c["low_contrast"]:
        style = "low_contrast"
    glow = Image.new("RGB", (width, height), (0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    for s, f in enumerate(frets):
        if f is None:
            continue
        x, y = layout.note_xy(s, f)
        r = layout.radius * rng.uniform(0.75, 1.25)
        box = [x - r, y - r, x + r, y + r]
        if f == 0:
            draw.ellipse(box, outline=(230, 230, 230), width=max(2, round(r / 4)))
            ignore.append((x, y))
            continue
        expected.append((x, y))
        if style == "white":
            draw.ellipse(box, fill=(245, 245, 240))
        elif style == "black":
            draw.ellipse(box, fill=(12, 12, 12), outline=(240, 240, 240), width=max(1, round(r / 5)))
        elif style == "red":
            draw.ellipse(box, fill=(200, 30, 30))
        elif style == "ring":
            draw.ellipse(box, outline=(240, 240, 240), width=max(2, round(r / 3)))
        elif style == "amber_glow":
            draw.ellipse(box, fill=(255, 190, 80))
            gr = r * 1.8
            glow_draw.ellipse([x - gr, y - gr, x + gr, y + gr], fill=(120, 70, 10))
        elif style == "low_contrast":
            lift = rng.choice([-1, 1]) * 45
            draw.ellipse(box, fill=tuple(int(np.clip(v + lift, 0, 255)) for v in wood))
    if style == "amber_glow":
        glow = glow.filter(ImageFilter.GaussianBlur(layout.radius * 0.8))
        image = Image.fromarray(np.clip(np.asarray(image, dtype=int) + np.asarray(glow, dtype=int), 0, 255).astype(np.uint8))

    if c["perspective"]:
        j = c["perspective"]
        corners = [(0, 0), (width, 0), (width, height), (0, height)]
        moved = [(x + rng.uniform(-j, j) * width, y + rng.uniform(-j, j) * height) for x, y in corners]
        out_to_in = _homography(moved, corners)  # PIL wants, for each output pixel, where to read in the input
        coeffs = (out_to_in / out_to_in[2, 2]).flatten()[:8]
        image = image.transform((width, height), Image.PERSPECTIVE, tuple(coeffs), Image.BILINEAR)
        in_to_out = np.linalg.inv(out_to_in)
        expected = _apply(in_to_out, expected)
        ignore = _apply(in_to_out, ignore)
    if c["blur"]:
        image = image.filter(ImageFilter.GaussianBlur(c["blur"]))
    if c["noise"]:
        noise = np.random.default_rng(seed + 2).normal(0, c["noise"], (height, width, 1))
        image = Image.fromarray(np.clip(np.asarray(image, dtype=float) + noise, 0, 255).astype(np.uint8))

    inside = [(x, y) for x, y in expected if 0 <= x < width and 0 <= y < height]
    return {
        "image": image, "expected": inside, "ignore": ignore, "radius": layout.radius,
        "tolerance": max(layout.radius * 1.5, layout.string_gap * 0.45),
        "frets": frets, "fret_range": (fret_start, fret_end), "style": style, "condition": condition,
    }
