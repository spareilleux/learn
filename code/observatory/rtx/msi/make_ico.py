"""The installer's icon: the project's own icon (icon.svg, drawn at 512 px by pwa/make_icons.gd) at the sizes
Windows asks a .ico for, from the Start menu's 16 px to Explorer's 256 px.

    py -3.14 make_ico.py <icon-512.png> <out.ico>
"""
import sys

from PIL import Image

SIZES = [(16, 16), (20, 20), (24, 24), (32, 32), (40, 40), (48, 48), (64, 64), (128, 128), (256, 256)]

src, out = sys.argv[1], sys.argv[2]
image = Image.open(src).convert('RGBA')
if image.size != (512, 512):
    sys.exit(f'{src} is {image.size}, not 512 x 512')
image.save(out, format='ICO', sizes=SIZES)
check = Image.open(out)
print('ico', out, sorted(check.info.get('sizes', [])))
