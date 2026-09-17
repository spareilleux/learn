---
title: 3. Matériaux, UV, et ce que glTF en garde
description: 'Les matériaux à nœuds avec le Principled BSDF et son modèle metallic-roughness, les valeurs de couleur linéaires, les coordonnées UV stockées par coin de face et un Smart UV Project, une texture image calculée pixel par pixel et le bug d''espace colorimétrique qu''elle a causé, puis la touche du cours exportée en glTF 2.0 — la conversion vers Y en haut, les sommets séparés, une texture de rugosité abandonnée sans avertissement, et des modificateurs qui ne sont pas appliqués par défaut.'
sidebar:
  order: 3
---

Code : le script de la leçon, [`scripts/l03_materials.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/l03_materials.py), les matériaux dans [`scripts/fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py), et le rapport, [`expected/l03_materials.txt`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/expected/l03_materials.txt).

## Un matériau est un arbre de nœuds

Dans Blender, un [matériau](https://docs.blender.org/manual/en/5.2/render/materials/introduction.html) est un graphe de nœuds de shader, modifié dans le [Shader Editor](https://docs.blender.org/manual/en/5.2/editors/shader_editor.html) du workspace **Shading**. Un nouveau matériau arrive avec deux nœuds, un Principled BSDF connecté au Material Output :

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

Les scripts plus anciens commencent par `material.use_nodes = True`. En 5.2, chaque matériau a un arbre de nœuds, et lire `use_nodes` lève un `DeprecationWarning` qui annonce sa suppression dans Blender 6.0.

Les entrées d'un nœud sont des sockets. Un socket non connecté utilise sa propre valeur, le champ à côté de lui dans l'éditeur ; un socket connecté prend la valeur du nœud qui lui est relié, calculée pour chaque point de la surface. Le graphe est un programme de flux de données, exécuté par le moteur de rendu pour chaque point d'ombrage.

### Le Principled BSDF

Une BSDF (bidirectional scattering distribution function, fonction de distribution de la diffusion bidirectionnelle) décrit comment une surface réfléchit et transmet la lumière. Le [Principled BSDF](https://docs.blender.org/manual/en/5.2/render/shader_nodes/shader/principled.html) s'appuie sur le modèle OpenPBR Surface, et empile des couches derrière ses 32 entrées : une base qui mélange métal, diffus, subsurface et transmission, une couche spéculaire, un film mince optionnel, un vernis (coat) et un reflet velouté (sheen), et l'émission. Pour la plupart des objets, trois entrées font le travail :

- **Base Color** : la couleur de la surface.
- **Metallic** : à 0, un diélectrique comme le bois ou le plastique, une base diffuse sous une réflexion spéculaire ; à 1, un métal, dont la réflexion est teintée de la couleur de base et n'a pas de partie diffuse.
- **Roughness** : 0 donne une réflexion parfaitement nette, 1 une réflexion diffuse.

C'est le modèle metallic-roughness de [glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#materials) et du `MeshStandardMaterial` de three.js, que couvre la [leçon 2 du cours three.js](../../threejs/02-geometries-materials-lights/). Un matériau fait de ces trois entrées s'exporte en glTF sans perte.

### Trois matériaux pour la touche

[`fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py) crée trois matériaux à partir de couleurs hexadécimales :

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

Un socket de couleur contient des valeurs **linéaires**, proportionnelles à l'énergie lumineuse. Une couleur hexadécimale comme `#5a3422` est en **sRGB**, encodée pour l'affichage : `0x5a / 255` vaut 0,353, soit 0,102 en linéaire. Oublier la conversion rend chaque couleur trop claire.

Chaque matériau a un utilisateur, le maillage : un slot de matériau est lié au maillage (`DATA`) par défaut, donc les 22 objets frettes, qui partagent un maillage, partagent aussi son matériau. Un slot peut être lié à l'objet à la place, pour donner des matériaux différents à des duplications liées.

## Les coordonnées UV

Une texture image a besoin de savoir quel pixel de l'image va où sur la surface. Les **coordonnées UV** donnent à chaque coin de face une position (u, v) dans l'image, de 0 à 1 : déplier un maillage aplatit sa surface dans ce carré, comme le patron d'une boîte en carton découpée et mise à plat. Le [manuel](https://docs.blender.org/manual/en/5.2/modeling/meshes/uv/unwrapping/introduction.html) couvre les méthodes ; dans l'interface, le workspace **UV Editing** montre le maillage et ses UV côte à côte, et `U` en Edit Mode ouvre le menu de dépliage.

Le script utilise [Smart UV Project](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/uv.html), qui coupe le maillage là où les faces se rencontrent au-delà d'un angle et range les morceaux. C'est un opérateur, donc il a besoin de l'Edit Mode, même en arrière-plan :

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

Les UV sont stockées par boucle, les coins de face de la leçon 2 : un coin de la plaque appartient à trois faces, et chaque face le place en un point différent de l'image. La face du dessus a reçu une bande d'environ 0,12 de large et de toute la hauteur de l'image, puisque chaque face de la plaque est devenue son propre îlot.

## Une texture image créée par le code

[`fretboard.grain_image`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py) calcule, pixel par pixel, une image de 256 × 32 faite de rayures ondulées autour de la couleur du palissandre, et l'intègre (pack) au fichier `.blend` ; le script la connecte à la Base Color par un nœud [Image Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/image.html). Il connecte aussi une [Noise Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/noise.html) procédurale à la Roughness, pour l'export ci-dessous :

```text
== An image texture made from code
image 'Rosewood grain' size (256, 32) channels 4 packed True colorspace sRGB is_float False
pixels[0] = 0.5 reads back as 0.5020 = 128 / 255
Rosewood links: ['Image Texture.Color -> Principled BSDF.Base Color', 'Noise Texture.Factor -> Principled BSDF.Roughness', 'Principled BSDF.BSDF -> Material Output.Surface']
```

[`Image.pixels`](https://docs.blender.org/api/5.2/bpy.types.Image.html#bpy.types.Image.pixels) prend des flottants, mais une nouvelle image est en 8 bits par canal dans l'espace colorimétrique sRGB, et elle stocke les valeurs que tu lui donnes sous forme d'octets, **sans les convertir** : 0,5 devient 128. Le moteur de rendu décode ensuite ces octets comme du sRGB.

La première version du script l'ignorait. Elle convertissait la couleur du palissandre en linéaire avant d'écrire les pixels, comme pour un socket de couleur, si bien que le moteur de rendu décodait une seconde fois une valeur déjà linéaire : la touche sortait beaucoup trop sombre. La règle est celle que three.js applique aux textures ([leçon 3 de three.js](../../threejs/03-color-tone-mapping-environments/)) : les images de couleur contiennent des valeurs sRGB, les facteurs de couleur des valeurs linéaires.

## Exportée en glTF 2.0

L'[exporteur glTF](https://docs.blender.org/manual/en/5.2/addons/import_export/scene_gltf2.html), développé par Khronos dans [glTF-Blender-IO](https://github.com/KhronosGroup/glTF-Blender-IO) et livré avec Blender, est lui aussi un opérateur :

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

Ce que l'export a gardé :

- **Le partage.** 33 nœuds et 3 maillages : les 22 frettes sont 22 nœuds qui pointent vers un seul maillage glTF, comme dans Blender.
- **Les facteurs**, en valeurs linéaires, identiques aux sockets. Un facteur égal à la valeur par défaut de glTF est omis : le maillechort n'a pas de `metallicFactor`, parce que la valeur par défaut est 1.
- **L'image**, écrite à côté du fichier en PNG et référencée par un nom encodé en URI, `Rosewood%20grain.png`.
- **Les axes, convertis.** Blender a Z en haut et glTF Y en haut, donc une position (x, y, z) devient (x, z, −y), et l'échelle échange ses deux dernières composantes. La position de la frette `(0.324, 0, 0.0006)` est devenue la translation `(0.324, 0.0006, 0)`.

Ce que l'export a changé ou abandonné :

- **Les sommets sont séparés.** Un sommet glTF est un ensemble d'attributs (position, normale, UV) qui doivent tous correspondre. Les 8 coins du fil de frette touchent chacun trois faces planes aux trois normales différentes, donc ils deviennent 24 sommets ; les 48 du repère rond en deviennent 144. Les GPU fonctionnent ainsi, et c'est le vertex buffer que reçoit three.js.
- **La rugosité a disparu, sans avertissement.** Le matériau du palissandre a `baseColorTexture` et `metallicFactor`, mais pas de rugosité. L'exporteur cherche une constante dans le socket Roughness, ou une constante multipliée par quelque chose qu'il reconnaît. Une texture de bruit n'est ni l'un ni l'autre, donc [`__gather_roughness_factor`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/blender/exp/material/pbr_metallic_roughness.py#L252-L269) ne renvoie rien, et un `roughnessFactor` absent vaut 1 en glTF. Dans three.js, la touche est complètement mate au lieu de 0,8, et le log de l'export n'en dit rien. Les textures procédurales n'existent pas en glTF : précalcule-les d'abord dans une image (bake).

Le manuel liste ce que l'exporteur lit pour chaque propriété ; le lire avant de construire un matériau pour le web évite un aller-retour.

### Les modificateurs et l'exporteur

La leçon 2 disait que le graphe de dépendances évalue les modificateurs pour le viewport et les rendus. L'exporteur n'utilise ce résultat que si tu le demandes :

```text
== Modifiers and the exporter
export_apply=False: POSITION count 24, indices 36
export_apply=True: POSITION count 384, indices 576
```

Un cube avec un modificateur Subdivision Surface s'exporte par défaut comme un simple cube. **Apply Modifiers** (`export_apply`) est [désactivé par défaut](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py#L679-L684), et sa description prévient qu'appliquer les modificateurs empêche d'exporter les shape keys, les morph targets de glTF.

### Les formats

L'opérateur propose deux formats : `GLB`, un seul fichier binaire, et `GLTF_SEPARATE`, un `.gltf` en JSON avec un `.bin` et les images à côté. Le manuel documente aussi **glTF Embedded**, un seul fichier JSON avec les données en base64, mais passer `GLTF_EMBEDDED` depuis un script échoue avec `enum "GLTF_EMBEDDED" not found in ('GLB', 'GLTF_SEPARATE')` : l'exporteur ne le [propose](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py#L148-L154) que si une préférence de l'add-on l'autorise. Le cours utilise `GLTF_SEPARATE` pour lire le JSON, et `GLB` pour le web, comme dans la [leçon 4 du cours three.js](../../threejs/04-gltf-models-and-animations/).

## Points clés

- Un matériau est un arbre de nœuds ; la Base Color, le Metallic et la Roughness du Principled BSDF forment le modèle metallic-roughness de glTF.
- Les sockets de couleur et les facteurs glTF sont linéaires ; convertis d'abord les couleurs hexadécimales depuis le sRGB.
- Les UV sont stockées par coin de face ; déplier aplatit la surface en îlots dans le carré de 0 à 1.
- Une image 8 bits stocke les valeurs que tu écris sous forme d'octets, et elles sont décodées comme du sRGB : écris-y des valeurs sRGB.
- L'exporteur glTF garde les facteurs, les textures images, l'instanciation et les axes (convertis vers Y en haut), sépare les sommets dont les attributs diffèrent, abandonne silencieusement les textures procédurales, et n'applique pas les modificateurs par défaut.

## Exercices

1. Supprime le lien de la Noise Texture vers la Roughness et exporte de nouveau. Que contient maintenant le `pbrMetallicRoughness` du palissandre ?
2. Exporte la touche en `.glb`. Lis ses 20 premiers octets : que contiennent-ils, d'après la [section GLB de la spécification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#binary-gltf-layout) ?
3. Exporte avec `export_yup=False`. Prédis la translation et l'échelle du nœud `Fret 12`, puis vérifie.

<details>
<summary>Solution 1</summary>

```text
== Exercise 1: unlink the noise
Rosewood pbrMetallicRoughness keys: ['baseColorTexture', 'metallicFactor', 'roughnessFactor'] | roughnessFactor 0.8000
```

Une fois le socket déconnecté, sa valeur, 0,8, est une constante que l'exporteur sait lire.

</details>

<details>
<summary>Solution 2</summary>

```text
== Exercise 2: one .glb file
magic b'glTF' | version 2 | first chunk type b'JSON'
```

Un en-tête de 12 octets, avec le nombre magique `glTF`, la version 2 et la longueur totale, puis la longueur du premier chunk et son type, `JSON`. Le chunk binaire (`BIN`) suit celui du JSON. Dans cette exécution, le `.glb` faisait 19 032 octets, et les trois fichiers séparés 21 953 au total.

</details>

<details>
<summary>Solution 3</summary>

```text
== Exercise 3: without +Y up
node 'Fret 12' translation (0.3240, 0.0000, 0.0006) scale (0.0024, 0.0520, 0.0012)
```

Les valeurs de Blender, inchangées. Le fichier a alors Z en haut, et une visionneuse à Y en haut comme three.js lit son Z comme la profondeur : le dessus de la touche fait face à la caméra au lieu du ciel.

</details>

## Sources

- Manuel de Blender 5.2 : [matériaux](https://docs.blender.org/manual/en/5.2/render/materials/introduction.html), [Principled BSDF](https://docs.blender.org/manual/en/5.2/render/shader_nodes/shader/principled.html), [Image Texture](https://docs.blender.org/manual/en/5.2/render/shader_nodes/textures/image.html), [dépliage UV](https://docs.blender.org/manual/en/5.2/modeling/meshes/uv/unwrapping/introduction.html), [outils UV](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/uv.html), [add-on glTF 2.0](https://docs.blender.org/manual/en/5.2/addons/import_export/scene_gltf2.html), [gestion des couleurs](https://docs.blender.org/manual/en/5.2/render/color_management/index.html).
- API Python de Blender 5.2 : [`Image`](https://docs.blender.org/api/5.2/bpy.types.Image.html), [`ShaderNodeBsdfPrincipled`](https://docs.blender.org/api/5.2/bpy.types.ShaderNodeBsdfPrincipled.html), [`bpy.ops.uv`](https://docs.blender.org/api/5.2/bpy.ops.uv.html), [`bpy.ops.export_scene`](https://docs.blender.org/api/5.2/bpy.ops.export_scene.html).
- Khronos, [spécification glTF 2.0](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html) : matériaux, structure du glTF binaire.
- L'exporteur glTF dans le code source de Blender à 5.2.2 : [`__init__.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py), [`pbr_metallic_roughness.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/blender/exp/material/pbr_metallic_roughness.py) ; en amont, [KhronosGroup/glTF-Blender-IO](https://github.com/KhronosGroup/glTF-Blender-IO).
