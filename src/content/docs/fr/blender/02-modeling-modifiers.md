---
title: 2. Modélisation polygonale et modificateurs
description: 'De quoi est fait un maillage — sommets, arêtes, faces et boucles — construit à partir de listes Python et avec bmesh, comment le sens d''enroulement fixe les normales, ce que disent le caractère manifold et la caractéristique d''Euler, les outils de l''Edit Mode, et la pile non destructive de modificateurs vue comme une chaîne de décorateurs dont l''ordre change le résultat, pour finir avec la touche du cours et ses frettes placées selon le tempérament égal.'
sidebar:
  order: 2
---

Code : le script de la leçon, [`scripts/l02_modeling.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/l02_modeling.py), le modèle de la touche, [`scripts/fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py), et le rapport, [`expected/l02_modeling.txt`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/expected/l02_modeling.txt).

## De quoi est fait un maillage

Un [maillage](https://docs.blender.org/manual/en/5.2/modeling/meshes/structure.html) (mesh) est une liste de **sommets** (des points), d'**arêtes** (des paires de sommets) et de **faces** (des polygones fermés de trois sommets ou plus). Blender ajoute un quatrième élément que les tutoriels mentionnent rarement : la **boucle** (loop), ou coin de face. Une face à quatre sommets a quatre boucles, et un sommet partagé par trois faces appartient à trois boucles. Tout ce qui peut différer d'une face à l'autre au même sommet est stocké par boucle : les coordonnées UV (leçon 3), les normales séparées (split normals), les couleurs de sommets.

La touche du cours commence comme une plaque effilée de huit sommets et six quadrilatères, donnés à [`Mesh.from_pydata`](https://docs.blender.org/api/5.2/bpy.types.Mesh.html#bpy.types.Mesh.from_pydata) sous forme de listes Python, comme on remplirait un vertex buffer et un index buffer :

```python
verts = [
    (0, -w0, -THICKNESS), (length, -w1, -THICKNESS), (length, w1, -THICKNESS), (0, w0, -THICKNESS),
    (0, -w0, 0), (length, -w1, 0), (length, w1, 0), (0, w0, 0),
]
faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
mesh = bpy.data.meshes.new(name)
mesh.from_pydata(verts, [], faces)
mesh.validate()
```

`from_pydata` déduit les arêtes des faces, et `validate` cherche des données invalides dans le résultat et corrige ce qu'il trouve. Le rapport :

```text
== A mesh from vertices and faces (from_pydata)
fretboard slab: V 8 E 12 F 6 loops 24
topology: {'quads': 6} boundary edges 0 non-manifold edges 0 V-E+F 2
face 0 (bottom) vertices [0, 3, 2, 1] normal (0.000, 0.000, -1.000)
face 1 (top) vertices [4, 5, 6, 7] normal (0.000, 0.000, 1.000)
the bottom face wound the other way: normal (0.000, 0.000, 1.000)
```

L'ordre des sommets d'une face, son **sens d'enroulement** (winding), fixe sa normale : vus du côté vers lequel pointe la normale, les sommets tournent dans le sens inverse des aiguilles d'une montre. Enroule la face du dessous dans l'autre sens, et sa normale pointe vers l'intérieur de la plaque. Les moteurs de rendu et les exporteurs utilisent les normales pour l'ombrage et pour l'élimination des faces arrière (back-face culling), donc une face retournée apparaît noire ou disparaît dans three.js. En Edit Mode, [**Mesh › Normals › Recalculate Outside**](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/mesh/normals.html) (`Shift` + `N`) tourne les faces sélectionnées vers l'extérieur.

## La topologie

Les modeleurs parlent de **topologie** : la façon dont les éléments sont connectés, indépendamment de la position des sommets. Le script compte quelques propriétés avec [`bmesh`](https://docs.blender.org/api/5.2/bmesh.html), la structure de maillage modifiable de Blender :

```text
== Open and non-manifold meshes
one quad: V 4 E 4 F 1 {'quads': 1} boundary edges 4 non-manifold edges 4 V-E+F 1
three quads sharing one edge: V 8 E 10 F 3 {'quads': 3} boundary edges 9 non-manifold edges 10 V-E+F 1
the slab triangulated: V 8 E 18 F 12 {'tris': 12} boundary edges 0 non-manifold edges 0 V-E+F 2
```

- Un maillage **manifold** (variété close) est un maillage où chaque arête a exactement deux faces : une surface fermée, comme la plaque. Une arête de **bord** (boundary) n'a qu'une face : c'est le bord d'une feuille ouverte. Une arête à trois faces, comme le dos d'un livre de trois pages, est elle aussi non manifold. L'impression 3D et les opérations booléennes attendent des maillages manifold.
- Pour une surface fermée, **V − E + F** est la caractéristique d'Euler : 2 pour tout ce qui a la forme d'une sphère, quelle que soit sa subdivision, 0 pour un tore (exercice 1). C'est une vérification peu coûteuse qu'un maillage généré n'a pas de trous.
- Les **quadrilatères** (quads) sont la norme en modélisation, parce que les boucles de quads se subdivisent proprement et que les outils de boucles d'arêtes les suivent. Les **triangles** sont ce que dessinent les GPU : l'exporteur glTF (leçon 3) et le GPU triangulent tout de toute façon. Les faces de plus de quatre côtés, les **n-gons**, conviennent aux surfaces planes et posent problème sur les surfaces courbes.

Un `Mesh` stocke des tableaux plats, compacts et rapides à lire. Un `BMesh` stocke les adjacences : chaque sommet connaît ses arêtes, chaque arête ses faces. C'est sur lui que travaille l'Edit Mode, et c'est lui qu'utilisent les scripts pour changer la topologie. On passe de l'un à l'autre avec `bm.from_mesh(mesh)` et `bm.to_mesh(mesh)`, comme on chargerait un tableau immuable dans une structure de graphe pour le modifier puis le réécrire.

## L'Edit Mode

Sélectionne le cube, appuie sur `Tab`, et te voilà en Edit Mode, où tu travailles sur les sommets (`1`), les arêtes (`2`) ou les faces (`3`). Les outils qu'un débutant utilise le plus, avec leurs raccourcis par défaut :

| Outil | Raccourci | Ce qu'il fait |
|---|---|---|
| [Extrude](https://docs.blender.org/manual/en/5.2/modeling/meshes/tools/extrude_region.html) | `E` | tire la sélection vers l'extérieur, avec de nouvelles faces sur ses côtés |
| Inset | `I` | crée une face plus petite à l'intérieur de chaque face sélectionnée |
| Loop cut | `Ctrl` + `R` | ajoute une boucle d'arêtes en travers d'une bande de quads |
| [Bevel](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/edge/bevel.html) | `Ctrl` + `B` | remplace les arêtes vives par une bande de faces |
| Knife | `K` | découpe de nouvelles arêtes en travers des faces |

Ces outils modifient le maillage lui-même. Un modèle construit uniquement avec eux est une suite de modifications dont l'historique est perdu à l'enregistrement : revenir changer la largeur d'un biseau oblige à annuler tout ce qui a suivi.

## La pile de modificateurs

Un [modificateur](https://docs.blender.org/manual/en/5.2/modeling/modifiers/introduction.html) (modifier) est une opération sur la géométrie d'un objet qui n'est pas appliquée au maillage : le maillage reste tel quel, et Blender recalcule le résultat chaque fois que quelque chose change. Les modificateurs d'un objet forment une **pile** (stack), exécutée de haut en bas, chacun prenant la sortie du précédent. Pour un développeur C# ou Java, c'est une chaîne de décorateurs autour du maillage, ou un pipeline LINQ ou Stream, évalué par un graphe de dépendances quand une entrée change.

Le script ajoute un [Bevel](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/bevel.html) puis un [Subdivision Surface](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/subdivision_surface.html) à un cube, et demande le maillage évalué au graphe de dépendances :

```python
def evaluated(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    eval_obj = obj.evaluated_get(depsgraph)
    text = counts(eval_obj.to_mesh())
    eval_obj.to_mesh_clear()
    return text
```

```text
== The modifier stack is evaluated; the mesh stays as it is
stack ['Bevel', 'Subdivision']
cube.data: V 8 E 12 F 6 | evaluated: V 866 E 1728 F 864
stack ['Subdivision', 'Bevel'] | evaluated: V 98 E 192 F 96
Subdivision hidden in the viewport | evaluated: V 56 E 108 F 54
Bevel applied: stack ['Subdivision'] | cube.data: V 56 E 108 F 54 | evaluated: V 866 E 1728 F 864
```

- `cube.data` garde ses 8 sommets, quoi que fasse la pile. Ce que dessine le viewport et ce que rend le moteur de rendu, c'est le maillage **évalué**, que calcule [`Depsgraph`](https://docs.blender.org/api/5.2/bpy.types.Depsgraph.html). `to_mesh` donne une copie temporaire, que `to_mesh_clear` libère. L'exporteur glTF fait exception : il écrit le maillage sans ses modificateurs, sauf si tu actives **Apply Modifiers** ([`export_apply`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/addons_core/io_scene_gltf2/__init__.py#L679-L684), désactivé par défaut).
- **L'ordre compte.** Avec le Bevel d'abord, les 12 arêtes du cube sont arrondies, puis la subdivision lisse un maillage biseauté : un cube arrondi. Avec la subdivision d'abord, le cube devient une quasi-sphère de 96 quads, puis le biseau ne fait rien : sa méthode de limite par défaut ne biseaute que les arêtes dont les faces se rencontrent à plus de 30°, et il n'en reste aucune. L'image montre les deux.
- Chaque modificateur peut être masqué dans le viewport ou dans les rendus sans être supprimé.
- **Apply** écrit le résultat d'un modificateur dans le maillage et le retire de la pile : les 56 sommets du biseau sont désormais de vrais sommets de `cube.data`. C'est la seule étape qui n'est pas réversible.

![Deux cubes avec les deux mêmes modificateurs : à gauche Bevel puis Subdivision, un cube aux arêtes arrondies ; à droite Subdivision puis Bevel, une sphère à facettes](../../../../assets/blender/l02-modifier-order.webp)

L'image a été rendue par [`scripts/render_images.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/render_images.py) avec Cycles, avec un ombrage lisse (smooth shading) sur les deux objets. L'ombrage lisse ne change que les normales utilisées pour l'éclairage, pas la géométrie : la silhouette de la sphère montre encore ses facettes.

### Mirror et Array

Deux modificateurs se chargent de copier de la géométrie. [Mirror](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/mirror.html) reflète le maillage par rapport à l'origine de l'objet, si bien qu'on ne modélise que la moitié d'un objet symétrique. [Array](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/array.html) le répète avec un décalage, relatif à la taille de l'objet ou constant :

```text
== Mirror and Array
a cube whose center is 1 m from the origin, mirrored in X, then 5 copies in Y: V 80 E 120 F 60
copies that touch, with Merge on: V 48 E 88 F 52
local bounds: evaluated (-1.50, -0.50, -0.50) (0.50, 4.50, 0.50) | cube.data (0.50, -0.50, -0.50) (1.50, 0.50, 0.50)
```

Le miroir s'applique par rapport à l'origine de l'objet, pas au centre du maillage : c'est parce que le maillage est décalé de 1 m par rapport à l'origine que les deux moitiés sont séparées. Avec des copies qui se touchent et **Merge** activé, le modificateur Array soude les sommets là où les copies se rencontrent : 8 contacts, 4 sommets et 4 arêtes chacun, soit 32 sommets et 32 arêtes de moins, et les deux faces plaquées l'une contre l'autre à chaque contact n'en font plus qu'une, soit 8 faces de moins. Cette face reste, à l'intérieur du solide. Les limites évaluées vont de −1,5 à 1,5 en X, alors que le maillage lui-même va de 0,5 à 1,5.

## La touche du cours

[`fretboard.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/fretboard.py) construit le modèle que les leçons suivantes éclairent, texturent, rendent et exportent :

- la touche, la plaque ci-dessus, longue de 476 mm, large de 43 mm au sillet et de 56 mm à la dernière frette ;
- 22 fils de frette : **un seul** maillage de cube, et 22 objets, chacun avec sa propre position et sa propre échelle, ayant la touche pour parent ;
- 10 repères ronds aux frettes 3, 5, 7, 9, 12 (deux), 15, 17, 19 et 21, qui partagent un maillage de cylindre.

Le tempérament égal place la frette *n* à *diapason* × (1 − 2<sup>−n/12</sup>) du sillet, donc chaque intervalle est 2<sup>1/12</sup> fois plus court que le précédent. Un modificateur Array ne sait répéter qu'un décalage constant ou relatif, donc il ne peut pas placer des frettes. Une boucle le peut :

```python
for n in range(1, FRETS + 1):
    x = fret_x(n)
    obj = bpy.data.objects.new(f"Fret {n:02d}", wire)
    obj.location = (x, 0, FRET_WIRE_HEIGHT / 2)
    obj.scale = (FRET_WIRE_WIDTH, width_at(x), FRET_WIRE_HEIGHT)
    obj.parent = board
    coll.objects.link(obj)
```

```text
== The course's fretboard
mesh 'Fret wire': V 8 E 12 F 6, 22 objects: Fret 01 to Fret 22
mesh 'Fretboard': V 8 E 12 F 6, 1 objects: Fretboard to Fretboard
mesh 'Inlay dot': V 48 E 72 F 26, 10 objects: Inlay 03 to Inlay 21
Fret 01: x 36.37 mm, length 44.01 mm
Fret 12: x 324.00 mm, length 52.04 mm
Fret 22: x 466.16 mm, length 56.00 mm
objects 33 | vertices stored 64 | vertices drawn 664
world bounds in mm (0.0, -28.1, -6.0) (476.2, 28.1, 1.2)
```

La 12e frette est à 324 mm, la moitié du diapason : l'octave. Les duplications liées de la leçon 1 portent leurs fruits ici : 64 sommets sont stockés pour 664 dessinés, et changer le profil du fil revient à changer un seul maillage. Avant de lire les limites dans le repère du monde, le script appelle `bpy.context.view_layer.update()` : les objets créés depuis Python ne reçoivent leur matrice monde, qui inclut la transformation du parent, qu'à la prochaine évaluation du view layer.

## Points clés

- Un maillage, ce sont des sommets, des arêtes, des faces et des boucles ; les données qui peuvent différer d'une face à l'autre en un même sommet, comme les UV, vivent sur les boucles.
- Le sens d'enroulement d'une face fixe sa normale ; dans un maillage fermé, chaque arête appartient à deux faces, et V − E + F = 2 quand il a la forme d'une sphère.
- `Mesh` stocke des tableaux plats ; `bmesh` stocke les adjacences, et c'est avec lui qu'on modifie la topologie.
- Les modificateurs forment une pile évaluée par le graphe de dépendances ; le maillage reste inchangé tant que tu n'en appliques pas un, et l'ordre de la pile change le résultat.
- Lis le maillage évalué avec `evaluated_get(depsgraph).to_mesh()`, et libère-le avec `to_mesh_clear()`.
- Certaines formes suivent une règle qu'aucun modificateur ne connaît, comme les frettes ; un script les place dans une boucle.

## Exercices

1. Ajoute un tore avec `bpy.ops.mesh.primitive_torus_add(major_segments=48, minor_segments=12)`. Prédis ses nombres de sommets, d'arêtes et de faces, et son V − E + F, puis vérifie.
2. Mets Subdivision avant Bevel, comme dans la leçon, et trouve le réglage du Bevel qui lui fait biseauter le cube subdivisé. Combien de sommets le résultat a-t-il ?
3. Vérifie à partir de `fretboard.fret_x` que le rapport entre deux intervalles de frettes consécutifs est le même tout le long du manche, et compare-le à 2<sup>1/12</sup>.

<details>
<summary>Solution 1</summary>

```text
== Exercise 1: the Euler characteristic of a torus
torus: V 576 E 1152 F 576 {'quads': 576} boundary edges 0 non-manifold edges 0 V-E+F 0
```

48 × 12 = 576 quads, et autant de sommets, puisque chaque sommet commence un quad. Chaque quad a 4 arêtes partagées par 2 faces : 576 × 4 / 2 = 1152 arêtes. La surface est fermée et manifold, et V − E + F = 0, la valeur pour un tore.

</details>

<details>
<summary>Solution 2</summary>

La **Limit Method** du biseau (`limit_method`) vaut par défaut `ANGLE`, avec 30°. Mets-la à `NONE` et chaque arête est biseautée :

```text
== Exercise 2: Subdivision then Bevel, without the angle limit
limit_method ANGLE angle 30.0 | evaluated: V 98 E 192 F 96
limit_method NONE | evaluated: V 866 E 1728 F 864
```

Les nombres se trouvent être les mêmes que dans l'autre ordre, mais les formes diffèrent : un maillage presque sphérique avec un biseau étroit sur chacune de ses arêtes, et non un cube arrondi.

</details>

<details>
<summary>Solution 3</summary>

```python
gaps = [fretboard.fret_x(n + 1) - fretboard.fret_x(n) for n in range(fretboard.FRETS)]
```

```text
== Exercise 3: the spacing of frets
gap nut-1 36.369 mm | gap 21-22 10.813 mm | gap n / gap n+1 ['1.059463'] | 2 ** (1/12) 1.059463
```

Les 21 rapports s'arrondissent tous aux mêmes six décimales, 1,059463, soit 2<sup>1/12</sup>. L'intervalle diminue de ce facteur à chaque frette, et c'est pourquoi le décalage constant d'un modificateur Array ne peut pas le reproduire.

</details>

## Sources

- Manuel de Blender 5.2 : [structure des maillages](https://docs.blender.org/manual/en/5.2/modeling/meshes/structure.html), [modificateurs](https://docs.blender.org/manual/en/5.2/modeling/modifiers/introduction.html), [Bevel](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/bevel.html), [Subdivision Surface](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/subdivision_surface.html), [Mirror](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/mirror.html), [Array](https://docs.blender.org/manual/en/5.2/modeling/modifiers/generate/array.html), [Extrude Region](https://docs.blender.org/manual/en/5.2/modeling/meshes/tools/extrude_region.html), [outil Bevel](https://docs.blender.org/manual/en/5.2/modeling/meshes/editing/edge/bevel.html).
- API Python de Blender 5.2 : [`Mesh`](https://docs.blender.org/api/5.2/bpy.types.Mesh.html), [`bmesh`](https://docs.blender.org/api/5.2/bmesh.html), [`Depsgraph`](https://docs.blender.org/api/5.2/bpy.types.Depsgraph.html), [`BevelModifier`](https://docs.blender.org/api/5.2/bpy.types.BevelModifier.html).
- Code source de Blender à 5.2.2 : [`blender_default.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/scripts/presets/keyconfig/keymap_data/blender_default.py), le keymap par défaut.
