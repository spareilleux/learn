"""Reads a binary glTF (.glb) without a 3D library: counts, materials, bounding box and topology.

A .glb is a 12-byte header (magic "glTF", version 2, total length), then chunks: a JSON chunk (the glTF document:
meshes, accessors, bufferViews, materials, textures) and usually a BIN chunk (the buffer the accessors point into).
Spec: https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#binary-gltf-layout

    inspect(path) -> {"triangles", "vertices", "primitives", "materials", "textures", "images", "attributes",
                      "bbox": {"min", "max", "extents", "sorted_ratios"}, "topology": {...}, ...}

Counts come from the accessors (a TRIANGLES primitive with indices has count/3 triangles, without indices
POSITION.count/3). The bounding box and the topology read the BIN chunk with NumPy, so they need the geometry to be
in the .glb itself (ComfyUI's SaveGLB writes it there). Node transforms are applied to the positions, so a model
exported under a rotated or scaled node is measured as it is shown.

Topology, after welding vertices that share a position (exporters split vertices along UV seams and hard normals):
  boundary_edges      edges used by 1 triangle (holes, open borders)
  nonmanifold_edges   edges used by 3 triangles or more
  watertight          no boundary and no non-manifold edge
  inconsistent_edges  edges two triangles walk in the same direction (flipped neighbours)
  components          groups of triangles connected through shared vertices
  degenerate          triangles with two identical welded corners
  euler               V - E + F of the welded mesh (2 for one closed surface of genus 0)
"""
import json
import struct

import numpy as np

MAGIC = b"glTF"
JSON_CHUNK, BIN_CHUNK = 0x4E4F534A, 0x004E4942
COMPONENTS = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT2": 4, "MAT3": 9, "MAT4": 16}
TRIANGLES = 4


class GlbError(ValueError):
    pass


def read_chunks(data):
    """(gltf dict, bin bytes or None) from the bytes of a .glb."""
    if len(data) < 20 or data[:4] != MAGIC:
        raise GlbError("not a binary glTF: the file does not start with 'glTF'")
    version, length = struct.unpack_from("<II", data, 4)
    if version != 2:
        raise GlbError(f"glTF version {version}, only 2 is read")
    if length > len(data):
        raise GlbError(f"header says {length} bytes, the file has {len(data)}")
    offset, gltf, binary = 12, None, None
    while offset + 8 <= length:
        size, kind = struct.unpack_from("<II", data, offset)
        body = data[offset + 8:offset + 8 + size]
        if len(body) != size:
            raise GlbError(f"chunk at byte {offset} is truncated")
        if kind == JSON_CHUNK and gltf is None:
            gltf = json.loads(body.decode("utf-8"))
        elif kind == BIN_CHUNK and binary is None:
            binary = body
        offset += 8 + size + (-size % 4)
    if gltf is None:
        raise GlbError("no JSON chunk")
    return gltf, binary


def accessor_array(gltf, binary, index):
    """The accessor's data as an (count, width) array, or None when it has no bufferView (sparse or empty)."""
    acc = gltf["accessors"][index]
    if "bufferView" not in acc or binary is None:
        return None
    view = gltf["bufferViews"][acc["bufferView"]]
    if view.get("buffer", 0) != 0:
        return None  # an external buffer: not inside the .glb
    dtype = np.dtype(COMPONENTS[acc["componentType"]]).newbyteorder("<")
    width = WIDTH[acc["type"]]
    count = acc["count"]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride") or dtype.itemsize * width
    if count == 0:
        return np.zeros((0, width), dtype)
    need = start + stride * (count - 1) + dtype.itemsize * width
    if need > len(binary):
        raise GlbError(f"accessor {index} reads past the end of the BIN chunk")
    if stride == dtype.itemsize * width:
        return np.frombuffer(binary, dtype, count * width, start).reshape(count, width)
    rows = np.frombuffer(binary, np.uint8, stride * (count - 1) + dtype.itemsize * width, start)
    rows = np.pad(rows, (0, stride * count - len(rows))).reshape(count, stride)[:, :dtype.itemsize * width]
    return rows.copy().view(dtype).reshape(count, width)


def node_matrix(node):
    if "matrix" in node:
        return np.array(node["matrix"], dtype=np.float64).reshape(4, 4).T  # column-major in glTF
    t = np.array(node.get("translation", [0, 0, 0]), dtype=np.float64)
    x, y, z, w = node.get("rotation", [0, 0, 0, 1])
    s = np.array(node.get("scale", [1, 1, 1]), dtype=np.float64)
    r = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                  [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                  [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
    m = np.eye(4)
    m[:3, :3] = r * s
    m[:3, 3] = t
    return m


def mesh_instances(gltf):
    """[(mesh index, world matrix)] for the default scene, or every mesh once when there is no scene."""
    nodes = gltf.get("nodes") or []
    scenes = gltf.get("scenes") or []
    if not scenes:
        return [(i, np.eye(4)) for i in range(len(gltf.get("meshes") or []))]
    roots = scenes[gltf.get("scene", 0)].get("nodes") or []
    found, stack = [], [(r, np.eye(4)) for r in roots]
    while stack:
        index, parent = stack.pop()
        node = nodes[index]
        world = parent @ node_matrix(node)
        if "mesh" in node:
            found.append((node["mesh"], world))
        stack.extend((c, world) for c in node.get("children") or [])
    return found


def components_labels(n, edges):
    """Connected component label (its smallest vertex) of each of n vertices, with NumPy: hook every edge's larger
    root under the smaller one, then jump pointers until they settle; a few rounds even for long thin meshes."""
    labels = np.arange(n)
    if len(edges) == 0:
        return labels
    a, b = edges[:, 0], edges[:, 1]
    while True:
        la, lb = labels[a], labels[b]
        low = np.minimum(la, lb)
        hooked = labels.copy()
        np.minimum.at(hooked, la, low)
        np.minimum.at(hooked, lb, low)
        while True:
            jumped = hooked[hooked]
            if np.array_equal(jumped, hooked):
                break
            hooked = jumped
        if np.array_equal(hooked, labels):
            return labels
        labels = hooked


def topology(positions, triangles):
    """Welded topology of a triangle soup: positions (n, 3) float, triangles (m, 3) int."""
    if len(triangles) == 0:
        return {"welded_vertices": 0, "edges": 0, "boundary_edges": 0, "nonmanifold_edges": 0, "watertight": False,
                "inconsistent_edges": 0, "components": 0, "degenerate": 0, "euler": 0}
    extent = float(np.max(np.ptp(positions, axis=0))) if len(positions) else 0.0
    step = extent * 1e-6 or 1e-12  # weld positions closer than a millionth of the model's size
    keys = np.ascontiguousarray(np.round(positions / step).astype(np.int64))
    _, weld = np.unique(keys.view([("", np.int64)] * 3).reshape(-1), return_inverse=True)
    weld = weld.reshape(-1)
    tri = weld[triangles]
    degenerate = (tri[:, 0] == tri[:, 1]) | (tri[:, 1] == tri[:, 2]) | (tri[:, 0] == tri[:, 2])
    tri = tri[~degenerate]
    used = np.unique(tri)
    directed = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    lo, hi = np.minimum(directed[:, 0], directed[:, 1]), np.maximum(directed[:, 0], directed[:, 1])
    n = np.int64(int(weld.max()) + 1)
    codes, counts = np.unique(lo.astype(np.int64) * n + hi, return_counts=True)
    undirected = np.stack([codes // n, codes % n], axis=1)
    _, same_counts = np.unique(directed[:, 0].astype(np.int64) * n + directed[:, 1], return_counts=True)
    labels = components_labels(int(n), undirected)
    boundary = int(np.sum(counts == 1))
    nonmanifold = int(np.sum(counts > 2))
    return {
        "welded_vertices": int(len(used)),
        "edges": int(len(undirected)),
        "boundary_edges": boundary,
        "nonmanifold_edges": nonmanifold,
        "watertight": boundary == 0 and nonmanifold == 0,
        "inconsistent_edges": int(np.sum(same_counts > 1)),
        "components": int(len(np.unique(labels[used]))),
        "degenerate": int(np.sum(degenerate)),
        "euler": int(len(used) - len(undirected) + len(tri)),
    }


def geometry(data):
    """(positions (n, 3) float64 in world space, triangles (m, 3) int64) of every TRIANGLES primitive."""
    gltf, binary = read_chunks(data)
    accessors, meshes = gltf.get("accessors") or [], gltf.get("meshes") or []
    positions, triangles, offset = [], [], 0
    for mesh_index, matrix in mesh_instances(gltf):
        for prim in meshes[mesh_index].get("primitives") or []:
            position = prim.get("attributes", {}).get("POSITION")
            if position is None or prim.get("mode", TRIANGLES) != TRIANGLES:
                continue
            pos = accessor_array(gltf, binary, position)
            count = accessors[position]["count"]
            if "indices" in prim:
                idx = accessor_array(gltf, binary, prim["indices"])
            else:
                idx = np.arange(count, dtype=np.int64)
            if pos is None or idx is None:
                continue
            idx = idx.reshape(-1)
            positions.append(pos.astype(np.float64) @ matrix[:3, :3].T + matrix[:3, 3])
            triangles.append(idx[:len(idx) - len(idx) % 3].astype(np.int64).reshape(-1, 3) + offset)
            offset += len(pos)
    if not positions:
        return np.zeros((0, 3)), np.zeros((0, 3), np.int64)
    return np.concatenate(positions), np.concatenate(triangles)


def preview(data, dst, size=256, max_faces=150_000):
    """A shaded view from above and to the side (glTF is Y-up), faces drawn back to front with Pillow, as WebP.
    Above max_faces, an even sample of the faces is drawn: enough for a thumbnail, not for judging small holes."""
    from PIL import Image, ImageDraw
    positions, triangles = geometry(data)
    image = Image.new("RGB", (size, size), (40, 42, 48))
    if len(triangles):
        if len(triangles) > max_faces:
            triangles = triangles[np.linspace(0, len(triangles) - 1, max_faces).astype(np.int64)]
        yaw, pitch = np.radians(35.0), np.radians(25.0)
        ry = np.array([[np.cos(yaw), 0, np.sin(yaw)], [0, 1, 0], [-np.sin(yaw), 0, np.cos(yaw)]])
        rx = np.array([[1, 0, 0], [0, np.cos(pitch), -np.sin(pitch)], [0, np.sin(pitch), np.cos(pitch)]])
        p = (positions - (positions.min(axis=0) + positions.max(axis=0)) / 2) @ (rx @ ry).T
        span = float(np.max(np.ptp(p[:, :2], axis=0))) or 1.0
        xy = np.stack([p[:, 0], -p[:, 1]], axis=1) / span * (size * 0.88) + size / 2
        corners = p[triangles]
        normals = np.cross(corners[:, 1] - corners[:, 0], corners[:, 2] - corners[:, 0])
        normals /= np.linalg.norm(normals, axis=1, keepdims=True) + 1e-12
        light = np.array([0.4, 0.6, 0.7]) / np.linalg.norm([0.4, 0.6, 0.7])
        shade = (60 + 180 * np.abs(normals @ light)).astype(int)
        # back faces first (a hint of the inside through holes), then front faces, each far (negative z) to near
        order = np.lexsort((corners[:, :, 2].mean(axis=1), normals[:, 2] > 0))
        draw = ImageDraw.Draw(image)
        for f in order:
            g = int(shade[f])
            draw.polygon([tuple(xy[v]) for v in triangles[f]], fill=(g, int(g * 0.93), int(g * 0.82)))
    image.save(dst, "WEBP", quality=80, method=6)
    return dst


def inspect_bytes(data, with_topology=True):
    gltf, binary = read_chunks(data)
    accessors = gltf.get("accessors") or []
    meshes = gltf.get("meshes") or []
    triangles = vertices = primitives = 0
    attributes, modes = set(), set()
    geometry_complete = True
    for mesh_index, _ in mesh_instances(gltf):
        for prim in meshes[mesh_index].get("primitives") or []:
            primitives += 1
            mode = prim.get("mode", TRIANGLES)
            modes.add(mode)
            attributes.update(prim.get("attributes", {}))
            position = prim.get("attributes", {}).get("POSITION")
            if position is None:
                continue
            count = accessors[position]["count"]
            vertices += count
            if mode != TRIANGLES:
                geometry_complete = False
                continue
            triangles += (accessors[prim["indices"]]["count"] if "indices" in prim else count) // 3
            if binary is None or "bufferView" not in accessors[position]:
                geometry_complete = False
    positions, tris = geometry(data) if binary is not None else (np.zeros((0, 3)), np.zeros((0, 3), np.int64))
    result = {
        "triangles": triangles,
        "vertices": vertices,
        "meshes": len(meshes),
        "primitives": primitives,
        "modes": sorted(modes),
        "attributes": sorted(attributes),
        "materials": len(gltf.get("materials") or []),
        "textures": len(gltf.get("textures") or []),
        "images": len(gltf.get("images") or []),
        "has_vertex_colors": "COLOR_0" in attributes,
        "has_uvs": "TEXCOORD_0" in attributes,
        "has_normals": "NORMAL" in attributes,
        "extensions_used": sorted(gltf.get("extensionsUsed") or []),
        "generator": (gltf.get("asset") or {}).get("generator"),
        "geometry_read": geometry_complete and len(positions) > 0,
    }
    if len(positions):
        lo, hi = positions.min(axis=0), positions.max(axis=0)
        extents = hi - lo
        longest = float(extents.max()) or 1.0
        result["bbox"] = {
            "min": [round(float(v), 6) for v in lo],
            "max": [round(float(v), 6) for v in hi],
            "extents": [round(float(v), 6) for v in extents],
            # longest first, each divided by the longest: comparable with a real object whatever the model's unit
            "sorted_ratios": [round(float(v) / longest, 4) for v in sorted(extents, reverse=True)],
        }
        if with_topology:
            result["topology"] = topology(positions, tris)
    return result


def inspect(path, with_topology=True):
    with open(path, "rb") as f:
        return inspect_bytes(f.read(), with_topology)


# ---------- writing, for tests and fixtures ----------
def build_glb(positions, triangles, material=False, texture_png=None, colors=None, index_type=5125, extras=None):
    """A minimal .glb: one mesh, one primitive, optional material, embedded PNG texture and vertex colors."""
    pos = np.asarray(positions, dtype="<f4")
    idx = np.asarray(triangles, dtype={5121: "<u1", 5123: "<u2", 5125: "<u4"}[index_type]).reshape(-1)
    chunks, views, accessors = [], [], []

    def add(blob, target=None):
        pad = -len(b"".join(chunks)) % 4
        if pad:
            chunks.append(b"\x00" * pad)
        offset = len(b"".join(chunks))
        chunks.append(blob)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(blob)}
        if target:
            view["target"] = target
        views.append(view)
        return len(views) - 1

    accessors.append({"bufferView": add(pos.tobytes(), 34962), "componentType": 5126, "count": len(pos),
                      "type": "VEC3", "min": pos.min(axis=0).tolist(), "max": pos.max(axis=0).tolist()})
    accessors.append({"bufferView": add(idx.tobytes(), 34963), "componentType": index_type, "count": len(idx),
                      "type": "SCALAR"})
    attributes = {"POSITION": 0}
    if colors is not None:
        col = np.asarray(colors, dtype="<f4")
        accessors.append({"bufferView": add(col.tobytes(), 34962), "componentType": 5126, "count": len(col),
                          "type": "VEC3"})
        attributes["COLOR_0"] = len(accessors) - 1
    primitive = {"attributes": attributes, "indices": 1, "mode": TRIANGLES}
    gltf = {"asset": {"version": "2.0", "generator": "galab test fixture"}, "scene": 0, "scenes": [{"nodes": [0]}],
            "nodes": [{"mesh": 0}], "meshes": [{"primitives": [primitive]}], "accessors": accessors,
            "bufferViews": views}
    if extras:
        gltf["asset"]["extras"] = extras
    if material or texture_png is not None:
        mat = {"pbrMetallicRoughness": {"baseColorFactor": [0.8, 0.6, 0.4, 1.0]}}
        if texture_png is not None:
            gltf["images"] = [{"bufferView": add(texture_png), "mimeType": "image/png"}]
            gltf["textures"] = [{"source": 0}]
            mat["pbrMetallicRoughness"]["baseColorTexture"] = {"index": 0}
        gltf["materials"] = [mat]
        primitive["material"] = 0
    binary = b"".join(chunks)
    binary += b"\x00" * (-len(binary) % 4)
    gltf["buffers"] = [{"byteLength": len(binary)}]
    text = json.dumps(gltf, separators=(",", ":")).encode()
    text += b" " * (-len(text) % 4)
    total = 12 + 8 + len(text) + 8 + len(binary)
    return b"".join([struct.pack("<4sII", MAGIC, 2, total), struct.pack("<II", len(text), JSON_CHUNK), text,
                     struct.pack("<II", len(binary), BIN_CHUNK), binary])


def cube(size=(1.0, 1.0, 1.0), welded=True):
    """A closed box centered on the origin, triangles facing outward: 8 vertices, or 24 split per face."""
    sx, sy, sz = (s / 2 for s in size)
    corners = [(-sx, -sy, -sz), (sx, -sy, -sz), (sx, sy, -sz), (-sx, sy, -sz),
               (-sx, -sy, sz), (sx, -sy, sz), (sx, sy, sz), (-sx, sy, sz)]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (2, 3, 7, 6), (1, 2, 6, 5), (0, 4, 7, 3)]
    if welded:
        tris = [t for a, b, c, d in faces for t in ((a, b, c), (a, c, d))]
        return corners, tris
    positions, tris = [], []
    for face in faces:
        base = len(positions)
        positions.extend(corners[i] for i in face)
        tris.extend([(base, base + 1, base + 2), (base, base + 2, base + 3)])
    return positions, tris
