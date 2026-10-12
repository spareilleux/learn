"""Detail maps for the stone and steel pass, from the ComfyUI outputs in base/output/books/.
    assets/stone_relief.png   R: tooled-limestone height (stone-tooled_00001_.png), tileable
    assets/steel_grime.png    R: cloudy stains, G: fine vertical streaks (steel-grime_00001_.png), tileable
    assets/pier_ornament_normal.png   normal map (OpenGL, Y+) from the existing pier_ornament.png:
        bright vines read as raised, dark grooves as cut; same UVs as the albedo.
Height channels: luminance, high-passed, made seamless (variance-preserving offset-blend),
normalised to mean 0.5, standard deviation 0.17 (as make_grain.py)."""
import json
import numpy as np
from PIL import Image

ROOT = "C:/tmp/observatory-prototype-v1/"
SRC = ROOT + "artpass/books/comfyui/base/output/books/"
FEATHER = 0.25


def luminance(path):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32) / 255.0
    return a @ np.array([0.2126, 0.7152, 0.0722], np.float32)


def blur(y, sigma):
    h, w = y.shape
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.fftfreq(w)[None, :]
    return np.real(np.fft.ifft2(np.fft.fft2(y) * np.exp(-2.0 * (np.pi * sigma) ** 2 * (fx ** 2 + fy ** 2)))).astype(np.float32)


def weight(n):
    d = np.minimum(np.arange(n) + 0.5, n - np.arange(n) - 0.5) / (FEATHER * n)
    t = np.clip(d, 0.0, 1.0)
    return t * t * (3 - 2 * t)


def seamless(y):
    h, w = y.shape
    wx = weight(w)[None, :]
    b = (y * wx + np.roll(y, w // 2, axis=1) * (1 - wx)) / np.sqrt(wx ** 2 + (1 - wx) ** 2)
    wy = weight(h)[:, None]
    return (b * wy + np.roll(b, h // 2, axis=0) * (1 - wy)) / np.sqrt(wy ** 2 + (1 - wy) ** 2)


def norm(y, std=0.17):
    return np.clip(0.5 + (y - y.mean()) / (y.std() + 1e-6) * std, 0.0, 1.0)


def seam(y):
    return {"wrap_x": round(float(np.abs(y[:, 0] - y[:, -1]).mean()), 4),
            "neighbour_x": round(float(np.abs(np.diff(y, axis=1)).mean()), 4),
            "wrap_y": round(float(np.abs(y[0] - y[-1]).mean()), 4),
            "neighbour_y": round(float(np.abs(np.diff(y, axis=0)).mean()), 4)}


def save(path, *channels):
    rgb = np.stack(list(channels) + [np.full_like(channels[0], 0.5)] * (3 - len(channels)), -1)
    Image.fromarray((rgb * 255 + 0.5).astype(np.uint8)).save(path, optimize=True)


report = {}
# Stone: tooled limestone height.
y = luminance(SRC + "stone-tooled_00001_.png")
stone = norm(seamless(y - blur(y, 48.0)))
save(ROOT + "assets/stone_relief.png", stone, stone, stone)
report["stone_relief"] = seam(stone)

# Steel: cloudy stains (band 24-160 px) and fine streaks (< 6 px).
y = luminance(SRC + "steel-grime_00001_.png")
stains = norm(seamless(blur(y, 24.0) - blur(y, 160.0)))
streaks = norm(seamless(y - blur(y, 6.0)))
save(ROOT + "assets/steel_grime.png", stains, streaks)
report["steel_grime"] = {"stains": seam(stains), "streaks": seam(streaks)}

# Pier ornament: height from luminance, lightly smoothed, then a normal map.
y = luminance(ROOT + "assets/pier_ornament.png")
hgt = blur(y - blur(y, 60.0), 1.2)
gx = (np.roll(hgt, -1, axis=1) - np.roll(hgt, 1, axis=1)) * 0.5
gy = (np.roll(hgt, -1, axis=0) - np.roll(hgt, 1, axis=0)) * 0.5
STRENGTH = 9.0
n = np.stack([-gx * STRENGTH, gy * STRENGTH, np.ones_like(gx)], -1)  # image rows grow downwards: +gy flips for Y+
n /= np.linalg.norm(n, axis=-1, keepdims=True)
save(ROOT + "assets/pier_ornament_normal.png", n[..., 0] * 0.5 + 0.5, n[..., 1] * 0.5 + 0.5, n[..., 2] * 0.5 + 0.5)
report["pier_ornament_normal"] = {"strength": STRENGTH, "mean_tilt_deg": round(float(np.degrees(np.arccos(n[..., 2])).mean()), 2),
                                  "p99_tilt_deg": round(float(np.percentile(np.degrees(np.arccos(n[..., 2])), 99)), 2)}
print(json.dumps(report))
