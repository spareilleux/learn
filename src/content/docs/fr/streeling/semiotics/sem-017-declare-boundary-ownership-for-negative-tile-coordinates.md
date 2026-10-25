---
title: Déclarer la propriété des frontières pour les coordonnées de tuiles négatives
description: Déclarer la propriété des frontières pour les coordonnées de tuiles négatives — Sémiotique
sidebar:
  label: SEM-017 · Déclarer la propriété des frontières pour les coordonnées de tuiles négatives
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-017-declare-boundary-ownership-for-negative-tile-coordinates.fr.md
---

:::note[Streeling University]
**SEM-017** · Déclarer la propriété des frontières pour les coordonnées de tuiles négatives · avancé · 45 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-017-declare-boundary-ownership-for-negative-tile-coordinates.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-013](../../semiotics/sem-013-align-two-motif-periods-at-a-textile-seam/), [CS-015](../../computer-science/cs-015-compose-overlapping-chunks-without-duplicate-frames/)
:::

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Un motif artisanal répété traverse l’origine du monde. Un calcul qui tronque vers zéro semble correct du côté positif, mais affecte un point légèrement à gauche de l’origine à la mauvaise tuile. Aligner les périodes conserve les phases ; cela ne définit pas la tuile propriétaire de chaque frontière spatiale.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Définissez chaque cellule comme un intervalle semi-ouvert incluant sa borne inférieure. La partie entière inférieure de la coordonnée normalisée donne alors son propriétaire unique, même du côté négatif. La référence [Python](https://docs.python.org/3/library/math.html) définit floor, sans établir un résultat d’exécution en scène. Atlas conserve des positions locales sans fournir cette règle d’indexation. Le témoin modifie seulement la règle et viole le même contrat de propriété ; il ne change pas silencieusement la spécification. Un futur adaptateur devra aussi préciser la tolérance numérique aux frontières calculées. Le prérequis sur les blocs adopte déjà des intervalles de trames semi-ouverts. Leur union ne dérive pas une adresse de cellule à partir d’une coordonnée réelle négative ; cette opération de quotient supplémentaire est le sujet du cours.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "coordinates": [
      -0.1,
      0,
      0.999,
      1
    ],
    "origin": 0,
    "pitch": 1,
    "index_rule": "floor"
  },
  "formula": "index=floor((x-origin)/pitch) for floor, otherwise trunc((x-origin)/pitch); lower=origin+index*pitch; owns=(lower<=x<lower+pitch); list failing coordinates",
  "expected": {
    "indices": [
      -1,
      0,
      0,
      1
    ],
    "ownership": [
      true,
      true,
      true,
      true
    ],
    "violating_coordinates": []
  },
  "negative_control": {
    "values": {
      "coordinates": [
        -0.1,
        0,
        0.999,
        1
      ],
      "origin": 0,
      "pitch": 1,
      "index_rule": "trunc"
    },
    "expected": {
      "indices": [
        0,
        0,
        0,
        1
      ],
      "ownership": [
        false,
        true,
        true,
        true
      ],
      "violating_coordinates": [
        -0.1
      ]
    }
  }
}
```

### Exercice 1

Trouvez les indices fondés sur floor.

<details><summary>Réponse 1</summary>

Ils sont `[-1,0,0,1]`. Chaque point appartient à son intervalle semi-ouvert déclaré.

</details>

### Exercice 2

Qui possède le point sur la frontière commune ?

<details><summary>Réponse 2</summary>

Le point `1` appartient à la tuile `1` ; la tuile `0` exclut sa borne supérieure. Il n’y a pas de double propriété.

</details>

### Exercice 3

Appliquez le témoin par troncature.

<details><summary>Réponse 3</summary>

Il donne `[0,0,0,1]`. La coordonnée `-0.1` sort de la tuile attribuée ; son contrôle de propriété vaut donc `false`.

</details>

### Exercice 4

Des exemples uniquement positifs révèlent-ils l’erreur ?

<details><summary>Réponse 4</summary>

Non. Les coordonnées non négatives fournies donnent le même résultat avec les deux règles. Une coordonnée négative est un test discriminant.

</details>

### Exercice 5

Que faut-il conserver dans un placement composé ?

<details><summary>Réponse 5</summary>

Conservez origine, pas, repère, convention de frontière et règle d’indexation. Le nom d’un motif périodique ne permet pas de les retrouver.

</details>

## Travail avec consultation des sources

Dessinez des intervalles voisins autour de l’origine, placez chaque coordonnée à la main et comparez les règles. Inspectez les positions locales Atlas et identifiez la convention de propriété manquante avant de proposer un DSL de tuiles.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

La coordonnée négative réfute l’interchangeabilité de la troncature et de floor pour l’attribution des tuiles.

## Sources et périmètre de validation

- [Prérequis déjà commité: sem-013-align-two-motif-periods-at-a-textile-seam](../../semiotics/sem-013-align-two-motif-periods-at-a-textile-seam/)

- [Prérequis déjà commité: cs-015-compose-overlapping-chunks-without-duplicate-frames](../../computer-science/cs-015-compose-overlapping-chunks-without-duplicate-frames/)

- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://docs.python.org/3/library/math.html)

- [Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
