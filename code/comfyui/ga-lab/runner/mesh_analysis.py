"""The `mesh` measure: what runner/glb.py recorded for each .glb output, against the experiment's predictions.

    - kind: mesh
      node: "90"                      # the SaveGLB node
      object_axis: object             # the axis whose label names the object
      pair_axis: octree               # optional: compare two values of an axis, object by object
      pair: [256, 380]                # triangles at the first divided by triangles at the second
      reference: {pick: [1.0, 0.87, 0.024]}   # sorted extents / longest of the real object

Rows: counts, watertight, boundary and non-manifold edges (and their share of the edges), components, texture and
vertex colors, sorted ratios and their difference with the reference. Summary: how many meshes are watertight, have
more than one component, have non-manifold edges on at least 0.5 % of their edges, and the triangle ratio per object.
When results.json has no `glb` for an output (a run before this measure existed), the file is read again.
"""
import os

from . import glb


def _record(out_dir, output):
    if output.get("glb"):
        return output["glb"]
    path = output["file"] if os.path.isabs(output["file"]) else os.path.join(out_dir, output["file"])
    return glb.inspect(path) if os.path.isfile(path) else None


def analyze(spec, done, out_dir):
    entry = {"spec": spec, "rows": []}
    node, object_axis = str(spec["node"]), spec.get("object_axis")
    reference = spec.get("reference") or {}
    for item in done:
        for output in item.get("outputs") or []:
            if output["node"] != node:
                continue
            g = _record(out_dir, output)
            row = {"key": item["key"], "labels": item["labels"], "seed": item["seed"], "sha256": output["sha256"],
                   "file": output["file"], "wall_time_s": item.get("wall_time_s"),
                   "peak_vram_used_bytes": (item.get("memory") or {}).get("peak_vram_used_bytes")}
            if g is None:
                row["error"] = "the .glb is not in results.json and its file is not on this machine"
                entry["rows"].append(row)
                continue
            topo = g.get("topology") or {}
            edges = topo.get("edges") or 0
            row.update({
                "triangles": g["triangles"], "vertices": g["vertices"], "materials": g["materials"],
                "textures": g["textures"], "has_vertex_colors": g["has_vertex_colors"],
                "watertight": topo.get("watertight"), "boundary_edges": topo.get("boundary_edges"),
                "nonmanifold_edges": topo.get("nonmanifold_edges"),
                "nonmanifold_share": round(topo["nonmanifold_edges"] / edges, 5) if edges else None,
                "inconsistent_edges": topo.get("inconsistent_edges"), "components": topo.get("components"),
                "extents": (g.get("bbox") or {}).get("extents"),
                "sorted_ratios": (g.get("bbox") or {}).get("sorted_ratios"),
            })
            name = str(item["labels"].get(object_axis)) if object_axis else None
            ref = {str(k): v for k, v in reference.items()}.get(name)
            if ref and row["sorted_ratios"]:
                row["reference_ratios"] = ref
                row["ratio_differences"] = [round(a - b, 4) for a, b in zip(row["sorted_ratios"], ref)]
            entry["rows"].append(row)
    measured = [r for r in entry["rows"] if "triangles" in r]
    summary = {
        "meshes": len(measured),
        "watertight": sum(1 for r in measured if r["watertight"]),
        "several_components": sum(1 for r in measured if (r["components"] or 0) > 1),
        "nonmanifold_share_at_least_0_5_percent": sum(1 for r in measured if (r["nonmanifold_share"] or 0) >= 0.005),
        "textured_or_colored": sum(1 for r in measured if r["textures"] or r["has_vertex_colors"]),
        "longest_extent_at_least_1_9": sum(1 for r in measured if r["extents"] and max(r["extents"]) >= 1.9),
    }
    pair_axis, pair = spec.get("pair_axis"), spec.get("pair")
    if pair_axis and pair and object_axis:
        by_object = {}
        for r in measured:
            by_object.setdefault(r["labels"].get(object_axis), {})[str(r["labels"].get(pair_axis))] = r["triangles"]
        summary["triangle_ratio"] = {
            name: round(counts[str(pair[0])] / counts[str(pair[1])], 4)
            for name, counts in sorted(by_object.items(), key=lambda kv: str(kv[0]))
            if counts.get(str(pair[0])) and counts.get(str(pair[1]))}
    entry["summary"] = summary
    return entry
