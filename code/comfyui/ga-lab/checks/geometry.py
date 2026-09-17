"""Where GA Fretboard Control Map draws things, read from its `layout` output instead of recomputed here.

The node pack (code/comfyui/custom-nodes/ga, commit 846bd2d) returns a third output, `layout`, a JSON string: the
board rectangle, the x of each fret wire, the y of each string, the note radius, one entry per note (center, string,
fret) and one per inlay. The lab's workflows send it to a PreviewAny node, so it lands in results.json as text.

When no JSON is at hand (the synthetic set, a check run by hand), Layout.compute asks the pack's own
drawing.fretboard_layout, imported without the pack's __init__ (which needs ComfyUI and torch). Either way there is
one source for the geometry; tests/test_geometry.py checks it against the pack's pixels.
"""
import importlib
import json
import os
import sys
import types

STRING_COUNT = 6
GA_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "custom-nodes", "ga"))


def ga_pack():
    """(drawing, theory) modules of the GA node pack, loaded as a package without running its __init__."""
    if "galab_ga_pack" not in sys.modules:
        if not os.path.isfile(os.path.join(GA_DIR, "drawing.py")):
            raise ImportError(f"the GA node pack is not at {GA_DIR}")
        pkg = types.ModuleType("galab_ga_pack")
        pkg.__path__ = [GA_DIR]
        sys.modules["galab_ga_pack"] = pkg
    return importlib.import_module("galab_ga_pack.drawing"), importlib.import_module("galab_ga_pack.theory")


def parse_voicing(text):
    """A voicing (x32010, x-10-12-12-12-10) or a symbol the pack knows -> 6 frets from low E, None when muted."""
    _, theory = ga_pack()
    return theory.resolve_chord(text)[1]


class Layout:
    def __init__(self, data):
        if isinstance(data, str):
            data = json.loads(data)
        self.data = data
        self.width, self.height = data["width"], data["height"]
        self.fret_start, self.fret_end, self.first_wire = data["fret_start"], data["fret_end"], data["first_wire"]
        board = data["board"]
        self.left, self.top, self.right, self.bottom = board["left"], board["top"], board["right"], board["bottom"]
        self.string_gap = data["string_gap"]
        self.radius = data["radius"]
        self._wires = {w["fret"]: w["x"] for w in data["fret_wires"]}
        self._strings = {s["string_index"]: s["y"] for s in data["strings"]}

    @classmethod
    def compute(cls, voicing=None, fret_start=0, fret_end=12, width=1024, height=1024, inlays="show"):
        """The layout the node would output for a chord voicing (or no notes), from the pack's own code."""
        drawing, theory = ga_pack()
        frets = parse_voicing(voicing) if isinstance(voicing, str) else voicing
        positions = theory.voicing_positions(frets) if frets else []
        return cls(drawing.fretboard_layout(positions, fret_start, fret_end, width, height, inlays))

    def wire_x(self, fret):
        return self._wires[fret]

    def wires(self):
        return sorted(self._wires.items())

    def string_y(self, string_index):
        """string_index counts from low E (0) to high E (5); the low E is at the bottom."""
        return self._strings[string_index]

    def note_xy(self, string_index, fret):
        """Where the map puts a note; an open string (fret 0) is left of the nut."""
        for note in self.data["notes"]:
            if note["string_index"] == string_index and note["fret"] == fret:
                return note["x"], note["y"]
        if fret == 0:
            return round(self.left - self.radius * 1.6), self.string_y(string_index)
        raise KeyError(f"no note on string {string_index} fret {fret} in this layout")

    def dots(self, include_open=False):
        """Centers of the notes the map draws, fretted notes only unless include_open."""
        return [(n["x"], n["y"]) for n in self.data["notes"] if include_open or n["fret"] > 0]

    def open_markers(self):
        """Where an open-string note would sit on each string, left of the nut: ignored by the dot check."""
        return [(round(self.left - self.radius * 1.6), self.string_y(s)) for s in range(STRING_COUNT)] \
            if self.fret_start == 0 else []

    def inlays(self):
        """(x, y, r) of the inlay rings the map draws (none when the node ran with inlays=hide)."""
        return [(m["x"], m["y"], m["r"]) for m in self.data["inlays"]]

    def inlay_positions(self):
        """Where inlays are on the neck even if the map hides them: a generated neck may still show inlays there."""
        if self.data["inlays"]:
            return self.inlays()
        full = Layout.compute(None, self.fret_start, self.fret_end, self.width, self.height, "show")
        return full.inlays()
