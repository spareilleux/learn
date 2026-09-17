"""Lesson 3: node materials with the Principled BSDF, UV unwrapping, an image texture, and what glTF keeps of them."""
import json
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(__file__))
from common import Report, f, vec  # noqa: E402
import fretboard  # noqa: E402

r = Report("l03_materials")
D = bpy.data
for obj in list(D.objects):
    D.objects.remove(obj)
bpy.ops.outliner.orphans_purge(do_recursive=True)
coll = fretboard.build()
board = D.objects["Fretboard"]

r.section("A new material and its node tree")
rosewood = D.materials.new("Rosewood")
r("nodes of a new material:", sorted(n.bl_idname for n in rosewood.node_tree.nodes))
for link in rosewood.node_tree.links:
    r("link:", link.from_node.name, repr(link.from_socket.name), "->", link.to_node.name, repr(link.to_socket.name))
bsdf = rosewood.node_tree.nodes["Principled BSDF"]
inputs = [s for s in bsdf.inputs if s.enabled]
r("Principled BSDF inputs:", len(bsdf.inputs), "| enabled:", len(inputs))
for name in ("Base Color", "Metallic", "Roughness", "IOR", "Alpha", "Normal", "Coat Weight", "Emission Strength"):
    socket = bsdf.inputs[name]
    value = socket.default_value
    if isinstance(value, float):
        shown = f(value, 3)
    else:
        shown = vec(value, 3)
    r(f"  {name!r} {socket.bl_idname} {shown}")
r("the viewport color outside the node tree, diffuse_color:", vec(rosewood.diffuse_color, 3))

r.section("Three materials for the fretboard")
D.materials.remove(rosewood)
mats = fretboard.add_materials()  # the same Principled BSDF, with base color, metallic and roughness set
rosewood, nickel, pearl = mats["Rosewood"], mats["Nickel silver"], mats["Pearl"]
for mat in (rosewood, nickel, pearl):
    node = mat.node_tree.nodes["Principled BSDF"]
    r(f"{mat.name!r}: base color (linear) {vec(node.inputs['Base Color'].default_value[:3], 4)}"
      f" metallic {f(node.inputs['Metallic'].default_value, 2)} roughness {f(node.inputs['Roughness'].default_value, 2)}"
      f" users {mat.users}")
r("the material lives on the mesh (slot link DATA), so the 22 frets share it:",
  [s.link for s in D.objects["Fret 07"].material_slots], D.objects["Fret 07"].active_material.name)

r.section("UV unwrapping")
mesh = board.data
r("UV layers before:", [uv.name for uv in mesh.uv_layers])
bpy.context.view_layer.objects.active = board
board.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
result = bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02, scale_to_bounds=False)
bpy.ops.object.mode_set(mode="OBJECT")
r("smart_project:", result, "| UV layers after:", [uv.name for uv in mesh.uv_layers])
uv = mesh.uv_layers.active.data
top = mesh.polygons[1]
top_uvs = [uv[i].uv for i in top.loop_indices]
r("top face: loops", list(top.loop_indices), "| UV bounds", vec([min(c[k] for c in top_uvs) for k in (0, 1)], 3),
  vec([max(c[k] for c in top_uvs) for k in (0, 1)], 3))
r("UV coordinates are stored per loop (face corner), not per vertex:", len(uv), "UVs for", len(mesh.vertices),
  "vertices")

r.section("An image texture made from code")
image = fretboard.grain_image()
r("image", repr(image.name), "size", tuple(image.size), "channels", image.channels, "packed", image.packed_file is not None,
  "colorspace", image.colorspace_settings.name, "is_float", image.is_float)
image.pixels[0] = 0.5
r("pixels[0] = 0.5 reads back as", f(image.pixels[0], 4), "=", round(image.pixels[0] * 255), "/ 255")
tex = rosewood.node_tree.nodes.new("ShaderNodeTexImage")
tex.image = image
bsdf = rosewood.node_tree.nodes["Principled BSDF"]
rosewood.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
noise = rosewood.node_tree.nodes.new("ShaderNodeTexNoise")
rosewood.node_tree.links.new(noise.outputs["Fac"], bsdf.inputs["Roughness"])
r("Rosewood links:", sorted(f"{l.from_node.name}.{l.from_socket.name} -> {l.to_node.name}.{l.to_socket.name}"
                            for l in rosewood.node_tree.links))

r.section("Exported to glTF 2.0")
gltf_dir = os.path.join(os.path.dirname(r.path), "l03-gltf")
os.makedirs(gltf_dir, exist_ok=True)
gltf_path = os.path.join(gltf_dir, "fretboard.gltf")
result = bpy.ops.export_scene.gltf(filepath=gltf_path, export_format="GLTF_SEPARATE", export_yup=True)
r("export_scene.gltf:", result, "| files", sorted(os.listdir(gltf_dir)))
with open(gltf_path, encoding="utf-8") as fp:
    gltf = json.load(fp)
r("asset:", gltf["asset"])
r("extensionsUsed:", gltf.get("extensionsUsed", []))
r("nodes", len(gltf["nodes"]), "| meshes", len(gltf["meshes"]), "| materials", len(gltf["materials"]),
  "| textures", len(gltf.get("textures", [])), "| images", [(i["uri"], i["mimeType"]) for i in gltf.get("images", [])])
for mat in gltf["materials"]:
    pbr = mat["pbrMetallicRoughness"]
    shown = ", ".join(f"{k} {vec(v, 4) if isinstance(v, list) else v if isinstance(v, (dict, int)) else f(v, 4)}"
                      for k, v in sorted(pbr.items()))
    r(f"material {mat['name']!r}: {shown}")
for m in gltf["meshes"]:
    for p in m["primitives"]:
        attrs = {k: gltf["accessors"][v]["count"] for k, v in sorted(p["attributes"].items())}
        indices = gltf["accessors"][p["indices"]]["count"]
        r(f"mesh {m['name']!r}: attributes (count per accessor) {attrs} indices {indices} material {p.get('material')}")
nodes = {n["name"]: n for n in gltf["nodes"]}
fret = nodes["Fret 12"]
r("node 'Fret 12': mesh", fret["mesh"], "translation", vec(fret["translation"], 4), "scale", vec(fret["scale"], 4))
r("in Blender: location", vec(D.objects["Fret 12"].location, 4), "scale", vec(D.objects["Fret 12"].scale, 4))
r("root node 'Fretboard': rotation", vec(nodes["Fretboard"].get("rotation", [0, 0, 0, 1]), 4), "children",
  len(nodes["Fretboard"]["children"]))
r("# .bin size in bytes:", os.path.getsize(os.path.join(gltf_dir, "fretboard.bin")))

r.section("Modifiers and the exporter")
bpy.ops.mesh.primitive_cube_add(size=0.05, location=(0, 0.1, 0))
cube = bpy.context.object
cube.modifiers.new("Subdivision", "SUBSURF").levels = 2
bpy.ops.object.select_all(action="DESELECT")
cube.select_set(True)
os.makedirs(os.path.join(os.path.dirname(r.path), "l03-modifiers"), exist_ok=True)
mod_path = os.path.join(os.path.dirname(r.path), "l03-modifiers", "cube.gltf")
for apply in (False, True):
    bpy.ops.export_scene.gltf(filepath=mod_path, export_format="GLTF_SEPARATE", use_selection=True, export_apply=apply)
    with open(mod_path, encoding="utf-8") as fp:
        doc = json.load(fp)
    prim = doc["meshes"][0]["primitives"][0]
    r(f"export_apply={apply}: POSITION count {doc['accessors'][prim['attributes']['POSITION']]['count']},"
      f" indices {doc['accessors'][prim['indices']]['count']}")
D.objects.remove(cube)
bpy.ops.export_scene.gltf(filepath=gltf_path, export_format="GLTF_SEPARATE")

r.section("Exercise 1: unlink the noise")
rosewood.node_tree.links.remove(next(l for l in rosewood.node_tree.links if l.from_node.name == "Noise Texture"))
bpy.ops.export_scene.gltf(filepath=gltf_path, export_format="GLTF_SEPARATE")
with open(gltf_path, encoding="utf-8") as fp:
    mat = next(m for m in json.load(fp)["materials"] if m["name"] == "Rosewood")
r("Rosewood pbrMetallicRoughness keys:", sorted(mat["pbrMetallicRoughness"]), "| roughnessFactor",
  f(mat["pbrMetallicRoughness"]["roughnessFactor"], 4))

r.section("Exercise 2: one .glb file")
glb_path = os.path.join(os.path.dirname(r.path), "fretboard.glb")
bpy.ops.export_scene.gltf(filepath=glb_path, export_format="GLB")
with open(glb_path, "rb") as fp:
    head = fp.read(20)
r("magic", head[:4], "| version", int.from_bytes(head[4:8], "little"), "| first chunk type", head[16:20])
separate = sum(os.path.getsize(os.path.join(gltf_dir, n)) for n in os.listdir(gltf_dir))
r("# .glb", os.path.getsize(glb_path), "bytes | .gltf + .bin + .png", separate, "bytes")

r.section("Exercise 3: without +Y up")
bpy.ops.export_scene.gltf(filepath=gltf_path, export_format="GLTF_SEPARATE", export_yup=False)
with open(gltf_path, encoding="utf-8") as fp:
    fret = next(n for n in json.load(fp)["nodes"] if n["name"] == "Fret 12")
r("node 'Fret 12' translation", vec(fret["translation"], 4), "scale", vec(fret["scale"], 4))

r.save()
