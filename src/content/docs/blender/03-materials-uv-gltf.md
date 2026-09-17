---
title: 3. Materials, UVs, and what glTF keeps of them
description: 'Node materials with the Principled BSDF and its metallic-roughness model, linear color values, UV coordinates stored per face corner and a Smart UV Project, an image texture computed pixel by pixel and the color-space bug it caused, then the course''s fretboard exported to glTF 2.0 — the Y-up conversion, split vertices, a roughness texture dropped without a warning, and modifiers that aren''t applied by default.'
sidebar:
  order: 3
---

Code: the lesson's script, [`scripts/l03_materials.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/l03_materials.py), the materials in [`scripts/fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py), and the report, [`expected/l03_materials.txt`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/expected/l03_materials.txt).

## A material is a node tree

In Blender, a [material](https://docs.blender.org/manual/en/5.2/render/materials/introduction.html) is a graph of shader nodes, edited in the [Shader Editor](https://docs.blender.org/manual/en/5.2/editors/shader_editor.html) of the **Shading** workspace. A new material comes with two nodes, a Principled BSDF connected to the Material Output:

```text
== A new material and its node tree
nodes of a new material: ['ShaderNodeBsdfPrincipled', 'ShaderNodeOutputMaterial']
link: Principled BSDF 'BSDF' -> Material Output 'Surface'
Principled BSDF inputs: 32 | enabled: 30
  'Base Color' NodeSocketColor (0.800, 0.800, 0.800, 1.000)
  'Metallic' NodeSocketFloatFactor 0.000
  'Roughness' NodeSocketFloatFactor 0.500
  'IOR' NodeSocketFloat 1.500
  'Alpha' NodeSocketFloatFactor 1.000
  'Normal' NodeSocketVector (0.000, 0.000, 0.000)
  'Coat Weight' NodeSocketFloatFactor 0.000
  'Emission Strength' NodeSocketFloat 0.000
the viewport color outside the node tree, diffuse_color: (0.800, 0.800, 0.800, 1.000)
```

Older scripts set `material.use_nodes = True` first. In 5.2, every material has a node tree, and reading `use_nodes` raises a `DeprecationWarning` that says it will be removed in Blender 6.0.

A node's inputs are sockets. An unconnected socket uses its own value, the field next to it in the editor; a connected socket takes the value of the node linked to it, computed for each point of the surface. The graph is a dataflow program, run by the renderer for every shading point.

### The Principled BSDF

A BSDF (bidirectional scattering distribution function) describes how a surface reflects and transmits light. The [Principled BSDF](https://docs.blender.org/manual/en/5.2/render/shader_nodes/shader/principled.html) is based on the OpenPBR Surface model, and stacks layers behind its 32 inputs: a base that mixes metal, diffuse, subsurface and transmission, a specular layer, an optional thin film, coat and sheen, and emission. For most objects, three inputs do the work:

- **Base Color**: the surface's color.
- **Metallic**: at 0, a dielectric such as wood or plastic, a diffuse base under a specular reflection; at 1, a metal, whose reflection is tinted with the base color and has no diffuse part.
- **Roughness**: 0 gives a perfectly sharp reflection, 1 a diffuse one.

This is the metallic-roughness model of [glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#materials) and of three.js's `MeshStandardMaterial`, which the [three.js course's lesson 2](../../threejs/02-geometries-materials-lights/) covers. A material made of these three inputs exports to glTF without loss.

### Three materials for the fretboard

[`fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py) makes three materials from hex colors:

```python
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
```

```text
== Three materials for the fretboard
'Rosewood': base color (linear) (0.1022, 0.0343, 0.0160) metallic 0.00 roughness 0.80 users 1
'Nickel silver': base color (linear) (0.5841, 0.5647, 0.5089) metallic 1.00 roughness 0.25 users 1
'Pearl': base color (linear) (0.8388, 0.7913, 0.6724) metallic 0.00 roughness 0.30 users 1
the material lives on the mesh (slot link DATA), so the 22 frets share it: ['DATA'] Nickel silver
```

A color socket holds **linear** values, proportional to light energy. A hex color such as `#5a3422` is **sRGB**, encoded for display: `0x5a / 255` is 0.353, which is 0.102 in linear. Forgetting the conversion makes every color too light.

Each material has one user, the mesh: a material slot is linked to the mesh (`DATA`) by default, so the 22 fret objects, which share one mesh, share its material too. A slot can be linked to the object instead, to give linked duplicates different materials.

## UV coordinates

An image texture needs to know which pixel of the image goes where on the surface. **UV coordinates** give each face corner a position (u, v) in the image, from 0 to 1: unwrapping a mesh flattens its surface into that square, like the pattern of a cardboard box cut open. The [manual](https://docs.blender.org/manual/en/5.2/modeling/meshes/uv/unwrapping/introduction.html) covers the methods; in the interface, the **UV Editing** workspace shows the mesh and its UVs side by side, and `U` in Edit Mode opens the unwrapping menu.

The script uses [Smart UV Project](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/uv.html), which splits the mesh where faces meet at more than an angle and packs the pieces. It is an operator, so it needs Edit Mode, even in the background:

```python
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
result = bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02, scale_to_bounds=False)
bpy.ops.object.mode_set(mode="OBJECT")
```

```text
== UV unwrapping
UV layers before: []
smart_project: {'FINISHED'} | UV layers after: ['UVMap']
top face: loops [4, 5, 6, 7] | UV bounds (0.124, 0.002) (0.241, 0.998)
UV coordinates are stored per loop (face corner), not per vertex: 24 UVs for 8 vertices
```

The UVs are stored per loop, the face corners of lesson 2: a corner of the slab belongs to three faces, and each face places it at a different point of the image. The top face got a strip about 0.12 wide and the whole height of the image, since each face of the slab became its own island.

## An image texture made from code

[`fretboard.grain_image`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py) computes a 256 × 32 image of wavy stripes around the rosewood color, pixel by pixel, packs it into the `.blend` file, and the script connects it to the Base Color through an [Image Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/image.html) node. It also connects a procedural [Noise Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/noise.html) to the Roughness, for the export below:

```text
== An image texture made from code
image 'Rosewood grain' size (256, 32) channels 4 packed True colorspace sRGB is_float False
pixels[0] = 0.5 reads back as 0.5020 = 128 / 255
Rosewood links: ['Image Texture.Color -> Principled BSDF.Base Color', 'Noise Texture.Factor -> Principled BSDF.Roughness', 'Principled BSDF.BSDF -> Material Output.Surface']
```

[`Image.pixels`](https://docs.blender.org/api/5.2/bpy.types.Image.html#bpy.types.Image.pixels) takes floats, but a new image is 8 bits per channel in the sRGB color space, and it stores the values you give it as bytes, **without converting them**: 0.5 becomes 128. The renderer then decodes those bytes as sRGB.

The first version of the script didn't know that. It converted the rosewood color to linear before writing the pixels, as for a color socket, so the renderer decoded an already linear value a second time: the board came out much too dark. The rule is the one three.js has for textures ([three.js lesson 3](../../threejs/03-color-tone-mapping-environments/)): color images hold sRGB values, color factors hold linear values.

## Exported to glTF 2.0

The [glTF exporter](https://docs.blender.org/manual/en/5.2/addons/import_export/scene_gltf2.html), developed by Khronos in [glTF-Blender-IO](https://github.com/KhronosGroup/glTF-Blender-IO) and shipped with Blender, is an operator too:

```python
bpy.ops.export_scene.gltf(filepath=gltf_path, export_format="GLTF_SEPARATE", export_yup=True)
```

```text
== Exported to glTF 2.0
export_scene.gltf: {'FINISHED'} | files ['Rosewood grain.png', 'fretboard.bin', 'fretboard.gltf']
asset: {'generator': 'Khronos glTF Blender I/O v5.2.40', 'version': '2.0'}
extensionsUsed: []
nodes 33 | meshes 3 | materials 3 | textures 1 | images [('Rosewood%20grain.png', 'image/png')]
material 'Nickel silver': baseColorFactor (0.5841, 0.5647, 0.5089, 1.0000), roughnessFactor 0.2500
material 'Pearl': baseColorFactor (0.8388, 0.7913, 0.6724, 1.0000), metallicFactor 0, roughnessFactor 0.3000
material 'Rosewood': baseColorTexture {'index': 0}, metallicFactor 0
mesh 'Fret wire': attributes (count per accessor) {'NORMAL': 24, 'POSITION': 24} indices 36 material 0
mesh 'Inlay dot': attributes (count per accessor) {'NORMAL': 144, 'POSITION': 144} indices 276 material 1
mesh 'Fretboard': attributes (count per accessor) {'NORMAL': 24, 'POSITION': 24, 'TEXCOORD_0': 24} indices 36 material 2
node 'Fret 12': mesh 0 translation (0.3240, 0.0006, 0.0000) scale (0.0024, 0.0012, 0.0520)
in Blender: location (0.3240, 0.0000, 0.0006) scale (0.0024, 0.0520, 0.0012)
root node 'Fretboard': rotation (0.0000, 0.0000, 0.0000, 1.0000) children 32
```

What the export kept:

- **The sharing.** 33 nodes and 3 meshes: the 22 frets are 22 nodes pointing to one glTF mesh, as in Blender.
- **The factors**, as linear values, identical to the sockets. A factor equal to glTF's default is left out: the nickel has no `metallicFactor`, because the default is 1.
- **The image**, written next to the file as a PNG and referenced by a URI-encoded name, `Rosewood%20grain.png`.
- **The axes, converted.** Blender is Z-up and glTF is Y-up, so a position (x, y, z) becomes (x, z, −y), and the scale swaps its last two components. The fret's location `(0.324, 0, 0.0006)` became the translation `(0.324, 0.0006, 0)`.

What the export changed or dropped:

- **Vertices are split.** A glTF vertex is a set of attributes (position, normal, UV) that must all match. The fret wire's 8 corners each touch three flat faces with three different normals, so they become 24 vertices; the inlay dot's 48 become 144. GPUs work this way, and it is the vertex buffer three.js receives.
- **The roughness is gone, with no warning.** Rosewood's material has `baseColorTexture` and `metallicFactor`, but no roughness. The exporter looks for a constant in the Roughness socket, or a constant multiplied by something it recognizes. A noise texture is neither, so [`__gather_roughness_factor`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/blender/exp/material/pbr_metallic_roughness.py#L252-L269) returns nothing, and a missing `roughnessFactor` means 1 in glTF. In three.js the board is fully matte instead of 0.8, and the export's log doesn't mention it. Procedural textures don't exist in glTF: bake them into an image first.

The manual lists what the exporter reads for each property; reading it before building a material for the web saves a round trip.

### Modifiers and the exporter

Lesson 2 said the dependency graph evaluates modifiers for the viewport and renders. The exporter doesn't use that result unless you ask:

```text
== Modifiers and the exporter
export_apply=False: POSITION count 24, indices 36
export_apply=True: POSITION count 384, indices 576
```

A cube with a Subdivision Surface modifier exports as a plain cube by default. **Apply Modifiers** (`export_apply`) is [off by default](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py#L679-L684), and its description warns that applying modifiers prevents exporting shape keys, the morph targets of glTF.

### Formats

The operator offers two formats: `GLB`, a single binary file, and `GLTF_SEPARATE`, a JSON `.gltf` with a `.bin` and the images next to it. The manual also documents **glTF Embedded**, a single JSON file with base64 data, but passing `GLTF_EMBEDDED` from a script fails with `enum "GLTF_EMBEDDED" not found in ('GLB', 'GLTF_SEPARATE')`: the exporter only [offers it](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py#L148-L154) when a preference of the add-on allows it. The course uses `GLTF_SEPARATE` to read the JSON, and `GLB` for the web, as in the [three.js course's lesson 4](../../threejs/04-gltf-models-and-animations/).

## Key takeaways

- A material is a node tree; the Principled BSDF's Base Color, Metallic and Roughness are glTF's metallic-roughness model.
- Color sockets and glTF factors are linear; convert hex colors from sRGB first.
- UVs are stored per face corner; unwrapping flattens the surface into islands in the 0 to 1 square.
- An 8-bit image stores the values you write as bytes, and they are decoded as sRGB: write sRGB values to it.
- The glTF exporter keeps factors, image textures, instancing and the axes (converted to Y-up), splits vertices whose attributes differ, drops procedural textures silently, and doesn't apply modifiers by default.

## Exercises

1. Remove the link from the Noise Texture to the Roughness and export again. What does Rosewood's `pbrMetallicRoughness` contain now?
2. Export the fretboard as a `.glb`. Read its first 20 bytes: what do they contain, according to the [GLB section of the specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#binary-gltf-layout)?
3. Export with `export_yup=False`. Predict the translation and scale of the `Fret 12` node, then check.

<details>
<summary>Solution 1</summary>

```text
== Exercise 1: unlink the noise
Rosewood pbrMetallicRoughness keys: ['baseColorTexture', 'metallicFactor', 'roughnessFactor'] | roughnessFactor 0.8000
```

With the socket unconnected, its value, 0.8, is a constant the exporter can read.

</details>

<details>
<summary>Solution 2</summary>

```text
== Exercise 2: one .glb file
magic b'glTF' | version 2 | first chunk type b'JSON'
```

A 12-byte header, the magic `glTF`, the version 2 and the total length, then the first chunk's length and its type, `JSON`. The binary chunk (`BIN`) follows the JSON one. In this run the `.glb` was 19,032 bytes, and the three separate files 21,953 together.

</details>

<details>
<summary>Solution 3</summary>

```text
== Exercise 3: without +Y up
node 'Fret 12' translation (0.3240, 0.0000, 0.0006) scale (0.0024, 0.0520, 0.0012)
```

Blender's values, unchanged. The file is then Z-up, and a Y-up viewer such as three.js reads its Z as depth: the board's top faces the camera instead of the sky.

</details>

## Sources

- Blender 5.2 manual: [materials](https://docs.blender.org/manual/en/5.2/render/materials/introduction.html), [Principled BSDF](https://docs.blender.org/manual/en/5.2/render/shader_nodes/shader/principled.html), [Image Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/image.html), [UV unwrapping](https://docs.blender.org/manual/en/5.2/modeling/meshes/uv/unwrapping/introduction.html), [UV tools](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/uv.html), [glTF 2.0 add-on](https://docs.blender.org/manual/en/5.2/addons/import_export/scene_gltf2.html), [color management](https://docs.blender.org/manual/en/5.2/render/color_management/index.html).
- Blender 5.2 Python API: [`Image`](https://docs.blender.org/api/5.2/bpy.types.Image.html), [`ShaderNodeBsdfPrincipled`](https://docs.blender.org/api/5.2/bpy.types.ShaderNodeBsdfPrincipled.html), [`bpy.ops.uv`](https://docs.blender.org/api/5.2/bpy.ops.uv.html), [`bpy.ops.export_scene`](https://docs.blender.org/api/5.2/bpy.ops.export_scene.html).
- Khronos, [glTF 2.0 specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html): materials, binary glTF layout.
- The glTF exporter in Blender's source at 5.2.2: [`__init__.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py), [`pbr_metallic_roughness.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/blender/exp/material/pbr_metallic_roughness.py); upstream, [KhronosGroup/glTF-Blender-IO](https://github.com/KhronosGroup/glTF-Blender-IO).
