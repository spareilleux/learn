# Machine learning course: turn the CI history of the DuckDB course and the Git history of this repository into two CSV files
# Run from the repository root: python code/machine-learning-ix/data/extract.py
import csv
import json
import subprocess
from datetime import datetime

runs = {r["databaseId"]: r for r in json.load(open("code/duckdb/data/runs.json", encoding="utf-8"))}
jobs = json.load(open("code/duckdb/data/jobs.json", encoding="utf-8"))
out = "code/machine-learning-ix/data/"


def seconds(start, end):
    parse = lambda s: datetime.fromisoformat(s.replace("Z", "+00:00"))
    return int((parse(end) - parse(start)).total_seconds())


def pages_at(sha):
    # Markdown pages of the site at that commit, all locales
    files = subprocess.run(["git", "ls-tree", "-r", "--name-only", sha, "src/content/docs"],
                           check=True, capture_output=True, text=True).stdout.split()
    return sum(1 for f in files if f.endswith((".md", ".mdx")))


def write(name, header, rows):
    with open(out + name, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)
    print(name, len(rows), "rows")


# builds.csv: one row per successful build job of the deploy workflow
builds = []
for job in jobs:
    run = runs[job["run_id"]]
    if run["workflowName"] != "Deploy to GitHub Pages" or job["name"] != "build" or job["conclusion"] != "success":
        continue
    step = next(s for s in job["steps"] if s["name"].startswith("Install, build"))
    builds.append((run["createdAt"], run["headSha"][:7], pages_at(run["headSha"]),
                   seconds(step["started_at"], step["completed_at"])))
builds.sort()
write("builds.csv", ["created_at", "sha", "pages", "build_seconds"], builds)

# jobs.csv: one row per finished job that checks out the repository, with the timings of the steps every such job has
rows = []
for job in jobs:
    if job["conclusion"] not in ("success", "failure"):
        continue
    steps = {}
    for s in job["steps"]:
        if s["started_at"] and s["completed_at"]:
            name = s["name"]
            if "heckout" in name:
                name = "post_checkout" if name.startswith("Post") else "checkout"
            steps[name] = seconds(s["started_at"], s["completed_at"])
    if "checkout" not in steps or "post_checkout" not in steps:
        continue
    os_name = job["labels"][0].removesuffix("-latest")
    rows.append((job["id"], runs[job["run_id"]]["workflowName"], job["name"], os_name,
                 seconds(job["created_at"], job["started_at"]), steps["Set up job"], steps["checkout"],
                 steps["post_checkout"], steps["Complete job"]))
rows.sort()
write("jobs.csv", ["job_id", "workflow", "job", "os", "queue_s", "setup_s", "checkout_s", "post_checkout_s", "complete_s"], rows)
