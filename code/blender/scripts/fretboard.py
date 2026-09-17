"""The course's model: a 22-fret guitar fretboard with a 648 mm (25.5 inch) scale, built from code.

Units are meters. X runs along the neck from the nut (x = 0) toward the body, Y across it, Z up.
Frets sit where equal temperament puts them: fret n is at scale * (1 - 2 ** (-n / 12)) from the nut.
"""
import math

import bmesh
import bpy

SCALE = 0.648
FRETS = 22
NUT_WIDTH = 0.043
LAST_FRET_WIDTH = 0.056
THICKNESS = 0.006
FRET_WIRE_WIDTH = 0.0024
FRET_WIRE_HEIGHT = 0.0012
INLAYS = (3, 5, 7, 9, 12, 15, 17, 19, 21)


def fret_x(n):
    return SCALE * (1 - 2 ** (-n / 12))


def width_at(x):
    return NUT_WIDTH + (LAST_FRET_WIDTH - NUT_WIDTH) * x / fret_x(FRETS)


def board_mesh(name="Fretboard"):
    """A tapered slab from eight vertices and six quads, the way from_pydata expects them."""
    length = fret_x(FRETS) + 0.010
    w0, w1 = NUT_WIDTH / 2, width_at(length) / 2
    verts = [
        (0, -w0, -THICKNESS), (length, -w1, -THICKNESS), (length, w1, -THICKNESS), (0, w0, -THICKNESS),
        (0, -w0, 0), (length, -w1, 0), (length, w1, 0), (0, w0, 0),
    ]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.validate()
    return mesh


def unit_cube_mesh(name):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def dot_mesh(name="Inlay dot"):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=24, radius1=0.003, radius2=0.003, depth=0.0004)
    bm.to_mesh(mesh)
    bm.free()
    return mesh


def build(parent_collection=None):
    """Creates the fretboard, its fret wires and its inlays in a new collection, and returns the collection."""
    coll = bpy.data.collections.new("Fretboard")
    (parent_collection or bpy.context.scene.collection).children.link(coll)

    board = bpy.data.objects.new("Fretboard", board_mesh())
    coll.objects.link(board)

    wire = unit_cube_mesh("Fret wire")  # one mesh for 22 objects: linked duplicates
    for n in range(1, FRETS + 1):
        x = fret_x(n)
        obj = bpy.data.objects.new(f"Fret {n:02d}", wire)
        obj.location = (x, 0, FRET_WIRE_HEIGHT / 2)
        obj.scale = (FRET_WIRE_WIDTH, width_at(x), FRET_WIRE_HEIGHT)
        obj.parent = board
        coll.objects.link(obj)

    dot = dot_mesh()
    for n in INLAYS:
        x = (fret_x(n - 1) + fret_x(n)) / 2
        ys = (-0.012, 0.012) if n == 12 else (0.0,)
        for i, y in enumerate(ys):
            suffix = "ab"[i] if len(ys) > 1 else ""
            obj = bpy.data.objects.new(f"Inlay {n:02d}{suffix}", dot)
            obj.location = (x, y, 0.0001)
            obj.parent = board
            coll.objects.link(obj)
    return coll


def srgb_to_linear(c):
    """Blender's color sockets and glTF's color factors hold linear values; a hex color is sRGB."""
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def principled(name, hex_color, metallic, roughness):
    mat = bpy.data.materials.new(name)  # a new material comes with a Principled BSDF and a Material Output
    node = mat.node_tree.nodes["Principled BSDF"]
    rgb = [srgb_to_linear(int(hex_color[i:i + 2], 16) / 255) for i in (1, 3, 5)]
    node.inputs["Base Color"].default_value = (*rgb, 1.0)
    node.inputs["Metallic"].default_value = metallic
    node.inputs["Roughness"].default_value = roughness
    return mat


def add_materials():
    """Rosewood for the board, nickel silver for the frets, pearl for the inlays, set on the meshes."""
    mats = {
        "Rosewood": principled("Rosewood", "#5a3422", 0.0, 0.8),
        "Nickel silver": principled("Nickel silver", "#c9c6bd", 1.0, 0.25),
        "Pearl": principled("Pearl", "#ece6d6", 0.0, 0.3),
    }
    bpy.data.meshes["Fretboard"].materials.append(mats["Rosewood"])
    bpy.data.meshes["Fret wire"].materials.append(mats["Nickel silver"])
    bpy.data.meshes["Inlay dot"].materials.append(mats["Pearl"])
    return mats


def grain_image(width=256, height=32):
    """A packed image of wavy stripes, darker and lighter than the rosewood color, computed pixel by pixel.

    The image is 8 bits per channel in the sRGB color space: pixels takes sRGB values, stored as bytes without conversion.
    """
    image = bpy.data.images.new("Rosewood grain", width=width, height=height)
    base = [c / 255 for c in (90, 52, 34)]
    pixels = []
    for y in range(height):
        for x in range(width):
            grain = 0.5 + 0.5 * math.sin(y * 0.9 + math.sin(x * 0.05) * 2.0)
            pixels += [c * (0.75 + 0.35 * grain) for c in base] + [1.0]
    image.pixels.foreach_set(pixels)
    image.pack()
    return image
