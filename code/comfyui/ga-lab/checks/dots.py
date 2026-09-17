"""Finds fret-position dots on a generated guitar neck and compares them with the GA control map.

Method (numpy and Pillow only):
1. on luma and two opponent color channels, at a few scales around the dot radius the map implies, the determinant
   of the Hessian of the Gaussian-smoothed channel, scale-normalized (sigma^4). It is large for round blobs, bright
   or dark, and near zero along lines, so strings and fret wires respond weakly; a string crossing a fret wire
   responds a little.
2. local maxima above a threshold relative to each channel's contrast (98th minus 2nd percentile, squared), kept
   greedily from the strongest, at least 1.5 dot radius apart;
3. detections near an inlay or an open-string marker of the map are ignored (those are dots on the map too, but
   not the chord's), and the rest are matched one to one with the chord's dots within a tolerance.

The threshold was chosen on a synthetic tuning split and measured on a separate test split: see evaluate.py and
results/dots-eval.json. Used from the command line:

    python -m checks.dots IMAGE --layout layout.json
    python -m checks.dots IMAGE --chord C --fret-start 0 --fret-end 5
"""
import argparse
import json
import math
import sys

import numpy as np
from PIL import Image

from .geometry import Layout

DEFAULT_THRESHOLD = 0.06  # evaluate.py picks it again on the tuning split
SCALES = (0.75, 1.0, 1.35)


def _kernel(sigma):
    radius = max(1, int(3 * sigma + 0.5))
    x = np.arange(-radius, radius + 1, dtype=np.float64)
    k = np.exp(-(x * x) / (2 * sigma * sigma))
    return k / k.sum()


def blur(image, sigma):
    k = _kernel(sigma)
    r = len(k) // 2
    padded = np.pad(image, ((0, 0), (r, r)), mode="reflect")
    rows = np.lib.stride_tricks.sliding_window_view(padded, len(k), axis=1) @ k
    padded = np.pad(rows, ((r, r), (0, 0)), mode="reflect")
    return np.lib.stride_tricks.sliding_window_view(padded, len(k), axis=0) @ k


def hessian_det(gray, sigma):
    L = blur(gray, sigma)
    P = np.pad(L, 1, mode="edge")
    lxx = P[1:-1, 2:] - 2 * P[1:-1, 1:-1] + P[1:-1, :-2]
    lyy = P[2:, 1:-1] - 2 * P[1:-1, 1:-1] + P[:-2, 1:-1]
    lxy = (P[2:, 2:] - P[2:, :-2] - P[:-2, 2:] + P[:-2, :-2]) / 4
    return (lxx * lyy - lxy * lxy) * sigma ** 4


def to_gray(image):
    if isinstance(image, str):
        with Image.open(image) as opened:
            return np.asarray(opened.convert("L"), dtype=np.float64)
    return np.asarray(image.convert("L"), dtype=np.float64)


def channels(image):
    """Luma and two opponent channels (red-green, yellow-blue): a red dot on brown wood has the wood's luma."""
    if isinstance(image, str):
        with Image.open(image) as opened:
            image = opened.convert("RGB")
    a = np.asarray(image.convert("RGB"), dtype=np.float64)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return [0.299 * r + 0.587 * g + 0.114 * b, r - g, (r + g) / 2 - b]


def response(image, radius):
    """The blob response map: for each channel, the max over SCALES of the scale-normalized Hessian determinant
    divided by the channel's contrast squared (98th minus 2nd percentile, at least 8 levels); then the max over
    channels."""
    base_sigma = max(radius / math.sqrt(2), 1.0)
    result = None
    for c in channels(image):
        lo, hi = np.percentile(c, [2, 98])
        contrast = max(hi - lo, 8.0)
        r = np.max([hessian_det(c, base_sigma * s) for s in SCALES], axis=0) / (contrast * contrast)
        result = r if result is None else np.maximum(result, r)
    return result


def peaks(resp, radius, threshold=None, max_peaks=200):
    """[(x, y, score)] of local maxima above the threshold, strongest first, at least 1.5 radius apart."""
    threshold = DEFAULT_THRESHOLD if threshold is None else threshold
    padded = np.pad(resp, 1, mode="constant", constant_values=-np.inf)
    neighbors = np.max(np.lib.stride_tricks.sliding_window_view(padded, (3, 3)), axis=(2, 3))
    ys, xs = np.nonzero((resp > threshold) & (resp >= neighbors))
    values = resp[ys, xs]
    kept = []
    min_d2 = (radius * 1.5) ** 2
    for i in np.argsort(-values)[:20000]:
        x, y = xs[i], ys[i]
        if all((x - kx) ** 2 + (y - ky) ** 2 >= min_d2 for kx, ky, _ in kept):
            kept.append((int(x), int(y), float(values[i] / threshold)))
            if len(kept) >= max_peaks:
                break
    return kept


def detect(image, radius, threshold=None, max_peaks=200):
    """[(x, y, score)] of blob centers, strongest first. score is the response over the threshold."""
    return peaks(response(image, radius), radius, threshold, max_peaks)


def match(expected, detected, tolerance):
    """Greedy one-to-one matching by distance. Returns (pairs, unmatched expected, unmatched detected)."""
    pairs = []
    candidates = sorted(
        (math.dist(e, d[:2]), i, j) for i, e in enumerate(expected) for j, d in enumerate(detected)
        if math.dist(e, d[:2]) <= tolerance)
    used_e, used_d = set(), set()
    for dist, i, j in candidates:
        if i in used_e or j in used_d:
            continue
        used_e.add(i)
        used_d.add(j)
        pairs.append((i, j, dist))
    missed = [e for i, e in enumerate(expected) if i not in used_e]
    extra = [d for j, d in enumerate(detected) if j not in used_d]
    return pairs, missed, extra


def on_geometry(d, layout, radius):
    """False for a detection on a fret wire of the map (a string crossing a wire) or off the board."""
    x, y = d[:2]
    if not (layout.top - radius <= y <= layout.bottom + radius and layout.left - 3 * radius <= x <= layout.right + radius):
        return False
    return all(abs(x - wx) >= 0.8 * radius for f, wx in layout.wires() if f > layout.first_wire)


def check(image, expected, ignore, radius, tolerance, threshold=None, resp=None, layout=None):
    """Detections within `tolerance` of an ignored point (inlay, open-string marker) are dropped before matching.

    resp, when given, is response(image, radius) computed once for several thresholds. layout, when given, is the
    map's geometry: detections on its fret wires or off its board are dropped too (the geometric prior)."""
    detected = peaks(response(image, radius) if resp is None else resp, radius, threshold)
    if layout is not None:
        detected = [d for d in detected if on_geometry(d, layout, radius)]
    kept = [d for d in detected
            if not any(math.dist(d[:2], p) <= tolerance for p in ignore)
            or any(math.dist(d[:2], e) <= tolerance for e in expected)]
    pairs, missed, extra = match(expected, kept, tolerance)
    return {"expected": len(expected), "detected": len(kept), "true_positives": len(pairs),
            "missed": [list(map(int, m)) for m in missed], "extra": [list(d[:2]) for d in extra],
            "exact": not missed and not extra}


def check_layout(image, layout, threshold=None, prior=True):
    """The map's notes, from its layout JSON (or a Layout), looked for on an image of the map's size."""
    if isinstance(image, str):
        with Image.open(image) as opened:
            image = opened.convert("RGB")
    layout = layout if isinstance(layout, Layout) else Layout(layout)
    if (image.width, image.height) != (layout.width, layout.height):
        raise ValueError(f"image {image.width}x{image.height} but layout {layout.width}x{layout.height}")
    expected = layout.dots()
    ignore = [(x, y) for x, y, _ in layout.inlay_positions()] + layout.open_markers()
    tolerance = max(layout.radius * 1.5, layout.string_gap * 0.45)
    result = check(image, expected, ignore, layout.radius, tolerance, threshold, layout=layout if prior else None)
    result.update(radius=layout.radius, tolerance=round(tolerance, 1))
    return result


def check_against_map(image, chord, fret_start, fret_end, threshold=None, prior=True, inlays="show"):
    """The same, with the layout computed by the GA pack for a chord, when no layout JSON was recorded."""
    if isinstance(image, str):
        with Image.open(image) as opened:
            image = opened.convert("RGB")
    layout = Layout.compute(chord, fret_start, fret_end, image.width, image.height, inlays)
    result = check_layout(image, layout, threshold, prior)
    result.update(chord=chord)
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("image")
    parser.add_argument("--layout", help="the layout JSON file GA Fretboard Control Map output (preferred)")
    parser.add_argument("--chord", help="without --layout: a voicing (x32010) or a symbol GA knows (C, Am, Bm7b5...)")
    parser.add_argument("--fret-start", type=int, default=0)
    parser.add_argument("--fret-end", type=int, default=5)
    parser.add_argument("--threshold", type=float)
    args = parser.parse_args(argv)
    if args.layout:
        with open(args.layout, encoding="utf-8") as f:
            result = check_layout(args.image, json.load(f), args.threshold)
    elif args.chord:
        result = check_against_map(args.image, args.chord, args.fret_start, args.fret_end, args.threshold)
    else:
        parser.error("give --layout or --chord")
    json.dump(result, sys.stdout, indent=1)
    print()
    return 0 if result["exact"] else 1


if __name__ == "__main__":
    sys.exit(main())
