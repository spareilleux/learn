"""Measures the dot detector on the synthetic set: threshold picked on a tuning split, numbers from a test split.

    python -m checks.evaluate [--per-condition 50] [--out checks/results/dots-eval.json]

Tuning split: seeds 100000 and up; test split: seeds 0 and up. The two never share a seed. Precision and recall
count dots; the image error rate counts images where at least one dot is missed or one extra dot is found (the
check of experiment 1 passes an image only when it is exact).
"""
import argparse
import json
import os
import sys
import time

from . import dots, synth
from .geometry import Layout

GA_CHORDS = ["C", "G", "Am", "F", "D", "E7", "Cmaj7", "Dm7", "G7", "Bm7b5"]
GA_RANGES = [(0, 5), (0, 12)]
GA_CONDITIONS = ["clean", "noise", "blur", "perspective", "combined"]
THRESHOLDS = (0.01, 0.015, 0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.1, 0.12)


def score(samples, threshold, prior):
    tp = exp = det = exact = 0
    for s in samples:
        if "response" not in s:
            s["response"] = dots.response(s["image"], s["radius"])
        layout = Layout.compute(s.get("frets"), *s["fret_range"], s["image"].width, s["image"].height,
                                "show") if prior else None
        r = dots.check(s["image"], s["expected"], s["ignore"], s["radius"], s["tolerance"], threshold, s["response"],
                       layout)
        tp += r["true_positives"]
        exp += r["expected"]
        det += r["detected"]
        exact += r["exact"]
    precision = tp / det if det else 1.0
    recall = tp / exp if exp else 1.0
    f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
    return {"images": len(samples), "dots": exp, "detections": det, "true_positives": tp,
            "precision": round(precision, 4), "recall": round(recall, 4), "f1": round(f1, 4),
            "image_error_rate": round(1 - exact / len(samples), 4) if samples else None}


def build(per_condition, offset):
    return [synth.sample(offset + i * 7 + j, c) for j, c in enumerate(synth.CONDITIONS) for i in range(per_condition)]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--per-condition", type=int, default=50)
    parser.add_argument("--tuning-per-condition", type=int, default=20)
    parser.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "results", "dots-eval.json"))
    args = parser.parse_args(argv)
    t0 = time.perf_counter()
    tuning = build(args.tuning_per_condition, 100000)
    test = build(args.per_condition, 0)
    result = {"method": "checks/dots.py", "scales": dots.SCALES, "conditions": synth.CONDITIONS,
              "tuning_images": len(tuning), "test_images": len(test), "variants": {}}
    for name, prior in (("with_geometric_prior", True), ("without_prior", False)):
        sweep = {str(t): score(tuning, t, prior) for t in THRESHOLDS}
        best = max(THRESHOLDS, key=lambda t: (sweep[str(t)]["f1"], -abs(t - dots.DEFAULT_THRESHOLD)))
        for t in THRESHOLDS:
            print(f"{name} tuning threshold {t}: {sweep[str(t)]}", flush=True)
        variant = {"threshold": best, "tuning_sweep": sweep, "per_condition": {}}
        for c in synth.CONDITIONS:
            variant["per_condition"][c] = score([s for s in test if s["condition"] == c], best, prior)
            print(f"{name} test {c}: {variant['per_condition'][c]}", flush=True)
        variant["overall"] = score(test, best, prior)
        styles = sorted({s["style"] for s in test})
        variant["per_dot_style"] = {st: score([s for s in test if s["style"] == st], best, prior) for st in styles}
        print(f"{name} test overall: {variant['overall']}", flush=True)
        result["variants"][name] = variant
    # Controls on the GA pack's own maps, with the threshold picked above for the prior: what the detector reads on
    # an image drawn exactly like the ControlNet input, clean and degraded. Not a claim about generated necks.
    threshold = result["variants"]["with_geometric_prior"]["threshold"]
    result["ga_maps"] = {"threshold": threshold, "chords": GA_CHORDS, "fret_ranges": GA_RANGES, "inlays": "hide"}
    for style in ("filled", "ring"):
        maps = [synth.ga_map_sample(chord, lo, hi, style, c, 7000 + i)
                for i, (chord, (lo, hi), c) in enumerate((ch, r, c) for ch in GA_CHORDS for r in GA_RANGES
                                                         for c in GA_CONDITIONS)]
        entry = {c: score([m for m in maps if m["condition"] == c], threshold, True) for c in GA_CONDITIONS}
        entry["overall"] = score(maps, threshold, True)
        result["ga_maps"][style] = entry
        print(f"GA {style} maps: {entry}", flush=True)
    result["seconds"] = round(time.perf_counter() - t0, 1)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=1)
        f.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
