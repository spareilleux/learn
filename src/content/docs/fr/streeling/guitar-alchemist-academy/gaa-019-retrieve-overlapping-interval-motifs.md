---
title: Retrouver les motifs d’intervalles qui se chevauchent
description: Retrouver les motifs d’intervalles qui se chevauchent — Guitar Alchemist Academy
sidebar:
  label: GAA-019 · Retrouver les motifs d’intervalles qui se chevauchent
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/fr/gaa-019-retrieve-overlapping-interval-motifs.fr.md
---

:::note[Streeling University]
**GAA-019** · Retrouver les motifs d’intervalles qui se chevauchent · avancé · 45 minutes

Généré par le département *Guitar Alchemist Academy* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/fr/gaa-019-retrieve-overlapping-interval-motifs.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAA-009](../../guitar-alchemist-academy/gaa-009-test-transposition-beyond-a-memorized-fret-pattern/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Une recherche de pratique GA retrouve le bon ensemble d’intervalles mais ignore qu’un motif court revient dans une phrase. L’ensemble ne conserve ni contiguïté, ni ordre, ni multiplicité des occurrences. Nous parcourons une suite d’intervalles dirigés et gardons aussi les correspondances qui se chevauchent. Cette recherche séquentielle dépasse l’exercice de transposition du prérequis.

Une occurrence commence à un indice d’intervalle, pas forcément au même indice de note dans toute représentation. Déclarez la convention et comparez chaque tranche au motif entier. Après une correspondance, avancez au départ suivant ; sauter toute la longueur du motif perdrait ici une occurrence superposée. Les positions permettent de retrouver les passages choisis, contrairement au seul total.

Le témoin réordonne le même multiensemble et supprime toutes les occurrences contiguës. Une stratégie qui juge ces suites identiques parce que leurs comptes coïncident échoue donc à cette tâche. Inversement, la correspondance exacte ignore rythme, phrasé et registre ; elle ne démontre pas une reconnaissance générale de thème. Le dossier conservé distingue déjà réponses de forme exacte et de famille. Appliquez cette discipline à l’objectif d’intervalles contigus. Une comparaison manuelle par fenêtres suffit avant de proposer un plongement ou un DSL. Aucune recherche réelle ni réponse d’apprenant n’a fourni ces suites.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-alchemist-academy/gaa-009-test-transposition-beyond-a-memorized-fret-pattern/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "interval_stream": [
      2,
      -1,
      2,
      -1,
      2
    ],
    "motif": [
      2,
      -1,
      2
    ]
  },
  "formula": "matches=[i for i in range(len(stream)-len(motif)+1) if stream[i:i+len(motif)]==motif]; count=len(matches); overlap is permitted",
  "expected": {
    "match_starts": [
      0,
      2
    ],
    "count": 2,
    "stream_multiset": {
      "2": 3,
      "-1": 2
    }
  },
  "negative_control": {
    "values": {
      "interval_stream": [
        2,
        2,
        -1,
        -1,
        2
      ],
      "motif": [
        2,
        -1,
        2
      ]
    },
    "expected": {
      "match_starts": [],
      "count": 0,
      "stream_multiset": {
        "2": 3,
        "-1": 2
      }
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez des intervalles entiers dirigés exacts et des correspondances contiguës avec chevauchement. Les indices d’intervalles commencent à zéro. Rythme, registre, identité thématique et recherche approximative sont hors objectif.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Examinez chaque départ sans sauter après une correspondance.

<details><summary>Réponse 1</summary>

Les positions affichées conservent les occurrences exactes, dont celle qui se superpose.

</details>

### Exercice 2

Quel élément les occurrences partagent-elles ?

<details><summary>Réponse 2</summary>

Elles partagent un intervalle de frontière ; le chevauchement est autorisé et n’est pas un doublon à supprimer.

</details>

### Exercice 3

Pourquoi conserver les positions avec le total ?

<details><summary>Réponse 3</summary>

Elles identifient les passages et rendent le chevauchement vérifiable ; le total ne les reconstruit pas.

</details>

### Exercice 4

Pourquoi le témoin de même multiensemble ne correspond-il pas ?

<details><summary>Réponse 4</summary>

Son ordre diffère : aucune tranche contiguë complète n’est égale au motif.

</details>

### Exercice 5

Qu’est-ce qui réfute une recherche fondée sur un ensemble non ordonné ?

<details><summary>Réponse 5</summary>

Les mêmes comptes donnent des occurrences différentes ; ce résumé est donc insuffisant pour la tâche.

</details>

## Travail avec consultation des sources

Marquez les occurrences et conservez leurs chevauchements. Rédigez une requête GA distinguant suite exacte et similarité non ordonnée.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
