"""Where two screenshots differ: mean and 99th percentile of the per-pixel difference (0-255, max of
RGB), the share of pixels over a threshold, the mean brightness of each, and a heat map (difference x4).
    python imgdiff.py <a.png> <b.png> <heat.png>"""
import sys

import numpy as np
from PIL import Image

a = np.asarray(Image.open(sys.argv[1]).convert('RGB')).astype(np.int16)
b = np.asarray(Image.open(sys.argv[2]).convert('RGB')).astype(np.int16)
d = np.abs(a - b).max(axis=2)
print(f'mean {d.mean():.2f}  p99 {np.percentile(d, 99):.0f}  over16 {100 * (d > 16).mean():.2f}%  '
      f'brightness a {a.mean():.1f} b {b.mean():.1f}')
h, w = d.shape
for name, (y0, y1, x0, x1) in {'top': (0, h // 3, 0, w), 'middle': (h // 3, 2 * h // 3, 0, w),
                                'bottom': (2 * h // 3, h, 0, w)}.items():
    print(f'  {name}: mean {d[y0:y1, x0:x1].mean():.2f}, brightness a {a[y0:y1, x0:x1].mean():.1f} b {b[y0:y1, x0:x1].mean():.1f}')
Image.fromarray(np.clip(d * 4, 0, 255).astype(np.uint8)).save(sys.argv[3])
