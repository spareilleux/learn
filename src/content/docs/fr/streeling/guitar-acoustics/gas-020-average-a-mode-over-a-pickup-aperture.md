---
title: Moyenner un mode sur l’ouverture d’un capteur
description: Moyenner un mode sur l’ouverture d’un capteur — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-020 · Moyenner un mode sur l’ouverture d’un capteur
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-020-average-a-mode-over-a-pickup-aperture.fr.md
---

:::note[Streeling University]
**GAS-020** · Moyenner un mode sur l’ouverture d’un capteur · avancé · 45 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-020-average-a-mode-over-a-pickup-aperture.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-015](../../guitar-acoustics/gas-015-separate-mode-excitation-from-observation/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un réglage de capteur proposé déplace un observateur ponctuel sans préciser sa largeur sensible. Un modèle d’observation peut combiner le déplacement sur une région ; différentes parties d’un mode s’annulent alors même si le centre n’est pas un nœud. Nous étudions une moyenne spatiale uniforme construite. Le prérequis distingue déjà excitation et observation ponctuelle. La nouvelle opération intègre l’observation sans modifier le pincement.

Intégrez chaque sinus sur l’ouverture centrée, puis divisez par sa largeur. Cette normalisation conserverait l’amplitude d’un champ spatial constant lorsque l’ouverture augmente. Le résultat est la valeur centrale multipliée par un facteur sinc dépendant de la largeur. Les signes comptent : l’annulation précède la prise de valeur absolue. Moyenner les modules supprimerait l’annulation étudiée.

Dans le cas fixe, les modes impairs considérés ont une valeur centrale non nulle et des atténuations différentes. Les modes pairs s’annulent déjà au centre et restent absents pour ce noyau symétrique. Cela ne rend pas la largeur inutile : le résultat dépend du centre, des modes et de la symétrie. Le témoin ponctuel retrouve les valeurs centrales sans changer l’excitation. Conservez noyau et normalisation dans toute proposition GA. Un capteur réel suit une autre physique ; l’intégrale pose une question d’étalonnage sans mesurer ni implémenter sa réponse.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-acoustics/gas-015-separate-mode-excitation-from-observation/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "center_fraction": 0.5,
    "width_fraction": 0.5,
    "modes": [
      1,
      2,
      3,
      4
    ]
  },
  "formula": "point_n=sin(n*pi*c); aperture_n=point_n*sin(n*pi*w/2)/(n*pi*w/2); aperture_n=point_n when w=0",
  "expected": {
    "point": [
      1,
      0,
      -1,
      0
    ],
    "aperture": [
      0.9003163161571061,
      0,
      -0.3001054387190354,
      0
    ]
  },
  "negative_control": {
    "values": {
      "center_fraction": 0.5,
      "width_fraction": 0,
      "modes": [
        1,
        2,
        3,
        4
      ]
    },
    "expected": {
      "point": [
        1,
        0,
        -1,
        0
      ],
      "aperture": [
        1,
        0,
        -1,
        0
      ]
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez des modes sinusoïdaux et une ouverture uniforme normalisée entièrement sur la corde. Gardez les moyennes signées. Détection électromagnétique, réponse en vitesse et étalonnage réel demandent un autre modèle et des observations.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Calculez les valeurs ponctuelles signées au centre.

<details><summary>Réponse 1</summary>

Les sinus donnés alternent entre ventres et nœuds ; conservez leurs signes et pas seulement leurs modules.

</details>

### Exercice 2

Pourquoi diviser l’intégrale par la largeur ?

<details><summary>Réponse 2</summary>

Le modèle est une moyenne. Sans division, changer la largeur changerait aussi la normalisation.

</details>

### Exercice 3

Quel mode non nul est le plus atténué ?

<details><summary>Réponse 3</summary>

Le mode impair le plus élevé perd une plus grande fraction de sa valeur ponctuelle par annulation spatiale.

</details>

### Exercice 4

Que retrouve le témoin de largeur nulle ?

<details><summary>Réponse 4</summary>

La limite déclarée retrouve chaque valeur ponctuelle avec la même excitation et le même centre.

</details>

### Exercice 5

Qu’est-ce qui réfute une fidélité déduite du seul point ?

<details><summary>Réponse 5</summary>

Des centres égaux avec des valeurs moyennées différentes montrent que le centre seul ne spécifie pas cette observation.

</details>

## Travail avec consultation des sources

Dérivez l’intégrale à la main et rédigez une revue conservant la largeur. Laissez ouvertes les questions électromagnétiques et les mesures.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
