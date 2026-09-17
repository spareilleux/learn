"""A cleanup pipeline for generated .glb models: import, report, clean, scale, turntable, export for three.js.

    blender --background --factory-startup --python-exit-code 1 --python scripts/glb_pipeline.py -- \
        <input.glb> <output dir> [--size 0.648] [--size-axis longest|x|y|z] [--max-tris 20000] \
        [--merge-distance 0.0001] [--frames 8] [--resolution 512] [--samples 32]

Writes <output dir>/<name>.report.txt, <name>-turntable-NN.webp and <name>.clean.glb.
The functions are also imported by pipeline_check.py, which runs them on a sample made in bpy.
"""
import argparse
import math
import os
import sys
import time

import bmesh
import bpy
from mathutils import Vector


def parse_args(argv):
    p = argparse.ArgumentParser(prog="glb_pipeline.py")
    p.add_argument("input")
    p.add_argument("output_dir")
    p.add_argument("--size", type=float, default=None, help="target size in meters along --size-axis")
    p.add_argument("--size-axis", default="longest", choices=["longest", "x", "y", "z"])
    p.add_argument("--max-tris", type=int, default=20000)
    p.add_argument("--merge-distance", type=float, default=0.0001, help="in the model's units, before scaling")
    p.add_argument("--min-part", type=float, default=0.01,
                   help="remove loose parts with fewer than this fraction of the faces (floaters); 0 keeps them")
    p.add_argument("--voxel-remesh", type=float, default=0,
                   help="rebuild the surface on a voxel grid of this size in meters, after scaling; 0 skips it")
    p.add_argument("--flat", action="store_true", help="keep flat shading instead of smooth shading")
    p.add_argument("--frames", type=int, default=8)
    p.add_argument("--resolution", type=int, default=512)
    p.add_argument("--samples", type=int, default=32)
    return p.parse_args(argv)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_glb(path):
    """Imports a .glb and joins its meshes into one object, with the transforms applied."""
    bpy.ops.import_scene.gltf(filepath=path)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"no mesh in {path}")
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    # Generated models often come under empties with rotations and scales: bake everything into the mesh
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in list(bpy.context.scene.objects):
        if o is not obj:
            bpy.data.objects.remove(o)
    obj.name = "Model"
    return obj


def mesh_report(obj):
    """Counts that tell whether a mesh is usable: triangles, manifold edges, loose parts, UVs, materials, bounds."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    tris = sum(len(f.verts) - 2 for f in bm.faces)
    boundary = sum(1 for e in bm.edges if e.is_boundary)
    non_manifold = sum(1 for e in bm.edges if not e.is_manifold)
    wire = sum(1 for e in bm.edges if e.is_wire)
    degenerate = sum(1 for f in bm.faces if f.calc_area() < 1e-12)

    # Loose parts: connected components over edges, with a union-find
    parent = list(range(len(bm.verts)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for e in bm.edges:
        a, b = find(e.verts[0].index), find(e.verts[1].index)
        if a != b:
            parent[a] = b
    parts = len({find(v.index) for v in bm.verts}) if bm.verts else 0

    uv_info = "none"
    if bm.loops.layers.uv:
        layer = bm.loops.layers.uv.active
        outside = total = 0
        uv_area = 0.0
        for f in bm.faces:
            uvs = [l[layer].uv for l in f.loops]
            for uv in uvs:
                total += 1
                if not (-1e-6 <= uv.x <= 1 + 1e-6 and -1e-6 <= uv.y <= 1 + 1e-6):
                    outside += 1
            for i in range(1, len(uvs) - 1):
                a, b, c = uvs[0], uvs[i], uvs[i + 1]
                uv_area += abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) / 2
        uv_info = (f"{len(bm.loops.layers.uv)} layer(s), {outside} of {total} UVs outside 0-1, "
                   f"UV area used {uv_area:.3f}")
    bm.free()

    corners = [obj.matrix_world @ v.co for v in mesh.vertices]
    lo = [min(c[i] for c in corners) for i in range(3)]
    hi = [max(c[i] for c in corners) for i in range(3)]
    size = [hi[i] - lo[i] for i in range(3)]
    images = sorted({(n.image.name, tuple(n.image.size)) for m in mesh.materials if m and m.node_tree
                     for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image}, key=str)
    return {
        "vertices": len(mesh.vertices), "faces": len(mesh.polygons), "triangles": tris,
        "boundary edges": boundary, "non-manifold edges": non_manifold, "wire edges": wire,
        "degenerate faces": degenerate, "loose parts": parts, "uv": uv_info,
        "materials": [m.name if m else None for m in mesh.materials],
        "images": [f"{n} {w}x{h}" for n, (w, h) in images],
        "size": "(" + ", ".join(f"{s:.4f}" for s in size) + ")",
        "min": "(" + ", ".join(f"{v:.4f}" for v in lo) + ")",
    }


def merge_by_distance(obj, distance):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    before = len(bm.verts)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=distance)
    after = len(bm.verts)
    bm.to_mesh(obj.data)
    bm.free()
    return before - after


def remove_small_parts(obj, fraction):
    """Deletes connected parts that hold fewer than `fraction` of the faces: the floaters of generated meshes."""
    if fraction <= 0:
        return []
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    seen, parts = set(), []
    for f in bm.faces:
        if f.index in seen:
            continue
        stack, part = [f], []
        seen.add(f.index)
        while stack:
            face = stack.pop()
            part.append(face)
            for e in face.edges:
                for g in e.link_faces:
                    if g.index not in seen:
                        seen.add(g.index)
                        stack.append(g)
        parts.append(part)
    total = len(bm.faces)
    small = [p for p in parts if len(p) < fraction * total]
    removed = sorted(len(p) for p in small)
    bmesh.ops.delete(bm, geom=[f for p in small for f in p], context="FACES")
    # Vertices and edges left without any face are parts too, and glTF would drop them silently
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=[e for e in bm.edges if not e.link_faces], context="EDGES_FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.is_valid and not v.link_faces], context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    return removed, len(loose)


def recalc_normals(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()


def decimate(obj, max_tris):
    """Adds a Decimate modifier when the mesh has more triangles than max_tris, and applies it."""
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if tris <= max_tris:
        return None
    ratio = max_tris / tris
    apply_modifier(obj, "DECIMATE", ratio=ratio)
    return ratio, tris, sum(len(p.vertices) - 2 for p in obj.data.polygons)


def apply_modifier(obj, kind, **settings):
    mod = obj.modifiers.new(kind.title(), kind)
    for k, v in settings.items():
        setattr(mod, k, v)
    with bpy.context.temp_override(object=obj, active_object=obj):
        bpy.ops.object.modifier_apply(modifier=mod.name)


def size_and_origin(obj, size, axis):
    """Scales the mesh to a real size in meters and puts the origin at the bottom center, at the world origin."""
    verts = obj.data.vertices
    lo = [min(v.co[i] for v in verts) for i in range(3)]
    hi = [max(v.co[i] for v in verts) for i in range(3)]
    dims = [hi[i] - lo[i] for i in range(3)]
    factor = 1.0
    if size:
        index = dims.index(max(dims)) if axis == "longest" else "xyz".index(axis)
        factor = size / dims[index]
    center = Vector(((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]))
    for v in verts:
        v.co = (v.co - center) * factor
    obj.data.update()
    obj.location = (0, 0, 0)
    return factor


def turntable(obj, out_dir, name, frames, resolution, samples):
    """Renders the model from `frames` angles around it with Cycles on the CPU, lit by a neutral studio."""
    scene = bpy.context.scene
    dims = obj.dimensions
    radius = max(dims) * 1.6
    height = dims.z / 2

    world = bpy.data.worlds.new("Studio") if scene.world is None else scene.world
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.05, 0.05, 0.055, 1)
    bg.inputs["Strength"].default_value = 1.0

    def add_light(name, energy, loc):
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy * radius * radius  # watts scale with the square of the distance
        light.size = radius
        o = bpy.data.objects.new(name, light)
        scene.collection.objects.link(o)
        o.location = loc
        d = Vector((0, 0, height)) - o.location
        o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()

    add_light("Key", 60, (radius, -radius, radius * 1.2))
    add_light("Fill", 20, (-radius, -radius * 0.5, radius * 0.5))
    add_light("Rim", 40, (0, radius * 1.2, radius))

    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = 50

    pivot = bpy.data.objects.new("Turntable", None)
    scene.collection.objects.link(pivot)
    obj.parent = pivot

    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_adaptive_sampling = False
    scene.cycles.use_denoising = False
    scene.cycles.seed = 0
    scene.render.resolution_x = scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "WEBP"
    scene.render.image_settings.quality = 90

    distance = radius * 1.4
    cam.location = (0, -distance, height + radius * 0.5)
    d = Vector((0, 0, height)) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()

    paths, seconds = [], []
    for i in range(frames):
        pivot.rotation_euler = (0, 0, 2 * math.pi * i / frames)
        path = os.path.join(out_dir, f"{name}-turntable-{i:02d}.webp")
        scene.render.filepath = path
        start = time.perf_counter()
        bpy.ops.render.render(write_still=True)
        seconds.append(time.perf_counter() - start)
        paths.append(path)
    obj.parent = None
    for o in list(scene.objects):
        if o is not obj:
            bpy.data.objects.remove(o)
    return paths, seconds


def export_glb(obj, path):
    """Exports for three.js: +Y up, modifiers applied, only this object."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True)
    return os.path.getsize(path)


def run(args, write):
    """The whole pipeline; write(line) receives the report. Lines starting with '# ' vary from run to run."""
    name = os.path.splitext(os.path.basename(args.input))[0]
    os.makedirs(args.output_dir, exist_ok=True)
    clear_scene()
    obj = import_glb(args.input)

    write(f"== {name}: as imported")
    for k, v in mesh_report(obj).items():
        write(f"{k}: {v}")

    write("")
    write("== Cleanup")
    write(f"merge by distance ({args.merge_distance}): {merge_by_distance(obj, args.merge_distance)} vertices removed")
    removed, loose = remove_small_parts(obj, args.min_part)
    write(f"loose parts under {args.min_part:.0%} of the faces removed: {len(removed)} (faces: {removed}); "
          f"vertices without faces removed: {loose}")
    recalc_normals(obj)
    if args.flat:
        write("normals recalculated outside, flat shading kept")
    else:
        obj.data.shade_smooth()
        write("normals recalculated outside, smooth shading")
    factor = size_and_origin(obj, args.size, args.size_axis)
    write(f"scale factor: {factor:.6f} (size {args.size} m along {args.size_axis}); origin at the bottom center")
    if args.voxel_remesh:
        before = len(obj.data.polygons)
        apply_modifier(obj, "REMESH", mode="VOXEL", voxel_size=args.voxel_remesh, use_smooth_shade=not args.flat)
        size_and_origin(obj, None, args.size_axis)
        write(f"voxel remesh ({args.voxel_remesh} m): {before} faces -> {len(obj.data.polygons)} quads")
        # Walls thinner than a voxel break into crumbs: a second pass of the floater filter
        removed, _ = remove_small_parts(obj, args.min_part)
        write(f"loose parts under {args.min_part:.0%} of the faces removed after the remesh: {len(removed)} (faces: {removed})")
    result = decimate(obj, args.max_tris)
    if result is None:
        write("decimate: not needed")
    else:
        ratio, before, after = result
        missed = "; target missed" if after > args.max_tris * 1.05 else ""
        write(f"decimate: ratio {ratio:.4f}, {before} -> {after} triangles (target {args.max_tris}){missed}")

    write("")
    write("== After cleanup")
    for k, v in mesh_report(obj).items():
        write(f"{k}: {v}")

    out_glb = os.path.join(args.output_dir, name + ".clean.glb")
    write("")
    write("== Export")
    write(f"# {os.path.basename(out_glb)}: {export_glb(obj, out_glb)} bytes")

    if args.frames:
        paths, seconds = turntable(obj, args.output_dir, name, args.frames, args.resolution, args.samples)
        write(f"turntable: {len(paths)} frames, {args.resolution}x{args.resolution}, {args.samples} samples, Cycles CPU")
        write(f"# turntable seconds per frame: {', '.join(f'{s:.2f}' for s in seconds)}")

    # The exported file, read back: what three.js will receive
    clear_scene()
    again = import_glb(out_glb)
    write("")
    write("== The exported .glb, imported again")
    for k, v in mesh_report(again).items():
        write(f"{k}: {v}")
    # glTF stores one vertex per distinct (position, normal, UV): seams and sharp edges split vertices again
    merged = merge_by_distance(again, 1e-7)
    report = mesh_report(again)
    write(f"merged again by position: {merged} vertices, boundary edges {report['boundary edges']},"
          f" non-manifold edges {report['non-manifold edges']}, loose parts {report['loose parts']}")
    return out_glb


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    args = parse_args(argv)
    lines = []

    def write(line):
        print(line)
        lines.append(line)

    run(args, write)
    name = os.path.splitext(os.path.basename(args.input))[0]
    with open(os.path.join(args.output_dir, name + ".report.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
