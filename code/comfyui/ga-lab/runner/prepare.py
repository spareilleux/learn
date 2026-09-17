"""Input images an experiment makes before its run: every kind is deterministic, so the item hashes are stable.

    {name: bracelet, kind: svg, src: path/to.svg, size: 1024}
    {name: inlays, kind: inlay_mask, fret_start: 0, fret_end: 12, width: 1344, height: 768, scale: 1.8}
        white where GA Fretboard Control Map draws its inlay rings (from the pack's fretboard_layout, grown by
        `scale`), black elsewhere
    {name: photo, kind: file, src: path/to.png}
"""
import os
import shutil

from PIL import Image, ImageDraw

from checks.geometry import Layout
from . import svg_raster
from .experiment import ExperimentError


def prepare(experiment, step, out_dir):
    name, kind = step.get("name"), step.get("kind")
    if not name or not kind:
        raise ExperimentError(f"{experiment.path}: a prepare step needs a name and a kind")
    dst = os.path.join(out_dir, "inputs", f"{experiment.id}-{name}.png")
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if kind == "svg":
        size = int(step.get("size", 1024))
        image = svg_raster.rasterize(experiment.resolve(step["src"]), size)
        image.save(dst, "PNG")
    elif kind == "inlay_mask":
        layout = Layout.compute(None, int(step.get("fret_start", 0)), int(step.get("fret_end", 12)),
                                int(step["width"]), int(step["height"]), "show")
        scale = float(step.get("scale", 1.8))
        mask = Image.new("RGB", (layout.width, layout.height), (0, 0, 0))
        draw = ImageDraw.Draw(mask)
        for x, y, r in layout.inlays():
            rr = max(r * scale, layout.string_gap * 0.45)
            draw.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(255, 255, 255))
        mask.save(dst, "PNG")
    elif kind == "file":
        shutil.copyfile(experiment.resolve(step["src"]), dst)
    else:
        raise ExperimentError(f"{experiment.path}: unknown prepare kind {kind!r}")
    return dst
