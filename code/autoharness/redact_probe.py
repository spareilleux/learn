"""AutoHarness course, lesson 1 exercise: run the pinned redactor on your own synthetic strings, isolated like fixtures.py.

    python redact_probe.py --clone <path to the clone> "password: hunter2hunter2" '{"password": "hunter2hunter2"}'

Each argument is redacted in a fresh child with the minimal environment and disposable HOME of fixtures.py, and printed
as a JSON pair [input, output]. Use made-up values only: this is a probe of the rules, not a place for real secrets.
"""
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True  # importing fixtures would otherwise leave a __pycache__ in the course folder
import fixtures  # noqa: E402

CHILD = ("import json, sys\n"
         "from autoharness.lib import redact\n"
         "for s in json.loads(sys.argv[1]):\n"
         "    print(json.dumps([s, redact.redact(s)], ensure_ascii=False))\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clone", required=True)
    ap.add_argument("text", nargs="+")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    head = subprocess.run(["git", "-C", a.clone, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    if head != fixtures.PIN:
        print(f"refusing: clone is at {head or '?'}, expected {fixtures.PIN}", file=sys.stderr)
        return 2
    with tempfile.TemporaryDirectory(prefix="ah-redact-") as tmp:
        proc = subprocess.run([sys.executable, "-c", CHILD, json.dumps(a.text)], cwd=tmp,
                              env=fixtures.minimal_env(str(Path(a.clone).resolve()), Path(tmp), None),
                              capture_output=True, text=True, encoding="utf-8", timeout=60)
    print(proc.stdout, end="")
    print(proc.stderr, end="", file=sys.stderr)
    return proc.returncode


if __name__ == "__main__":
    sys.exit(main())
