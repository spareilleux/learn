"""Reads a .glb back: node tree, materials, animation curves parsed from the file, then the mesh counts from Blender.

`report(path, write)` writes one line per fact, so `atlas_check.py` can compare them with `expected/`.
Adapted from the script written by the orchestrator's agent for the Atlas des Douze models; the preview render
it also produced is left out, since the report has to be identical on the three CI runners.
"""
import json
import math
import os
import struct

import bpy
from mathutils import Quaternion, Vector

COMPONENTS = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}


def read_glb(path):
    """The JSON chunk and the binary chunk of a .glb, without any library."""
    data = open(path, "rb").read()
    magic, version, length = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67 and version == 2, (magic, version)
    off, chunks = 12, {}
    while off < length:
        clen, ctype = struct.unpack_from("<II", data, off)
        chunks[ctype] = data[off + 8: off + 8 + clen]
        off += 8 + clen
    return json.loads(chunks[0x4E4F534A]), chunks.get(0x004E4942, b"")


def accessor(gltf, binary, i):
    a = gltf["accessors"][i]
    view = gltf["bufferViews"][a["bufferView"]]
    n = COMPONENTS[a["type"]]
    assert a["componentType"] == 5126, a["componentType"]      # float
    base = view.get("byteOffset", 0) + a.get("byteOffset", 0)
    vals = struct.unpack_from("<%df" % (a["count"] * n), binary, base)
    return [vals[k * n:(k + 1) * n] for k in range(a["count"])]


def angles_about_axis(values):
    """The rotations of a quaternion track, unwrapped in degrees about the axis of the first turned key."""
    axis, total, prev, out = None, 0.0, None, []
    for (x, y, z, w) in values:
        q = Quaternion((w, x, y, z))
        if axis is None and q.angle > 1e-4:
            axis = q.axis
        angle = 2 * math.atan2(Vector((x, y, z)).dot(axis), w) if axis is not None else 0.0
        if prev is not None:
            delta = angle - prev
            while delta > math.pi:
                delta -= 2 * math.pi
            while delta < -math.pi:
                delta += 2 * math.pi
            total += delta
        prev = angle
        out.append(math.degrees(total))
    return axis, out


def report(path, write):
    gltf, binary = read_glb(path)
    write(f"# {os.path.basename(path)}: {os.path.getsize(path)} bytes")
    nodes = gltf["nodes"]

    def tree(i, depth=0):
        node = nodes[i]
        kind = "mesh" if "mesh" in node else "empty"
        t = [round(v, 4) for v in node.get("translation", [0, 0, 0])]
        write("  " * depth + f"- {node.get('name')} ({kind}) t={t}")
        for c in node.get("children", []):
            tree(c, depth + 1)

    write("nodes:")
    for root in gltf["scenes"][gltf.get("scene", 0)]["nodes"]:
        tree(root)
    write(f"materials: {[m.get('name') for m in gltf.get('materials', [])]}")
    write(f"animations: {len(gltf.get('animations', []))}")
    for anim in gltf.get("animations", []):
        for channel in anim["channels"]:
            sampler = anim["samplers"][channel["sampler"]]
            times = accessor(gltf, binary, sampler["input"])
            values = accessor(gltf, binary, sampler["output"])
            target = nodes[channel["target"]["node"]].get("name")
            write(f"animation {anim.get('name')}: node {target}, {channel['target']['path']}, "
                  f"{sampler.get('interpolation', 'LINEAR')}, {len(times)} keys, "
                  f"{times[0][0]:.4f} s to {times[-1][0]:.4f} s")
            if channel["target"]["path"] != "rotation":
                continue
            axis, angles = angles_about_axis(values)
            loops = (all(abs(a - b) < 1e-4 for a, b in zip(values[0], values[-1]))
                     or all(abs(a + b) < 1e-4 for a, b in zip(values[0], values[-1])))
            write(f"  axis {[round(a, 3) for a in axis]}, from {angles[0]:.3f} to {angles[-1]:.3f} deg, "
                  f"min {min(angles):.3f}, max {max(angles):.3f}, first key equals last: {loops}")
            quarters = [0, len(times) // 4, len(times) // 2, 3 * len(times) // 4, len(times) - 1]
            write("  " + ", ".join(f"{times[k][0]:.3f} s: {angles[k]:.2f} deg" for k in quarters))

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    bpy.context.scene.frame_set(0)
    bpy.context.view_layer.update()
    total = 0
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    write("as imported:")
    for ob in sorted(bpy.data.objects, key=lambda o: o.name):
        tris = 0
        if ob.type == "MESH":
            ob.data.calc_loop_triangles()
            tris = len(ob.data.loop_triangles)
            total += tris
            for v in ob.data.vertices:
                w = ob.matrix_world @ v.co
                lo, hi = Vector(map(min, lo, w)), Vector(map(max, hi, w))
        action = ob.animation_data.action.name if ob.animation_data and ob.animation_data.action else None
        mats = [m.name for m in ob.data.materials] if ob.type == "MESH" else []
        write(f"- {ob.name}: {ob.type.lower()}, parent {ob.parent.name if ob.parent else 'none'}, "
              f"{tris} triangles, materials {mats}, action {action}")
    write(f"triangles: {total}")
    # The importer turns glTF Y-up into Blender Z-up: glTF y is Blender z, glTF z is minus Blender y
    write(f"bounds in glTF axes: x [{lo.x:.4f}, {hi.x:.4f}], y [{lo.z:.4f}, {hi.z:.4f}], "
          f"z [{-hi.y:.4f}, {-lo.y:.4f}], height {hi.z - lo.z:.4f}")
