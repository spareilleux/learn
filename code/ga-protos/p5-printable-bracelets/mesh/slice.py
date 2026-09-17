"""Run the meshes through a slicer, in console mode, and read back what it says.

PrusaSlicer and OrcaSlicer both slice from the command line with no window and no printer attached. Everything the
profile needs is given as options, so the run does not depend on a configuration bundle someone set up by hand:

    python mesh/slice.py --slicer "<path>/prusa-slicer-console.exe" --out G:/learn-lab/ga-protos/p5 \
        --results results/slicer.json G:/learn-lab/ga-protos/p5/*.stl

What comes back is the G-code's own footer: the filament it will use, in millimetres, cubic centimetres and grams,
and the printing time the slicer estimates. The standard output also carries the repairs the slicer made, which is the
one check trimesh cannot make for us: PrusaSlicer runs its own mesh repair before slicing and says what it fixed.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import time
from pathlib import Path

# A 0.4 mm nozzle, PLA, 0.2 mm layers, 3 perimeters, 15 % gyroid: an ordinary profile, spelled out so the run is
# reproducible on a machine that has never opened the slicer's window.
PROFILE = [
    "--nozzle-diameter", "0.4",
    "--filament-diameter", "1.75",
    "--filament-density", "1.24",
    "--filament-cost", "25",
    "--layer-height", "0.2",
    "--first-layer-height", "0.2",
    "--perimeters", "3",
    "--top-solid-layers", "4",
    "--bottom-solid-layers", "4",
    "--fill-density", "15%",
    "--fill-pattern", "gyroid",
    "--temperature", "215",
    "--first-layer-temperature", "215",
    "--bed-temperature", "60",
    "--first-layer-bed-temperature", "60",
    "--support-material-threshold", "45",
    "--skirts", "1",
    "--bed-shape", "0x0,250x0,250x210,0x210",
    "--gcode-flavor", "marlin2",
]

FOOTER = {
    "filament_used_mm": re.compile(r"^; filament used \[mm\] = ([\d.]+)", re.M),
    "filament_used_cm3": re.compile(r"^; filament used \[cm3\] = ([\d.]+)", re.M),
    "filament_used_g": re.compile(r"^; filament used \[g\] = ([\d.]+)", re.M),
    "total_filament_cost": re.compile(r"^; total filament cost = ([\d.]+)", re.M),
    "estimated_printing_time": re.compile(r"^; estimated printing time \(normal mode\) = (.+)$", re.M),
}

# PrusaSlicer 2.9 does not write a layer count in the footer; count the layer changes instead, and read back the
# extrusion widths it actually used, which is how a thin feature announces that it did not fit whole extrusions.
LAYER_CHANGE = re.compile(r"^;LAYER_CHANGE$", re.M)
WIDTH = re.compile(r"^;WIDTH:([\d.]+)$", re.M)

REPAIR = re.compile(r"(repaired|auto-repair|degenerate|edges fixed|facets removed|backwards edges|open edges|holes)", re.I)


def find_slicer(explicit: str | None) -> str | None:
    if explicit:
        return explicit
    for name in ("prusa-slicer-console", "prusa-slicer", "PrusaSlicer", "orca-slicer", "orcaslicer", "OrcaSlicer"):
        found = shutil.which(name)
        if found:
            return found
    return None


def slice_one(slicer: str, stl: Path, out: Path, supports: bool) -> dict:
    out.mkdir(parents=True, exist_ok=True)
    gcode = out / f"{stl.stem}{'-supported' if supports else ''}.gcode"
    cmd = [slicer, "--export-gcode", *PROFILE]
    cmd += ["--support-material"] if supports else []
    cmd += ["--output", str(gcode), str(stl)]
    started = time.perf_counter()
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
    elapsed = time.perf_counter() - started
    record = {
        "stl": stl.name,
        "supports": supports,
        "returncode": proc.returncode,
        "slice_s": round(elapsed, 2),
        "stdout": proc.stdout.strip()[-4000:],
        "stderr": proc.stderr.strip()[-4000:],
        "repair_lines": [l for l in (proc.stdout + proc.stderr).splitlines() if REPAIR.search(l)],
    }
    if gcode.exists():
        text = gcode.read_text(encoding="utf-8", errors="replace")
        record["gcode_bytes"] = gcode.stat().st_size
        record["report"] = {k: (m.group(1).strip() if (m := rx.search(text)) else None) for k, rx in FOOTER.items()}
        widths = sorted({round(float(w), 3) for w in WIDTH.findall(text)})
        record["report"]["layers"] = len(LAYER_CHANGE.findall(text))
        record["report"]["extrusion_width_min_mm"] = widths[0] if widths else None
        record["report"]["extrusion_width_max_mm"] = widths[-1] if widths else None
        record["report"]["extrusion_widths_off_nominal"] = sum(1 for w in widths if abs(w - 0.45) > 0.02)
        record["report"]["distinct_extrusion_widths"] = len(widths)
    return record


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stl", nargs="*", type=Path)
    parser.add_argument("--slicer", default=None, help="path to prusa-slicer-console.exe or orca-slicer")
    parser.add_argument("--out", type=Path, required=True, help="where the G-code goes; outside the repository")
    parser.add_argument("--results", type=Path, default=None)
    parser.add_argument("--supports", action="store_true", help="also slice each file with supports on")
    args = parser.parse_args()

    slicer = find_slicer(args.slicer)
    if slicer is None:
        report = {"slicer": None, "note": "no slicer on this machine: every slicer figure stays to verify"}
        print(json.dumps(report, indent=2))
        if args.results:
            args.results.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        return 0

    version = subprocess.run([slicer, "--help"], capture_output=True, text=True).stdout.splitlines()
    runs = []
    for stl in args.stl:
        runs.append(slice_one(slicer, stl, args.out, supports=False))
        if args.supports:
            runs.append(slice_one(slicer, stl, args.out, supports=True))
    report = {
        "slicer": slicer,
        "version": next((l.strip() for l in version if "PrusaSlicer" in l or "Orca" in l), "unknown"),
        "profile": PROFILE,
        "runs": runs,
    }
    text = json.dumps(report, indent=2)
    if args.results:
        args.results.parent.mkdir(parents=True, exist_ok=True)
        args.results.write_text(text + "\n", encoding="utf-8")
    else:
        print(text)
    for r in runs:
        rep = r.get("report", {})
        print(f"{r['stl']:34s} supports={r['supports']!s:5s} rc={r['returncode']} "
              f"{rep.get('filament_used_g')} g  {rep.get('estimated_printing_time')}  layers={rep.get('layers')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
