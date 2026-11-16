"""AutoHarness course: run fixtures.py against the pinned clone and compare it with the measured run.

    python check.py --clone <path to the clone at the pinned commit>

Every line of results/fixtures-run.jsonl (Windows 11, cp1252) must come back identical, with one exception written
down before any run elsewhere (the journal's "To verify" list): off Windows, F4's first run is expected to read its
skill back equal, like its UTF-8-mode control. Whether UTF-8 mode was on for that run is printed, not compared: the
fixture's environment sets no locale, and Python turns UTF-8 mode on in the C locale (PEP 540). The last line must
say the real ~/.claude/autoharness existed after the run exactly when it existed before. Exits 1 and prints each
difference otherwise.
"""
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def expected_lines():
    lines = [json.loads(line) for line in (HERE / "results" / "fixtures-run.jsonl").read_text(encoding="utf-8").splitlines()]
    if os.name != "nt":
        control = lines[-2]  # F4 again with PYTHONUTF8=1
        first = next(r for r in lines if r["fixture"] == "F4" and r["pythonutf8"] is None)
        first["read_back"] = control["read_back"]
        first.pop("utf8_mode")
    return lines[:-1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clone", required=True)
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    proc = subprocess.run([sys.executable, str(HERE / "fixtures.py"), "--clone", a.clone],
                          capture_output=True, text=True, encoding="utf-8", timeout=600)
    if proc.returncode != 0:
        print(f"fixtures.py exited with {proc.returncode}\n{proc.stdout}{proc.stderr}")
        return 1
    got = [json.loads(line) for line in proc.stdout.splitlines()]
    state, got = got[-1], got[:-1]
    want = expected_lines()
    differences = []
    if len(got) != len(want):
        differences.append(f"{len(got)} fixture lines, {len(want)} expected")
    for g, w in zip(got, want):
        if os.name != "nt" and g["fixture"] == "F4" and g["pythonutf8"] is None:
            print(f"F4 without PYTHONUTF8: utf8_mode={g.pop('utf8_mode')}, read_back={g['read_back']}")
        label = g["fixture"] + (" (PYTHONUTF8=1)" if g["pythonutf8"] else "")
        for key in sorted(set(g) | set(w)):
            if g.get(key) != w.get(key):
                differences.append(f"{label} {key}: got {g.get(key)!r}, measured {w.get(key)!r}")
    if state["exists_after"] != state["real_state_dir_existed_before"]:
        differences.append(f"the real state directory changed: {state}")
    for d in differences:
        print("DIFF", d)
    print(f"{len(got)} fixture runs, {len(differences)} differences, real state directory {state}")
    return 1 if differences else 0


if __name__ == "__main__":
    sys.exit(main())
