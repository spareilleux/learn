"""Four low-poly figures for a crowd that a game engine walks in its vertex shader, the walk carried in the UVs.

Made for the Observatory demo's palace gardens (version 38, 2026-10-04): a courtier in a long robe, a lady in a
flared gown, a walker in a knee-length tunic and a gardener in a wide hat, 1.7 m tall, no face, no costume from any
film or series. Each figure is one mesh in three materials, exported to glTF: skin, cloth (coloured per instance in
the game) and trim (shoes, trousers, hair, hat). The game's shader (Godot) reads the UVs, not the shape:
  u: a leg's swing, + for the left leg and - for the right, its size the stride (1, or 0.6 under a robe);
     +2 for the right arm and -2 for the left; 0 elsewhere;
  v, as glTF stores it: how far down a robe or a tunic hangs, 0 at the waist and 1 at the hem; 0 elsewhere.
glTF flips v (v_gltf = 1 - v_blender), so the script stores 1 - weight in Blender.

The report checks what the shader relies on: why a vertex's place cannot tell an arm from a leg, the triangle
count and flags of each figure, and that the flags come back unchanged from the exported files.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(__file__))
from common import Report, f, out_dir  # noqa: E402

HIP_Z = 0.92
SHOULDER_Z = 1.42
FIGURES = ("courtier", "lady", "walker", "gardener")


class Figure:
    """Parts by material, each a bmesh with a UV layer carrying the walk's flags."""

    def __init__(self):
        self.parts = {name: bmesh.new() for name in ("skin", "cloth", "trim")}
        self.uv = {name: bm.loops.layers.uv.new("UVMap") for name, bm in self.parts.items()}

    def _flag(self, mat, faces, swing, hang=None):
        """hang: a function of a vertex's height giving its sway weight (0 at the waist, 1 at the hem)."""
        uv = self.uv[mat]
        for face in faces:
            for loop in face.loops:
                w = hang(loop.vert.co.z) if hang else 0.0
                # glTF flips v (v' = 1 - v): stored flipped, the engine reads the weight.
                loop[uv].uv = (swing, 1.0 - w)

    def tube(self, mat, rings, sides=8, swing=0.0, hang=None, cap_bottom=True, cap_top=True):
        """rings: [(centre Vector, radius x, radius y)] from bottom to top, each a horizontal ellipse."""
        bm = self.parts[mat]
        loops = []
        for c, rx, ry in rings:
            loop = []
            for k in range(sides):
                a = 2.0 * math.pi * (k + 0.5) / sides
                loop.append(bm.verts.new(c + Vector((math.cos(a) * rx, math.sin(a) * ry, 0.0))))
            loops.append(loop)
        faces = []
        for i in range(len(loops) - 1):
            for k in range(sides):
                k1 = (k + 1) % sides
                faces.append(bm.faces.new((loops[i][k], loops[i][k1], loops[i + 1][k1], loops[i + 1][k])))
        if cap_bottom:
            faces.append(bm.faces.new(list(reversed(loops[0]))))
        if cap_top:
            faces.append(bm.faces.new(loops[-1]))
        self._flag(mat, faces, swing, hang)
        return faces

    def limb(self, mat, a, b, ra, rb, sides=6, swing=0.0):
        """A tapered tube from point a to point b."""
        bm = self.parts[mat]
        axis = (b - a).normalized()
        side = axis.orthogonal().normalized()
        up = axis.cross(side)
        loops = []
        for c, r in ((a, ra), (b, rb)):
            loops.append([bm.verts.new(c + (side * math.cos(2 * math.pi * k / sides) + up * math.sin(2 * math.pi * k / sides)) * r)
                          for k in range(sides)])
        faces = []
        for k in range(sides):
            k1 = (k + 1) % sides
            faces.append(bm.faces.new((loops[0][k], loops[0][k1], loops[1][k1], loops[1][k])))
        faces.append(bm.faces.new(list(reversed(loops[0]))))
        faces.append(bm.faces.new(loops[1]))
        self._flag(mat, faces, swing)
        return faces

    def blob(self, mat, centre, radii, subdiv=1, swing=0.0):
        bm = self.parts[mat]
        made = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0,
                                          matrix=Matrix.Translation(centre) @ Matrix.Diagonal((*radii, 1.0)))
        faces = list({face for v in made["verts"] for face in v.link_faces})
        self._flag(mat, faces, swing)
        return faces

    def box(self, mat, centre, size, swing=0.0):
        bm = self.parts[mat]
        made = bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(centre) @ Matrix.Diagonal((*size, 1.0)))
        faces = list({face for v in made["verts"] for face in v.link_faces})
        self._flag(mat, faces, swing)
        return faces


# The legs' and arms' sizes, named because the report compares them.
LEG_X, LEG_TOP_R = 0.095, 0.075
ARM_X, ARM_TOP_R = 0.2, 0.055


def body(fig, legs="trim", sleeves="cloth", stride=1.0):
    """Feet, legs, torso, neck, head, arms, hands: the parts every figure shares. Left is -X (facing +Y).
    stride: how far the legs swing (a robe shortens the step)."""
    for side, swing in ((-1.0, 1.0), (1.0, -1.0)):
        x = side * LEG_X
        fig.box("trim", Vector((x, 0.05, 0.035)), (0.1, 0.25, 0.07), swing=swing * stride)
        fig.limb(legs, Vector((x, 0.0, 0.07)), Vector((x, 0.0, HIP_Z)), 0.045, LEG_TOP_R, swing=swing * stride)
        # The arms swing against the legs on their side: 2 marks an arm.
        sx = side * ARM_X
        fig.limb(sleeves, Vector((sx, 0.0, SHOULDER_Z)), Vector((side * 0.235, 0.02, 0.84)), ARM_TOP_R, 0.04, swing=-2.0 * swing)
        fig.blob("skin", Vector((side * 0.24, 0.025, 0.79)), (0.04, 0.045, 0.055), swing=-2.0 * swing)
    fig.tube("cloth", [(Vector((0, 0, 0.86)), 0.16, 0.11), (Vector((0, 0, 1.05)), 0.15, 0.1),
                       (Vector((0, 0, 1.33)), 0.19, 0.115), (Vector((0, 0, 1.46)), 0.14, 0.09)])
    fig.limb("skin", Vector((0, 0, 1.44)), Vector((0, 0.005, 1.53)), 0.05, 0.045)
    fig.blob("skin", Vector((0, 0.01, 1.61)), (0.088, 0.1, 0.112), subdiv=2)


def robe(fig, waist_z, hem_r, mat="cloth"):
    """A robe flaring from the waist to the ankles, open at the foot."""
    def hang(z):
        return max(0.0, min(1.0, (waist_z - z) / (waist_z - 0.08)))
    fig.tube(mat, [(Vector((0, 0, 0.08)), hem_r, hem_r * 0.86), (Vector((0, 0, 0.5)), hem_r * 0.78, hem_r * 0.66),
                   (Vector((0, 0, waist_z)), 0.17, 0.12)], sides=12, hang=hang, cap_bottom=False, cap_top=False)


def make(name):
    fig = Figure()
    if name in ("courtier", "walker"):
        # Short hair over the crown and the back of the head, the face left bare.
        fig.blob("trim", Vector((0, -0.014, 1.648)), (0.093, 0.1, 0.088))
    if name == "courtier":
        body(fig, stride=0.6)
        robe(fig, 1.02, 0.3)
        # A mantle over the shoulders.
        fig.tube("cloth", [(Vector((0, -0.01, 1.2)), 0.25, 0.16), (Vector((0, 0, 1.47)), 0.2, 0.12)], sides=10,
                 cap_bottom=False)
        fig.tube("trim", [(Vector((0, 0, 1.0)), 0.175, 0.125), (Vector((0, 0, 1.05)), 0.172, 0.122)], sides=10)
    elif name == "lady":
        body(fig, stride=0.6)
        robe(fig, 1.1, 0.38)
        # Hair gathered at the back of the head.
        fig.blob("trim", Vector((0, -0.07, 1.64)), (0.07, 0.06, 0.065))
        fig.blob("trim", Vector((0, -0.01, 1.66)), (0.093, 0.095, 0.085))
    elif name == "walker":
        body(fig)
        fig.tube("cloth", [(Vector((0, 0, 0.6)), 0.22, 0.17), (Vector((0, 0, 0.98)), 0.165, 0.115)], sides=10,
                 hang=lambda z: max(0.0, min(1.0, (0.98 - z) / 0.38)), cap_bottom=False, cap_top=False)
        fig.tube("trim", [(Vector((0, 0, 0.94)), 0.168, 0.118), (Vector((0, 0, 0.99)), 0.166, 0.116)], sides=10)
    else:  # gardener
        body(fig)
        fig.tube("cloth", [(Vector((0, 0, 0.66)), 0.21, 0.16), (Vector((0, 0, 0.98)), 0.165, 0.115)], sides=10,
                 hang=lambda z: max(0.0, min(1.0, (0.98 - z) / 0.32)), cap_bottom=False, cap_top=False)
        # A wide straw hat.
        fig.tube("trim", [(Vector((0, 0.01, 1.68)), 0.24, 0.24), (Vector((0, 0.01, 1.7)), 0.24, 0.24)], sides=14)
        fig.tube("trim", [(Vector((0, 0.01, 1.69)), 0.11, 0.11), (Vector((0, 0.01, 1.79)), 0.095, 0.095)], sides=10)
    return fig


def flags(mesh):
    """Triangles by walk flag, read from the active UV layer: legs with the feet (|u| 1 or 0.6), arms with the hands (|u| 2), hanging cloth
    (a weight 1 - v above 0), and the largest weight."""
    uv = mesh.uv_layers.active.data
    out = {"legs": 0, "legs_robed": 0, "arms": 0, "hanging": 0, "still": 0}
    top = 0.0
    for p in mesh.polygons:
        us = [uv[i].uv[0] for i in p.loop_indices]
        ws = [1.0 - uv[i].uv[1] for i in p.loop_indices]
        tris = len(p.vertices) - 2
        u = max(us, key=abs)
        top = max(top, max(ws))
        if abs(abs(u) - 2.0) < 1e-4:
            out["arms"] += tris
        elif abs(abs(u) - 1.0) < 1e-4:
            out["legs"] += tris
        elif abs(abs(u) - 0.6) < 1e-4:
            out["legs_robed"] += tris
        elif max(ws) > 1e-4:
            out["hanging"] += tris
        else:
            out["still"] += tris
    return out, top


def export(name, fig, folder):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = []
    for mat, bm in fig.parts.items():
        if not bm.faces:
            continue
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        m = bpy.data.meshes.new(f"{name}_{mat}")
        bm.to_mesh(m)
        bm.free()
        # Cloth smooth too: flat, a robe's twelve facets read as stripes, one of them black in the shade.
        for p in m.polygons:
            p.use_smooth = mat in ("skin", "cloth")
        m.materials.append(bpy.data.materials.new(mat))
        o = bpy.data.objects.new(m.name, m)
        bpy.context.scene.collection.objects.link(o)
        o.select_set(True)
        objs.append(o)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = objs[0]
    path = os.path.join(folder, f"garden_figure_{name}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=True, export_normals=True, export_texcoords=True,
                              export_materials="EXPORT", export_image_format="NONE")
    return o.data, path


def reimport(path):
    """The exported file read back: one mesh per material, as glTF primitives."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    meshes = [o.data for o in bpy.context.scene.objects if o.type == "MESH"]
    tris = sum(len(p.vertices) - 2 for m in meshes for p in m.polygons)
    totals = {}
    top = 0.0
    for m in meshes:
        part, t = flags(m)
        top = max(top, t)
        for k, v in part.items():
            totals[k] = totals.get(k, 0) + v
    return tris, totals, top, len(meshes)


r = Report("crowd_kit")
folder = os.path.join(out_dir(), "crowd")
os.makedirs(folder, exist_ok=True)
r("# blender", bpy.app.version_string)

r.section("A vertex's place cannot tell an arm from a leg")
leg_out = LEG_X + LEG_TOP_R
arm_in = ARM_X - ARM_TOP_R
r("leg top, outer edge from the middle:", f(leg_out, 3), "m")
r("arm at the shoulder, inner edge from the middle:", f(arm_in, 3), "m")
r("overlap:", f(leg_out - arm_in, 3), "m, so the UVs flag them: |u| 1 or 0.6 a leg, |u| 2 an arm")

r.section("Figures")
for name in FIGURES:
    mesh, path = export(name, make(name), folder)
    tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
    top = max(v.co.z for v in mesh.vertices)
    by_flag, weight = flags(mesh)
    r(name, "triangles", tris, "vertices", len(mesh.vertices), "height", f(top, 3), "m")
    r("  by flag:", " ".join(f"{k} {v}" for k, v in by_flag.items()), "| largest hang weight", f(weight, 3))
    tris2, by_flag2, weight2, parts = reimport(path)
    same = tris2 == tris and by_flag2 == by_flag and abs(weight2 - weight) < 1e-4
    r("  read back from the .glb:", parts, "mesh," if parts == 1 else "meshes,", tris2, "triangles, flags", "unchanged" if same else f"CHANGED {by_flag2} {f(weight2, 3)}")
    r("#", name, os.path.getsize(path), "bytes")
r.save()
