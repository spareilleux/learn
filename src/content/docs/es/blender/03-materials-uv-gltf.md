---
title: 3. Materiales, UV, y lo que glTF conserva de ellos
description: 'Materiales de nodos con el Principled BSDF y su modelo metallic-roughness, valores de color lineales, coordenadas UV guardadas por esquina de cara y un Smart UV Project, una textura de imagen calculada píxel a píxel y el error de espacio de color que provocó, y después el diapasón del curso exportado a glTF 2.0 — la conversión a Y hacia arriba, los vértices divididos, una textura de rugosidad descartada sin aviso, y los modificadores que no se aplican por defecto.'
sidebar:
  order: 3
---

Código: el script de la lección, [`scripts/l03_materials.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/l03_materials.py), los materiales de [`scripts/fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py), y el informe, [`expected/l03_materials.txt`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/expected/l03_materials.txt).

## Un material es un árbol de nodos

En Blender, un [material](https://docs.blender.org/manual/en/5.2/render/materials/introduction.html) es un grafo de nodos de shader, que se edita en el [Shader Editor](https://docs.blender.org/manual/en/5.2/editors/shader_editor.html) del workspace **Shading**. Un material nuevo viene con dos nodos, un Principled BSDF conectado al Material Output:

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

Los scripts más antiguos empiezan poniendo `material.use_nodes = True`. En la 5.2, todos los materiales tienen un árbol de nodos, y leer `use_nodes` lanza un `DeprecationWarning` que dice que se eliminará en Blender 6.0.

Las entradas de un nodo son sockets. Un socket sin conectar usa su propio valor, el campo que tiene al lado en el editor; un socket conectado toma el valor del nodo enlazado a él, calculado para cada punto de la superficie. El grafo es un programa de flujo de datos, que el renderizador ejecuta para cada punto de sombreado.

### El Principled BSDF

Una BSDF (función de distribución de dispersión bidireccional) describe cómo refleja y transmite la luz una superficie. El [Principled BSDF](https://docs.blender.org/manual/en/5.2/render/shader_nodes/shader/principled.html) se basa en el modelo OpenPBR Surface, y apila capas detrás de sus 32 entradas: una base que mezcla metal, difuso, subsuperficie y transmisión, una capa especular, una película fina opcional, una capa de barniz (coat) y un brillo aterciopelado (sheen), y la emisión. Para la mayoría de los objetos, tres entradas hacen el trabajo:

- **Base Color**: el color de la superficie.
- **Metallic**: con 0, un dieléctrico como la madera o el plástico, una base difusa bajo un reflejo especular; con 1, un metal, cuyo reflejo se tiñe con el color base y no tiene parte difusa.
- **Roughness**: 0 da un reflejo perfectamente nítido, 1 uno difuso.

Es el modelo metallic-roughness de [glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#materials) y del `MeshStandardMaterial` de three.js, que trata la [lección 2 del curso de three.js](../../threejs/02-geometries-materials-lights/). Un material hecho con estas tres entradas se exporta a glTF sin pérdidas.

### Tres materiales para el diapasón

[`fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py) crea tres materiales a partir de colores hexadecimales:

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

Un socket de color guarda valores **lineales**, proporcionales a la energía luminosa. Un color hexadecimal como `#5a3422` está en **sRGB**, codificado para la pantalla: `0x5a / 255` da 0,353, que en lineal es 0,102. Olvidar la conversión hace que todos los colores salgan demasiado claros.

Cada material tiene un usuario, la malla: una ranura de material está enlazada por defecto a la malla (`DATA`), así que los 22 objetos de traste, que comparten una malla, comparten también su material. Una ranura puede enlazarse al objeto en su lugar, para dar materiales distintos a duplicados enlazados.

## Las coordenadas UV

Una textura de imagen necesita saber qué píxel de la imagen va en qué lugar de la superficie. Las **coordenadas UV** dan a cada esquina de cara una posición (u, v) en la imagen, de 0 a 1: desplegar una malla aplana su superficie en ese cuadrado, como el patrón de una caja de cartón abierta. El [manual](https://docs.blender.org/manual/en/5.2/modeling/meshes/uv/unwrapping/introduction.html) cubre los métodos; en la interfaz, el workspace **UV Editing** muestra la malla y sus UV una al lado de la otra, y `U` en Edit Mode abre el menú de despliegue.

El script usa [Smart UV Project](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/uv.html), que corta la malla donde las caras se encuentran con más de cierto ángulo y empaqueta las piezas. Es un operador, así que necesita Edit Mode, incluso en segundo plano:

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

Las UV se guardan por loop, las esquinas de cara de la lección 2: una esquina de la losa pertenece a tres caras, y cada cara la coloca en un punto distinto de la imagen. La cara superior recibió una tira de unos 0,12 de ancho y toda la altura de la imagen, ya que cada cara de la losa se convirtió en su propia isla.

## Una textura de imagen hecha desde código

[`fretboard.grain_image`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py) calcula píxel a píxel una imagen de 256 × 32 con franjas onduladas en torno al color del palisandro, la empaqueta en el archivo `.blend`, y el script la conecta al Base Color a través de un nodo [Image Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/image.html). También conecta un [Noise Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/noise.html) procedural a la Roughness, para la exportación de más abajo:

```text
== An image texture made from code
image 'Rosewood grain' size (256, 32) channels 4 packed True colorspace sRGB is_float False
pixels[0] = 0.5 reads back as 0.5020 = 128 / 255
Rosewood links: ['Image Texture.Color -> Principled BSDF.Base Color', 'Noise Texture.Factor -> Principled BSDF.Roughness', 'Principled BSDF.BSDF -> Material Output.Surface']
```

[`Image.pixels`](https://docs.blender.org/api/5.2/bpy.types.Image.html#bpy.types.Image.pixels) recibe floats, pero una imagen nueva tiene 8 bits por canal en el espacio de color sRGB, y guarda los valores que le das como bytes, **sin convertirlos**: 0,5 se convierte en 128. Después, el renderizador decodifica esos bytes como sRGB.

La primera versión del script no lo sabía. Convertía el color del palisandro a lineal antes de escribir los píxeles, como para un socket de color, así que el renderizador decodificaba por segunda vez un valor ya lineal: la tabla salía demasiado oscura. La regla es la misma que three.js tiene para las texturas ([lección 3 de three.js](../../threejs/03-color-tone-mapping-environments/)): las imágenes de color guardan valores sRGB, los factores de color guardan valores lineales.

## Exportado a glTF 2.0

El [exportador glTF](https://docs.blender.org/manual/en/5.2/addons/import_export/scene_gltf2.html), desarrollado por Khronos en [glTF-Blender-IO](https://github.com/KhronosGroup/glTF-Blender-IO) e incluido con Blender, también es un operador:

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

Lo que conservó la exportación:

- **El reparto.** 33 nodos y 3 mallas: los 22 trastes son 22 nodos que apuntan a una sola malla glTF, como en Blender.
- **Los factores**, como valores lineales, idénticos a los sockets. Un factor igual al valor por defecto de glTF se omite: la alpaca (Nickel silver) no tiene `metallicFactor`, porque el valor por defecto es 1.
- **La imagen**, escrita junto al archivo como PNG y referenciada por un nombre codificado como URI, `Rosewood%20grain.png`.
- **Los ejes, convertidos.** Blender tiene Z hacia arriba y glTF tiene Y hacia arriba, así que una posición (x, y, z) pasa a ser (x, z, −y), y la escala intercambia sus dos últimas componentes. La posición del traste `(0.324, 0, 0.0006)` se convirtió en la traslación `(0.324, 0.0006, 0)`.

Lo que la exportación cambió o descartó:

- **Los vértices se dividen.** Un vértice glTF es un conjunto de atributos (posición, normal, UV) que deben coincidir todos. Cada una de las 8 esquinas del alambre de traste toca tres caras planas con tres normales distintas, así que se convierten en 24 vértices; los 48 del marcador de punto pasan a 144. Las GPU trabajan así, y es el búfer de vértices que recibe three.js.
- **La rugosidad desaparece, sin aviso.** El material Rosewood tiene `baseColorTexture` y `metallicFactor`, pero ninguna rugosidad. El exportador busca una constante en el socket Roughness, o una constante multiplicada por algo que reconoce. Una textura de ruido no es ninguna de las dos cosas, así que [`__gather_roughness_factor`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/blender/exp/material/pbr_metallic_roughness.py#L252-L269) no devuelve nada, y un `roughnessFactor` ausente significa 1 en glTF. En three.js la tabla es completamente mate en lugar de 0,8, y el log de la exportación no lo menciona. Las texturas procedurales no existen en glTF: hornéalas antes en una imagen.

El manual enumera lo que lee el exportador para cada propiedad; leerlo antes de construir un material para la web ahorra un viaje de ida y vuelta.

### Los modificadores y el exportador

La lección 2 decía que el grafo de dependencias evalúa los modificadores para el viewport y los renders. El exportador no usa ese resultado salvo que se lo pidas:

```text
== Modifiers and the exporter
export_apply=False: POSITION count 24, indices 36
export_apply=True: POSITION count 384, indices 576
```

Un cubo con un modificador Subdivision Surface se exporta por defecto como un cubo simple. **Apply Modifiers** (`export_apply`) está [desactivado por defecto](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py#L679-L684), y su descripción advierte que aplicar los modificadores impide exportar las shape keys, los morph targets de glTF.

### Los formatos

El operador ofrece dos formatos: `GLB`, un único archivo binario, y `GLTF_SEPARATE`, un `.gltf` en JSON con un `.bin` y las imágenes al lado. El manual también documenta **glTF Embedded**, un único archivo JSON con los datos en base64, pero pasar `GLTF_EMBEDDED` desde un script falla con `enum "GLTF_EMBEDDED" not found in ('GLB', 'GLTF_SEPARATE')`: el exportador solo [lo ofrece](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py#L148-L154) cuando lo permite una preferencia del add-on. El curso usa `GLTF_SEPARATE` para leer el JSON, y `GLB` para la web, como en la [lección 4 del curso de three.js](../../threejs/04-gltf-models-and-animations/).

## Puntos clave

- Un material es un árbol de nodos; Base Color, Metallic y Roughness del Principled BSDF son el modelo metallic-roughness de glTF.
- Los sockets de color y los factores de glTF son lineales; convierte antes los colores hexadecimales desde sRGB.
- Las UV se guardan por esquina de cara; desplegar aplana la superficie en islas dentro del cuadrado de 0 a 1.
- Una imagen de 8 bits guarda como bytes los valores que escribes, y se decodifican como sRGB: escribe en ella valores sRGB.
- El exportador glTF conserva los factores, las texturas de imagen, las instancias y los ejes (convertidos a Y hacia arriba), divide los vértices cuyos atributos difieren, descarta en silencio las texturas procedurales, y no aplica los modificadores por defecto.

## Ejercicios

1. Quita el enlace del Noise Texture a la Roughness y vuelve a exportar. ¿Qué contiene ahora el `pbrMetallicRoughness` de Rosewood?
2. Exporta el diapasón como `.glb`. Lee sus 20 primeros bytes: ¿qué contienen, según la [sección GLB de la especificación](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#binary-gltf-layout)?
3. Exporta con `export_yup=False`. Predice la traslación y la escala del nodo `Fret 12`, y después compruébalo.

<details>
<summary>Solución 1</summary>

```text
== Exercise 1: unlink the noise
Rosewood pbrMetallicRoughness keys: ['baseColorTexture', 'metallicFactor', 'roughnessFactor'] | roughnessFactor 0.8000
```

Con el socket sin conectar, su valor, 0,8, es una constante que el exportador puede leer.

</details>

<details>
<summary>Solución 2</summary>

```text
== Exercise 2: one .glb file
magic b'glTF' | version 2 | first chunk type b'JSON'
```

Una cabecera de 12 bytes, con el número mágico `glTF`, la versión 2 y la longitud total, y después la longitud del primer chunk y su tipo, `JSON`. El chunk binario (`BIN`) va detrás del de JSON. En esta ejecución, el `.glb` ocupaba 19.032 bytes, y los tres archivos separados 21.953 en total.

</details>

<details>
<summary>Solución 3</summary>

```text
== Exercise 3: without +Y up
node 'Fret 12' translation (0.3240, 0.0000, 0.0006) scale (0.0024, 0.0520, 0.0012)
```

Los valores de Blender, sin cambios. El archivo tiene entonces Z hacia arriba, y un visor con Y hacia arriba como three.js lee su Z como profundidad: la cara superior de la tabla mira a la cámara en lugar de al cielo.

</details>

## Fuentes

- Manual de Blender 5.2: [materiales](https://docs.blender.org/manual/en/5.2/render/materials/introduction.html), [Principled BSDF](https://docs.blender.org/manual/en/5.2/render/shader_nodes/shader/principled.html), [Image Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/image.html), [despliegue de UV](https://docs.blender.org/manual/en/5.2/modeling/meshes/uv/unwrapping/introduction.html), [herramientas UV](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/uv.html), [add-on glTF 2.0](https://docs.blender.org/manual/en/5.2/addons/import_export/scene_gltf2.html), [gestión del color](https://docs.blender.org/manual/en/5.2/render/color_management/index.html).
- API de Python de Blender 5.2: [`Image`](https://docs.blender.org/api/5.2/bpy.types.Image.html), [`ShaderNodeBsdfPrincipled`](https://docs.blender.org/api/5.2/bpy.types.ShaderNodeBsdfPrincipled.html), [`bpy.ops.uv`](https://docs.blender.org/api/5.2/bpy.ops.uv.html), [`bpy.ops.export_scene`](https://docs.blender.org/api/5.2/bpy.ops.export_scene.html).
- Khronos, [especificación de glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html): materiales, estructura del glTF binario.
- El exportador glTF en el código fuente de Blender en la 5.2.2: [`__init__.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py), [`pbr_metallic_roughness.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/blender/exp/material/pbr_metallic_roughness.py); en el proyecto original, [KhronosGroup/glTF-Blender-IO](https://github.com/KhronosGroup/glTF-Blender-IO).
