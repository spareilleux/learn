"""Shared helpers for the two procedural models: scene, materials, bmesh primitives, modifiers and glTF export.

Blender 5.2, Z-up, front towards -Y, which the glTF exporter turns into Y-up with the front towards +Z.
Written by the orchestrator's agent for the Atlas des Douze models.
"""
import math
import bpy
import bmesh
from mathutils import Matrix, Vector


def reset_scene(fps):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.fps = fps
    sc.render.fps_base = 1.0
    sc.frame_start = 0
    bpy.context.preferences.edit.keyframe_new_interpolation_type = 'LINEAR'
    return sc


def material(name, color, metallic=0.0, roughness=0.5):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    m.diffuse_color = (*color, 1.0)
    return m


def new_object(name, bm=None, mat=None, parent=None, location=(0, 0, 0)):
    if bm is None:
        obj = bpy.data.objects.new(name, None)
        obj.empty_display_size = 0.05
    else:
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        obj = bpy.data.objects.new(name, me)
        if mat:
            me.materials.append(mat)
    bpy.context.scene.collection.objects.link(obj)
    if parent:
        obj.parent = parent
        obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.location = location
    return obj


# ---------- bmesh primitives (all append into an existing bmesh) ----------

def prism(bm, z0, z1, r0, r1, dx0=0.0, dy0=0.0, dx1=0.0, dy1=0.0):
    """Frustum between two axis-aligned rectangles r=(xmin,xmax,ymin,ymax)."""
    def ring(z, r):
        x0, x1, y0, y1 = r
        return [bm.verts.new(v) for v in ((x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z))]
    a = ring(z0, r0)
    b = ring(z1, r1)
    bm.faces.new(list(reversed(a)))
    bm.faces.new(b)
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((a[i], a[j], b[j], b[i]))
    return a + b


def quad_prism(bm, pts_bottom, pts_top):
    """General 8-vertex hexahedron from two CCW (seen from +Z) quads."""
    a = [bm.verts.new(p) for p in pts_bottom]
    b = [bm.verts.new(p) for p in pts_top]
    bm.faces.new(list(reversed(a)))
    bm.faces.new(b)
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((a[i], a[j], b[j], b[i]))


def box(bm, cx, cy, cz, sx, sy, sz):
    prism(bm, cz - sz / 2, cz + sz / 2,
          (cx - sx / 2, cx + sx / 2, cy - sy / 2, cy + sy / 2),
          (cx - sx / 2, cx + sx / 2, cy - sy / 2, cy + sy / 2))


def cylinder(bm, radius1, radius2, depth, segments, matrix=Matrix.Identity(4), caps=True):
    bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=segments,
                          radius1=radius1, radius2=radius2, depth=depth, matrix=matrix)


def recalc(bm):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)


def apply_modifiers(obj):
    for mod in list(obj.modifiers):
        with bpy.context.temp_override(object=obj, active_object=obj, selected_objects=[obj]):
            bpy.ops.object.modifier_apply(modifier=mod.name)


def bevel(obj, width, segments=2, angle=35):
    m = obj.modifiers.new("Bevel", 'BEVEL')
    m.width = width
    m.segments = segments
    m.limit_method = 'ANGLE'
    m.angle_limit = math.radians(angle)
    m.harden_normals = False
    apply_modifiers(obj)


def smooth(obj, angle=35):
    me = obj.data
    me.shade_smooth()
    me.set_sharp_from_angle(angle=math.radians(angle))


def mesh_to_bm(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    return bm


def sweep_tube(bm, path_pts, radii, segments, cap_start=False, cap_end=False):
    """Tube along a polyline with parallel-transport frames. Returns (last ring verts, last frame)."""
    n = len(path_pts)
    tangents = []
    for i in range(n):
        a = path_pts[max(i - 1, 0)]
        b = path_pts[min(i + 1, n - 1)]
        tangents.append((b - a).normalized())
    up = Vector((1, 0, 0)) if abs(tangents[0].x) < 0.9 else Vector((0, 1, 0))
    u = tangents[0].cross(up).normalized()
    rings = []
    prev_t = tangents[0]
    for i in range(n):
        t = tangents[i]
        axis = prev_t.cross(t)
        if axis.length > 1e-8:
            ang = prev_t.angle(t)
            u = (Matrix.Rotation(ang, 3, axis.normalized()) @ u).normalized()
        prev_t = t
        v = t.cross(u).normalized()
        ring = []
        for k in range(segments):
            a = 2 * math.pi * k / segments
            ring.append(bm.verts.new(path_pts[i] + radii[i] * (math.cos(a) * u + math.sin(a) * v)))
        rings.append(ring)
    for i in range(n - 1):
        for k in range(segments):
            k2 = (k + 1) % segments
            bm.faces.new((rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k]))
    if cap_start:
        bm.faces.new(list(reversed(rings[0])))
    if cap_end:
        bm.faces.new(rings[-1])
    return rings[-1], (u, t.cross(u).normalized(), tangents[-1])


def bezier(p0, p1, p2, p3, steps):
    pts = []
    for i in range(steps + 1):
        s = i / steps
        pts.append((1 - s) ** 3 * p0 + 3 * (1 - s) ** 2 * s * p1 + 3 * (1 - s) * s ** 2 * p2 + s ** 3 * p3)
    return pts


def world_bbox(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    bpy.context.view_layer.update()
    for o in objs:
        if o.type != 'MESH':
            continue
        for v in o.data.vertices:
            w = o.matrix_world @ v.co
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def normalize_height(objs):
    """Uniformly scale mesh data and local translations so world height = 1, base at z=0."""
    lo, hi = world_bbox(objs)
    s = 1.0 / (hi.z - lo.z)
    for o in objs:
        if o.type == 'MESH':
            o.data.transform(Matrix.Scale(s, 4))
        o.location = o.location * s
    bpy.context.view_layer.update()
    lo, hi = world_bbox(objs)
    for o in objs:
        if o.parent is None:
            if o.type == 'MESH' and o.location.length < 1e-9:
                o.data.transform(Matrix.Translation((0, 0, -lo.z)))
            else:
                o.location.z -= lo.z
    bpy.context.view_layer.update()
    return s


def triangles(obj):
    me = obj.data
    me.calc_loop_triangles()
    return len(me.loop_triangles)


def export_glb(path):
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_animations=True,
        export_animation_mode='ACTIONS',
        export_force_sampling=True,
        export_draco_mesh_compression_enable=False,
        export_cameras=False,
        export_lights=False,
        export_materials='EXPORT',
    )
