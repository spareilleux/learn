"""A gramophone modelled in bpy: case, horn revolved from a profile, and a record turning at 78 rpm.

glTF Y-up, base on the origin, height 1, front towards +Z. Node names: caisse, pavillon, then disque, etiquette
and repere under the animated tourne. Written by the orchestrator's agent for the Atlas des Douze; kept here as
the comparison point of the journal entry on procedural modelling, and checked by scripts/atlas_check.py.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Matrix, Vector
import kit as C

OUT = os.environ.get("ATLAS_OUT") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "gramophone.glb")
FPS = 100
DURATION = 1.54       # 2 turns at 78 rpm
FRAMES = int(round(DURATION * FPS))   # 154
TURNS = 2

C.reset_scene(FPS)
wood = C.material("caisse", (0.30, 0.13, 0.05), 0.0, 0.4)
brass = C.material("pavillon", (0.85, 0.66, 0.32), 1.0, 0.28)
ebonite = C.material("disque", (0.02, 0.02, 0.02), 0.0, 0.25)
label = C.material("etiquette", (0.55, 0.08, 0.06), 0.0, 0.6)
mark = C.material("repere", (0.92, 0.88, 0.75), 0.0, 0.5)

TOP = 0.235
REC = Vector((-0.04, -0.03, 0.243))

# ---------------- caisse ----------------
bm = bmesh.new()
C.prism(bm, 0.0, 0.03, (-0.285, 0.285, -0.285, 0.285), (-0.285, 0.285, -0.285, 0.285))
C.prism(bm, 0.03, 0.22, (-0.26, 0.26, -0.26, 0.26), (-0.26, 0.26, -0.26, 0.26))
C.prism(bm, 0.22, TOP, (-0.272, 0.272, -0.272, 0.272), (-0.272, 0.272, -0.272, 0.272))
# front and side panels (proud frames)
C.box(bm, 0, -0.263, 0.125, 0.40, 0.008, 0.13)
C.box(bm, 0, 0.263, 0.125, 0.40, 0.008, 0.13)
C.box(bm, -0.263, 0, 0.125, 0.008, 0.40, 0.13)
C.box(bm, 0.263, 0, 0.125, 0.008, 0.40, 0.13)
C.recalc(bm)
caisse = C.new_object("caisse", bm, wood)
C.bevel(caisse, 0.004, 2, 35)
bm = C.mesh_to_bm(caisse)
# felt platter and crank (kept in the box node)
C.cylinder(bm, 0.195, 0.195, 0.008, 48, Matrix.Translation((REC.x, REC.y, TOP + 0.004)))
rotX = Matrix.Rotation(math.pi / 2, 4, 'Y')
C.cylinder(bm, 0.012, 0.012, 0.06, 12, Matrix.Translation((0.29, 0.03, 0.13)) @ rotX)
C.box(bm, 0.322, 0.03, 0.095, 0.012, 0.022, 0.09)
C.cylinder(bm, 0.013, 0.011, 0.05, 12, Matrix.Translation((0.35, 0.03, 0.06)) @ rotX)
C.recalc(bm)
bm.to_mesh(caisse.data)
bm.free()
C.smooth(caisse, 35)

# ---------------- pavillon (post, elbow, tone arm, soundbox, neck, bell) ----------------
bm = bmesh.new()
BASE = Vector((0.19, 0.19, 0.0))
C.cylinder(bm, 0.035, 0.03, 0.012, 24, Matrix.Translation((BASE.x, BASE.y, TOP + 0.006)))
C.cylinder(bm, 0.02, 0.02, 0.08, 16, Matrix.Translation((BASE.x, BASE.y, TOP + 0.045)))
ELBOW = Vector((BASE.x, BASE.y, 0.325))
bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=0.03, matrix=Matrix.Translation(ELBOW))

# tone arm to the soundbox resting on the record
needle = Vector((REC.x + 0.085, REC.y - 0.085, 0.0))
dirv = Vector((needle.x - ELBOW.x, needle.y - ELBOW.y, 0)).normalized()
SB = Vector((needle.x, needle.y, 0.29))
arm_end = SB - dirv * 0.012
arm_pts = [ELBOW + (arm_end - ELBOW) * (i / 6) for i in range(7)]
C.sweep_tube(bm, arm_pts, [0.016 - 0.007 * i / 6 for i in range(7)], 12, cap_end=True)
align = dirv.to_track_quat('Z', 'Y').to_matrix().to_4x4()
C.cylinder(bm, 0.036, 0.036, 0.016, 24, Matrix.Translation(SB) @ align)
C.cylinder(bm, 0.028, 0.028, 0.02, 24, Matrix.Translation(SB + dirv * 0.004) @ align)
C.cylinder(bm, 0.005, 0.002, 0.03, 8, Matrix.Translation((needle.x, needle.y, 0.262)))

# curved neck (swept tube)
d = Vector((-0.25, -0.8, 0.55)).normalized()
P3 = Vector((0.10, 0.14, 0.62))
neck = C.bezier(ELBOW + Vector((0, 0, 0.005)), Vector((0.19, 0.24, 0.52)), P3 - 0.15 * d, P3, 20)
R0, R1 = 0.02, 0.04
radii = [R0 + (R1 - R0) * (i / 20) ** 2 for i in range(21)]
C.sweep_tube(bm, neck, radii, 16)
C.recalc(bm)
pav = C.new_object("pavillon", bm, brass)

# bell: revolve a flared profile (Screw modifier) then give it thickness
L, R = 0.34, 0.20
prof = []
N = 16
for i in range(N + 1):
    s = i / N
    prof.append((R1 * math.exp(s * math.log(R / R1)), 0.0, -0.01 + s * (L + 0.01)))
prof.append((R + 0.012, 0.0, L - 0.004))
prof.append((R + 0.016, 0.0, L - 0.016))
bm = bmesh.new()
vs = [bm.verts.new(p) for p in prof]
for a, b in zip(vs, vs[1:]):
    bm.edges.new((a, b))
bell = C.new_object("bell_tmp", bm)
scr = bell.modifiers.new("revolve", 'SCREW')
scr.axis = 'Z'
scr.angle = 2 * math.pi
scr.steps = 36
scr.render_steps = 36
scr.screw_offset = 0.0
scr.use_merge_vertices = True
sol = bell.modifiers.new("thick", 'SOLIDIFY')
sol.thickness = 0.005
sol.offset = 0.0
C.apply_modifiers(bell)
bell.data.transform(Matrix.Translation(P3) @ d.to_track_quat('Z', 'Y').to_matrix().to_4x4())
bm = C.mesh_to_bm(pav)
bm.from_mesh(bell.data)
bpy.data.objects.remove(bell, do_unlink=True)
C.recalc(bm)
bm.to_mesh(pav.data)
bm.free()
C.smooth(pav, 50)

# ---------------- tourne (record, label, mark) ----------------
tourne = C.new_object("tourne", None, location=REC)
bm = bmesh.new()
C.cylinder(bm, 0.19, 0.19, 0.004, 64, Matrix.Translation((0, 0, 0.002)))
C.cylinder(bm, 0.178, 0.178, 0.0055, 64, Matrix.Translation((0, 0, 0.00275)))
C.cylinder(bm, 0.07, 0.07, 0.006, 32, Matrix.Translation((0, 0, 0.003)))
C.recalc(bm)
disque = C.new_object("disque", bm, ebonite, parent=tourne)
C.smooth(disque, 30)

bm = bmesh.new()
C.cylinder(bm, 0.055, 0.055, 0.0015, 32, Matrix.Translation((0, 0, 0.00675)))
C.cylinder(bm, 0.005, 0.005, 0.02, 12, Matrix.Translation((0, 0, 0.01)))
C.recalc(bm)
etiq = C.new_object("etiquette", bm, label, parent=tourne)
C.smooth(etiq, 30)

bm = bmesh.new()
C.box(bm, 0.145, 0.0, 0.0063, 0.05, 0.012, 0.0022)   # radial ivory tab near the rim
C.box(bm, 0.035, 0.0, 0.0078, 0.022, 0.008, 0.0016)  # matching stripe on the label
C.recalc(bm)
repere = C.new_object("repere", bm, mark, parent=tourne)

objs = [caisse, pav, tourne, disque, etiq, repere]
s = C.normalize_height(objs)
print("scale factor", s)

tourne.rotation_mode = 'XYZ'
for f in range(FRAMES + 1):
    tourne.rotation_euler = (0.0, 0.0, math.radians(360.0 * TURNS * f / FRAMES))
    tourne.keyframe_insert("rotation_euler", index=2, frame=f)
tourne.animation_data.action.name = "gramophone_tourne"
bpy.context.scene.frame_end = FRAMES
bpy.context.scene.frame_set(0)

for o in objs:
    if o.type == 'MESH':
        print("TRIS", o.name, C.triangles(o))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
C.export_glb(OUT)
print("EXPORTED", OUT, os.path.getsize(OUT))
