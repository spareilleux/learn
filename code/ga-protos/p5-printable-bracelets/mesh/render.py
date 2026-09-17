"""Pictures of the bracelets, rendered by Blender in the background.

Blender is not needed to build or to measure anything: it only makes the images the lesson shows. Run it against an
installation you already have, read-only -- the script writes nothing inside Blender's folder:

    blender --background --python mesh/render.py -- --stl G:/learn-lab/ga-protos/p5/C-major-triad-cone.stl \
        --out public/ga-lab/p5/c-major-cone.png --view three-quarter

``--view top`` looks straight down the bangle's axis, which is the view that shows the bore, and therefore the view
that shows a bead eating into it.
"""

from __future__ import annotations

import argparse
import math
import sys

import bpy  # only exists inside Blender


def clear() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_stl(path: str):
    if hasattr(bpy.ops.wm, "stl_import"):
        bpy.ops.wm.stl_import(filepath=path)
    else:  # Blender 3.x and earlier
        bpy.ops.import_mesh.stl(filepath=path)
    obj = bpy.context.selected_objects[0]
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()
    for polygon in obj.data.polygons:
        polygon.use_smooth = False
    return obj


def material(obj, rgba=(0.10, 0.38, 0.78, 1.0)) -> None:
    mat = bpy.data.materials.new("filament")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = rgba
    bsdf.inputs["Roughness"].default_value = 0.55
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = 0.0
    obj.data.materials.append(mat)


def studio(view: str, radius: float) -> None:
    world = bpy.data.worlds.new("world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.02, 0.025, 0.05, 1.0)
    bpy.context.scene.world = world

    for name, location, energy in (
        ("key", (radius * 2.2, -radius * 2.4, radius * 2.6), 2400.0),
        ("fill", (-radius * 2.6, -radius * 1.2, radius * 1.2), 900.0),
        ("rim", (0.0, radius * 3.0, radius * 1.6), 1400.0),
    ):
        light = bpy.data.lights.new(name, type="AREA")
        light.energy = energy
        light.size = radius * 1.5
        obj = bpy.data.objects.new(name, light)
        obj.location = location
        obj.rotation_euler = (0.0, 0.0, 0.0)
        constraint = obj.constraints.new("TRACK_TO")
        bpy.context.scene.collection.objects.link(obj)
        constraint.track_axis = "TRACK_NEGATIVE_Z"
        constraint.up_axis = "UP_Y"

    camera_data = bpy.data.cameras.new("camera")
    camera_data.lens = 55.0
    camera = bpy.data.objects.new("camera", camera_data)
    if view == "top":
        camera.location = (0.0, 0.0, radius * 5.6)
        camera.rotation_euler = (0.0, 0.0, 0.0)
    else:
        angle = math.radians(24.0)
        camera.location = (0.0, -radius * 5.2 * math.cos(angle), radius * 5.2 * math.sin(angle))
        camera.rotation_euler = (math.radians(90.0) - angle, 0.0, 0.0)
    bpy.context.scene.collection.objects.link(camera)
    bpy.context.scene.camera = camera
    for light in [o for o in bpy.data.objects if o.type == "LIGHT"]:
        light.constraints[0].target = bpy.data.objects.get("bracelet")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stl", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--view", choices=["three-quarter", "top"], default="three-quarter")
    parser.add_argument("--width", type=int, default=1100)
    parser.add_argument("--height", type=int, default=800)
    parser.add_argument("--samples", type=int, default=64)
    args = parser.parse_args(argv)

    clear()
    obj = import_stl(args.stl)
    obj.name = "bracelet"
    material(obj)
    # The mesh is in millimetres and Blender's lights are in watts per square metre: a 70 mm bangle imported as a
    # 70 metre one comes out black. Normalise it to a bangle one unit across, centred on the origin.
    span = max(obj.dimensions.x, obj.dimensions.y)
    obj.scale = (2.0 / span, 2.0 / span, 2.0 / span)
    bpy.context.view_layer.update()
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.location = (0.0, 0.0, -obj.dimensions.z / 2.0)
    if args.view != "top":
        # Half a turn, so pitch class 0 -- its keel, and its bead when the set has a C -- is on the side facing the
        # camera. The top view keeps C where the reader expects it, at twelve o'clock.
        obj.rotation_euler = (0.0, 0.0, math.pi)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=False)
    radius = 1.0
    studio(args.view, radius)

    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "CYCLES"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    if scene.render.engine == "CYCLES":
        scene.cycles.samples = args.samples
    elif hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = args.samples
    scene.render.resolution_x = args.width
    scene.render.resolution_y = args.height
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.compression = 95
    scene.render.film_transparent = False
    scene.render.filepath = args.out
    bpy.ops.render.render(write_still=True)
    print(f"rendered {args.stl} -> {args.out} with {scene.render.engine}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]))
