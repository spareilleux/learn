---
module_id: "sem-015-bind-a-surface-marker-to-barycentric-vertex-identity"
department: "semiotics"
course: "Lier un repère de surface à l’identité des sommets barycentriques"
level: "advanced"
prerequisites: ["sem-004-face-identity-under-reindexing"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Lier un repère de surface à l’identité des sommets barycentriques

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Une épingle de révision peut rester sur la même face nommée tout en glissant après une permutation des sommets. L’identité de face désigne la surface ; les poids barycentriques désignent le point intérieur relativement à un triplet ordonné. Le cours précédent préserve le sens de la face ; celui-ci ajoute la liaison nécessaire à un repère précis.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Permuter les sommets ne change rien si les poids suivent les identités correspondantes. Le point reste identique, car seules les positions dans la liste changent, pas les contributions. [PBRT](https://pbr-book.org/4ed/Shapes/Triangle_Meshes) montre l’interpolation barycentrique des impacts et textures. Atlas construit des maillages à partir de sommets, sans constituer un système d’annotations persistantes. Conserver la face tout en gardant les anciens emplacements de poids change le point désigné. Un remaillage exige un autre argument de correspondance.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "vertices": [
      [
        0,
        0
      ],
      [
        4,
        0
      ],
      [
        0,
        2
      ]
    ],
    "weights": [
      0.25,
      0.5,
      0.25
    ],
    "new_vertex_order": [
      0,
      2,
      1
    ],
    "remap_weights": true
  },
  "formula": "p=sum(weights[i]*vertices[i]); vertices_new=vertices[order]; weights_new=weights[order] if remap else weights; p_new=sum(weights_new[i]*vertices_new[i]); preserved=(p_new==p)",
  "expected": {
    "original": [
      2,
      0.5
    ],
    "remapped_weights": [
      0.25,
      0.25,
      0.5
    ],
    "new_point": [
      2,
      0.5
    ],
    "preserved": true
  },
  "negative_control": {
    "values": {
      "vertices": [
        [
          0,
          0
        ],
        [
          4,
          0
        ],
        [
          0,
          2
        ]
      ],
      "weights": [
        0.25,
        0.5,
        0.25
      ],
      "new_vertex_order": [
        0,
        2,
        1
      ],
      "remap_weights": false
    },
    "expected": {
      "original": [
        2,
        0.5
      ],
      "remapped_weights": [
        0.25,
        0.5,
        0.25
      ],
      "new_point": [
        1,
        1
      ],
      "preserved": false
    }
  }
}
```

### Exercice 1

Placez le repère initial.

<details><summary>Réponse 1</summary>

Il se trouve en `[2,0.5]` dans les unités du plan déclaré. Les poids se rapportent à l’ordre initial des sommets.

</details>

### Exercice 2

Permutez ensemble les sommets et les poids.

<details><summary>Réponse 2</summary>

Les poids deviennent `[0.25,0.25,0.5]` et donnent `[2,0.5]` ; `preserved=true`.

</details>

### Exercice 3

Appliquez le témoin aux anciens emplacements.

<details><summary>Réponse 3</summary>

Les poids inchangés `[0.25,0.5,0.25]` donnent `[1,1]` ; `preserved=false`. La face nommée peut rester identique.

</details>

### Exercice 4

Une somme de poids égale à l’unité suffit-elle pour une épingle intérieure ?

<details><summary>Réponse 4</summary>

Non. Les poids doivent aussi être non négatifs et rester liés aux sommets voulus.

</details>

### Exercice 5

Que faut-il transmettre avec une annotation ?

<details><summary>Réponse 5</summary>

Liez la révision de surface, les identités ordonnées des sommets et les poids. Une nouvelle triangulation exige un transfert justifié plutôt qu’une réutilisation aveugle des indices.

</details>

## Travail avec consultation des sources

Dessinez manuellement le triangle et les positions des repères. Inspectez la création du maillage Atlas, puis proposez une annotation liée à la source et aux identités des sommets. Confrontez la conservation du seul identifiant de face au témoin.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

La face et sa géométrie restent identiques mais les anciens poids déplacent le point : cela réfute la conservation du repère déduite du seul identifiant de face.

## Sources et périmètre de validation

- [Prérequis déjà commité: sem-004-face-identity-under-reindexing](../../semiotics/en/sem-004-face-identity-under-reindexing.md)

- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://pbr-book.org/4ed/Shapes/Triangle_Meshes)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
