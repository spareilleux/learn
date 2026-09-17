"""Rebuild the suite on the runner and check it against the figures the lesson quotes.

The published numbers come from the author's machine; this says whether the same geometry comes out of the same code
on Linux, Windows and macOS. Volumes are compared to a millimetre cubed, which is far tighter than anything a printer
could tell apart and loose enough for three different builds of manifold3d.

    python mesh/check_ci.py --results results/measurements.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from bracelet import Bracelet  # noqa: E402
from measure import measure_all  # noqa: E402
from run import POSITIONS_DEG  # noqa: E402
from sets import resolve  # noqa: E402

TOLERANCE_CM3 = 0.001


def check_keel(published: Path, rebuilt: Path) -> list[str]:
    """The keel's three shapes must still measure what the lesson says they measure."""
    here = json.loads(rebuilt.read_text(encoding="utf-8"))["variants"]
    there = json.loads(published.read_text(encoding="utf-8"))["variants"]
    problems = []
    if len(here) != len(there):
        return [f"the sweep has {len(here)} variants here and {len(there)} in {published}"]
    for a, b in zip(here, there):
        if a["keel_chamfer_mm"] != b["keel_chamfer_mm"]:
            problems.append(f"keel {a['keel_chamfer_mm']} mm is not in the same place in the two sweeps")
        if abs(a["min_slope_deg"] - b["min_slope_deg"]) > 0.05:
            problems.append(f"keel {a['keel_chamfer_mm']} mm: slope {a['min_slope_deg']} vs published {b['min_slope_deg']}")
        if a["keel_depth_mm"] != b["keel_depth_mm"]:
            problems.append(f"keel {a['keel_chamfer_mm']} mm: depths {a['keel_depth_mm']} vs published {b['keel_depth_mm']}")
    return problems


def check_export(run: Path, limit: int = 3_000_000) -> list[str]:
    """One bracelet written out: closed, and small enough to send to anyone."""
    record = json.loads(run.read_text(encoding="utf-8"))["bracelets"][0]
    problems = []
    if not record["union"]["topology"]["watertight"]:
        problems.append("the exported bracelet is not watertight")
    for kind in ("stl", "3mf"):
        size = record.get(kind, {}).get("bytes")
        if size is None:
            problems.append(f"no {kind} was written: {record.get(kind)}")
        elif size > limit:
            problems.append(f"the {kind} is {size} bytes, over the {limit} the lesson claims")
        else:
            print(f"{kind}: {size} bytes")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results", type=Path, default=Path("results/measurements.json"))
    parser.add_argument("--keel", nargs=2, type=Path, metavar=("PUBLISHED", "REBUILT"),
                        help="compare two keel sweeps instead of rebuilding the suite")
    parser.add_argument("--export", type=Path, default=None, metavar="RUN_JSON",
                        help="check one exported bracelet instead of rebuilding the suite")
    args = parser.parse_args()

    if args.keel or args.export:
        problems = (check_keel(*args.keel) if args.keel else []) + (check_export(args.export) if args.export else [])
        for p in problems:
            print("MISMATCH", p, file=sys.stderr)
        print(f"{len(problems)} mismatches")
        return 1 if problems else 0

    published = json.loads(args.results.read_text(encoding="utf-8"))
    problems: list[str] = []
    checked = 0

    for record in published["bracelets"]:
        if record["bead"] == "none":
            continue
        pcs = resolve(record["name"])
        if list(pcs) != record["pitch_classes"]:
            problems.append(f"{record['name']}: pitch classes {list(pcs)} != published {record['pitch_classes']}")
            continue
        bracelet = Bracelet(record["name"], pcs, record["bead"])
        here = measure_all(bracelet.solid(), POSITIONS_DEG)
        there = record["union"]
        label = f"{record['name']} ({record['bead']})"
        checked += 1

        if not here["topology"]["watertight"] or here["topology"]["bodies"] != 1:
            problems.append(f"{label}: the union is not one closed solid here")
        if here["topology"]["euler_number"] != 0:
            problems.append(f"{label}: Euler characteristic {here['topology']['euler_number']}, a bangle should be 0")
        if here["topology"]["manifold3d_status"] != "NoError":
            problems.append(f"{label}: manifold3d says {here['topology']['manifold3d_status']}")
        gap = abs(here["solidity"]["volume_cm3"] - there["solidity"]["volume_cm3"])
        if gap > TOLERANCE_CM3:
            problems.append(f"{label}: volume {here['solidity']['volume_cm3']} vs published {there['solidity']['volume_cm3']}")
        if here["fit"]["inner_diameter_mm"] != there["fit"]["inner_diameter_mm"]:
            problems.append(f"{label}: inner diameter {here['fit']['inner_diameter_mm']} vs {there['fit']['inner_diameter_mm']}")

        if record["bead"] == "cone":
            if here["overhangs"]["steep_area_cm2"] != 0.0:
                problems.append(f"{label}: {here['overhangs']['steep_area_cm2']} cm2 would need support, the design says none")
            if here["fit"]["inner_diameter_mm"] < 64.98:
                problems.append(f"{label}: the bore is down to {here['fit']['inner_diameter_mm']} mm")
        else:
            # The published failure has to stay reproducible, or the lesson is quoting a ghost.
            if here["fit"]["inner_diameter_mm"] > 63.1:
                problems.append(f"{label}: the spherical beads no longer eat into the bore; lesson 5 says they do")
            if here["overhangs"]["steep_area_cm2"] <= 0.0:
                problems.append(f"{label}: the spherical beads no longer overhang; lesson 5 says they do")

        if "naive" in record:
            naive = measure_all(bracelet.naive(), POSITIONS_DEG)
            if naive["topology"]["bodies"] != 14:
                problems.append(f"{label}: the un-unioned parts make {naive['topology']['bodies']} bodies, not 14")
            if not naive["topology"]["watertight"]:
                problems.append(f"{label}: the un-unioned parts are not watertight here; lesson 5 says they are")
            if naive["solidity"]["volume_cm3"] <= here["solidity"]["volume_cm3"]:
                problems.append(f"{label}: the un-unioned parts no longer over-count the volume")

    for p in problems:
        print("MISMATCH", p, file=sys.stderr)
    print(f"{checked} bracelets rebuilt and compared with {args.results}: {len(problems)} mismatches")
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())
