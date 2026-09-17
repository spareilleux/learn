"""Guitar theory for the GA nodes, computed locally: no network, no Guitar Alchemist server.

The data comes from Guitar Alchemist's source at a pinned commit (GA_SHA):
- the tuning, Tuning.Default = "E2 A2 D3 G3 B3 E4" (Common/GA.Domain.Core/Instruments/Tuning.cs#L23), which GA
  stores highest string first (Tuning.cs#L86-L109), string 1 being "the first string (Highest pitch)"
  (Common/GA.Domain.Core/Instruments/Primitives/Str.cs#L35-L43);
- the major scale, Scale.Major = "C D E F G A B" (Common/GA.Domain.Core/Theory/Tonal/Scales/Scale.cs#L53), and the
  names of its modes, MajorScaleDegree.ToName (Common/GA.Domain.Core/Theory/Tonal/Primitives/Diatonic/
  MajorScaleDegree.cs#L52-L62);
- chord formulas in semitones above the root, like ChordFormula.FromSemitones
  (Common/GA.Domain.Core/Theory/Harmony/ChordFormula.cs#L121-L137).

Voicings are written like chord charts, low E first ("x32010"); GA's Voicing.Diagram is high E first ("0-1-0-2-3-x").
"""

import re

GA_SHA = "a826864f3a012cad88e415954bf57eca0ce12aa6"

# MIDI numbers of the open strings, low E (string 6) first: E2 A2 D3 G3 B3 E4.
STANDARD_TUNING = (40, 45, 50, 55, 59, 64)
STRING_COUNT = len(STANDARD_TUNING)
MAX_FRET = 24

LETTERS = "CDEFGAB"
NATURAL_PITCH_CLASS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
MAJOR_SCALE = (0, 2, 4, 5, 7, 9, 11)  # C D E F G A B
MODES = ("Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian")
KEYS = ("C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B")

# How each mode differs from the major or the natural minor scale: plain words for a prompt.
MODE_CHARACTER = {
    "Ionian": "major, bright and settled",
    "Dorian": "minor with a raised sixth, warm",
    "Phrygian": "minor with a lowered second, dark and tense",
    "Lydian": "major with a raised fourth, floating",
    "Mixolydian": "major with a lowered seventh, bluesy",
    "Aeolian": "natural minor, melancholic",
    "Locrian": "diminished, unstable",
}

# Chord formulas in semitones above the root.
CHORD_FORMULAS = {
    "": (0, 4, 7),
    "m": (0, 3, 7),
    "7": (0, 4, 7, 10),
    "maj7": (0, 4, 7, 11),
    "m7": (0, 3, 7, 10),
    "m7b5": (0, 3, 6, 10),
}

# Common shapes, low E first. tests/test_ga.py checks that each one plays exactly the notes of its symbol.
CHORD_SHAPES = {
    "C": "x32010",
    "D": "xx0232",
    "E": "022100",
    "F": "133211",
    "G": "320003",
    "A": "x02220",
    "Am": "x02210",
    "Dm": "xx0231",
    "Em": "022000",
    "E7": "020100",
    "G7": "320001",
    "Cmaj7": "x32000",
    "Dm7": "xx0211",
    "Bm7b5": "x2323x",
}

_COMPACT = re.compile(r"^[xX0-9]{6}$")
_SEPARATED = re.compile(r"^[xX0-9]+([\s,-]+[xX0-9]+){5}$")
_SYMBOL = re.compile(r"^([A-G])([#b]?)(maj7|m7b5|m7|m|7)?$")


def parse_voicing(text):
    """'x32010' or 'x-10-12-12-12-10' -> a tuple of 6 frets, low E first, None for a muted string."""
    text = text.strip()
    if _COMPACT.match(text):
        parts = list(text)
    elif _SEPARATED.match(text):
        parts = re.split(r"[\s,-]+", text)
    else:
        raise ValueError(f"not a voicing: {text!r} (expected 6 frets from low E, like x32010 or x-10-12-12-12-10)")
    frets = []
    for part in parts:
        if part in ("x", "X"):
            frets.append(None)
        else:
            fret = int(part)
            if fret > MAX_FRET:
                raise ValueError(f"fret {fret} is above {MAX_FRET}")
            frets.append(fret)
    return tuple(frets)


def resolve_chord(text):
    """A voicing, or a symbol from CHORD_SHAPES -> (symbol or '', frets)."""
    text = text.strip()
    if text in CHORD_SHAPES:
        return text, parse_voicing(CHORD_SHAPES[text])
    try:
        return "", parse_voicing(text)
    except ValueError:
        known = " ".join(CHORD_SHAPES)
        raise ValueError(f"unknown chord {text!r}: write a voicing like x32010, or one of {known}") from None


def ga_diagram(frets):
    """The same voicing in GA's order, high E first, like Voicing.Diagram: x32010 -> 0-1-0-2-3-x."""
    return "-".join("x" if f is None else str(f) for f in reversed(frets))


def pitch_classes(frets, tuning=STANDARD_TUNING):
    """The set of pitch classes (0 = C) a voicing plays."""
    return {(open_note + fret) % 12 for open_note, fret in zip(tuning, frets) if fret is not None}


def key_pitch_class(key):
    pc = NATURAL_PITCH_CLASS[key[0]]
    for accidental in key[1:]:
        pc += 1 if accidental == "#" else -1
    return pc % 12


def symbol_pitch_classes(symbol):
    """'Bm7b5' -> {11, 2, 5, 9}."""
    match = _SYMBOL.match(symbol)
    if not match:
        raise ValueError(f"not a chord symbol: {symbol!r}")
    root = key_pitch_class(match.group(1) + match.group(2))
    return {(root + step) % 12 for step in CHORD_FORMULAS[match.group(3) or ""]}


def mode_steps(mode):
    """Semitones above the tonic: the major scale rotated to start on the mode's degree."""
    degree = MODES.index(mode)
    rotated = MAJOR_SCALE[degree:] + tuple(s + 12 for s in MAJOR_SCALE[:degree])
    return tuple(s - rotated[0] for s in rotated)


def spell_mode(key, mode):
    """'C', 'Dorian' -> ['C', 'D', 'Eb', 'F', 'G', 'A', 'Bb']: one letter per degree, then its accidental."""
    if key not in KEYS:
        raise ValueError(f"unknown key {key!r}")
    tonic = key_pitch_class(key)
    first_letter = LETTERS.index(key[0])
    notes = []
    for i, step in enumerate(mode_steps(mode)):
        letter = LETTERS[(first_letter + i) % 7]
        offset = (tonic + step - NATURAL_PITCH_CLASS[letter]) % 12
        if offset > 6:
            offset -= 12
        notes.append(letter + ("#" * offset if offset >= 0 else "b" * -offset))
    return notes


def mode_pitch_classes(key, mode):
    tonic = key_pitch_class(key)
    return {(tonic + step) % 12 for step in mode_steps(mode)}


def scale_positions(key, mode, fret_start, fret_end, tuning=STANDARD_TUNING):
    """Every (string index from low E, fret) between two frets whose note is in the mode."""
    wanted = mode_pitch_classes(key, mode)
    return [(s, f) for s, open_note in enumerate(tuning)
            for f in range(fret_start, fret_end + 1) if (open_note + f) % 12 in wanted]


def voicing_positions(frets):
    return [(s, f) for s, f in enumerate(frets) if f is not None]


def scale_prompt(key, mode, subject=""):
    """A deterministic prompt fragment for a key and a mode."""
    notes = " ".join(spell_mode(key, mode))
    fragment = f"inspired by the {key} {mode} mode ({notes}), {MODE_CHARACTER[mode]} mood"
    subject = subject.strip()
    return f"{subject}, {fragment}" if subject else fragment
