#!/usr/bin/env python3
"""Check the Streeling fixtures: layout, programs, and saved results against fresh runs.

    python code/streeling/check.py                          # layout, compile, every analyze.py --check
    python code/streeling/check.py --demerzel <clone>       # also every extract.py, against a Demerzel clone

Each module folder code/streeling/<department>/<module>/ holds analyze.py, scenarios.json, results.json and
README.md, plus extract.py and observed-input.json when the module reads observed repository data. analyze.py
reads only the folder; extract.py reads GuitarAlchemist/Demerzel. With --demerzel, the clone is checked out at
each extract's PINNED_COMMIT and the program writes to a scratch file that must equal observed-input.json.
Standard library only, Python 3.9 or later.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
PIN = re.compile(r'^(?:PINNED|SOURCE)_COMMIT = "([0-9a-f]{40})"$', re.M)


def modules() -> list[Path]:
    return sorted(p for p in HERE.glob("*/*") if p.is_dir() and re.fullmatch(r"[a-z]+-\d{3}", p.name))


def same_text(a: Path, b: Path) -> bool:
    return a.read_bytes().replace(b"\r\n", b"\n") == b.read_bytes().replace(b"\r\n", b"\n")


def run(args: list[str], cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, encoding="utf-8", timeout=600)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--demerzel", type=Path, help="a clone of GuitarAlchemist/Demerzel with full history")
    args = parser.parse_args()
    failures: list[str] = []
    found = modules()
    if not found:
        failures.append(f"no module folder under {HERE}")

    for module in found:
        name = module.relative_to(HERE).as_posix()
        expected = ["analyze.py", "scenarios.json", "results.json", "README.md"]
        if (module / "extract.py").is_file():
            expected.append("observed-input.json")
        missing = [f for f in expected if not (module / f).is_file()]
        if missing:
            failures.append(f"{name}: missing {', '.join(missing)}")
        for program in sorted(module.glob("*.py")):
            try:
                compile(program.read_text(encoding="utf-8"), str(program), "exec")
            except SyntaxError as exc:
                failures.append(f"{name}/{program.name}: {exc}")

    for module in found:
        name = module.relative_to(HERE).as_posix()
        start = time.monotonic()
        done = run([sys.executable, "-I", "-B", str(module / "analyze.py"), "--check"], cwd=HERE.parents[1])
        line = (done.stdout.strip().splitlines() or [""])[-1]
        print(f"{name}: analyze.py --check, exit {done.returncode}, {time.monotonic() - start:.1f} s: {line}")
        if done.returncode != 0:
            failures.append(f"{name}: analyze.py --check exit {done.returncode}: {(done.stdout + done.stderr)[-600:]}")

    if args.demerzel:
        clone = args.demerzel.resolve()
        with tempfile.TemporaryDirectory() as scratch:
            for module in found:
                program = module / "extract.py"
                if not program.is_file():
                    continue
                name = module.relative_to(HERE).as_posix()
                pin = PIN.search(program.read_text(encoding="utf-8"))
                if not pin:
                    failures.append(f"{name}/extract.py: no PINNED_COMMIT or SOURCE_COMMIT")
                    continue
                checkout = run(["git", "-C", str(clone), "checkout", "-q", "--detach", pin[1]], cwd=HERE)
                if checkout.returncode != 0:
                    failures.append(f"{name}: git checkout {pin[1]}: {checkout.stderr.strip()}")
                    continue
                output = Path(scratch) / f"{module.name}-observed-input.json"
                start = time.monotonic()
                done = run([sys.executable, "-I", "-B", str(program), "--repo-root", str(clone), "--output", str(output)],
                           cwd=HERE.parents[1])
                same = done.returncode == 0 and same_text(output, module / "observed-input.json")
                print(f"{name}: extract.py at {pin[1][:7]}, exit {done.returncode}, {time.monotonic() - start:.1f} s, "
                      f"{'same as' if same else 'DIFFERS FROM'} observed-input.json")
                if not same:
                    failures.append(f"{name}: extract.py exit {done.returncode}: {(done.stdout + done.stderr)[-600:]}")

    for failure in failures:
        print(f"FAIL {failure}", file=sys.stderr)
    print(f"{len(found)} modules, {len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
