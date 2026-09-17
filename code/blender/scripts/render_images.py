"""Renders the lessons' illustrations as WebP files, and prints how long each render took.

Not part of check.sh: these renders use the GPU for EEVEE and for Cycles with OptiX, and their pixels depend on it.
    blender --background --factory-startup --python scripts/render_images.py -- <output dir> [job ...]
Jobs: modifiers, materials, samples, engines (default: all).
"""
import math
import os
import sys
import time

import bpy

sys.path.insert(0, os.path.dirname(__file__))
from common import out_dir  # noqa: E402
import stage  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:]
OUT = out_dir()
JOBS = args[1:] or ["modifiers", "materials", "samples", "engines"]
scene = bpy.context.scene


def save(name, engine, samples=None, width=960, height=540, denoise=False, device="CPU"):
    scene.render.engine = engine
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = width, height, 100
    if engine == "CYCLES":
        c = scene.cycles
        c.device = device
        c.samples = samples
        c.use_adaptive_sampling = False
        c.use_denoising = denoise
        c.seed = 0
    elif samples:
        scene.eevee.taa_render_samples = samples
    settings = scene.render.image_settings
    settings.file_format = "WEBP"
    settings.quality = 90
    scene.render.filepath = os.path.join(OUT, name + ".webp")
    start = time.perf_counter()
    bpy.ops.render.render(write_still=True)
    seconds = time.perf_counter() - start
    print(f"RENDER {name}: {engine} {device if engine == 'CYCLES' else ''} samples {samples} denoise {denoise} {width}x{height} {seconds:.2f} s")
    return seconds


def use_gpu():
    prefs = bpy.context.preferences.addons["cycles"].preferences
    for backend in ("OPTIX", "CUDA"):
        try:
            prefs.compute_device_type = backend
        except TypeError:
            continue
        prefs.refresh_devices()
        gpus = [d for d in prefs.devices if d.type == backend]
        if gpus:
            for d in prefs.devices:
                d.use = d.type == backend
            print("GPU", backend, [d.name for d in gpus])
            return True
    return False


if "modifiers" in JOBS:
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj)
    for x, order in ((-1.4, ("BEVEL", "SUBSURF")), (1.4, ("SUBSURF", "BEVEL"))):
        bpy.ops.mesh.primitive_cube_add(size=2, location=(x, 0, 0))
        cube = bpy.context.object
        for kind in order:
            m = cube.modifiers.new(kind.title(), kind)
            if kind == "BEVEL":
                m.width, m.segments = 0.1, 2
            else:
                m.levels = m.render_levels = 2
        bpy.ops.object.shade_smooth()
    stage.area_light("Key", 400.0, 3.0, (-3, -5, 6), (0, 0, 0))
    stage.area_light("Fill", 100.0, 4.0, (5, -2, 2), (0, 0, 0))
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    cam.location = (0, -9, 4.5)
    stage.aim(cam, (0, 0, 0))
    scene.camera = cam
    save("l02-modifier-order", "CYCLES", samples=64, denoise=True)

if "materials" in JOBS or "engines" in JOBS or "samples" in JOBS:
    stage.build_scene(with_texture=True)

if "materials" in JOBS:
    save("l03-fretboard-materials", "CYCLES", samples=128, denoise=True)

if "samples" in JOBS:
    for samples in (1, 16, 256):
        save(f"l04-cycles-{samples}-samples", "CYCLES", samples=samples, width=480, height=270)
    save("l04-cycles-16-samples-denoised", "CYCLES", samples=16, width=480, height=270, denoise=True)

if "engines" in JOBS:
    cpu = save("l04-cycles-cpu", "CYCLES", samples=256, denoise=True)
    if use_gpu():
        save("l04-cycles-gpu", "CYCLES", samples=256, denoise=True, device="GPU")
    try:
        save("l04-eevee", "BLENDER_EEVEE", samples=64)  # the first EEVEE render compiles its shaders
        save("l04-eevee", "BLENDER_EEVEE", samples=64)
    except Exception as e:  # EEVEE needs a GPU context, even in the background
        print("EEVEE failed:", e)
