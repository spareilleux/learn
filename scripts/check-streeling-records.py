"""Check the Streeling records kept beside the course source: production records and review packets.

A production record says which module a department produced and how far it got; a review packet is the brief a
reviewer follows and the learner task it hands out. Nothing on the site is generated from them, so nothing else
notices when one is malformed or names a module that does not exist.

    python scripts/check-streeling-records.py              # check streeling/
    python scripts/check-streeling-records.py --self-test  # prove each check can fail

- Every streeling/course-productions/*.json is valid against streeling/schemas/course-production.schema.json, is
  named after its pipeline_id, carries a timestamp with its time zone, and names a department and an English
  module that exist in streeling/.
- Every streeling/reviews/<code>-review-brief.md has its <code>-learner-task.md and the reverse, <code> is the
  code of an English module, and every relative link in them resolves.

Needs jsonschema (`pip install jsonschema`). Exits non-zero when one check fails.
"""
from __future__ import annotations

import argparse
import datetime
import json
import re
import shutil
import sys
import tempfile
from pathlib import Path

import jsonschema

REPO = Path(__file__).resolve().parents[1]
PACKET = re.compile(r"^([a-z]+-\d{3})-(review-brief|learner-task)\.md$")
LINK = re.compile(r"\]\(([^)\s]+)\)")
PAIR = {"review-brief": "learner-task", "learner-task": "review-brief"}


def check(streeling: Path, quiet: bool = False) -> list[str]:
    failures: list[str] = []
    modules = {p.stem: p.parent.parent.name for p in streeling.glob("courses/*/en/*.md") if p.name != "README.md"}
    codes = {re.match(r"[a-z]+-\d{3}", m)[0] for m in modules if re.match(r"[a-z]+-\d{3}", m)}

    schema = json.loads((streeling / "schemas" / "course-production.schema.json").read_text(encoding="utf-8"))
    validator = jsonschema.validators.validator_for(schema)(schema)
    records = sorted((streeling / "course-productions").glob("*.json"))
    for path in records:
        name = path.relative_to(streeling).as_posix()
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            failures.append(f"{name}: not JSON: {exc}")
            continue
        errors = sorted(validator.iter_errors(record), key=lambda e: list(e.path))
        for error in errors:
            failures.append(f"{name}: {'/'.join(map(str, error.path)) or '(root)'}: {error.message}")
        if errors:
            continue
        if path.stem != record["pipeline_id"]:
            failures.append(f"{name}: named {path.stem}, but its pipeline_id is {record['pipeline_id']}")
        try:
            stamp = datetime.datetime.fromisoformat(record["timestamp"].replace("Z", "+00:00"))
            if stamp.tzinfo is None:
                failures.append(f"{name}: timestamp {record['timestamp']} has no time zone")
        except ValueError:
            failures.append(f"{name}: timestamp {record['timestamp']} is not an ISO 8601 date and time")
        if not (streeling / "departments" / f"{record['department']}.department.json").is_file():
            failures.append(f"{name}: department {record['department']} has no department file")
        if modules.get(record["module_id"]) != record["department"]:
            failures.append(f"{name}: module {record['module_id']} is not an English module of {record['department']}")

    packets = sorted(p for p in (streeling / "reviews").glob("*.md") if p.name != "README.md")
    names = {p.name for p in packets}
    for path in packets:
        name = path.relative_to(streeling).as_posix()
        match = PACKET.match(path.name)
        if not match:
            failures.append(f"{name}: not named <code>-review-brief.md or <code>-learner-task.md")
            continue
        code, kind = match[1], match[2]
        if f"{code}-{PAIR[kind]}.md" not in names:
            failures.append(f"{name}: {code}-{PAIR[kind]}.md is missing")
        if code not in codes:
            failures.append(f"{name}: no English module has the code {code}")
        for href in LINK.findall(path.read_text(encoding="utf-8")):
            if re.match(r"^[a-z]+:", href) or href.startswith("#"):
                continue
            if not (path.parent / href.split("#", 1)[0]).exists():
                failures.append(f"{name}: link {href} does not resolve")

    if not quiet:
        print(f"{len(records)} production records, {len(packets)} review files")
    return failures


def self_test() -> int:
    """Break a copy of streeling/ one way at a time; each break must be reported, and the intact copy must pass."""
    def edit_record(field, value):
        def apply(root: Path) -> None:
            path = sorted((root / "course-productions").glob("*.json"))[0]
            record = json.loads(path.read_text(encoding="utf-8"))
            if value is None:
                del record[field]
            else:
                record[field] = value
            path.write_text(json.dumps(record), encoding="utf-8")
        return apply

    def rename_record(root: Path) -> None:
        path = sorted((root / "course-productions").glob("*.json"))[0]
        path.rename(path.with_name("cp-renamed.json"))

    def drop_learner_task(root: Path) -> None:
        sorted((root / "reviews").glob("*-learner-task.md"))[0].unlink()

    breaks = [
        ("a required field removed", edit_record("status", None), "'status' is a required property"),
        ("a status outside the enum", edit_record("status", "done"), "is not one of"),
        ("a file not named after its pipeline_id", rename_record, "but its pipeline_id is"),
        ("a timestamp without a time zone", edit_record("timestamp", "2026-10-13T12:00:00"), "has no time zone"),
        ("a module that does not exist", edit_record("module_id", "psy-999-nowhere"), "is not an English module"),
        ("a review brief without its learner task", drop_learner_task, "-learner-task.md is missing"),
    ]
    failed = 0
    with tempfile.TemporaryDirectory() as scratch:
        for label, apply, expected in [("the intact copy", None, None)] + breaks:
            root = Path(scratch) / "streeling"
            shutil.rmtree(root, ignore_errors=True)
            shutil.copytree(REPO / "streeling", root)
            if apply:
                apply(root)
            found = check(root, quiet=True)
            ok = not found if expected is None else any(expected in f for f in found)
            print(f"{'ok  ' if ok else 'FAIL'} {label}: {len(found)} failure(s) reported")
            failed += not ok
    print(f"self-test: {len(breaks) + 1 - failed}/{len(breaks) + 1} cases behave")
    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--self-test", action="store_true", help="prove each check can fail")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    failures = check(REPO / "streeling")
    for failure in failures:
        print(f"FAIL {failure}", file=sys.stderr)
    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
