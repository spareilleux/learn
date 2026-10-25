---
title: Répartir les attaques avec une grille de parties entières
description: Répartir les attaques avec une grille de parties entières — Musiques et langues du monde
sidebar:
  label: WML-019 · Répartir les attaques avec une grille de parties entières
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-019-distribute-onsets-with-a-floor-lattice.fr.md
---

:::note[Streeling University]
**WML-019** · Répartir les attaques avec une grille de parties entières · avancé · 45 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-019-distribute-onsets-with-a-floor-lattice.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-006](../../world-music-languages/wml-006-preserve-the-origin-of-an-additive-cycle/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Une proposition de pratique demande un nombre fixé d’attaques réparties dans un cycle. Conserver le total ne détermine pas l’espacement. Nous construisons une grille par parties entières, examinons tous les écarts circulaires, puis appliquons une rotation déclarée. Le prérequis vérifie déjà l’origine d’un groupement fourni ; cette leçon ajoute sa construction avant ce contrôle.

Multipliez chaque indice d’événement par le nombre de pulsations, divisez par le nombre d’attaques et arrondissez vers le bas. Les départs entiers répartissent les événements construits. Tournez-les ensuite d’une même quantité modulo le cycle. Le tri convient à l’affichage ancré ; l’identité des événements demanderait un champ séparé si une tâche distinguait les coups individuels.

Notre critère est volontairement limité : l’écart maximal et le minimal diffèrent au plus d’une pulsation. Ce n’est ni une définition complète de régularité musicale ni une attribution culturelle. Le témoin groupé garde comptes et rotation mais échoue à ce critère. Oublier l’écart de bouclage cacherait son plus grand silence. Un cercle dessiné à la main fournit donc une référence utile avant tout DSL ou suggestion d’agent. Le cours conservé motive la conservation de l’origine, de l’ordre et des limites culturelles. Aucun enregistrement, rythme validé culturellement ou résultat GA n’a fourni ces événements.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../world-music-languages/wml-006-preserve-the-origin-of-an-additive-cycle/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "pulse_count": 8,
    "onset_count": 3,
    "rotation": 1,
    "policy": "floor_lattice",
    "supplied_onsets": null
  },
  "formula": "base[i]=floor(i*N/K) for i=0..K-1 in floor_lattice, else supplied_onsets; rotated=sorted((base+rotation)%N); gaps=cyclic differences including wrap; balanced=max(gaps)-min(gaps)<=1",
  "expected": {
    "base_onsets": [
      0,
      2,
      5
    ],
    "rotated_onsets": [
      1,
      3,
      6
    ],
    "cyclic_gaps": [
      2,
      3,
      3
    ],
    "balanced": true
  },
  "negative_control": {
    "values": {
      "pulse_count": 8,
      "onset_count": 3,
      "rotation": 1,
      "policy": "supplied",
      "supplied_onsets": [
        0,
        1,
        2
      ]
    },
    "expected": {
      "base_onsets": [
        0,
        1,
        2
      ],
      "rotated_onsets": [
        1,
        2,
        3
      ],
      "cyclic_gaps": [
        1,
        1,
        6
      ],
      "balanced": false
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez des attaques entières distinctes sur une grille circulaire uniforme et des comptes positifs compatibles. Le critère inclut le bouclage. C’est un test local d’espacement, pas un théorème complet de régularité ni une attribution culturelle.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Construisez les départs non tournés par la partie entière.

<details><summary>Réponse 1</summary>

Utilisez chaque indice plutôt qu’une somme arrondie répétée ; les départs fixes sont affichés.

</details>

### Exercice 2

Appliquez la rotation sans changer le compte.

<details><summary>Réponse 2</summary>

Ajoutez la rotation modulo le cycle à chaque départ, puis triez les positions distinctes.

</details>

### Exercice 3

Calculez tous les écarts, bouclage compris.

<details><summary>Réponse 3</summary>

Leur somme est le nombre de pulsations et le cas principal respecte le critère maximal moins minimal.

</details>

### Exercice 4

Pourquoi le témoin groupé échoue-t-il ?

<details><summary>Réponse 4</summary>

Son bouclage est beaucoup plus grand que les écarts voisins malgré les comptes identiques.

</details>

### Exercice 5

Qu’est-ce qui réfute la conservation par le seul compte ?

<details><summary>Réponse 5</summary>

Des comptes égaux et des écarts différents montrent que la cardinalité ne reconstruit pas l’espacement.

</details>

## Travail avec consultation des sources

Dessinez les cycles sans aide. Proposez une instruction GA conservant règle, rotation et écarts sans attribution à une tradition.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
