"""A metronome modelled in bpy: pyramid case, graduated scale, pendulum with a sliding weight, swinging at 80 BPM.

glTF Y-up, base on the origin, height 1, front towards +Z. Node names: corps, then tige and poids under the
animated pivot. Written by the orchestrator's agent for the Atlas des Douze; kept here as the comparison point
of the journal entry on procedural modelling against image-to-3D, and checked by scripts/atlas_check.py.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Matrix, Vector
import kit as C

OUT = os.environ.get("ATLAS_OUT") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "metronome.glb")
FPS = 60
PERIOD = 1.5          # one full back-and-forth at 80 BPM
FRAMES = int(round(PERIOD * FPS))   # 90
AMP = 20.0

C.reset_scene(FPS)
wood = C.material("corps", (0.36, 0.17, 0.07), 0.0, 0.45)
brass_t = C.material("tige", (0.83, 0.64, 0.30), 1.0, 0.3)
brass_p = C.material("poids", (0.83, 0.64, 0.30), 1.0, 0.25)

Z0, Z1 = 0.05, 0.90          # pyramid body
YB, YT = -0.145, -0.075      # front face y at Z0/Z1 (front is -Y)


def face_y(z):
    return YB + (z - Z0) * (YT - YB) / (Z1 - Z0)


# ---- body pyramid with a front slot cut by boolean ----
bm = bmesh.new()
C.prism(bm, Z0, Z1, (-0.22, 0.22, -0.145, 0.145), (-0.075, 0.075, -0.075, 0.075))
C.recalc(bm)
body = C.new_object("corps", bm, wood)

bm = bmesh.new()
zc0, zc1 = 0.085, 0.42
C.quad_prism(bm,
             [(-0.10, -0.40, zc0), (0.10, -0.40, zc0), (0.10, -0.095, zc0), (-0.10, -0.095, zc0)],
             [(-0.055, -0.40, zc1), (0.055, -0.40, zc1), (0.055, -0.095, zc1), (-0.055, -0.095, zc1)])
C.recalc(bm)
cutter = C.new_object("cutter", bm)
mod = body.modifiers.new("slot", 'BOOLEAN')
mod.operation = 'DIFFERENCE'
mod.solver = 'EXACT'
mod.object = cutter
C.apply_modifiers(body)
bpy.data.objects.remove(cutter, do_unlink=True)

bm = C.mesh_to_bm(body)
# plinth + moulding
C.prism(bm, 0.0, 0.035, (-0.25, 0.25, -0.175, 0.175), (-0.25, 0.25, -0.175, 0.175))
C.prism(bm, 0.035, 0.055, (-0.24, 0.24, -0.165, 0.165), (-0.225, 0.225, -0.15, 0.15))
# four small feet
for sx in (-1, 1):
    for sy in (-1, 1):
        C.cylinder(bm, 0.022, 0.018, 0.012, 12, Matrix.Translation((sx * 0.21, sy * 0.135, 0.004)))
# top cap and pointed roof
C.prism(bm, 0.895, 0.925, (-0.088, 0.088, -0.088, 0.088), (-0.088, 0.088, -0.088, 0.088))
C.prism(bm, 0.925, 0.99, (-0.08, 0.08, -0.08, 0.08), (-0.012, 0.012, -0.012, 0.012))
C.cylinder(bm, 0.012, 0.004, 0.012, 12, Matrix.Translation((0, 0, 0.994)))
# scale plate on the sloped front face, with tick marks
pz0, pz1 = 0.44, 0.86
def plate_quad(z, hw, t0, t1):
    return [(-hw, face_y(z) - t0, z), (hw, face_y(z) - t0, z), (hw, face_y(z) + t1, z), (-hw, face_y(z) + t1, z)]
C.quad_prism(bm, plate_quad(pz0, 0.04, 0.006, 0.003), plate_quad(pz1, 0.03, 0.006, 0.003))
n_ticks = 12
for i in range(n_ticks):
    z = pz0 + 0.02 + i * (pz1 - pz0 - 0.04) / (n_ticks - 1)
    hw = 0.02 if i % 2 == 0 else 0.012
    C.quad_prism(bm, plate_quad(z - 0.002, hw, 0.009, -0.004), plate_quad(z + 0.002, hw, 0.009, -0.004))
# rim around slot bottom (a small brass-free wooden sill)
C.prism(bm, 0.07, 0.085, (-0.11, 0.11, face_y(0.07) - 0.008, -0.09), (-0.11, 0.11, face_y(0.085) - 0.008, -0.09))
C.recalc(bm)
bm.to_mesh(body.data)
bm.free()
C.bevel(body, 0.004, 2, 35)
C.smooth(body, 35)

# ---- pivot + pendulum ----
PIV = Vector((0.0, -0.135, 0.16))
pivot = C.new_object("pivot", None, location=PIV)
pivot.empty_display_type = 'ARROWS'

bm = bmesh.new()
C.cylinder(bm, 0.0065, 0.0065, 0.80, 12, Matrix.Translation((0, 0, 0.34)))           # rod -0.06..0.74
C.cylinder(bm, 0.0065, 0.002, 0.02, 12, Matrix.Translation((0, 0, 0.75)))             # tip
C.cylinder(bm, 0.014, 0.014, 0.022, 16, Matrix.Rotation(math.pi / 2, 4, 'X'))        # pivot hub
C.cylinder(bm, 0.018, 0.018, 0.03, 16, Matrix.Translation((0, 0, -0.045)))            # counterweight
C.recalc(bm)
tige = C.new_object("tige", bm, brass_t, parent=pivot)
C.smooth(tige, 40)

bm = bmesh.new()
C.quad_prism(bm,
             [(-0.034, -0.02, 0.47), (0.034, -0.02, 0.47), (0.034, 0.018, 0.47), (-0.034, 0.018, 0.47)],
             [(-0.022, -0.02, 0.53), (0.022, -0.02, 0.53), (0.022, 0.018, 0.53), (-0.022, 0.018, 0.53)])
C.recalc(bm)
poids = C.new_object("poids", bm, brass_p, parent=pivot)
C.bevel(poids, 0.005, 3, 30)
bm = C.mesh_to_bm(poids)
C.cylinder(bm, 0.009, 0.009, 0.016, 16, Matrix.Translation((0, -0.026, 0.5)) @ Matrix.Rotation(math.pi / 2, 4, 'X'))
C.cylinder(bm, 0.014, 0.014, 0.006, 16, Matrix.Translation((0, -0.036, 0.5)) @ Matrix.Rotation(math.pi / 2, 4, 'X'))
C.recalc(bm)
bm.to_mesh(poids.data)
bm.free()
C.smooth(poids, 30)

objs = [body, pivot, tige, poids]
s = C.normalize_height(objs)
print("scale factor", s)

# ---- animation: sine swing about the front axis (Blender Y = glTF -Z) ----
pivot.rotation_mode = 'XYZ'
for f in range(FRAMES + 1):
    ang = AMP * math.sin(2 * math.pi * f / FRAMES)
    pivot.rotation_euler = (0.0, math.radians(ang), 0.0)
    pivot.keyframe_insert("rotation_euler", index=1, frame=f)
pivot.animation_data.action.name = "metronome_balancier"
pivot.rotation_euler = (0, 0, 0)
bpy.context.scene.frame_end = FRAMES
bpy.context.scene.frame_set(0)

for o in objs:
    if o.type == 'MESH':
        print("TRIS", o.name, C.triangles(o))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
C.export_glb(OUT)
print("EXPORTED", OUT, os.path.getsize(OUT))
