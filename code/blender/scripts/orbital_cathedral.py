"""Original scene study. Run ONLY in a separate --background --factory-startup process.
Usage: blender --background --factory-startup --python-exit-code 1 --threads 8
       --python orbital_cathedral.py -- <new-output-directory>
Verification: actual render, saved blend, object assertions, machine-readable report.
No reference-artifact source or generated ComfyUI asset is used.
"""
import json
import math
import random
import sys
import time
from pathlib import Path

import bpy
from mathutils import Vector

# Reuse the course's camera aiming and area-light helpers, never its destructive build_scene.
sys.path.insert(0, str(Path(__file__).parent))
from stage import aim, area_light

assert bpy.app.background, "This script must not run in the user's interactive Blender."
out = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
out.mkdir(parents=True, exist_ok=False)
scene = bpy.context.scene
for obj in list(scene.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
rng = random.Random(190926)

def material(name, color, metallic=0.0, roughness=0.4, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Emission Color"].default_value = (*color, 1)
    shader.inputs["Emission Strength"].default_value = emission
    return mat

stone = material("Midnight basalt", (0.021, 0.037, 0.052), 0.45, 0.28)
gold = material("Brushed champagne titanium", (0.52, 0.28, 0.095), 0.78, 0.25)
cyan = material("Glacial light", (0.025, 0.65, 1.0), emission=5)
amber = material("Solar light", (1.0, 0.35, 0.045), emission=6)
white = material("Star light", (0.65, 0.8, 1.0), emission=3)
water = material("Obsidian mirror", (0.008, 0.025, 0.039), 0.8, 0.19)

def cube(name, loc, scale, mat, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name, obj.dimensions = name, scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Soft machined edges", "BEVEL")
        mod.width, mod.segments = bevel, 3
    return obj

def ring(name, center, radius, thickness, mat, tilt=0):
    bpy.ops.mesh.primitive_torus_add(major_segments=128, minor_segments=12,
        location=center, major_radius=radius, minor_radius=thickness,
        rotation=(math.pi / 2, tilt, 0))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj

cube("Infinite reflecting basin", (0, 10, -0.3), (170, 170, 0.3), water)
cube("Processional causeway", (0, -1.5, 0), (3.2, 29, 0.5), stone, 0.1)
for x in (-1.57, 1.57):
    cube("Recessed cyan guide", (x, -1.5, 0.27), (0.025, 29, 0.015), cyan)
for y in range(-15, 14, 2):
    cube("Causeway brass joint", (0, y, 0.26), (3.12, 0.018, 0.015), gold)
for side in (-1, 1):
    for i in range(9):
        x, y, h = side * (5.6 + i * 0.25), -10 + i * 3.7, 10.5 + i * 0.6
        cube("Cathedral monolith", (x, y, h / 2), (0.7, 0.9, h), stone, 0.09)
        cube("Monolith inlay", (x - side * 0.36, y - 0.46, h / 2),
             (0.045, 0.04, h * 0.92), gold)
        cube("Monolith beacon", (x, y, h + 0.04), (0.7, 0.9, 0.04), cyan)
center = (0, 11, 6.2)
for r, t, m in [(5.7, .22, gold), (5.35, .055, cyan), (4.95, .16, stone),
                 (4.65, .035, amber), (3.8, .055, gold)]:
    ring("Astronomical halo", center, r, t, m)
for i in range(48):
    a = i * math.tau / 48
    obj = cube("Radial calibration", (5.68 * math.cos(a), 10.98, 6.2 + 5.68 * math.sin(a)),
               (.06, .42, .35 if i % 4 == 0 else .15), amber if i % 4 == 0 else gold)
    obj.rotation_euler[1] = math.pi / 2 - a
bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=32, radius=2.7, location=(0, 14, 6.2))
planet = bpy.context.object
planet.name = "Dark celestial core"
planet.data.materials.append(stone)
for p in planet.data.polygons:
    p.use_smooth = True
ring("Inclined orbital filament", (0, 14, 6.2), 3.45, .026, cyan, .65)

# A small figure provides scale; all geometry is editable.
cube("Traveller cloak", (0.25, -0.5, 0.95), (.38, .25, 1.3), gold, .07)
bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=.16, location=(.25, -.5, 1.78))
bpy.context.object.name = "Traveller head"
bpy.context.object.data.materials.append(stone)
for i in range(180):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=rng.uniform(.018, .05),
        location=(rng.uniform(-55, 55), rng.uniform(45, 65), rng.uniform(4, 43)))
    bpy.context.object.name = "Distant star"
    bpy.context.object.data.materials.append(white)
world = scene.world
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs["Color"].default_value = (.012, .025, .07, 1)
bg.inputs["Strength"].default_value = .3
area_light("Glacial key", 3500, 9, (-8, 2, 14), (0, 9, 4), (.15, .55, 1))
area_light("Amber rim", 4500, 8, (6, 17, 11), (0, 8, 5), (1, .36, .1))
area_light("Causeway fill", 1600, 10, (0, -6, 9), (0, 4, 0), (.25, .55, 1))
cam_data = bpy.data.cameras.new("Processional camera")
cam = bpy.data.objects.new("Processional camera", cam_data)
scene.collection.objects.link(cam)
cam.location = (0, -24, 4.3)
aim(cam, (0, 11, 5.6))
cam_data.lens = 38
scene.camera = cam
try:
    scene.render.engine = "CYCLES"
except TypeError as exc:
    raise RuntimeError(f"Cycles unavailable: {exc}")
scene.cycles.device = "CPU"
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.cycles.time_limit = 95
scene.cycles.seed = 190926
scene.render.resolution_x, scene.render.resolution_y = 1100, 700
scene.render.resolution_percentage = 100
formats = {i.identifier for i in scene.render.image_settings.bl_rna.properties["file_format"].enum_items}
assert "PNG" in formats
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(out / "orbital-cathedral.png")
scene.render.threads_mode = "FIXED"
scene.render.threads = 8
assert len(scene.objects) > 250 and scene.camera
bpy.ops.wm.save_as_mainfile(filepath=str(out / "orbital-cathedral.blend"))
start = time.perf_counter()
bpy.ops.render.render(write_still=True)
seconds = time.perf_counter() - start
assert (out / "orbital-cathedral.png").stat().st_size > 10000
report = dict(blender=bpy.app.version_string, objects=len(scene.objects),
    engine=scene.render.engine, device=scene.cycles.device, cpu_threads=8,
    samples=24, resolution=[1100, 700], render_seconds=round(seconds, 3),
    gpu_seconds=0, comfyui_used=False, reference_artifact_read=False,
    source="Original procedural study; course stage.aim and stage.area_light reused")
(out / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report))
