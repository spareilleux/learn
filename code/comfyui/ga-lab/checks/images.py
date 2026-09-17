"""Small image measures used by the experiments' analyses: seams, pixel differences, rank correlation, bracelets."""
import math

import numpy as np
from PIL import Image


def load(path):
    with Image.open(path) as image:
        image.seek(0)
        return np.asarray(image.convert("RGB"), dtype=np.float64)


def seam_ratio(path):
    """How visible the wrap-around seams of a texture are, against its ordinary neighbor differences.

    Mean absolute difference between the last and first column (and row), divided by the mean difference between
    adjacent columns (and rows) inside the image. About 1: the tile wraps like any interior line; well above 1: a
    visible seam when the texture repeats.
    """
    a = load(path)
    wrap_x = np.abs(a[:, -1] - a[:, 0]).mean()
    wrap_y = np.abs(a[-1] - a[0]).mean()
    inner_x = np.abs(np.diff(a, axis=1)).mean()
    inner_y = np.abs(np.diff(a, axis=0)).mean()
    return {"seam_ratio_x": round(wrap_x / max(inner_x, 1e-9), 3), "seam_ratio_y": round(wrap_y / max(inner_y, 1e-9), 3)}


def pixel_diff(path_a, path_b, level=8):
    """Share of pixels whose largest channel difference is above `level`, and the mean absolute difference."""
    a, b = load(path_a), load(path_b)
    if a.shape != b.shape:
        return {"error": f"sizes differ: {a.shape} and {b.shape}"}
    d = np.abs(a - b).max(axis=2)
    return {"share_above": round(float((d > level).mean()), 4), "mean_abs": round(float(np.abs(a - b).mean()), 3)}


def palette_size(path, coverage=0.9, bits=5):
    """How many colors, quantized to `bits` per channel, cover `coverage` of the pixels: pixel art needs few."""
    a = load(path).astype(np.int64) >> (8 - bits)
    codes = (a[..., 0] << (2 * bits)) | (a[..., 1] << bits) | a[..., 2]
    counts = np.sort(np.bincount(codes.ravel()))[::-1]
    return {"palette_size": int(np.searchsorted(np.cumsum(counts), coverage * codes.size) + 1)}


def spearman(xs, ys):
    """Spearman's rank correlation, ties given their mean rank."""
    def ranks(v):
        order = sorted(range(len(v)), key=lambda i: v[i])
        r = [0.0] * len(v)
        i = 0
        while i < len(order):
            j = i
            while j + 1 < len(order) and v[order[j + 1]] == v[order[i]]:
                j += 1
            for k in range(i, j + 1):
                r[order[k]] = (i + j) / 2
            i = j + 1
        return r
    rx, ry = ranks(xs), ranks(ys)
    mx, my = sum(rx) / len(rx), sum(ry) / len(ry)
    num = sum((a - mx) * (b - my) for a, b in zip(rx, ry))
    den = math.sqrt(sum((a - mx) ** 2 for a in rx) * sum((b - my) ** 2 for b in ry))
    return num / den if den else float("nan")


def bracelet_readback(path, circles, view_size):
    """Which of a bracelet's 12 positions still read as filled on an image made from it.

    circles are (cx, cy, r, filled) from runner.svg_raster.circles in viewBox units of `view_size`, for the
    rasterized square image. The 12 disk means are split in two at their largest gap; either side may be the
    "filled" one, since img2img can turn dark dots into bright gems, so the agreement is the better of the two
    readings, returned with the polarity that gave it.
    """
    a = load(path).mean(axis=2)
    h, w = a.shape
    scale = min(w, h) / view_size
    small = [c for c in circles if c[2] < 12]  # the 12 position markers, not the outer ring
    values = []
    yy, xx = np.mgrid[0:h, 0:w]
    for cx, cy, r, filled in small:
        mask = (xx - cx * scale) ** 2 + (yy - cy * scale) ** 2 <= (5 * scale) ** 2
        values.append(float(a[mask].mean()))
    ordered = sorted(values)
    _, i = max((ordered[k + 1] - ordered[k], k) for k in range(len(ordered) - 1))
    threshold = (ordered[i] + ordered[i + 1]) / 2
    truth = [c[3] for c in small]
    best = None
    for polarity, read in (("dark", [v < threshold for v in values]), ("bright", [v > threshold for v in values])):
        agree = sum(1 for x, y in zip(read, truth) if x == y)
        if best is None or agree > best["agree"]:
            best = {"positions": len(small), "agree": agree, "polarity": polarity, "read_filled": sum(read),
                    "true_filled": sum(truth), "exact": agree == len(small)}
    return best
