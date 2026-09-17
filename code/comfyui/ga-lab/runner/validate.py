"""Checks the lab's workflows against a running server's GET /object_info: classes, input names, combo values.

    python -m runner.validate --server http://127.0.0.1:8188 [workflows/*.api.json]

Model file names are not checked (the CI server has no models); every other combo value must be one the server
offers. Exit code 1 lists the problems.
"""
import argparse
import glob
import json
import os
import sys

from .comfy import Comfy
from .models import LOADERS


def problems(workflow, info, name):
    found = []
    for node_id, node in workflow.items():
        cls = node["class_type"]
        if cls not in info:
            found.append(f"{name} node {node_id}: {cls} is not on the server")
            continue
        spec = info[cls].get("input", {})
        declared = {**spec.get("required", {}), **spec.get("optional", {})}
        for key, value in node["inputs"].items():
            if key not in declared:
                found.append(f"{name} node {node_id} ({cls}): no input {key!r}")
                continue
            if isinstance(value, list) or key in LOADERS.get(cls, {}):
                continue
            kind = declared[key][0] if declared[key] else None
            options = kind if isinstance(kind, list) else (declared[key][1].get("options") if kind == "COMBO" and
                                                           len(declared[key]) > 1 else None)
            if options is not None and value not in options:
                found.append(f"{name} node {node_id} ({cls}): {key}={value!r} not in {options[:8]}")
    return found


def main(argv=None):
    lab = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--server", required=True)
    parser.add_argument("workflows", nargs="*")
    args = parser.parse_args(argv)
    info = Comfy(args.server, timeout=120).get_json("/object_info")
    paths = args.workflows or sorted(glob.glob(os.path.join(lab, "workflows", "*.api.json")))
    all_problems = []
    for path in paths:
        with open(path, encoding="utf-8") as f:
            wf = json.load(f)
        p = problems(wf, info, os.path.basename(path))
        print(f"{'ok  ' if not p else 'FAIL'} {os.path.basename(path)}")
        all_problems += p
    for p in all_problems:
        print("  " + p)
    return 1 if all_problems else 0


if __name__ == "__main__":
    sys.exit(main())
