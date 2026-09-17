"""Build the bracelets, measure them, write the files.

    python mesh/run.py --set "C major-triad" --bead both --out G:/learn-lab/ga-protos/p5
    python mesh/run.py --suite --out G:/learn-lab/ga-protos/p5 --results results/measurements.json

The meshes themselves never enter the repository: they go to ``--out``, outside it. What comes back is the JSON of
measurements, which is small and is what the lesson quotes.
"""

from __future__ import annotations

import argparse
import json
import math
import platform
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import trimesh  # noqa: E402

from bracelet import BEAD_SHAPES, HEIGHT, INNER_DIAMETER, SEGMENTS, WALL, Bracelet, position_angle  # noqa: E402
from measure import measure_all  # noqa: E402
from sets import resolve, spell  # noqa: E402

# The thirteen qualities prototype 2 recognizes, on C, plus two scales: the suite the lesson quotes.
SUITE = [f"C {q}" for q in (
    "major-triad", "minor-triad", "diminished-triad", "augmented-triad", "sus2", "sus4",
    "major-6", "dominant-7", "major-7", "minor-7", "half-diminished-7", "diminished-7", "add-9",
)] + ["C Major", "A Minor.Natural"]

POSITIONS_DEG = [math.degrees(position_angle(pc)) % 360.0 for pc in range(12)]


def build_one(name: str, bead: str, out: Path | None, naive: bool) -> dict:
    started = time.perf_counter()
    pcs = resolve(name)
    bracelet = Bracelet(name=name, pitch_classes=pcs, bead_shape=bead)
    solid = bracelet.solid()
    built = time.perf_counter() - started
    record = {
        "name": name,
        "pitch_classes": list(pcs),
        "notes": spell(pcs),
        "bead": bead,
        "build_s": round(built, 3),
        "union": measure_all(solid, POSITIONS_DEG),
    }
    if naive:
        record["naive"] = measure_all(bracelet.naive(), POSITIONS_DEG)
    if out is not None:
        out.mkdir(parents=True, exist_ok=True)
        stem = f"{name.replace(' ', '-').replace('.', '-')}-{bead}"
        stl = out / f"{stem}.stl"
        solid.export(stl)
        record["stl"] = {"path": str(stl), "bytes": stl.stat().st_size}
        threemf = out / f"{stem}.3mf"
        try:
            trimesh.Scene(solid).export(threemf)
            record["3mf"] = {"path": str(threemf), "bytes": threemf.stat().st_size}
        except Exception as exc:  # noqa: BLE001 - reported, not raised
            record["3mf"] = {"error": f"{type(exc).__name__}: {exc}"}
        if naive:
            naive_stl = out / f"{stem}-naive.stl"
            bracelet.naive().export(naive_stl)
            record["naive_stl"] = {"path": str(naive_stl), "bytes": naive_stl.stat().st_size}
    return record


def build_band(out: Path | None) -> dict:
    """The band with nothing on it: the control the slicer's extrusion widths are compared against."""
    from bracelet import _band  # noqa: PLC0415 - only this one run needs the bare band

    band = _band()
    record = {"name": "plain band", "pitch_classes": [], "notes": "", "bead": "none", "build_s": 0.0,
              "union": measure_all(band, POSITIONS_DEG)}
    if out is not None:
        out.mkdir(parents=True, exist_ok=True)
        stl = out / "plain-band.stl"
        band.export(stl)
        record["stl"] = {"path": str(stl), "bytes": stl.stat().st_size}
    return record


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--set", action="append", default=[], help="a bracelet, named '<root> <ga id>'")
    parser.add_argument("--band", action="store_true", help="also build the bare band, with no bead, rib or keel")
    parser.add_argument("--suite", action="store_true", help="the 13 chord qualities on C, plus C major and A natural minor")
    parser.add_argument("--bead", choices=[*BEAD_SHAPES, "both"], default="cone")
    parser.add_argument("--out", type=Path, default=None, help="where the .stl and .3mf go; outside the repository")
    parser.add_argument("--results", type=Path, default=None, help="where the measurements go")
    parser.add_argument("--naive", action="store_true", help="also measure the parts simply concatenated, with no boolean")
    parser.add_argument("--keel-chamfer", type=float, default=None, help="height of the keel's end ramps, in mm; 0 is the shipped design")
    args = parser.parse_args()

    if args.keel_chamfer is not None:
        import bracelet as bracelet_module

        bracelet_module.KEEL_CHAMFER = args.keel_chamfer

    names = list(args.set) + (SUITE if args.suite else [])
    if not names and not args.band:
        parser.error("give --set, --suite or --band")
    beads = list(BEAD_SHAPES) if args.bead == "both" else [args.bead]

    started = time.perf_counter()
    records = [build_one(name, bead, args.out, args.naive) for name in names for bead in beads]
    if args.band:
        records.append(build_band(args.out))
    elapsed = time.perf_counter() - started

    report = {
        "design": {
            "inner_diameter_mm": INNER_DIAMETER,
            "wall_mm": WALL,
            "height_mm": HEIGHT,
            "segments": SEGMENTS,
            "keel_chamfer_mm": __import__("bracelet").KEEL_CHAMFER,
            "positions_deg": [round(a, 3) for a in POSITIONS_DEG],
        },
        "machine": {"python": platform.python_version(), "platform": platform.platform(), "trimesh": trimesh.__version__},
        "total_s": round(elapsed, 2),
        "bracelets": records,
    }
    text = json.dumps(report, indent=2)
    if args.results:
        args.results.parent.mkdir(parents=True, exist_ok=True)
        args.results.write_text(text + "\n", encoding="utf-8")
    else:
        print(text)
    for r in records:
        t = r["union"]["topology"]
        print(
            f"{r['name']:24s} {r['bead']:6s} {r['notes']:22s} watertight={t['watertight']} bodies={t['bodies']} "
            f"faces={t['faces']} vol={r['union']['solidity']['volume_cm3']} cm3 "
            f"overhang={r['union']['overhangs']['steep_fraction'] * 100:.2f} %",
            file=sys.stderr,
        )
    print(f"{len(records)} bracelets in {elapsed:.1f} s", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
