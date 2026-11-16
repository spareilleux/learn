---
title: Faire le bilan d’énergie à une jonction d’impédances
description: Faire le bilan d’énergie à une jonction d’impédances — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-018 · Faire le bilan d’énergie à une jonction d’impédances
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-018-account-for-energy-at-an-impedance-junction.fr.md
---

:::note[Streeling University]
**GAS-018** · Faire le bilan d’énergie à une jonction d’impédances · avancé · 45 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-018-account-for-energy-at-an-impedance-junction.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-011](../../guitar-acoustics/gas-011-track-reflection-polarity-at-string-boundaries/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Une revue de modèle de guitare voit une amplitude transmise supérieure à l’amplitude incidente et conclut à une création d’énergie. Elle oublie l’impédance associée à la variable d’onde. Une jonction de pression volontairement simple permet de distinguer rapports d’amplitude et fractions d’énergie avant d’employer le vocabulaire de diffusion pour un chevalet. Ce bilan dépasse le signe de déplacement étudié en prérequis ; les variables sont différentes.

La source dérive la continuité de pression et de débit pour des impédances réelles positives. Dans notre cas construit, le rapport de pression transmise dépasse l’unité alors que la fraction de puissance reste inférieure à l’unité. Le carré de l’amplitude sans rapport d’impédances donnerait un bilan faux. Les fractions réfléchie et transmise reconstituent la fraction incidente sous les hypothèses idéales déclarées. Signes et directions suivent notre convention d’ondes progressives.

Le témoin adapté ne réduit pas seulement un gain arbitraire : il change la relation de frontière et annule la réflexion, sans supprimer l’onde transmise. Cette distinction compte avant de proposer un réglage d’amortissement du retour. Un vrai chevalet présente des interactions plus complexes ; nous n’avons ni courbe mesurée ni paramètre de couplage étalonné. Une table directe de pression et de puissance pondérée précède tout DSL de jonction. Ne transformez pas ce résultat en règle de déplacement.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-acoustics/gas-011-track-reflection-polarity-at-string-boundaries/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lecture primaire](https://www.dsprelated.com/freebooks/pasp/Scattering_Impedance_Changes.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "incident_pressure": 1,
    "impedance_left": 1,
    "impedance_right": 3
  },
  "formula": "r=(Z2-Z1)/(Z1+Z2); t=1+r; reflected_fraction=r^2; transmitted_fraction=(Z1/Z2)*t^2; total=reflected_fraction+transmitted_fraction",
  "expected": {
    "pressure_reflection": 0.5,
    "pressure_transmission": 1.5,
    "reflected_fraction": 0.25,
    "transmitted_fraction": 0.75,
    "total": 1
  },
  "negative_control": {
    "values": {
      "incident_pressure": 1,
      "impedance_left": 1,
      "impedance_right": 1
    },
    "expected": {
      "pressure_reflection": 0,
      "pressure_transmission": 1,
      "reflected_fraction": 0,
      "transmitted_fraction": 1,
      "total": 1
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez une onde plane normale, des impédances réelles positives et une jonction sans perte ni état stocké. Aucune onde n’arrive de droite. Ces rapports de pression ne remplacent pas ceux du déplacement de corde.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Dérivez les rapports de pression réfléchie et transmise.

<details><summary>Réponse 1</summary>

La réflexion est la différence d’impédances sur leur somme ; ajoutez l’unité pour la transmission de pression dans cette convention.

</details>

### Exercice 2

Pourquoi une amplitude supérieure à l’unité ne viole-t-elle pas l’énergie ?

<details><summary>Réponse 2</summary>

La puissance transmise utilise aussi le rapport d’impédances ; l’amplitude seule n’est pas une fraction de puissance.

</details>

### Exercice 3

Vérifiez le bilan complet de puissance.

<details><summary>Réponse 3</summary>

Les fractions affichées reconstituent toute la fraction incidente pour cette jonction sans perte.

</details>

### Exercice 4

Que donne le témoin adapté ?

<details><summary>Réponse 4</summary>

La réflexion disparaît, tandis que pression et puissance traversent la frontière adaptée.

</details>

### Exercice 5

Qu’est-ce qui rejette une interprétation directe du chevalet ?

<details><summary>Réponse 5</summary>

Sans identité de variable ni modèle d’impédance mesuré, ce résultat d’onde plane ne permet pas une affirmation étalonnée sur le chevalet.

</details>

## Travail avec consultation des sources

Annotez un schéma GA proposé avec les variables d’onde et le bilan pondéré. Conservez la frontière adaptée comme contre-cas obligatoire.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
