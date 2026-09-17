"""Chord diagrams and fretboard control maps drawn with Pillow, without fonts or anti-aliasing.

Pillow's ImageDraw draws lines, rectangles and ellipses without anti-aliasing, and the only digits are drawn from a
3x5 grid below, so the pixels depend on the inputs and on Pillow, not on the fonts installed on a machine.
"""

from PIL import Image, ImageDraw

from . import theory

# 3x5 digits, one string per row, for the fret number next to a diagram.
_DIGITS = {
    "0": ("###", "#.#", "#.#", "#.#", "###"),
    "1": (".#.", "##.", ".#.", ".#.", "###"),
    "2": ("###", "..#", "###", "#..", "###"),
    "3": ("###", "..#", "###", "..#", "###"),
    "4": ("#.#", "#.#", "###", "..#", "..#"),
    "5": ("###", "#..", "###", "..#", "###"),
    "6": ("###", "#..", "###", "#.#", "###"),
    "7": ("###", "..#", "..#", "..#", "..#"),
    "8": ("###", "#.#", "###", "#.#", "###"),
    "9": ("###", "#.#", "###", "..#", "###"),
}

# Inlay markers of a guitar neck; 12 and 24 have two.
INLAYS = (3, 5, 7, 9, 12, 15, 17, 19, 21, 24)


def _draw_number(draw, number, x, y, cell, fill):
    for i, ch in enumerate(str(number)):
        for row, pattern in enumerate(_DIGITS[ch]):
            for col, bit in enumerate(pattern):
                if bit == "#":
                    left = x + (i * 4 + col) * cell
                    top = y + row * cell
                    draw.rectangle([left, top, left + cell - 1, top + cell - 1], fill=fill)


def chord_diagram(frets, size=512, frets_shown=5):
    """A chord chart: string 6 (low E) on the left, the nut at the top, black on white, size x size pixels."""
    ink, paper = (0, 0, 0), (255, 255, 255)
    image = Image.new("RGB", (size, size), paper)
    draw = ImageDraw.Draw(image)

    fretted = [f for f in frets if f is not None and f > 0]
    base = 1 if not fretted or max(fretted) <= frets_shown else min(fretted)

    left, right = round(size * 0.22), round(size * 0.86)
    top, bottom = round(size * 0.22), round(size * 0.92)
    string_gap = (right - left) / (theory.STRING_COUNT - 1)
    fret_gap = (bottom - top) / frets_shown
    line = max(1, size // 160)
    radius = round(min(string_gap, fret_gap) * 0.32)

    for s in range(theory.STRING_COUNT):
        x = round(left + s * string_gap)
        draw.rectangle([x - line // 2, top, x - line // 2 + line - 1, bottom], fill=ink)
    for i in range(frets_shown + 1):
        y = round(top + i * fret_gap)
        thickness = line * 4 if i == 0 and base == 1 else line
        draw.rectangle([left, y - thickness + 1, right + line - 1, y], fill=ink)
    if base > 1:
        cell = max(2, size // 64)
        _draw_number(draw, base, round(size * 0.04), round(top + fret_gap / 2 - 2.5 * cell), cell, ink)

    marker_y = round(top - fret_gap * 0.55)
    for s, fret in enumerate(frets):
        x = round(left + s * string_gap)
        if fret is None:
            r = radius
            draw.line([x - r, marker_y - r, x + r, marker_y + r], fill=ink, width=line * 2)
            draw.line([x - r, marker_y + r, x + r, marker_y - r], fill=ink, width=line * 2)
        elif fret == 0:
            draw.ellipse([x - radius, marker_y - radius, x + radius, marker_y + radius], outline=ink, width=line * 2)
        else:
            y = round(top + (fret - base + 0.5) * fret_gap)
            draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=ink)
    return image


def fret_x(fret, fret_start, fret_end, left, right):
    """Horizontal position of a fret wire, spaced like a real neck: a fret n sits at 1 - 2^(-n/12) of the scale."""
    def distance(n):
        return 1 - 2 ** (-n / 12)
    span = distance(fret_end) - distance(fret_start)
    return left + (distance(fret) - distance(fret_start)) / span * (right - left)


def fretboard_layout(positions, fret_start=0, fret_end=12, width=1024, height=1024, inlays="show"):
    """Where fretboard_maps draws the board, the strings, the notes and the inlays, in pixels, without drawing.

    Returns a dict that json.dumps can write: the board rectangle, the x of each fret wire, the y of each string,
    the note radius, one entry per note shown and one per inlay marker (none when inlays is "hide"). In notes and
    strings, "string" counts from the high E (1) to the low E (6) and "string_index" from the low E (0), like the
    positions. Notes outside fret_start..fret_end are left out; open strings (fret 0) sit left of the nut.
    """
    if not 0 <= fret_start < fret_end <= theory.MAX_FRET:
        raise ValueError(f"need 0 <= fret_start < fret_end <= {theory.MAX_FRET}, got {fret_start} and {fret_end}")
    if inlays not in ("show", "hide"):
        raise ValueError(f"inlays must be 'show' or 'hide', got {inlays!r}")
    first_wire = max(fret_start - 1, 0)
    board_left, board_right = round(width * 0.10), round(width * 0.96)
    neck_height = min(height * 0.6, (board_right - board_left) / (fret_end - first_wire) * 2.4)
    board_top = round(height / 2 - neck_height / 2)
    board_bottom = round(height / 2 + neck_height / 2)
    string_gap = (board_bottom - board_top) / theory.STRING_COUNT

    def wire(fret):
        return fret_x(fret, first_wire, fret_end, board_left, board_right)

    radius = round(min(string_gap, wire(fret_end) - wire(fret_end - 1)) * 0.3)

    def string_y(s):  # s counts from low E; the low E is at the bottom
        return round(board_bottom - (s + 0.5) * string_gap)

    def fret_center(fret):
        return round((wire(fret - 1) + wire(fret)) / 2)

    markers = []
    if inlays == "show":
        for fret in INLAYS:
            if first_wire < fret <= fret_end:
                if fret % 12 == 0:  # 12 and 24 have two markers
                    ys = [round(board_top + 2 * string_gap), round(board_bottom - 2 * string_gap)]
                else:
                    ys = [round((board_top + board_bottom) / 2)]
                markers.extend({"fret": fret, "x": fret_center(fret), "y": y, "r": max(2, radius // 2)} for y in ys)
    notes = []
    for s, fret in positions:
        if not fret_start <= fret <= fret_end:
            continue
        x = round(board_left - radius * 1.6) if fret == 0 else fret_center(fret)
        notes.append({"string": theory.STRING_COUNT - s, "string_index": s, "fret": fret, "x": x, "y": string_y(s),
                      "r": radius})
    return {
        "width": width, "height": height, "fret_start": fret_start, "fret_end": fret_end, "first_wire": first_wire,
        "board": {"left": board_left, "top": board_top, "right": board_right, "bottom": board_bottom},
        "string_gap": string_gap,
        "fret_wires": [{"fret": f, "x": round(wire(f))} for f in range(first_wire, fret_end + 1)],
        "strings": [{"string": theory.STRING_COUNT - s, "string_index": s, "y": string_y(s)}
                    for s in range(theory.STRING_COUNT)],
        "radius": radius,
        "notes": notes,
        "inlays": markers,
    }


def fretboard_maps(positions, fret_start=0, fret_end=12, width=1024, height=1024, line_width=4, note_style="ring",
                   inlays="show"):
    """A neck seen from the front, headstock on the left, high E at the top (like tablature).

    Returns two RGB images of width x height:
    - lines: white edges on black, like the output of a Canny node, for a canny/lineart ControlNet;
    - depth: nearer is brighter (background black, fingerboard grey, strings lighter, notes white), for a depth
      ControlNet.
    positions are (string index from low E, fret) pairs; none (the voicing xxxxxx) draws an empty neck. The frets
    fret_start to fret_end are shown: with fret_start 0 the board starts at the nut and open strings are drawn left
    of it, otherwise it starts at the fret wire before fret_start.
    note_style "ring" draws each note on the lines map as a black disc with a white outline, "filled" as a plain
    white disc. inlays "hide" leaves the inlay rings out. Every coordinate comes from fretboard_layout.
    """
    if note_style not in ("ring", "filled"):
        raise ValueError(f"note_style must be 'ring' or 'filled', got {note_style!r}")
    layout = fretboard_layout(positions, fret_start, fret_end, width, height, inlays)
    lines = Image.new("RGB", (width, height), (0, 0, 0))
    depth = Image.new("RGB", (width, height), (0, 0, 0))
    ld, dd = ImageDraw.Draw(lines), ImageDraw.Draw(depth)
    white = (255, 255, 255)
    board = layout["board"]
    board_left, board_top, board_right, board_bottom = board["left"], board["top"], board["right"], board["bottom"]

    dd.rectangle([board_left, board_top, board_right, board_bottom], fill=(96, 96, 96))
    ld.rectangle([board_left, board_top, board_right, board_bottom], outline=white, width=line_width)

    for wire in layout["fret_wires"]:
        x = wire["x"]
        w = line_width * 3 if wire["fret"] == 0 else line_width
        ld.rectangle([x - w // 2, board_top, x - w // 2 + w - 1, board_bottom], fill=white)
        dd.rectangle([x - w // 2, board_top, x - w // 2 + w - 1, board_bottom], fill=(150, 150, 150))
    for marker in layout["inlays"]:
        x, y, r = marker["x"], marker["y"], marker["r"]
        ld.ellipse([x - r, y - r, x + r, y + r], outline=white, width=max(1, line_width // 2))
    for string in layout["strings"]:
        s, y = string["string_index"], string["y"]
        w = max(1, line_width // 2 + (theory.STRING_COUNT - 1 - s) // 2)  # low strings are thicker
        ld.rectangle([board_left, y - w // 2, board_right, y - w // 2 + w - 1], fill=white)
        dd.rectangle([board_left, y - w // 2, board_right, y - w // 2 + w - 1], fill=(190, 190, 190))

    for note in layout["notes"]:
        x, y, r = note["x"], note["y"], note["r"]
        if note_style == "ring":
            ld.ellipse([x - r, y - r, x + r, y + r], fill=(0, 0, 0), outline=white, width=line_width)
        else:
            ld.ellipse([x - r, y - r, x + r, y + r], fill=white)
        dd.ellipse([x - r, y - r, x + r, y + r], fill=white)
    return lines, depth
