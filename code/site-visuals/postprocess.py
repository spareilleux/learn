"""Turn the two chosen ComfyUI outputs into the site's WebP assets, with the only two edits made by hand.

    python postprocess.py <folder holding home-20260927.png and ix-20260927.png> <repository root>

- home: the top 48 rows are cropped, which removes a stray "5" the model drew in the dome.
- ix: a 36 x 20 pixel indicator panel at (66, 416) is blurred, which removes three glyph-like marks.
Needs Pillow.
"""
import sys
from pathlib import Path

from PIL import Image, ImageFilter

src, repo = Path(sys.argv[1]), Path(sys.argv[2])

home = Image.open(src / "home-20260927.png").convert("RGB").crop((0, 48, 1344, 768))
home.save(repo / "src/assets/home/research-observatory.webp", "WEBP", quality=82, method=6)

ix = Image.open(src / "ix-20260927.png").convert("RGB")
box, pad = (66, 416, 102, 436), 8
around = ix.crop((box[0] - pad, box[1] - pad, box[2] + pad, box[3] + pad)).filter(ImageFilter.GaussianBlur(4))
ix.paste(around.crop((pad, pad, pad + box[2] - box[0], pad + box[3] - box[1])), box)
ix.save(repo / "src/assets/machine-learning-ix/ix-machine-city.webp", "WEBP", quality=82, method=6)
