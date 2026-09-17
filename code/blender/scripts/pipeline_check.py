"""Checks glb_pipeline.py in CI on a sample made here, shaped like what image-to-3D generators produce.

The sample is a guitar pick of about one unit, with the flaws of a generated mesh: triangles only, every face with
its own vertices, some faces turned inside out, a small floating blob, a texture with the lighting painted in,
and an origin away from the model. The generated models themselves stay out of the repository.
"""
import argparse
import os
import sys

import bmesh
import bpy
from mathutils import Matrix

sys.path.insert(0, os.path.dirname(__file__))
from common import Report, out_dir  # noqa: E402
import glb_pipeline  # noqa: E402

r = Report("pipeline_check")
work = os.path.abspath(os.path.join(out_dir(), "pipeline"))
os.makedirs(work, exist_ok=True)
sample = os.path.join(work, "sample-pick.glb")

bpy.ops.wm.read_factory_settings(use_empty=True)
mesh = bpy.data.meshes.new("pick")
bm = bmesh.new()
bm.loops.layers.uv.new("UVMap")
bmesh.ops.create_icosphere(bm, subdivisions=5, radius=0.5, calc_uvs=True)
for v in bm.verts:
    x, y, z = v.co
    # A flat teardrop: wide at one end, pointed at the other
    v.co = (x * (1.0 + 0.6 * y), y * 1.15, z * 0.12)
flipped = [f for f in bm.faces if f.calc_center_median().x > 0.25]
bmesh.ops.reverse_faces(bm, faces=flipped)
blob = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.03, matrix=Matrix.Translation((0.0, -0.75, 0.0)))
bmesh.ops.split_edges(bm, edges=bm.edges[:])
bm.to_mesh(mesh)
bm.free()

# The lighting painted into the texture: bright on top-left, dark on bottom-right, whatever the light in the scene
image = bpy.data.images.new("baked", 64, 64)
pixels = []
for j in range(64):
    for i in range(64):
        shade = 0.25 + 0.7 * (1 - i / 63) * (j / 63)
        pixels += [0.9 * shade, 0.45 * shade, 0.1 * shade, 1.0]
image.pixels.foreach_set(pixels)
image.pack()
mat = bpy.data.materials.new("generated")
tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
tex.image = image
mat.node_tree.links.new(tex.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
mesh.materials.append(mat)
obj = bpy.data.objects.new("pick", mesh)
bpy.context.scene.collection.objects.link(obj)
obj.location = (0.2, 0.0, 0.1)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=sample, export_format="GLB", use_selection=True)
r("# sample-pick.glb:", os.path.getsize(sample), "bytes")

args = argparse.Namespace(input=sample, output_dir=work, size=0.03, size_axis="longest", max_tris=2000,
                          merge_distance=0.0001, min_part=0.01, voxel_remesh=0, flat=False, frames=4, resolution=128, samples=8)
glb_pipeline.run(args, r)

# The same sample through a voxel remesh, the way out when Decimate can't reach its target on a non-manifold mesh
r("")
args.output_dir, args.voxel_remesh, args.frames = os.path.join(work, "remesh"), 0.0005, 0
glb_pipeline.run(args, r)
r.save()
