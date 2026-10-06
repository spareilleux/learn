"""The steel portal chamber, gaia geometry pass (OBSERVATORY-GAIA-ART-20261006, isolated copy only).

After "La boite fait encore tres cartoon" and "ok repare la geometrie de la boite" / "utilise blender"
(the author, 2026-10-06). Derived from the prototype's artpass/blender/steel_portal.py: the same
footprint, wall height, door, band heights, node names (DoorHinge, DoorLeaf...) and material names
(SP_Steel, SP_SteelTrim, SP_SteelDark...), so scripts/steel_cube.gd maps it the same way, and the same
baked brushed-steel images (artpass/blender/textures, not baked again). What changes, against what read
as a toy in the path-traced renders:
  - corners: the eight 68 mm round rods (EdgeRibs) are gone; the sheet is folded round each corner
    (30 mm radius), and every part around it (bands, cornice, plinth) follows the same rounded plan;
  - seam bands: 14 mm proud instead of 25, their edges rounded;
  - rivets: 22 mm button heads 4.5 mm proud instead of 36 mm and 7 mm, at a 120 mm pitch, each a
    little off its line and of its size; a few are hex bolts, a few are missing; the columns beside
    the corners (no joint there any more) are replaced by columns along the plate joints at +-0.96 m;
  - roof: a stepped cornice (fascia, step, drip lid) instead of one 22 cm slab;
  - plinth: two steps;
  - door: bevelled leaf, stamped panels with chamfered fields instead of flat plates, three barrel
    hinges, a lever handle on a backplate with a keyhole, flush screws; a stepped door frame;
  - a conduit with clamps and a junction box on the front-right face.
No texture is made or downloaded. Run (background, factory settings; never touches an open Blender):
  blender-launcher.exe --background --factory-startup --python <run_logged.py> -- steel_portal_gaia.py <log>
"""
import json
import math
import os
import random
import sys
import time

import bmesh
import bpy
from mathutils import Matrix, Vector

# The project is the nearest folder above this script that holds project.godot, so the same file
# builds into the gaia copy (artpass/gaia/blender) or the prototype (artpass/blender). run_logged.py
# execs it without __file__: its path is the first argument after "--".
HERE = os.path.dirname(os.path.abspath(sys.argv[sys.argv.index("--") + 1])).replace("\\", "/")
OUT = HERE
while not os.path.exists(OUT + "/project.godot"):
    if os.path.dirname(OUT) == OUT:
        raise SystemExit("no project.godot above " + HERE)
    OUT = os.path.dirname(OUT)
BLEND = HERE + "/steel_portal_gaia.blend"
GLB = OUT + "/assets/steel_portal_gaia.glb"
PREVIEW = HERE + "/steel_portal_gaia_preview.png"
CLOSEUP = HERE + "/steel_portal_gaia_closeup.png"
TEX_DIR = OUT + "/artpass/blender/textures"
REPORT = HERE + "/steel_portal_gaia_report.json"

TILE_M = 2.0
HALF = 2.0
CHAMFER = 0.55
FLOOR = 0.14
HEIGHT = 4.4
WALL = 0.14
DOOR_W = 1.5
DOOR_TOP = 2.8
DOOR_OPEN_DEG = 38.0
CORNER_R = 0.03       # the fold radius of the sheet at each corner
ARC_SEG = 6           # segments per 45 degree corner
SEED = 20261006

t0 = time.time()
rng = random.Random(SEED)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
collection = bpy.data.collections.new("SteelPortal")
scene.collection.children.link(collection)
helpers = bpy.data.collections.new("Cutters")
scene.collection.children.link(helpers)


def material(name, color, metallic, roughness, emission=None, strength=0.0):
    m = bpy.data.materials.new(name)
    if hasattr(m, "use_nodes"):
        m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (*color, 1.0)
    p.inputs["Metallic"].default_value = metallic
    p.inputs["Roughness"].default_value = roughness
    if emission:
        p.inputs["Emission Color"].default_value = (*emission, 1.0)
        p.inputs["Emission Strength"].default_value = strength
    m.diffuse_color = (*color, 1.0)
    return m


def brushed_material(name, color, mr_img, normal_img):
    m = bpy.data.materials.new(name)
    if hasattr(m, "use_nodes"):
        m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    p = nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (*color, 1.0)
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = mr_img
    sep = nodes.new("ShaderNodeSeparateColor")
    links.new(tex.outputs["Color"], sep.inputs["Color"])
    links.new(sep.outputs["Green"], p.inputs["Roughness"])
    links.new(sep.outputs["Blue"], p.inputs["Metallic"])
    ntex = nodes.new("ShaderNodeTexImage")
    ntex.image = normal_img
    nmap = nodes.new("ShaderNodeNormalMap")
    links.new(ntex.outputs["Color"], nmap.inputs["Color"])
    links.new(nmap.outputs["Normal"], p.inputs["Normal"])
    m.diffuse_color = (*color, 1.0)
    return m


def box_uvs(bm):
    uvl = bm.loops.layers.uv.new("UVMap")
    bm.normal_update()
    for f in bm.faces:
        n = f.normal
        t = Vector((-n.y, n.x))
        for loop in f.loops:
            co = loop.vert.co
            if abs(n.z) > 0.7 or t.length < 1e-6:
                u, v = co.x, co.y
            else:
                tn = t.normalized()
                u, v = co.x * tn.x + co.y * tn.y, co.z
            loop[uvl].uv = (u / TILE_M, v / TILE_M)


def new_object(name, bm, mat, parent=None, coll=collection, smooth=False, uvs=False):
    if uvs:
        box_uvs(bm)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    if smooth:
        for poly in me.polygons:
            poly.use_smooth = True
    me.materials.append(mat)
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    if parent:
        ob.parent = parent
    return ob


def smooth_by_angle(ob, degrees=30.0):
    """Shade smooth across the folded corners and the bevels' segments, sharp at edges over `degrees`.
    Blender 5 has no mesh auto-smooth flag: a geometry-nodes modifier, added after the solidify,
    boolean and bevel so it sees their edges, then a weighted-normal one; the glTF exporter applies
    both into the split normals."""
    ng = bpy.data.node_groups.get("GaiaSmoothByAngle")
    if ng is None:
        ng = bpy.data.node_groups.new("GaiaSmoothByAngle", "GeometryNodeTree")
        ng.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
        ng.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
        gi = ng.nodes.new("NodeGroupInput")
        go = ng.nodes.new("NodeGroupOutput")
        faces = ng.nodes.new("GeometryNodeSetShadeSmooth")
        faces.domain = "FACE"
        edges = ng.nodes.new("GeometryNodeSetShadeSmooth")
        edges.domain = "EDGE"
        ea = ng.nodes.new("GeometryNodeInputMeshEdgeAngle")
        cmp = ng.nodes.new("FunctionNodeCompare")
        cmp.data_type = "FLOAT"
        cmp.operation = "LESS_EQUAL"
        cmp.inputs[1].default_value = math.radians(degrees)
        ng.links.new(ea.outputs["Unsigned Angle"], cmp.inputs[0])
        ng.links.new(gi.outputs[0], faces.inputs["Geometry"])
        ng.links.new(faces.outputs["Geometry"], edges.inputs["Geometry"])
        ng.links.new(cmp.outputs[0], edges.inputs["Shade Smooth"])
        ng.links.new(edges.outputs["Geometry"], go.inputs[0])
    mod = ob.modifiers.new("SmoothByAngle", "NODES")
    mod.node_group = ng
    # Smooth vertices on a big panel otherwise average in the bevel and fillet faces: their normals
    # tilt by a different amount at each corner, and the long triangles of the exported panel show
    # as thin diagonal lines under the path tracer (shellverify-20261006, cabin_front). Area-weighted
    # normals keep each panel flat and leave the curvature to the small faces.
    wn = ob.modifiers.new("WeightedNormal", "WEIGHTED_NORMAL")
    wn.mode = "FACE_AREA"
    wn.weight = 100
    wn.keep_sharp = True


def octagon_offset(o=0.0):
    """The plan octagon pushed outwards by o metres on every face (not scaled)."""
    h = HALF + o
    c = (HALF - CHAMFER) + o * (math.sqrt(2.0) - 1.0)
    return [Vector(p) for p in [(-c, -h), (c, -h), (h, -c), (h, c), (c, h), (-c, h), (-h, c), (-h, -c)]]


def plan(o=0.0, r=None):
    """The rounded plan: the octagon offset by o, each corner filleted with radius CORNER_R + o."""
    pts = octagon_offset(o)
    rad = CORNER_R + o if r is None else r
    if rad <= 0:
        return pts
    out = []
    n = len(pts)
    half = math.radians(22.5)
    for i in range(n):
        p, a, b = pts[i], pts[i - 1], pts[(i + 1) % n]
        da, db = (a - p).normalized(), (b - p).normalized()
        d = rad * math.tan(half)
        p0, p1 = p + da * d, p + db * d
        c = p + (da + db).normalized() * (rad / math.cos(half))
        a0 = math.atan2(p0.y - c.y, p0.x - c.x)
        a1 = math.atan2(p1.y - c.y, p1.x - c.x)
        sweep = (a1 - a0 + math.pi) % (2 * math.pi) - math.pi
        for k in range(ARC_SEG + 1):
            ang = a0 + sweep * k / ARC_SEG
            out.append(Vector((c.x + rad * math.cos(ang), c.y + rad * math.sin(ang))))
    return out


def tube(bm, pts, z0, z1):
    bottom = [bm.verts.new((p.x, p.y, z0)) for p in pts]
    top = [bm.verts.new((p.x, p.y, z1)) for p in pts]
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((bottom[i], bottom[j], top[j], top[i]))


def slab(bm, pts, z0, z1):
    geom = bmesh.ops.contextual_create(bm, geom=[bm.verts.new((p.x, p.y, z0)) for p in pts])
    face = geom["faces"][0]
    ext = bmesh.ops.extrude_face_region(bm, geom=[face], use_keep_orig=True)
    top_verts = [v for v in ext["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=top_verts, vec=(0, 0, z1 - z0))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])


def box(bm, center, size, rot=None):
    m = Matrix.Translation(center)
    if rot is not None:
        m = m @ rot
    bmesh.ops.create_cube(bm, size=1.0, matrix=m @ Matrix.Diagonal((*size, 1.0)))


def cylinder(bm, center, radius, depth, axis="Z", segments=16):
    rot = {"Z": Matrix.Identity(4), "X": Matrix.Rotation(math.radians(90), 4, "Y"),
           "Y": Matrix.Rotation(math.radians(90), 4, "X")}[axis]
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=radius, depth=depth,
                          matrix=Matrix.Translation(center) @ rot)


def modifiers(ob, cutter=None, solidify=None, solidify_offset=-1.0, bevel=0.0, segments=2, angle=30.0):
    if solidify:
        s = ob.modifiers.new("Solidify", "SOLIDIFY")
        s.thickness = solidify
        s.offset = solidify_offset
    if cutter:
        b = ob.modifiers.new("DoorCut", "BOOLEAN")
        b.operation = "DIFFERENCE"
        b.solver = "EXACT"
        b.object = cutter
    if bevel:
        bv = ob.modifiers.new("EdgeBevel", "BEVEL")
        bv.width = bevel
        bv.segments = segments
        bv.limit_method = "ANGLE"
        bv.angle_limit = math.radians(angle)


# The same baked brushed-steel images as the prototype's shell: only the geometry changes.
MR_IMG = bpy.data.images.load(TEX_DIR + "/steel_brushed_metalrough.png")
NORMAL_IMG = bpy.data.images.load(TEX_DIR + "/steel_brushed_normal.png")
for img in (MR_IMG, NORMAL_IMG):
    img.colorspace_settings.name = "Non-Color"
MR_IMG.name = "SteelBrushed_MetalRough"
NORMAL_IMG.name = "SteelBrushed_normal"
MAT = {
    "steel": brushed_material("SP_Steel", (0.62, 0.64, 0.68), MR_IMG, NORMAL_IMG),
    "trim": brushed_material("SP_SteelTrim", (0.5, 0.51, 0.53), MR_IMG, NORMAL_IMG),
    "dark": material("SP_SteelDark", (0.2, 0.21, 0.23), 0.85, 0.45),
    "brass": material("SP_Brass", (0.8, 0.6, 0.32), 1.0, 0.3),
    "plaque": material("SP_Plaque", (0.08, 0.09, 0.1), 0.3, 0.6),
    "lamp": material("SP_StatusLamp", (0.2, 1.0, 0.5), 0.0, 0.4, (0.3, 1.0, 0.55), 6.0),
}

RIVET_R = 0.011
RIVET_H = 0.0045
counts = {"rivets": 0, "hex_bolts": 0, "missing": 0, "flush_screws": 0}


def rivet_head(bm, at, out, up=Vector((0, 0, 1)), r=RIVET_R, h=RIVET_H, seg=(16, 8)):
    z = out.normalized()
    x = up.cross(z)
    if x.length < 1e-6:
        x = Vector((1, 0, 0))
    x.normalize()
    y = z.cross(x)
    rot = Matrix((x, y, z)).transposed().to_4x4()
    m = Matrix.Translation(at) @ rot @ Matrix.Diagonal((r, r, h, 1.0))
    geom = bmesh.ops.create_uvsphere(bm, u_segments=seg[0], v_segments=seg[1], radius=1.0)
    back = [v for v in geom["verts"] if v.co.z < -1e-4]
    bmesh.ops.delete(bm, geom=back, context="VERTS")
    bmesh.ops.transform(bm, matrix=m, verts=[v for v in geom["verts"] if v.is_valid])


def hex_bolt(bm, at, out, up=Vector((0, 0, 1))):
    z = out.normalized()
    x = up.cross(z).normalized()
    y = z.cross(x)
    turn = Matrix.Rotation(rng.uniform(0, math.pi / 3), 4, "Z")
    rot = Matrix((x, y, z)).transposed().to_4x4() @ turn
    geom = bmesh.ops.create_cone(bm, cap_ends=True, segments=6, radius1=0.012, radius2=0.012, depth=0.006,
                                 matrix=Matrix.Translation(at + z * 0.003) @ rot)
    return geom


def fastener(bm, at, out, along, up=Vector((0, 0, 1))):
    """A rivet a little off its line and of its size; now and then a hex bolt, or nothing."""
    roll = rng.random()
    if roll < 0.01:
        counts["missing"] += 1
        return
    p = at + along * rng.uniform(-0.0015, 0.0015) + up * rng.uniform(-0.0015, 0.0015)
    if roll < 0.025:
        hex_bolt(bm, p, out, up)
        counts["hex_bolts"] += 1
        return
    rivet_head(bm, p, out, up, r=RIVET_R * rng.uniform(0.92, 1.08), h=RIVET_H * rng.uniform(0.8, 1.15))
    counts["rivets"] += 1


# Door cutter: kept in the .blend, excluded from the export.
bm = bmesh.new()
box(bm, Vector((0, -HALF, FLOOR + (DOOR_TOP - FLOOR) / 2)), (DOOR_W, 1.2, DOOR_TOP - FLOOR))
cutter = bpy.data.objects.new("DoorCutter", bpy.data.meshes.new("DoorCutter"))
bm.to_mesh(cutter.data)
bm.free()
helpers.objects.link(cutter)
cutter.display_type = "WIRE"
cutter.hide_render = True

root = bpy.data.objects.new("SteelPortal", None)
collection.objects.link(root)

# Shell: the sheet folded round the corners, solidified inwards, the door cut, its edges eased.
bm = bmesh.new()
tube(bm, plan(0.0), FLOOR, HEIGHT)
shell = new_object("Shell", bm, MAT["steel"], root, uvs=True)
modifiers(shell, cutter, solidify=WALL, bevel=0.006, segments=2)
smooth_by_angle(shell)

# Seam bands: 14 mm proud, rounded edges, following the folded corners.
for name, z, height in [("BandBase", 0.26, 0.12), ("BandLow", 1.45, 0.04), ("BandHigh", 2.95, 0.04), ("BandTop", 4.22, 0.12)]:
    bm = bmesh.new()
    tube(bm, plan(0.002), z - height / 2, z + height / 2)
    ob = new_object(name, bm, MAT["trim"], root, uvs=True)
    modifiers(ob, cutter, solidify=0.012, solidify_offset=1.0, bevel=0.004, segments=3)
    smooth_by_angle(ob)

# Fasteners: rows either side of the narrow bands, above the base band and below the top band,
# and columns along the plate joints at +-0.96 m of each wide face's centre.
pts = octagon_offset(0.0)
row_z = (0.26 + 0.09, 1.45 - 0.07, 1.45 + 0.07, 2.95 - 0.07, 2.95 + 0.07, 4.22 - 0.09)
bm = bmesh.new()
for i in range(8):
    a, b = pts[i], pts[(i + 1) % 8]
    edge = b - a
    length = edge.length
    t = edge / length
    out = Vector((edge.y, -edge.x, 0.0)).normalized()
    t3 = Vector((t.x, t.y, 0.0))
    front = i == 0
    wide = i % 2 == 0
    margin = 0.1
    span = length - 2 * margin
    count = max(1, round(span / 0.12))
    for z in row_z:
        for j in range(count + 1):
            k = margin + span * j / count
            q = a + t * k
            if front and abs(q.x) < DOOR_W / 2 + 0.16 and z < DOOR_TOP + 0.05:
                continue
            fastener(bm, Vector((q.x, q.y, z)), out, t3)
    if wide:
        for side in (-1, 1):
            k = length / 2 + side * (0.96 + 0.028)
            q = a + t * k
            for lo, hi in ((0.32 + 0.09, 1.45 - 0.07), (1.45 + 0.07, 2.95 - 0.07), (2.95 + 0.07, 4.22 - 0.09)):
                n_up = max(1, round((hi - lo) / 0.15))
                for j in range(1, n_up):
                    z = lo + (hi - lo) * j / n_up
                    if front and abs(q.x) < DOOR_W / 2 + 0.16 and z < DOOR_TOP + 0.05:
                        continue
                    fastener(bm, Vector((q.x, q.y, z)), out, t3)
new_object("Rivets", bm, MAT["trim"], root, smooth=True, uvs=True)

# Roof: a stepped cornice (fascia, step, drip lid) instead of one slab.
bm = bmesh.new()
slab(bm, plan(0.012), HEIGHT, HEIGHT + 0.12)
cornice = new_object("Cornice", bm, MAT["trim"], root, uvs=True)
modifiers(cornice, None, bevel=0.006, segments=2)
smooth_by_angle(cornice)
bm = bmesh.new()
slab(bm, plan(0.045), HEIGHT + 0.12, HEIGHT + 0.155)
step = new_object("CorniceStep", bm, MAT["trim"], root, uvs=True)
modifiers(step, None, bevel=0.008, segments=2)
smooth_by_angle(step)
bm = bmesh.new()
slab(bm, plan(0.085), HEIGHT + 0.155, HEIGHT + 0.22)
roof = new_object("Roof", bm, MAT["steel"], root, uvs=True)
modifiers(roof, None, bevel=0.012, segments=3)
smooth_by_angle(roof)

# Plinth: two steps.
bm = bmesh.new()
slab(bm, plan(0.18), 0.0, 0.07)
slab(bm, plan(0.12), 0.07, FLOOR)
plinth = new_object("Plinth", bm, MAT["dark"], root)
modifiers(plinth, None, bevel=0.01, segments=2)
smooth_by_angle(plinth)

# Door frame: a stepped architrave.
bm = bmesh.new()
y = -HALF - 0.025
for sx in (-1, 1):
    box(bm, Vector((sx * (DOOR_W / 2 + 0.06), y, (FLOOR + DOOR_TOP + 0.12) / 2)), (0.12, 0.07, DOOR_TOP + 0.12 - FLOOR))
    box(bm, Vector((sx * (DOOR_W / 2 + 0.12 + 0.02), -HALF - 0.012, (FLOOR + DOOR_TOP + 0.16) / 2)), (0.04, 0.04, DOOR_TOP + 0.16 - FLOOR))
box(bm, Vector((0, y, DOOR_TOP + 0.06)), (DOOR_W + 0.24, 0.07, 0.12))
box(bm, Vector((0, -HALF - 0.012, DOOR_TOP + 0.14)), (DOOR_W + 0.32, 0.04, 0.04))
frame = new_object("DoorFrame", bm, MAT["trim"], root, uvs=True)
modifiers(frame, None, bevel=0.006, segments=2)

# Plaque, vents, status lamp, as before but eased.
bm = bmesh.new()
box(bm, Vector((1.12, -HALF - 0.006, 1.9)), (0.5, 0.012, 0.36))
plaque = new_object("Plaque", bm, MAT["trim"], root, uvs=True)
modifiers(plaque, None, bevel=0.004, segments=2)
bm = bmesh.new()
for sx in (-1, 1):
    for sz in (-1, 1):
        rivet_head(bm, Vector((1.12 + sx * 0.21, -HALF - 0.012, 1.9 + sz * 0.14)), Vector((0, -1, 0)), r=0.008, h=0.003)
new_object("PlaqueScrews", bm, MAT["trim"], root, smooth=True, uvs=True)
bm = bmesh.new()
box(bm, Vector((-1.12, -HALF - 0.004, 3.5)), (0.56, 0.008, 0.5))
new_object("VentRecess", bm, MAT["plaque"], root)
bm = bmesh.new()
for k in range(8):
    geom = bmesh.ops.create_cube(bm, size=1.0)
    m = Matrix.Translation((-1.12, -HALF - 0.03, 3.29 + k * 0.06)) @ Matrix.Rotation(math.radians(-35.0), 4, "X") \
        @ Matrix.Diagonal((0.52, 0.004, 0.055, 1.0))
    bmesh.ops.transform(bm, matrix=m, verts=geom["verts"])
box(bm, Vector((-1.12, -HALF - 0.03, 3.265)), (0.58, 0.05, 0.025))
box(bm, Vector((-1.12, -HALF - 0.03, 3.735)), (0.58, 0.05, 0.025))
for sx in (-1, 1):
    box(bm, Vector((-1.12 + sx * 0.2775, -HALF - 0.03, 3.5)), (0.025, 0.05, 0.495))
vents = new_object("Vents", bm, MAT["trim"], root, uvs=True)
modifiers(vents, None, bevel=0.002, segments=1)
bm = bmesh.new()
lamp_at = (pts[7] + pts[6]) / 2
bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.045,
                          matrix=Matrix.Translation((lamp_at.x - 0.04, lamp_at.y - 0.04, 1.2)))
new_object("StatusLamp", bm, MAT["lamp"], root, smooth=True)
bm = bmesh.new()
cylinder(bm, Vector((lamp_at.x - 0.012, lamp_at.y - 0.04, 1.2)), 0.06, 0.03, axis="X", segments=20)
new_object("StatusLampBezel", bm, MAT["dark"], root, smooth=True)

# Conduit and junction box on the front-right cut face (i = 1), clamped every 0.6 m or so.
a, b = pts[1], pts[2]
mid = (a + b) / 2
out1 = Vector(((b - a).y, -(b - a).x)).normalized()
along = (b - a).normalized()
face_rot = Matrix((Vector((along.x, along.y, 0)), Vector((out1.x, out1.y, 0)), Vector((0, 0, 1)))).transposed().to_4x4()
jb = Vector((mid.x, mid.y, 0.0)) + Vector((out1.x, out1.y, 0)) * 0.045 + Vector((0, 0, 0.95))
cx = Vector((mid.x, mid.y, 0.0)) + Vector((out1.x, out1.y, 0)) * 0.03
bm = bmesh.new()
box(bm, jb, (0.16, 0.08, 0.22), rot=face_rot)
box(bm, jb + Vector((out1.x, out1.y, 0)) * 0.042, (0.13, 0.006, 0.19), rot=face_rot)
junction = new_object("JunctionBox", bm, MAT["dark"], root)
modifiers(junction, None, bevel=0.006, segments=2)
bm = bmesh.new()
cylinder(bm, Vector((cx.x, cx.y, (FLOOR + 0.84) / 2)), 0.016, 0.84 - FLOOR, segments=14)
cylinder(bm, Vector((cx.x, cx.y, (1.06 + HEIGHT) / 2)), 0.016, HEIGHT - 1.06, segments=14)
for zc in (0.45, 1.6, 2.3, 3.4, 4.0):
    box(bm, Vector((cx.x, cx.y, zc)), (0.05, 0.05, 0.025), rot=face_rot)
new_object("Conduit", bm, MAT["dark"], root, smooth=True)

# Door: an empty on the hinge line, the leaf and its hardware parented to it.
hinge = bpy.data.objects.new("DoorHinge", None)
collection.objects.link(hinge)
hinge.parent = root
hinge.location = (-DOOR_W / 2, -HALF, FLOOR)
hinge.rotation_euler = (0, 0, math.radians(-DOOR_OPEN_DEG))
leaf_w, leaf_h = DOOR_W - 0.04, DOOR_TOP - FLOOR - 0.03
bm = bmesh.new()
box(bm, Vector((0.02 + leaf_w / 2, -0.045, 0.01 + leaf_h / 2)), (leaf_w, 0.09, leaf_h))
leaf = new_object("DoorLeaf", bm, MAT["steel"], hinge, uvs=True)
modifiers(leaf, None, bevel=0.005, segments=2)
bm = bmesh.new()
for zc in (0.72, 1.92):
    box(bm, Vector((0.02 + leaf_w / 2, -0.09 - 0.007, zc)), (leaf_w - 0.36, 0.014, 0.9))
panels = new_object("DoorPanels", bm, MAT["trim"], hinge, uvs=True)
modifiers(panels, None, bevel=0.01, segments=3)
bm = bmesh.new()
for zc in (0.3, leaf_h / 2 + 0.01, leaf_h - 0.28):
    cylinder(bm, Vector((-0.004, -0.098, zc)), 0.019, 0.16, segments=16)
    cylinder(bm, Vector((-0.004, -0.098, zc + 0.085)), 0.011, 0.012, segments=12)
    box(bm, Vector((0.045, -0.093, zc)), (0.09, 0.006, 0.15))
hinges = new_object("DoorHinges", bm, MAT["trim"], hinge, smooth=False, uvs=True)
modifiers(hinges, None, bevel=0.002, segments=1)
bm = bmesh.new()
hx = leaf_w - 0.14
box(bm, Vector((hx, -0.095, 1.2)), (0.05, 0.01, 0.26))
cylinder(bm, Vector((hx, -0.11, 1.26)), 0.022, 0.02, axis="Y", segments=20)
cylinder(bm, Vector((hx - 0.065, -0.128, 1.26)), 0.011, 0.13, axis="X", segments=12)
bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=0.013, matrix=Matrix.Translation((hx - 0.13, -0.128, 1.26)))
handle = new_object("DoorHandle", bm, MAT["brass"], hinge, smooth=True)
bm = bmesh.new()
box(bm, Vector((hx, -0.1005, 1.12)), (0.008, 0.002, 0.022))
new_object("DoorKeyhole", bm, MAT["plaque"], hinge)
bm = bmesh.new()
for zc in (0.2, leaf_h / 2, leaf_h - 0.2):
    for xc in (0.1, leaf_w - 0.06):
        rivet_head(bm, Vector((xc, -0.09, zc)), Vector((0, -1, 0)), r=0.007, h=0.0015)
        counts["flush_screws"] += 1
new_object("DoorRivets", bm, MAT["trim"], hinge, smooth=True, uvs=True)

bpy.context.view_layer.update()
os.makedirs(os.path.dirname(GLB), exist_ok=True)
os.makedirs(HERE, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=BLEND)

for ob in scene.objects:
    ob.select_set(ob.users_collection[0] == collection)
bpy.ops.export_scene.gltf(filepath=GLB, export_format="GLB", use_selection=True, export_apply=True, export_yup=True)

# The prototype script's two previews, from the same cameras, for a before/after outside Godot.
cam_data = bpy.data.cameras.new("PreviewCamera")
cam = bpy.data.objects.new("PreviewCamera", cam_data)
helpers.objects.link(cam)
cam.location = (3.4, -8.2, 2.3)
cam.rotation_euler = (Vector((0, 0, 1.9)) - cam.location).to_track_quat("-Z", "Y").to_euler()
cam_data.lens = 40
scene.camera = cam
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "MATERIAL"
scene.display.shading.show_cavity = True
scene.display.shading.show_shadows = True
scene.render.resolution_x, scene.render.resolution_y = 960, 720
scene.render.filepath = PREVIEW
bpy.ops.render.render(write_still=True)

world = bpy.data.worlds.new("CloseupWorld")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.03, 0.045, 0.08, 1.0)
scene.world = world
key = bpy.data.lights.new("CloseupKey", "AREA")
key.energy = 900.0
key.size = 1.5
key.color = (0.82, 0.88, 1.0)
key_ob = bpy.data.objects.new("CloseupKey", key)
helpers.objects.link(key_ob)
key_ob.location = (3.2, -5.0, 4.2)
key_ob.rotation_euler = (Vector((0.6, -2.0, 2.2)) - key_ob.location).to_track_quat("-Z", "Y").to_euler()
warm = bpy.data.lights.new("CloseupWarm", "POINT")
warm.energy = 60.0
warm.color = (1.0, 0.72, 0.42)
warm_ob = bpy.data.objects.new("CloseupWarm", warm)
helpers.objects.link(warm_ob)
warm_ob.location = (0.0, -1.2, 2.0)
cam.location = (1.9, -4.3, 2.1)
cam.rotation_euler = (Vector((0.9, -2.0, 2.0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
cam_data.lens = 50
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 32
scene.render.resolution_x, scene.render.resolution_y = 960, 640
scene.render.filepath = CLOSEUP
tc = time.time()
bpy.ops.render.render(write_still=True)
closeup_seconds = round(time.time() - tc, 2)

depsgraph = bpy.context.evaluated_depsgraph_get()
objects = {}
total_faces = 0
for ob in collection.objects:
    if ob.type == "MESH":
        ev = ob.evaluated_get(depsgraph)
        me = ev.to_mesh()
        objects[ob.name] = {"verts": len(me.vertices), "faces": len(me.polygons), "material": ob.material_slots[0].material.name}
        total_faces += len(me.polygons)
        ev.to_mesh_clear()
    else:
        objects[ob.name] = {"type": ob.type}
report = {
    "blender": bpy.app.version_string, "seconds": round(time.time() - t0, 2), "seed": SEED,
    "blend": BLEND, "glb": GLB, "glb_bytes": os.path.getsize(GLB), "preview": PREVIEW, "closeup": CLOSEUP,
    "closeup_seconds": closeup_seconds, "fasteners": counts, "corner_radius_m": CORNER_R,
    "textures_reused": [TEX_DIR + "/steel_brushed_metalrough.png", TEX_DIR + "/steel_brushed_normal.png"],
    "total_faces": total_faces, "objects": objects,
}
with open(REPORT, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=1)
print("STEEL_PORTAL_GAIA_REPORT", json.dumps({k: report[k] for k in ("blender", "seconds", "glb_bytes", "fasteners", "total_faces")}))
