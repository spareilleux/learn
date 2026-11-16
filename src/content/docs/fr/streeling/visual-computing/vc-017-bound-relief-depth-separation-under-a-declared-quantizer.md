---
title: Évaluer la séparation d’un relief avec un quantificateur déclaré
description: Évaluer la séparation d’un relief avec un quantificateur déclaré — Informatique visuelle
sidebar:
  label: VC-017 · Évaluer la séparation d’un relief avec un quantificateur déclaré
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-017-bound-relief-depth-separation-under-a-declared-quantizer.fr.md
---

:::note[Streeling University]
**VC-017** · Évaluer la séparation d’un relief avec un quantificateur déclaré · avancé · 45 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-017-bound-relief-depth-separation-under-a-declared-quantizer.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-014](../../visual-computing/vc-014-predict-an-embroidered-stitch-pixel-footprint/), [INF-005](../../information-theory/inf-005-quantization-and-indistinguishable-renders/)
:::

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Une arête en relief peut occuper des pixels visibles tout en partageant son code de profondeur avec le fond. L’empreinte à l’écran et la discrimination en profondeur sont des questions distinctes. Le prérequis sur la perte d’information montre déjà des collisions de quantification ; ce cours compose projection en distance inverse et quantificateur fini pour étudier le choix des plans de coupe.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Notre coordonnée place le plan proche à la borne supérieure et le plan lointain à la borne inférieure. Des écarts égaux dans le monde produisent donc des écarts de profondeur encodée inégaux. Godot documente la profondeur inversée non linéaire et sa reconstruction selon le moteur de rendu, sans identifier notre quantificateur pédagogique à un format GPU. Le pipeline expose des paramètres de capture sans choisir cette projection. Déplacer le plan proche exclut aussi davantage de géométrie : agrandir un écart de codes a un coût.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "near_m": 1,
    "far_m": 100,
    "depths_m": [
      10,
      10.1
    ],
    "quantizer_steps": 255
  },
  "formula": "d(z)=(1/z-1/far)/(1/near-1/far); q(z)=floor(steps*d(z)+0.5); separated=q(z1)!=q(z2)",
  "expected": {
    "encoded": [
      0.09090909090909093,
      0.08990899089908992
    ],
    "codes": [
      23,
      23
    ],
    "separated": false
  },
  "negative_control": {
    "values": {
      "near_m": 5,
      "far_m": 100,
      "depths_m": [
        10,
        10.1
      ],
      "quantizer_steps": 255
    },
    "expected": {
      "encoded": [
        0.4736842105263158,
        0.4684731631057843
      ],
      "codes": [
        121,
        119
      ],
      "separated": true
    }
  }
}
```

### Exercice 1

Calculez les codes du cas principal.

<details><summary>Réponse 1</summary>

Ils valent `[23,23]` ; `separated=false`. Des profondeurs physiques distinctes fusionnent après l’arrondi déclaré.

</details>

### Exercice 2

Une largeur de fil visible évite-t-elle cette collision ?

<details><summary>Réponse 2</summary>

Non. Le prérequis traite l’étendue dans le plan de l’image ; ce modèle traite la profondeur stockée selon la direction de la caméra.

</details>

### Exercice 3

Appliquez le plan proche modifié.

<details><summary>Réponse 3</summary>

Les codes deviennent `[121,119]` et `separated=true`. Les profondeurs du relief restent identiques.

</details>

### Exercice 4

Quel compromis accompagne ce changement ?

<details><summary>Réponse 4</summary>

La limite proche passe de `1 m` à `5 m`, ce qui exclurait le contenu plus proche. La séparation des codes ne suffit pas à choisir la caméra.

</details>

### Exercice 5

Cet exemple prédit-il un défaut de précision de Godot ?

<details><summary>Réponse 5</summary>

Non. Il faut identifier le moteur de rendu, la matrice de projection et le format réel du tampon, puis mesurer. L’arrondi uniforme fini est ici une hypothèse construite.

</details>

## Travail avec consultation des sources

Dressez à la main le tableau des inverses de profondeur, valeurs encodées et codes arrondis. Inspectez les paramètres de capture et le passage Godot sur la profondeur. Précisez les champs de caméra et de format manquants pour un futur essai de relief.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

L’affirmation selon laquelle des profondeurs distinctes restent toujours discernables après stockage échoue sur la paire de codes égaux ; une affirmation d’exécution exigerait aussi une mesure du tampon.

## Sources et périmètre de validation

- [Prérequis déjà commité: vc-014-predict-an-embroidered-stitch-pixel-footprint](../../visual-computing/vc-014-predict-an-embroidered-stitch-pixel-footprint/)

- [Prérequis déjà commité: inf-005-quantization-and-indistinguishable-renders](../../information-theory/inf-005-quantization-and-indistinguishable-renders/)

- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)

- [Lecture primaire](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html)

- [Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
