"""ComfyUI course, lesson 12: one CSV row per job of a jobs file, from what the worker left in its store.

    python jobs/results.py jobs/ga-chord-neck.jsonl out/store-ga > results.csv

A job's parameters come from its "set" object; its outcome from <store>/<job id>/done.json or failed.txt.
A job with neither has not run yet: its status is "pending", and running the same jobs file again runs only those.
"""
import csv
import json
import sys
from pathlib import Path


def main(jobs_file: str, store: str) -> None:
    jobs = [json.loads(line) for line in Path(jobs_file).read_text(encoding="utf-8").splitlines() if line.strip()]
    keys = sorted({key for job in jobs for key in job.get("set", {})})
    out = csv.writer(sys.stdout, lineterminator="\n")
    out.writerow(["job", *keys, "status", "gpu", "attempts", "files", "reason"])
    seen = set()
    for job in jobs:
        if job["id"] in seen:
            continue  # a duplicate line is the same job
        seen.add(job["id"])
        folder = Path(store) / job["id"]
        values = [job.get("set", {}).get(key, "") for key in keys]
        if (folder / "done.json").exists():
            done = json.loads((folder / "done.json").read_text(encoding="utf-8"))
            files = " ".join(f"{f['name']}:{f['sha256']}" for f in done["files"])
            out.writerow([job["id"][:8], *values, "done", done["gpu"], done["attempts"], files, ""])
        elif (folder / "failed.txt").exists():
            reason = (folder / "failed.txt").read_text(encoding="utf-8").strip()
            out.writerow([job["id"][:8], *values, "dead-lettered", "", "", "", reason])
        else:
            out.writerow([job["id"][:8], *values, "pending", "", "", "", ""])


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
