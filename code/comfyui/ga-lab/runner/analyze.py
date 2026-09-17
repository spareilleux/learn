"""Computes the measures an experiment declares under `analysis`, from its results.json, into analysis.json.

    analysis:
      - {kind: dots, node: "9", layout_node: "23", chord_path: "18.chord", fret_start_path: "18.fret_start",
         fret_end_path: "18.fret_end", inlays_path: "18.inlays"}   # layout_node first; the paths when it has no text
      - {kind: seam, node: "40"}
      - {kind: pixel_diff, node: "10", axis: format, reference: bf16}
      - {kind: luma_rank, node: "9", axis: mode, order: [Locrian, Phrygian, Aeolian, Dorian, Mixolydian, Ionian, Lydian]}
      - {kind: bracelet, node: "9", svg: ../path/to/bracelet.svg}   # relative to the experiment file
      - {kind: palette, node: "9"}
      - {kind: stats, node: "9"}
      - {kind: mesh, node: "90", object_axis: object}   # see runner/mesh_analysis.py

Only items with status done are measured; the report lists how many.
"""
import json
import os
from collections import defaultdict

from checks import dots, images
from . import mesh_analysis, svg_raster
from .experiment import Experiment


def outputs(item, node):
    return [o for o in item.get("outputs") or [] if o["node"] == str(node)]


def file_of(out_dir, output):
    path = output["file"]
    return path if os.path.isabs(path) else os.path.join(out_dir, path)


def analyze(experiment_path, out_dir):
    exp = Experiment(experiment_path)
    with open(os.path.join(out_dir, "results.json"), encoding="utf-8") as f:
        results = json.load(f)
    done = [i for i in results["items"] if i["status"] == "done"]
    report = {"experiment": exp.id, "items": len(results["items"]), "done": len(done), "analyses": []}
    for spec in exp.data.get("analysis") or []:
        kind, node = spec["kind"], spec.get("node")
        entry = {"spec": spec, "rows": []}
        if kind == "dots":
            groups = defaultdict(lambda: {"images": 0, "exact": 0, "expected": 0, "true_positives": 0, "detected": 0})
            for item in done:
                for o in outputs(item, node):
                    p = item["params"]
                    layout = (item.get("texts") or {}).get(str(spec.get("layout_node")))
                    if layout:  # the node's own layout output, recorded by PreviewAny
                        r = dots.check_layout(file_of(out_dir, o), layout[0] if isinstance(layout, list) else layout,
                                              spec.get("threshold"))
                    else:
                        r = dots.check_against_map(file_of(out_dir, o), p[spec["chord_path"]],
                                                   int(p[spec["fret_start_path"]]), int(p[spec["fret_end_path"]]),
                                                   spec.get("threshold"), inlays=p.get(spec.get("inlays_path", ""), "show"))
                    r["layout_from"] = "node" if layout else "recomputed"
                    entry["rows"].append({"key": item["key"], "labels": item["labels"], "seed": item["seed"], **r})
                    g = groups[item["labels"].get(spec.get("group_by", ""), "all")]
                    g["images"] += 1
                    g["exact"] += r["exact"]
                    for k in ("expected", "true_positives", "detected"):
                        g[k] += r[k]
            entry["summary"] = {k: {**v, "recall": round(v["true_positives"] / v["expected"], 3) if v["expected"] else None,
                                    "precision": round(v["true_positives"] / v["detected"], 3) if v["detected"] else None}
                                for k, v in groups.items()}
        elif kind == "seam":
            for item in done:
                for o in outputs(item, node):
                    entry["rows"].append({"key": item["key"], "labels": item["labels"], "seed": item["seed"],
                                          **images.seam_ratio(file_of(out_dir, o))})
        elif kind == "pixel_diff":
            by_seed = defaultdict(dict)
            for item in done:
                for o in outputs(item, node):
                    rest = tuple(sorted((k, v) for k, v in item["labels"].items() if k != spec["axis"]))
                    by_seed[(item["seed"], rest)][item["labels"][spec["axis"]]] = file_of(out_dir, o)
            for (seed, rest), files in sorted(by_seed.items(), key=str):
                ref = files.get(str(spec["reference"]))
                for label, path in sorted(files.items()):
                    if ref and label != str(spec["reference"]):
                        entry["rows"].append({"seed": seed, "others": dict(rest), "variant": label,
                                              "reference": spec["reference"], **images.pixel_diff(ref, path)})
        elif kind == "luma_rank":
            order = [str(v) for v in spec["order"]]
            for seed in sorted({i["seed"] for i in done}):
                xs, ys = [], []
                for item in done:
                    if item["seed"] != seed:
                        continue
                    for o in outputs(item, node):
                        label = item["labels"][spec["axis"]]
                        xs.append(order.index(label))
                        ys.append(o["mean_luma"])
                        entry["rows"].append({"seed": seed, "label": label, "mean_luma": o["mean_luma"],
                                              "mean_saturation": o["mean_saturation"]})
                if len(xs) > 2:
                    entry.setdefault("spearman", {})[str(seed)] = round(images.spearman(xs, ys), 3)
        elif kind == "bracelet":
            svg = exp.resolve(spec["svg"])
            circles = svg_raster.circles(svg)
            import xml.etree.ElementTree as ET
            view = float(ET.parse(svg).getroot().attrib["viewBox"].split()[2])
            for item in done:
                for o in outputs(item, node):
                    entry["rows"].append({"key": item["key"], "labels": item["labels"], "seed": item["seed"],
                                          **images.bracelet_readback(file_of(out_dir, o), circles, view)})
        elif kind == "palette":
            for item in done:
                for o in outputs(item, node):
                    entry["rows"].append({"labels": item["labels"], "seed": item["seed"],
                                          **images.palette_size(file_of(out_dir, o))})
        elif kind == "stats":
            for item in done:
                for o in outputs(item, node):
                    entry["rows"].append({"labels": item["labels"], "seed": item["seed"], "wall_time_s": item.get("wall_time_s"),
                                          "peak_vram_used_bytes": (item.get("memory") or {}).get("peak_vram_used_bytes"),
                                          "peak_ram_used_bytes": (item.get("memory") or {}).get("peak_ram_used_bytes"),
                                          "mean_luma": o.get("mean_luma"), "sha256": o["sha256"]})
        elif kind == "mesh":
            entry = mesh_analysis.analyze(spec, done, out_dir)
        else:
            entry["error"] = f"unknown analysis kind {kind!r}"
        report["analyses"].append(entry)
    dst = os.path.join(out_dir, "analysis.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=1, ensure_ascii=False)
        f.write("\n")
    return dst, report
