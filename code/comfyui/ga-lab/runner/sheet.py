"""WebP thumbnails and a labelled contact sheet, with Pillow."""
import math
import os

from PIL import Image, ImageDraw, ImageFont, ImageStat

THUMB = 256
CELL = 256
LABEL_H = 44


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:  # Pillow < 10.1
        return ImageFont.load_default()


def first_frame(path):
    with Image.open(path) as image:
        image.seek(0)
        return image.convert("RGB")


def image_stats(path):
    """Size, frame count, mean luma and mean saturation (0-255), for predictions about brightness or color."""
    with Image.open(path) as image:
        frames = getattr(image, "n_frames", 1)
    rgb = first_frame(path)
    luma = ImageStat.Stat(rgb.convert("L")).mean[0]
    saturation = ImageStat.Stat(rgb.convert("HSV").getchannel("S")).mean[0]
    return {"width": rgb.width, "height": rgb.height, "frames": frames,
            "mean_luma": round(luma, 2), "mean_saturation": round(saturation, 2)}


def thumbnail(src, dst, size=THUMB):
    image = first_frame(src)
    image.thumbnail((size, size), Image.LANCZOS)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    image.save(dst, "WEBP", quality=80, method=6)
    return dst


def _wrap(draw, text, width, f):
    words, lines, line = text.split(), [], ""
    for w in words:
        trial = (line + " " + w).strip()
        if draw.textlength(trial, font=f) <= width or not line:
            line = trial
        else:
            lines.append(line)
            line = w
    if line:
        lines.append(line)
    return lines


def contact_sheet(results, out_dir, dst, columns=None):
    """One cell per item and output: the thumbnail and its labels; items that could not run show their reason."""
    cells = []
    for item in results["items"]:
        label = ", ".join(f"{k}={v}" for k, v in item["labels"].items())
        label = (label + f", seed={item['seed']}").lstrip(", ")
        if item.get("status") == "done" and item.get("outputs"):
            for out in item["outputs"]:
                if out.get("thumb"):
                    cells.append((os.path.join(out_dir, out["thumb"]), label, None))
        else:
            reason = item.get("status", "pending")
            if item.get("error"):
                reason += ": " + item["error"]
            cells.append((None, label, reason))
    if not cells:
        return None
    if columns is None:
        axes = results.get("axes") or []
        last = len(axes[-1]["values"]) if axes else 0
        columns = last if 2 <= last <= 8 else min(8, math.ceil(math.sqrt(len(cells))))
    rows = math.ceil(len(cells) / columns)
    header = 56
    sheet = Image.new("RGB", (columns * CELL, header + rows * (CELL + LABEL_H)), (250, 250, 247))
    draw = ImageDraw.Draw(sheet)
    small, title = font(13), font(18)
    draw.text((8, 6), f"{results['experiment']['id']}: {results['experiment']['title']}"[:140], fill=(20, 20, 20), font=title)
    server = results.get("server") or {}
    note = f"ComfyUI {server.get('comfyui_version', '?')} ({(server.get('comfyui_commit') or '?')[:7]}), " \
           f"generated images, see results.json for models and seeds"
    draw.text((8, 32), note, fill=(90, 90, 90), font=small)
    for i, (thumb, label, reason) in enumerate(cells):
        x, y = (i % columns) * CELL, header + (i // columns) * (CELL + LABEL_H)
        if thumb and os.path.isfile(thumb):
            image = first_frame(thumb)
            sheet.paste(image, (x + (CELL - image.width) // 2, y + (CELL - image.height) // 2))
        else:
            draw.rectangle([x + 4, y + 4, x + CELL - 5, y + CELL - 5], fill=(225, 225, 225))
            for j, line in enumerate(_wrap(draw, reason or "", CELL - 20, small)[:10]):
                draw.text((x + 10, y + 10 + j * 16), line, fill=(120, 30, 30), font=small)
        for j, line in enumerate(_wrap(draw, label, CELL - 8, small)[:2]):
            draw.text((x + 4, y + CELL + 4 + j * 16), line, fill=(30, 30, 30), font=small)
    os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
    sheet.save(dst, "WEBP", quality=78, method=6)
    return dst
