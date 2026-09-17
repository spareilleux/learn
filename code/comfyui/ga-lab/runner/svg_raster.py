"""Rasterizes the small SVG subset of the music theory course's diagrams with Pillow, without Cairo.

The pitch-class bracelets in src/assets/music-theory-ga use svg, circle, polygon, line and text, colors written
as var(--sl-..., #fallback) or currentColor, and opacity attributes. That subset is drawn here at 4 times the size
and downsampled, for anti-aliased edges. Anything else (path, g, transform) raises, so a new diagram fails loudly.
"""
import re
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw, ImageFont

NS = "{http://www.w3.org/2000/svg}"
NAMED = {"white": (255, 255, 255), "black": (0, 0, 0), "red": (255, 0, 0), "none": None}
SUPERSAMPLE = 4


def parse_color(value, current):
    if value is None:
        return None
    value = value.strip()
    m = re.match(r"var\(\s*--[\w-]+\s*,\s*(.+)\)$", value)
    if m:
        value = m.group(1).strip()
    if value == "currentColor":
        return current
    if value in NAMED:
        return NAMED[value]
    if value.startswith("#"):
        h = value[1:]
        if len(h) == 3:
            h = "".join(c * 2 for c in h)
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    m = re.match(r"rgb\((\d+),\s*(\d+),\s*(\d+)\)", value)
    if m:
        return tuple(int(g) for g in m.groups())
    raise ValueError(f"unsupported color {value!r}")


def attributes(element):
    attrs = dict(element.attrib)
    for part in (attrs.pop("style", "") or "").split(";"):
        if ":" in part:
            k, v = part.split(":", 1)
            attrs.setdefault(k.strip(), v.strip())
            if k.strip() in ("fill", "stroke"):  # style wins over presentation attributes
                attrs[k.strip()] = v.strip()
    return attrs


def blend(color, opacity, background):
    if color is None:
        return None
    return tuple(round(c * opacity + b * (1 - opacity)) for c, b in zip(color, background))


def rasterize(path, size, background=(255, 255, 255), current=(0, 0, 0)):
    """An RGB image of size x size (the viewBox is scaled to fit, centered)."""
    root = ET.parse(path).getroot()
    vb = [float(v) for v in re.split(r"[\s,]+", root.attrib["viewBox"].strip())]
    scale = size * SUPERSAMPLE / max(vb[2], vb[3])
    ox = (size * SUPERSAMPLE - vb[2] * scale) / 2 - vb[0] * scale
    oy = (size * SUPERSAMPLE - vb[3] * scale) / 2 - vb[1] * scale
    big = Image.new("RGB", (size * SUPERSAMPLE, size * SUPERSAMPLE), background)
    draw = ImageDraw.Draw(big)

    def pt(x, y):
        return (ox + float(x) * scale, oy + float(y) * scale)

    for el in root:
        tag = el.tag.replace(NS, "")
        a = attributes(el)
        opacity = float(a.get("opacity", 1))
        fill = blend(parse_color(a.get("fill", "black"), current), opacity * float(a.get("fill-opacity", 1)), background)
        stroke = blend(parse_color(a.get("stroke", "none"), current), opacity * float(a.get("stroke-opacity", 1)), background)
        width = max(1, round(float(a.get("stroke-width", 1)) * scale)) if stroke else 0
        if tag == "circle":
            cx, cy = pt(a["cx"], a["cy"])
            r = float(a["r"]) * scale
            box = [cx - r, cy - r, cx + r, cy + r]
            draw.ellipse(box, fill=fill)
            if stroke:
                draw.ellipse(box, outline=stroke, width=width)
        elif tag in ("polygon", "polyline"):
            nums = [float(n) for n in re.split(r"[\s,]+", a["points"].strip())]
            points = [pt(nums[i], nums[i + 1]) for i in range(0, len(nums), 2)]
            if tag == "polygon" and fill:
                draw.polygon(points, fill=fill)
            if stroke:
                draw.line(points + ([points[0]] if tag == "polygon" else []), fill=stroke, width=width, joint="curve")
        elif tag == "line":
            draw.line([pt(a["x1"], a["y1"]), pt(a["x2"], a["y2"])], fill=stroke or fill, width=width or 1)
        elif tag == "rect":
            x, y = pt(a.get("x", 0), a.get("y", 0))
            draw.rectangle([x, y, x + float(a["width"]) * scale, y + float(a["height"]) * scale], fill=fill,
                           outline=stroke, width=width)
        elif tag == "text":
            try:
                f = ImageFont.load_default(size=float(a.get("font-size", 12)) * scale)
            except TypeError:
                f = ImageFont.load_default()
            anchor = {"middle": "m", "end": "r"}.get(a.get("text-anchor"), "l") + \
                ("m" if a.get("dominant-baseline") == "central" else "s")
            draw.text(pt(a["x"], a["y"]), el.text or "", fill=fill, font=f, anchor=anchor)
        elif tag in ("title", "desc"):
            continue
        else:
            raise ValueError(f"{path}: unsupported SVG element <{tag}>")
    return big.resize((size, size), Image.LANCZOS)


def circles(path):
    """(cx, cy, r, filled) of each circle in viewBox units: filled when its fill isn't the background."""
    root = ET.parse(path).getroot()
    result = []
    for el in root:
        if el.tag.replace(NS, "") == "circle":
            a = attributes(el)
            fill = parse_color(a.get("fill", "black"), (0, 0, 0))
            result.append((float(a["cx"]), float(a["cy"]), float(a["r"]), fill not in (None, (255, 255, 255))))
    return result
