"""The fretboard on a studio stage: three area lights, a camera aimed at the first frets, and a dim gray world.

Used by lesson 4 and by render_images.py.
"""
import math

import bpy
from mathutils import Vector

import fretboard


def aim(obj, target):
    """Points an object's -Z axis (where cameras and lights look) at a target, with +Y up."""
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def area_light(name, energy, size, location, target, color=(1.0, 1.0, 1.0)):
    light = bpy.data.lights.new(name, "AREA")
    light.energy = energy  # watts
    light.size = size  # meters
    light.color = color
    obj = bpy.data.objects.new(name, light)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    aim(obj, target)
    return obj


def build_scene(with_texture=False):
    """Replaces the factory scene with the fretboard, its materials, the lights, the camera and the world."""
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj)
    bpy.ops.outliner.orphans_purge(do_recursive=True)
    fretboard.build()
    mats = fretboard.add_materials()
    if with_texture:
        board = bpy.data.objects["Fretboard"]
        bpy.context.view_layer.objects.active = board
        board.select_set(True)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
        bpy.ops.object.mode_set(mode="OBJECT")
        tree = mats["Rosewood"].node_tree
        tex = tree.nodes.new("ShaderNodeTexImage")
        tex.image = fretboard.grain_image()
        tree.links.new(tex.outputs["Color"], tree.nodes["Principled BSDF"].inputs["Base Color"])

    target = (0.12, 0.0, 0.0)
    area_light("Key", 3.0, 0.25, (0.05, -0.45, 0.45), target, (1.0, 0.95, 0.88))
    area_light("Fill", 0.6, 0.5, (0.35, 0.45, 0.25), target, (0.85, 0.9, 1.0))
    area_light("Rim", 4.0, 0.1, (-0.25, 0.2, 0.12), target)

    cam_data = bpy.data.cameras.new("Camera")
    cam_data.lens = 50
    cam = bpy.data.objects.new("Camera", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = (-0.12, -0.2, 0.14)
    aim(cam, target)
    bpy.context.scene.camera = cam

    world = bpy.context.scene.world
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.02, 0.02, 0.025, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
