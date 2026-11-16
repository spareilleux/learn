---
module_id: "vc-018-carry-alpha-association-through-a-textile-edge"
department: "visual-computing"
course: "Conserver la convention d’alpha au bord d’un textile"
level: "advanced"
prerequisites: ["phy-009-distinguish-linear-color-from-display-encoding", "vc-010-preserve-packed-texture-channel-contracts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Conserver la convention d’alpha au bord d’un textile

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Une découpe brodée transparente peut présenter une frange sombre si le consommateur multiplie la couleur par alpha une seconde fois. L’ordre des canaux et le codage des couleurs ne précisent pas si RGB a déjà été associé à alpha. Ce cours ajoute cette convention à une proposition de transfert de texture de ComfyUI vers une scène.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Partez de la couleur non associée, formez sa contribution une seule fois, puis appliquez la composition source-over prémultipliée. La contribution du fond diminue selon la fraction non couverte. Le [W3C](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/) définit ces représentations ; le helper ComfyUI inspecté récupère des octets d’image sans déclarer leur convention d’alpha. Un téléchargement réussi ne tranche donc pas la question. Un échantillon opaque discrimine mal les chemins, car les calculs correct et doublement multiplié y coïncident.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "source_straight": [
      1,
      0,
      0
    ],
    "source_alpha": 0.25,
    "backdrop_straight": [
      0,
      0,
      1
    ],
    "backdrop_alpha": 1
  },
  "formula": "premul=source_alpha*source_straight; out=premul+(1-source_alpha)*backdrop_alpha*backdrop_straight; out_alpha=source_alpha+(1-source_alpha)*backdrop_alpha; double_multiplied=source_alpha*premul+(1-source_alpha)*backdrop_alpha*backdrop_straight",
  "expected": {
    "source_premultiplied": [
      0.25,
      0,
      0
    ],
    "out_premultiplied": [
      0.25,
      0,
      0.75
    ],
    "out_alpha": 1,
    "double_multiplied": [
      0.0625,
      0,
      0.75
    ]
  },
  "negative_control": {
    "values": {
      "source_straight": [
        1,
        0,
        0
      ],
      "source_alpha": 1,
      "backdrop_straight": [
        0,
        0,
        1
      ],
      "backdrop_alpha": 1
    },
    "expected": {
      "source_premultiplied": [
        1,
        0,
        0
      ],
      "out_premultiplied": [
        1,
        0,
        0
      ],
      "out_alpha": 1,
      "double_multiplied": [
        1,
        0,
        0
      ]
    }
  }
}
```

### Exercice 1

Associez une fois la couleur source.

<details><summary>Réponse 1</summary>

La contribution vaut `[0.25,0,0]`. Conservez l’étiquette de représentation avec le vecteur.

</details>

### Exercice 2

Calculez la composition source-over.

<details><summary>Réponse 2</summary>

Le résultat vaut `[0.25,0,0.75]`, avec alpha `1`. Sur ce fond opaque, la sortie associée est aussi égale à la sortie non associée.

</details>

### Exercice 3

Calculez la seconde multiplication erronée.

<details><summary>Réponse 3</summary>

Elle donne `[0.0625,0,0.75]` et réduit encore la contribution source. C’est une erreur de représentation, sans preuve d’un défaut de teinture ou de matériau.

</details>

### Exercice 4

Appliquez le témoin opaque.

<details><summary>Réponse 4</summary>

Les chemins donnent tous deux `[1,0,0]`, avec alpha `1`. Leur accord ne valide pas les contours translucides.

</details>

### Exercice 5

Que faut-il nommer dans le transfert d’une texture ?

<details><summary>Réponse 5</summary>

Précisez le domaine colorimétrique, les rôles des canaux, l’association alpha et l’ordre de composition. La récupération des octets ne fournit pas cette sémantique.

</details>

## Travail avec consultation des sources

Préparez une table manuelle des contributions avant d’inspecter le helper de téléchargement. Proposez un diagnostic de bord comprenant des cas translucides et opaques, puis consignez les métadonnées d’association nécessaires à un futur importeur.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

L’affirmation selon laquelle un accord sur des pixels opaques prouve la bonne gestion d’alpha est réfutée par les résultats translucides différents avec la même arithmétique.

## Sources et périmètre de validation

- [Prérequis déjà commité: phy-009-distinguish-linear-color-from-display-encoding](../../physics/en/phy-009-distinguish-linear-color-from-display-encoding.md)

- [Prérequis déjà commité: vc-010-preserve-packed-texture-channel-contracts](../../visual-computing/en/vc-010-preserve-packed-texture-channel-contracts.md)

- [Source de projet conservée](../../../../code/comfyui/ga-lab/runner/comfy.py)

- [Lecture primaire](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
