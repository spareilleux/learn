"""Lesson 2: polygonal modeling from code, topology, and the non-destructive modifier stack."""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(__file__))
from common import Report, f, vec  # noqa: E402
import fretboard  # noqa: E402

r = Report("l02_modeling")
D = bpy.data
for obj in list(D.objects):
    D.objects.remove(obj)


def counts(mesh):
    return f"V {len(mesh.vertices)} E {len(mesh.edges)} F {len(mesh.polygons)}"


def topology(mesh):
    bm = bmesh.new()
    bm.from_mesh(mesh)
    sides = {}
    for face in bm.faces:
        kind = {3: "tris", 4: "quads"}.get(len(face.verts), "ngons")
        sides[kind] = sides.get(kind, 0) + 1
    boundary = sum(1 for e in bm.edges if e.is_boundary)
    non_manifold = sum(1 for e in bm.edges if not e.is_manifold)
    euler = len(bm.verts) - len(bm.edges) + len(bm.faces)
    bm.free()
    return f"{dict(sorted(sides.items()))} boundary edges {boundary} non-manifold edges {non_manifold} V-E+F {euler}"


def evaluated(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    eval_obj = obj.evaluated_get(depsgraph)
    text = counts(eval_obj.to_mesh())
    eval_obj.to_mesh_clear()
    return text


r.section("A mesh from vertices and faces (from_pydata)")
board = fretboard.board_mesh()
r("fretboard slab:", counts(board), "loops", len(board.loops))
r("topology:", topology(board))
r("face 0 (bottom) vertices", list(board.polygons[0].vertices), "normal", vec(board.polygons[0].normal, 3))
r("face 1 (top) vertices", list(board.polygons[1].vertices), "normal", vec(board.polygons[1].normal, 3))
faces = [tuple(p.vertices) for p in board.polygons]
flipped = D.meshes.new("Flipped")
flipped.from_pydata([v.co[:] for v in board.vertices], [], [tuple(reversed(faces[0]))] + faces[1:])
r("the bottom face wound the other way: normal", vec(flipped.polygons[0].normal, 3))

r.section("Open and non-manifold meshes")
plane = D.meshes.new("Plane")
plane.from_pydata([(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)], [], [(0, 1, 2, 3)])
r("one quad:", counts(plane), topology(plane))
book = D.meshes.new("Book")
book.from_pydata([(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0), (0, 0, 1), (1, 0, 1), (0, -1, 0), (1, -1, 0)], [],
                 [(0, 1, 2, 3), (0, 1, 5, 4), (0, 1, 7, 6)])
r("three quads sharing one edge:", counts(book), topology(book))
tri = D.meshes.new("Triangulated")
bm = bmesh.new()
bm.from_mesh(board)
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bm.to_mesh(tri)
bm.free()
r("the slab triangulated:", counts(tri), topology(tri))

r.section("The modifier stack is evaluated; the mesh stays as it is")
bpy.ops.mesh.primitive_cube_add(size=2)
cube = bpy.context.object
bevel = cube.modifiers.new("Bevel", "BEVEL")
bevel.width = 0.1
bevel.segments = 2
subsurf = cube.modifiers.new("Subdivision", "SUBSURF")
subsurf.levels = 2
r("stack", [m.name for m in cube.modifiers])
r("cube.data:", counts(cube.data), "| evaluated:", evaluated(cube))
bpy.ops.object.modifier_move_to_index(modifier="Subdivision", index=0)
r("stack", [m.name for m in cube.modifiers], "| evaluated:", evaluated(cube))
subsurf.show_viewport = False
r("Subdivision hidden in the viewport | evaluated:", evaluated(cube))
subsurf.show_viewport = True
bpy.ops.object.modifier_move_to_index(modifier="Bevel", index=0)
bpy.ops.object.modifier_apply(modifier="Bevel")
r("Bevel applied: stack", [m.name for m in cube.modifiers], "| cube.data:", counts(cube.data),
  "| evaluated:", evaluated(cube))

r.section("Mirror and Array")
bpy.ops.mesh.primitive_cube_add(size=1)
half = bpy.context.object
half.data.transform(Matrix.Translation((1, 0, 0)))  # the mesh moves, the object's origin stays at 0
mirror = half.modifiers.new("Mirror", "MIRROR")
array = half.modifiers.new("Array", "ARRAY")
array.count = 5
array.relative_offset_displace = (0, 1.5, 0)
r("a cube whose center is 1 m from the origin, mirrored in X, then 5 copies in Y:", evaluated(half))
array.relative_offset_displace = (0, 1, 0)
array.use_merge_vertices = True
r("copies that touch, with Merge on:", evaluated(half))
ev = half.evaluated_get(bpy.context.evaluated_depsgraph_get())
lo = [min(c[i] for c in ev.bound_box) for i in range(3)]
hi = [max(c[i] for c in ev.bound_box) for i in range(3)]
r("local bounds: evaluated", vec(lo, 2), vec(hi, 2), "| cube.data", vec([min(v.co[i] for v in half.data.vertices) for i in range(3)], 2),
  vec([max(v.co[i] for v in half.data.vertices) for i in range(3)], 2))

r.section("The course's fretboard")
for obj in list(D.objects):
    D.objects.remove(obj)
bpy.ops.outliner.orphans_purge(do_recursive=True)
coll = fretboard.build()
bpy.context.view_layer.update()  # computes matrix_world for the new objects and their parent
objs = sorted(coll.objects, key=lambda o: o.name)
by_mesh = {}
for obj in objs:
    by_mesh.setdefault(obj.data.name, []).append(obj.name)
for name, users in sorted(by_mesh.items()):
    r(f"mesh {name!r}: {counts(D.meshes[name])}, {len(users)} objects: {users[0]} to {users[-1]}")
for n in (1, 12, 22):
    fret = D.objects[f"Fret {n:02d}"]
    r(f"Fret {n:02d}: x {f(fret.location.x * 1000, 2)} mm, length {f(fret.scale.y * 1000, 2)} mm")
r("objects", len(objs), "| vertices stored", sum(len(D.meshes[n].vertices) for n in by_mesh),
  "| vertices drawn", sum(len(o.data.vertices) for o in objs))
corners = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
r("world bounds in mm", vec([min(c[i] for c in corners) * 1000 for i in range(3)], 1),
  vec([max(c[i] for c in corners) * 1000 for i in range(3)], 1))

r.section("Exercise 1: the Euler characteristic of a torus")
bpy.ops.mesh.primitive_torus_add(major_segments=48, minor_segments=12)
r("torus:", counts(bpy.context.object.data), topology(bpy.context.object.data))

r.section("Exercise 2: Subdivision then Bevel, without the angle limit")
bpy.ops.mesh.primitive_cube_add(size=2)
cube = bpy.context.object
subsurf = cube.modifiers.new("Subdivision", "SUBSURF")
subsurf.levels = 2
bevel = cube.modifiers.new("Bevel", "BEVEL")
bevel.width, bevel.segments = 0.1, 2
r("limit_method", bevel.limit_method, "angle", f(math.degrees(bevel.angle_limit), 1), "| evaluated:", evaluated(cube))
bevel.limit_method = "NONE"
r("limit_method NONE | evaluated:", evaluated(cube))

r.section("Exercise 3: the spacing of frets")
gaps = [fretboard.fret_x(n + 1) - fretboard.fret_x(n) for n in range(fretboard.FRETS)]
r("gap nut-1", f(gaps[0] * 1000, 3), "mm | gap 21-22", f(gaps[21] * 1000, 3), "mm | gap n / gap n+1",
  sorted({f(gaps[n] / gaps[n + 1], 6) for n in range(fretboard.FRETS - 1)}), "| 2 ** (1/12)", f(2 ** (1 / 12), 6))

r.save()
