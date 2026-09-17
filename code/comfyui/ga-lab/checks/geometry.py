"""Where GA Fretboard Control Map draws things, computed without drawing.

This mirrors the layout of code/comfyui/custom-nodes/ga/drawing.py (fretboard_maps), written by the custom node
lane: neck horizontal, headstock left, high E on top, frets spaced like a real neck. tests/test_geometry.py
renders the node's map and checks these coordinates against its pixels, so a change there fails here.
"""
import re

STRING_COUNT = 6
INLAYS = (3, 5, 7, 9, 12, 15, 17, 19, 21, 24)
SHAPES = {  # the symbols GA Fretboard Control Map accepts, low E first (custom-nodes/ga/theory.py CHORD_SHAPES)
    "C": "x32010", "D": "xx0232", "E": "022100", "F": "133211", "G": "320003", "A": "x02220", "Am": "x02210",
    "Dm": "xx0231", "Em": "022000", "E7": "020100", "G7": "320001", "Cmaj7": "x32000", "Dm7": "xx0211",
    "Bm7b5": "x2323x",
}


def parse_voicing(text):
    text = SHAPES.get(text.strip(), text.strip())
    parts = list(text) if re.fullmatch(r"[xX0-9]{6}", text) else re.split(r"[\s,-]+", text)
    if len(parts) != STRING_COUNT:
        raise ValueError(f"not a voicing: {text!r}")
    return tuple(None if p in ("x", "X") else int(p) for p in parts)


def fret_x(fret, fret_start, fret_end, left, right):
    def distance(n):
        return 1 - 2 ** (-n / 12)
    span = distance(fret_end) - distance(fret_start)
    return left + (distance(fret) - distance(fret_start)) / span * (right - left)


class Layout:
    def __init__(self, fret_start=0, fret_end=12, width=1024, height=1024):
        self.fret_start, self.fret_end, self.width, self.height = fret_start, fret_end, width, height
        self.first_wire = max(fret_start - 1, 0)
        self.left, self.right = round(width * 0.10), round(width * 0.96)
        neck_height = min(height * 0.6, (self.right - self.left) / (fret_end - self.first_wire) * 2.4)
        self.top = round(height / 2 - neck_height / 2)
        self.bottom = round(height / 2 + neck_height / 2)
        self.string_gap = (self.bottom - self.top) / STRING_COUNT
        gap_min = self.wire_x(fret_end) - self.wire_x(fret_end - 1)
        self.radius = round(min(self.string_gap, gap_min) * 0.3)

    def wire_x(self, fret):
        return fret_x(fret, self.first_wire, self.fret_end, self.left, self.right)

    def string_y(self, s):
        """s counts from low E (0) to high E (5); the low E is at the bottom."""
        return round(self.bottom - (s + 0.5) * self.string_gap)

    def note_xy(self, string, fret):
        if fret == 0:
            x = round(self.left - self.radius * 1.6)
        else:
            x = round((self.wire_x(fret - 1) + self.wire_x(fret)) / 2)
        return x, self.string_y(string)

    def dots(self, voicing, include_open=False):
        """Centers of the notes of a voicing, as the map draws them (open strings are left of the nut)."""
        frets = parse_voicing(voicing) if isinstance(voicing, str) else voicing
        result = []
        for s, f in enumerate(frets):
            if f is None or not self.fret_start <= f <= self.fret_end or (f == 0 and not include_open):
                continue
            result.append(self.note_xy(s, f))
        return result

    def inlays(self):
        """(x, y, r) of the inlay rings the map draws; fret 12 and 24 have two."""
        result = []
        for fret in INLAYS:
            if self.first_wire < fret <= self.fret_end:
                x = round((self.wire_x(fret - 1) + self.wire_x(fret)) / 2)
                r = max(2, self.radius // 2)
                if fret % 12 == 0:
                    ys = [round(self.top + 2 * self.string_gap), round(self.bottom - 2 * self.string_gap)]
                else:
                    ys = [round((self.top + self.bottom) / 2)]
                result.extend((x, y, r) for y in ys)
        return result
