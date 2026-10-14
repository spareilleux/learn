"""Sharpness of still frames: mean |Laplacian| of luma over a few regions (fractions of the frame), so that an
anti-aliasing that blurs shows up next to one that only steadies. Usage: py -3.14 sharp.py label=path.png ..."""
import sys

import numpy as np
from PIL import Image

REGIONS = {  # x0, y0, x1, y1 as fractions
    'shelves': (0.62, 0.34, 0.78, 0.62),
    'books_left': (0.08, 0.36, 0.26, 0.60),
    'dome': (0.30, 0.02, 0.70, 0.22),
    'floor': (0.10, 0.88, 0.40, 0.99),
    'statue': (0.80, 0.68, 0.88, 0.86),
}

rows = []
for arg in sys.argv[1:]:
    label, path = arg.split('=', 1)
    a = np.asarray(Image.open(path).convert('RGB'), dtype=np.float32) / 255.0
    lum = 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]
    h, w = lum.shape
    out = {'label': label}
    for k, (x0, y0, x1, y1) in REGIONS.items():
        r = lum[int(y0 * h):int(y1 * h), int(x0 * w):int(x1 * w)]
        lap = np.abs(4 * r[1:-1, 1:-1] - r[:-2, 1:-1] - r[2:, 1:-1] - r[1:-1, :-2] - r[1:-1, 2:])
        out[k] = lap.mean()
    rows.append(out)

base = rows[0]
print('label'.ljust(14) + ''.join(k.rjust(12) for k in REGIONS))
for r in rows:
    print(r['label'].ljust(14) + ''.join(f'{r[k] / base[k]:12.2f}' for k in REGIONS))
print('(relative to ' + base['label'] + '; absolute ' + ', '.join(f'{k} {base[k]:.4f}' for k in REGIONS) + ')')
