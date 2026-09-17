"""The three GA nodes, in ComfyUI's V1 node format: INPUT_TYPES, RETURN_TYPES, FUNCTION and CATEGORY.

Nothing here runs at import except definitions: no network, no subprocess, no pip install, no model download.
An IMAGE in ComfyUI is a float32 tensor of shape [batch, height, width, 3] with values in 0..1, as LoadImage builds
it in ComfyUI's nodes.py.
"""

import numpy as np

from . import drawing, theory

CATEGORY = "Guitar Alchemist"


def to_image(*images):
    """Pillow RGB images of one size -> a ComfyUI IMAGE batch (a NumPy array when PyTorch is absent, in tests)."""
    batch = np.stack([np.asarray(img.convert("RGB"), dtype=np.float32) / 255.0 for img in images])
    try:
        import torch
    except ImportError:
        return batch
    return torch.from_numpy(batch)


class GAChordDiagram:
    """A chord chart for a voicing (x32010, low E first) or a known symbol (C, Am, G7, Bm7b5...)."""

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "chord": ("STRING", {"default": "x32010", "multiline": False}),
                "size": ("INT", {"default": 512, "min": 128, "max": 2048, "step": 8}),
            }
        }

    RETURN_TYPES = ("IMAGE", "STRING")
    RETURN_NAMES = ("image", "ga_diagram")
    FUNCTION = "draw"
    CATEGORY = CATEGORY
    DESCRIPTION = "Draws a chord diagram. ga_diagram is the same voicing in GA's order, high E first."

    def draw(self, chord, size):
        _, frets = theory.resolve_chord(chord)
        return (to_image(drawing.chord_diagram(frets, size)), theory.ga_diagram(frets))


class GAFretboardControlMap:
    """A fretboard with the notes of a chord or a mode, as a line map and a depth-like map for ControlNet."""

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "source": (["chord", "scale"], {"default": "chord"}),
                "chord": ("STRING", {"default": "x32010"}),
                "key": (list(theory.KEYS), {"default": "C"}),
                "mode": (list(theory.MODES), {"default": "Ionian"}),
                "fret_start": ("INT", {"default": 0, "min": 0, "max": theory.MAX_FRET - 1}),
                "fret_end": ("INT", {"default": 12, "min": 1, "max": theory.MAX_FRET}),
                "width": ("INT", {"default": 1024, "min": 256, "max": 2048, "step": 8}),
                "height": ("INT", {"default": 1024, "min": 256, "max": 2048, "step": 8}),
                "line_width": ("INT", {"default": 4, "min": 1, "max": 16}),
            }
        }

    RETURN_TYPES = ("IMAGE", "IMAGE")
    RETURN_NAMES = ("lines", "depth")
    FUNCTION = "draw"
    CATEGORY = CATEGORY
    DESCRIPTION = "White edges on black for a canny or lineart ControlNet, and a depth-like map (nearer is brighter)."

    def draw(self, source, chord, key, mode, fret_start, fret_end, width, height, line_width):
        if source == "chord":
            positions = theory.voicing_positions(theory.resolve_chord(chord)[1])
        else:
            positions = theory.scale_positions(key, mode, fret_start, fret_end)
        lines, depth = drawing.fretboard_maps(positions, fret_start, fret_end, width, height, line_width)
        return (to_image(lines), to_image(depth))


class GAScalePrompt:
    """A prompt fragment for a key and a mode, the same text every time."""

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "key": (list(theory.KEYS), {"default": "C"}),
                "mode": (list(theory.MODES), {"default": "Dorian"}),
                "subject": ("STRING", {"default": "abstract album cover", "multiline": True}),
            }
        }

    RETURN_TYPES = ("STRING",)
    RETURN_NAMES = ("prompt",)
    FUNCTION = "build"
    CATEGORY = CATEGORY

    def build(self, key, mode, subject):
        return (theory.scale_prompt(key, mode, subject),)


NODE_CLASS_MAPPINGS = {
    "GAChordDiagram": GAChordDiagram,
    "GAFretboardControlMap": GAFretboardControlMap,
    "GAScalePrompt": GAScalePrompt,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "GAChordDiagram": "GA Chord Diagram",
    "GAFretboardControlMap": "GA Fretboard Control Map",
    "GAScalePrompt": "GA Scale Prompt",
}
