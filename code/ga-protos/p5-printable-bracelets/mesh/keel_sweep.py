"""The three keels, measured side by side.

The keel that marks C started as a wedge with a ramp at each end, meant to be at 45 degrees and built at 36. Making
the ramp a real 45 degrees removed the overhang and cost the mark its depth near the band's edges. Removing the ramp
removed both problems, because a vertical feature on a vertical wall, printed with the bangle's axis up, never hangs
over anything. This script measures all three so the lesson can quote them.

    python mesh/keel_sweep.py --results results/keel-sweep.json
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

import bracelet as bracelet_module  # noqa: E402
from bracelet import HEIGHT, OUTER_R, Bracelet, position_angle  # noqa: E402
from measure import overhangs, topology  # noqa: E402
from sets import resolve  # noqa: E402

VARIANTS = [
    (1.6, "the first try: 1.6 mm of ramp for 2.2 mm of depth, called 45 degrees in the hypotheses and built at 36"),
    (2.2, "a real 45 degree ramp: as much height as depth"),
    (0.0, "no ramp at all, the shipped design"),
]


def keel_depth(solid, z: float) -> float:
    a = math.radians(math.degrees(position_angle(0)) % 360.0)
    hits, _, _ = solid.ray.intersects_location(
        np.array([[0.0, 0.0, z]]), np.array([[math.cos(a), math.sin(a), 0.0]]), multiple_hits=True
    )
    return round(float(np.hypot(hits[:, 0], hits[:, 1]).max()) - OUTER_R, 4)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results", type=Path, default=None)
    parser.add_argument("--name", default="C major-triad")
    args = parser.parse_args()

    original = bracelet_module.KEEL_CHAMFER
    rows = []
    try:
        for chamfer, why in VARIANTS:
            bracelet_module.KEEL_CHAMFER = chamfer
            solid = Bracelet(args.name, resolve(args.name), "cone").solid()
            o = overhangs(solid)
            rows.append({
                "keel_chamfer_mm": chamfer,
                "why": why,
                "min_slope_deg": o.min_slope_deg,
                "steep_area_cm2": o.steep_area_cm2,
                "steep_fraction": o.steep_fraction,
                "watertight": topology(solid).watertight,
                "keel_depth_mm": {f"z={z}": keel_depth(solid, z) for z in (0.5, 1.0, 2.0, HEIGHT / 2)},
            })
    finally:
        bracelet_module.KEEL_CHAMFER = original

    report = {"bracelet": args.name, "threshold_deg": 45.0, "variants": rows}
    text = json.dumps(report, indent=2)
    if args.results:
        args.results.parent.mkdir(parents=True, exist_ok=True)
        args.results.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
