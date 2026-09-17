"""Lesson 4: lights, a camera, color management, and Cycles on the CPU: samples, noise, seed and denoising."""
import hashlib
import math
import os
import sys
import time

import bpy

sys.path.insert(0, os.path.dirname(__file__))
from common import Report, f, vec  # noqa: E402
import stage  # noqa: E402

r = Report("l04_render")
D = bpy.data
scene = bpy.context.scene
out = os.path.dirname(r.path)

r.section("Render engines")
r("engine of the factory scene:", scene.render.engine)
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
r("RenderSettings.engine enum at class level:", engines)
r("RenderEngine subclasses:", sorted(f"{t.__name__} {getattr(t, 'bl_idname', '-')}" for t in bpy.types.RenderEngine.__subclasses__()))

stage.build_scene()

r.section("Lights and camera")
for obj in sorted((o for o in scene.objects if o.type == "LIGHT"), key=lambda o: o.name):
    light = obj.data
    size = f" size {f(light.size, 2)} m" if light.type == "AREA" else ""
    r(f"{obj.name}: {light.type} {f(light.energy, 1)} W{size} color {vec(light.color, 2)} location {vec(obj.location, 2)}")
cam = scene.camera
r(f"camera: lens {f(cam.data.lens, 1)} mm sensor {f(cam.data.sensor_width, 1)} mm"
  f" horizontal field of view {f(math.degrees(cam.data.angle), 1)} degrees location {vec(cam.location, 3)}")
world = scene.world.node_tree.nodes["Background"]
r("world background:", vec(world.inputs["Color"].default_value[:3], 3), "strength", f(world.inputs["Strength"].default_value, 2))

r.section("Color management")
vs = scene.view_settings
r("display device", scene.display_settings.display_device, "| view transform", vs.view_transform, "| look", vs.look,
  "| exposure", f(vs.exposure, 1), "| gamma", f(vs.gamma, 1))

r.section("Cycles settings")
scene.render.engine = "CYCLES"
c = scene.cycles
r("device", c.device, "| samples", c.samples, "| adaptive", c.use_adaptive_sampling, "threshold", f(c.adaptive_threshold, 3),
  "| denoise", c.use_denoising, c.denoiser, "| seed", c.seed, "| max bounces", c.max_bounces,
  "| clamp indirect", f(c.sample_clamp_indirect, 1))

c.device = "CPU"
c.use_adaptive_sampling = False  # every pixel gets every sample, so noise follows the sample count
c.use_denoising = False
c.seed = 0
scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 160, 90, 100
scene.render.use_persistent_data = False


def render(name, samples, fmt="OPEN_EXR"):
    c.samples = samples
    settings = scene.render.image_settings
    settings.file_format = fmt
    if fmt == "OPEN_EXR":
        settings.color_depth = "32"
        path = os.path.join(out, f"l04-{name}.exr")
    else:
        settings.color_depth = "8"
        path = os.path.join(out, f"l04-{name}.png")
    scene.render.filepath = path
    start = time.perf_counter()
    bpy.ops.render.render(write_still=True)
    seconds = time.perf_counter() - start
    image = D.images.load(path)
    pixels = list(image.pixels)
    D.images.remove(image)
    return pixels, seconds


def rms(a, b):
    """Root mean square difference over the RGB channels of two float images."""
    total = n = 0
    for i in range(0, len(a), 4):
        for k in range(3):
            total += (a[i + k] - b[i + k]) ** 2
            n += 1
    return math.sqrt(total / n)


def mean_rgb(p):
    count = len(p) // 4
    return [sum(p[i + k] for i in range(0, len(p), 4)) / count for k in range(3)]


r.section("Noise against the sample count (160 x 90, no adaptive sampling, no denoising)")
reference, seconds = render("reference", 4096)
r("reference: 4096 samples, mean linear RGB", vec(mean_rgb(reference), 3))
r("# reference render time", f(seconds, 2), "s")
previous = None
for samples in (1, 4, 16, 64, 256):
    pixels, seconds = render(f"s{samples}", samples)
    error = rms(pixels, reference)
    ratio = "" if previous is None else f" | previous / this {f(previous / error, 2)}"
    r(f"{samples:4d} samples: RMS difference from the reference {f(error, 4)}{ratio}")
    r(f"# {samples} samples: {f(seconds, 2)} s")
    previous = error

r.section("The seed")
a, _ = render("seed0", 16)
b, _ = render("seed0-again", 16)
c.seed = 1
d, _ = render("seed1", 16)
r("16 samples, seed 0 twice: identical", a == b, "| seed 0 and seed 1: identical", a == d, "RMS between them", f(rms(a, d), 4))
c.seed = 0

r.section("Denoising")
c.use_denoising = True
c.denoiser = "OPENIMAGEDENOISE"
c.denoising_use_gpu = False
denoised, seconds = render("s16-denoised", 16)
r("16 samples + OpenImageDenoise: RMS difference from the reference", f(rms(denoised, reference), 4),
  "| without:", f(rms(a, reference), 4))
r("# denoised render time", f(seconds, 2), "s")
c.use_denoising = False

r.section("The same render, 8 bits after the view transform")
png, _ = render("s16", 16, fmt="PNG")
digest = hashlib.sha256(bytes(round(v * 255) for v in png)).hexdigest()
r("# pixels sha256", digest)
r("mean 8-bit RGB", vec([x * 255 for x in mean_rgb(png)], 1))

r.save()
