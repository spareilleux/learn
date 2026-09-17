"""Command line of the GA lab runner. Run from code/comfyui/ga-lab:

    python -m runner plan EXPERIMENT [--models-dir DIR ...]
        items, models, sizes and the memory estimate, without a server
    python -m runner run EXPERIMENT --server http://127.0.0.1:8188 --models-dir DIR [--models-dir DIR ...] [--out DIR]
        runs the items one at a time against a server someone else started, then writes the contact sheet
    python -m runner analyze EXPERIMENT [--out DIR]
        the measures the experiment declares, into analysis.json
    python -m runner sheet EXPERIMENT [--out DIR]
        writes the contact sheet again from results.json
"""
import argparse
import json
import os
import sys

from . import analyze, memory, models, sheet
from .experiment import Experiment, ExperimentError, apply_sets


def default_out(experiment_path, out):
    lab = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.abspath(out or os.path.join(lab, "results", Experiment(experiment_path).id))


def plan(args):
    exp = Experiment(args.experiment)
    items = exp.items()
    print(f"{exp.id}: {exp.data['title']}\n{len(items)} items")
    seen = {}
    for item in items:
        _, wf = exp.workflow(item["workflow"])
        sets = {k: ("<input>" if isinstance(v, dict) else v) for k, v in item["sets"].items()}
        prompt = apply_sets(wf, sets, item["workflow"])
        described = models.describe(prompt, [os.path.abspath(d) for d in args.models_dir or []])
        key = tuple((m["folder"], m["name"]) for m in described)
        seen.setdefault(key, (described, 0))
        seen[key] = (described, seen[key][1] + 1)
        labels = ", ".join(f"{k}={v}" for k, v in item["labels"].items())
        print(f"  {labels}, seed={item['seed']}  [{os.path.basename(item['workflow'])}]")
    for described, count in seen.values():
        total = sum(m["bytes"] or 0 for m in described)
        print(f"model set used by {count} item(s):")
        for m in described:
            size = f"{m['bytes'] / memory.GIB:.2f} GB" if m["bytes"] else "not found under --models-dir"
            print(f"  {m['folder']}/{m['name']}: {size}")
        need = total + (args.margin_gb + exp.extra_memory_gb) * memory.GIB
        print(f"  memory rule: {total / memory.GIB:.2f} GB + {args.margin_gb + exp.extra_memory_gb:.1f} GB margin "
              f"= {need / memory.GIB:.2f} GB of free RAM needed")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(prog="python -m runner", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("plan")
    p.add_argument("experiment")
    p.add_argument("--models-dir", action="append")
    p.add_argument("--margin-gb", type=float, default=8.0)

    r = sub.add_parser("run")
    r.add_argument("experiment")
    r.add_argument("--server", required=True, help="URL of a ComfyUI server that is already running")
    r.add_argument("--models-dir", action="append", required=True,
                   help="a models folder the server reads (repeat for extra_model_paths); used for sizes and hashes")
    r.add_argument("--out", help="default: results/<experiment id> next to this runner")
    r.add_argument("--images", help="where full-size outputs go (default: <out>/images, not committed)")
    r.add_argument("--hash-cache", help="default: <out>/../.model-sha256.json")
    r.add_argument("--margin-gb", type=float, default=8.0)
    r.add_argument("--min-free-vram-gb", type=float, default=10.0)
    r.add_argument("--poll-interval", type=float, default=0.5)
    r.add_argument("--item-timeout", type=float, default=1800)
    r.add_argument("--http-timeout", type=float, default=30)
    r.add_argument("--limit", type=int, default=0, help="run at most N items this time (0: all)")
    r.add_argument("--comfyui-commit", help="the server's commit, when its version isn't in KNOWN_COMMITS")
    r.add_argument("--no-free", action="store_true", help="don't POST /free when the set of models changes")
    r.add_argument("--free-wait", type=float, default=3.0)

    a = sub.add_parser("analyze")
    a.add_argument("experiment")
    a.add_argument("--out")

    s = sub.add_parser("sheet")
    s.add_argument("experiment")
    s.add_argument("--out")

    args = parser.parse_args(argv)
    try:
        if args.command == "plan":
            return plan(args)
        if args.command == "run":
            from .run import run
            return run(args)
        out = default_out(args.experiment, args.out)
        if args.command == "analyze":
            dst, report = analyze.analyze(args.experiment, out)
            for entry in report["analyses"]:
                print(json.dumps({k: v for k, v in entry.items() if k != "rows"}, ensure_ascii=False))
            print(f"-> {dst}")
            return 0
        if args.command == "sheet":
            with open(os.path.join(out, "results.json"), encoding="utf-8") as f:
                results = json.load(f)
            print(sheet.contact_sheet(results, out, os.path.join(out, "sheet.webp")))
            return 0
    except ExperimentError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    return 2


if __name__ == "__main__":
    sys.exit(main())
