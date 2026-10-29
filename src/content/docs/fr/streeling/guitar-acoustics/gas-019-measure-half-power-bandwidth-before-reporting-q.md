---
title: Mesurer la largeur à mi-puissance avant d’annoncer Q
description: Mesurer la largeur à mi-puissance avant d’annoncer Q — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-019 · Mesurer la largeur à mi-puissance avant d’annoncer Q
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-019-measure-half-power-bandwidth-before-reporting-q.fr.md
---

:::note[Streeling University]
**GAS-019** · Mesurer la largeur à mi-puissance avant d’annoncer Q · avancé · 45 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-019-measure-half-power-bandwidth-before-reporting-q.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-007](../../guitar-acoustics/gas-007-distinguish-body-poles-from-string-partials/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Une explication du filtre de corps GA annonce un centre de résonance et qualifie la réponse d’étroite sans donner de largeur. Le centre seul ne décrit pas la sélectivité. Nous introduisons une courbe de puissance normalisée et calculons les fréquences où elle atteint la moitié du maximum. C’est une mesure de largeur, différente de la recherche d’un pôle ou d’un pic.

La courbe construite permet de résoudre directement les croisements. Les points comprennent le centre et les deux limites exactes : aucune interpolation cachée n’intervient. Si une mesure ne contenait pas ces limites, il faudrait annoncer un estimateur et une résolution fréquentielle. Un graphique clairsemé ne crée pas une précision absente des données.

Le témoin conserve le centre et le maximum, tout en élargissant la réponse. Les valeurs normalisées sont les mêmes à des fréquences différemment espacées : les axes font donc partie du tableau. Le quotient de largeur change alors qu’un résumé du pic ne signalerait rien. La moitié de l’amplitude est un autre seuil que la moitié de la puissance et donnerait d’autres limites. Q désigne ici le quotient déclaré du centre par la largeur. Le relier au temps d’amortissement, aux pertes d’un matériau ou au rayon d’un pôle du moteur exigerait un modèle compatible. Le cours conservé fournit une frontière concrète, pas ces équivalences manquantes.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-acoustics/gas-007-distinguish-body-poles-from-string-partials/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "center_hz": 100,
    "halfwidth_hz": 5,
    "frequencies_hz": [
      90,
      95,
      100,
      105,
      110
    ]
  },
  "formula": "P(f)=1/(1+((f-f0)/b)^2); half_power_edges=[f0-b,f0+b]; bandwidth=2*b; Q=f0/bandwidth",
  "expected": {
    "relative_power": [
      0.2,
      0.5,
      1,
      0.5,
      0.2
    ],
    "half_power_edges_hz": [
      95,
      105
    ],
    "bandwidth_hz": 10,
    "Q": 10
  },
  "negative_control": {
    "values": {
      "center_hz": 100,
      "halfwidth_hz": 10,
      "frequencies_hz": [
        80,
        90,
        100,
        110,
        120
      ]
    },
    "expected": {
      "relative_power": [
        0.2,
        0.5,
        1,
        0.5,
        0.2
      ],
      "half_power_edges_hz": [
        90,
        110
      ],
      "bandwidth_hz": 20,
      "Q": 5
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez une courbe de puissance construite isolée, une demi-largeur positive et des croisements continus exacts. Son Q est défini par le quotient affiché. Aucun ajustement physique ni conversion de rayon de pôle n’est implicite.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Repérez les limites exactes à mi-puissance.

<details><summary>Réponse 1</summary>

Posez la puissance égale à la moitié du maximum ; les limites sont à une demi-largeur du centre.

</details>

### Exercice 2

Calculez largeur totale et quotient Q.

<details><summary>Réponse 2</summary>

Soustrayez les limites, puis divisez le centre par cette largeur totale, comme dans le cas fixe.

</details>

### Exercice 3

Pourquoi préciser puissance plutôt qu’amplitude ?

<details><summary>Réponse 3</summary>

Le seuil de demi-amplitude donnerait d’autres fréquences et une autre largeur.

</details>

### Exercice 4

Que conserve et que change le témoin élargi ?

<details><summary>Réponse 4</summary>

Il conserve centre et maximum, double la largeur et divise le quotient Q par deux.

</details>

### Exercice 5

Qu’est-ce qui réfute une sélectivité déduite du seul pic ?

<details><summary>Réponse 5</summary>

Les centres égaux avec largeurs différentes montrent que le centre seul ne détermine pas ce Q.

</details>

## Travail avec consultation des sources

Préparez un relevé proposé avec axes, type de seuil et règle de croisement. Laissez non résolue la conversion vers les coefficients GA.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
