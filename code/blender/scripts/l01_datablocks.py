"""Lesson 1: the .blend file as a database of data-blocks.

What the factory startup scene contains, objects and the data they point to, users, linked and full duplicates,
orphans and fake users, what saving keeps, name collisions, and RNA introspection.
"""
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(__file__))
from common import Report, vec  # noqa: E402

r = Report("l01_datablocks")
D = bpy.data

r.section("Version")
r("bpy.app.version_string:", bpy.app.version_string)
r("bpy.app.version_file:", bpy.app.version_file)

r.section("The factory startup scene")
for scene in D.scenes:
    r("scene", repr(scene.name), "engine", scene.render.engine, "frames", scene.frame_start, "-", scene.frame_end)


def tree(coll, depth=0):
    r("  " * depth + "collection", repr(coll.name), "objects", sorted(o.name for o in coll.objects))
    for child in coll.children:
        tree(child, depth + 1)


tree(bpy.context.scene.collection)
for obj in sorted(D.objects, key=lambda o: o.name):
    data = obj.data
    r(f"object {obj.name!r} type {obj.type} data {type(data).__name__} {data.name!r} location {vec(obj.location, 3)}")

r.section("What bpy.data holds (non-empty collections)")
for prop in D.bl_rna.properties:
    if prop.type == "COLLECTION":
        items = getattr(D, prop.identifier)
        if len(items) and prop.identifier != "all_ids":
            r(f"bpy.data.{prop.identifier}: {sorted(i.name for i in items)}")

r.section("An object points to its data")
cube = D.objects["Cube"]
mesh = cube.data
r("cube.data is bpy.data.meshes['Cube']:", mesh == D.meshes["Cube"])
r("mesh", repr(mesh.name), "vertices", len(mesh.vertices), "edges", len(mesh.edges), "faces", len(mesh.polygons),
  "loops", len(mesh.loops))
r("material slots", [(s.link, s.material.name) for s in cube.material_slots])
r("users: object", cube.users, "mesh", mesh.users, "material", D.materials["Material"].users)

r.section("Linked duplicate (Alt+D) and full duplicate (Shift+D)")
linked = cube.copy()  # a new object, the same mesh
linked.name = "Linked"
bpy.context.scene.collection.objects.link(linked)
r("after the linked duplicate: objects", len(D.objects), "meshes", len(D.meshes), "mesh users", mesh.users)
full = cube.copy()
full.data = mesh.copy()  # a new object and a new mesh
full.name = "Full"
bpy.context.scene.collection.objects.link(full)
r("after the full duplicate: meshes", sorted((m.name, m.users) for m in D.meshes))
r("the material is shared by both meshes: material users", D.materials["Material"].users)

r.section("Orphans and fake users")
D.objects.remove(full)
r("after removing the object 'Full': meshes", sorted((m.name, m.users) for m in D.meshes))
kept = D.meshes.new("Kept")
kept.use_fake_user = True
r("a new mesh with a fake user: users", kept.users, "use_fake_user", kept.use_fake_user)
path = os.path.abspath(os.path.join(os.path.dirname(r.path), "l01.blend"))
bpy.ops.wm.save_as_mainfile(filepath=path, copy=True)
with D.libraries.load(path) as (data_from, data_to):
    r("meshes written to the file:", sorted(data_from.meshes))
    r("objects written to the file:", sorted(data_from.objects))
r("# file size in bytes:", os.path.getsize(path))
purged = bpy.ops.outliner.orphans_purge(do_local_ids=True, do_linked_ids=True, do_recursive=True)
r("orphans_purge:", purged, "meshes left", sorted((m.name, m.users) for m in D.meshes))

r.section("Names are unique per type")
again = D.meshes.new("Cube")
r("D.meshes.new('Cube').name:", repr(again.name))
r("a material may also be called 'Cube':", repr(D.materials.new("Cube").name))
long_name = "x" * 300
r("a 300-character name is cut to", len(D.meshes.new(long_name).name), "characters")

r.section("RNA: properties describe themselves")
loc = bpy.types.Object.bl_rna.properties["location"]
r("Object.location: type", loc.type, "subtype", loc.subtype, "unit", loc.unit, "array_length", loc.array_length)
r("default", list(loc.default_array))
r("repr(cube):", repr(cube))
r("repr(cube.location):", repr(cube.location))
r("path_from_id('location'):", cube.path_from_id("location"))
r("path_resolve('location'):", repr(cube.path_resolve("location")))
r("Object has", len(bpy.types.Object.bl_rna.properties), "RNA properties; Mesh has",
  len(bpy.types.Mesh.bl_rna.properties))
r("an ID's own properties:", [p.identifier for p in bpy.types.ID.bl_rna.properties][:8])

r.section("Exercise 1: remove the Cube object, save, and reload")
bpy.ops.wm.read_factory_settings(use_empty=False)
D = bpy.data
D.objects.remove(D.objects["Cube"])
r("before saving: mesh 'Cube' users", D.meshes["Cube"].users, "| material 'Material' users", D.materials["Material"].users)
path = os.path.abspath(os.path.join(os.path.dirname(r.path), "l01-ex1.blend"))
bpy.ops.wm.save_as_mainfile(filepath=path)
bpy.ops.wm.open_mainfile(filepath=path)
D = bpy.data
r("after reloading: meshes", sorted(m.name for m in D.meshes), "| materials", sorted((m.name, m.users) for m in D.materials))

r.section("Exercise 2: who uses a data-block?")
bpy.ops.wm.read_factory_settings(use_empty=False)
D = bpy.data
cube = D.objects["Cube"]
twin = cube.copy()
twin.name = "Twin"
bpy.context.scene.collection.objects.link(twin)
users = D.user_map(subset=[D.meshes["Cube"], D.materials["Material"]])
for id_, used_by in sorted(users.items(), key=lambda kv: kv[0].name):
    r(f"{id_!r} is used by {sorted(repr(u) for u in used_by)}")

r.save()
