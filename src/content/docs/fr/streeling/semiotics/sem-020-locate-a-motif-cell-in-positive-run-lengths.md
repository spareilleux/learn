---
title: Localiser une cellule de motif dans des longueurs de séquence positives
description: Localiser une cellule de motif dans des longueurs de séquence positives — Sémiotique
sidebar:
  label: SEM-020 · Localiser une cellule de motif dans des longueurs de séquence positives
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-020-locate-a-motif-cell-in-positive-run-lengths.fr.md
---

:::note[Streeling University]
**SEM-020** · Localiser une cellule de motif dans des longueurs de séquence positives · avancé · 45 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-020-locate-a-motif-cell-in-positive-run-lengths.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-013](../../semiotics/sem-013-align-two-motif-periods-at-a-textile-seam/), [INF-011](../../information-theory/inf-011-separate-compressed-size-from-preserved-information/)
:::

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Une bordure brodée répète un motif stocké par séquences de longueur donnée plutôt que cellule par cellule. Prendre l’indice de séquence pour l’indice de cellule change le référent : une longue séquence de chaîne couvre plusieurs cellules, la suivante de trame une seule éventuellement. L’opération localise une cellule globale en réduisant son adresse déphasée dans la période puis en cherchant les fins cumulées. C’est un contrat de sens sur papier, sans parseur de production ni nouveau format de compression.

Validez les longueurs avant de calculer la période. Elles doivent être des entiers strictement positifs, afin que les fins cumulées croissent strictement. La cellule appartient à la première fin strictement supérieure au décalage réduit ; l’égalité avec une fin appartient à la séquence suivante. Cela préserve les frontières internes semi-ouvertes sans confondre cette opération avec l’indexation de tuiles négatives. Le modulo traite la répétition ; la recherche traite les régions internes inégales.

Le témoin à longueur nulle demande un refus, pas une réparation devinée. Remplacer la longueur un du cas principal par zéro réduirait sa somme de `6` à `5` si cette entrée était admise. Supprimer ensuite l’enregistrement de longueur nulle ne change ni cette somme ni les symboles développés ; cela efface l’instruction mal formée et sa provenance. Le contrat de longueurs strictement positives refuse donc l’entrée avant de lui attribuer une période. Un transfert IX futur peut conserver deux séquences de symbole identique pour des provenances différentes ; leur fusion doit être une réécriture explicite avec correspondance. L’assistant peut la proposer, sans déclarer l’entrée mal formée admise parce que l’aperçu reste rayé.

Le prérequis commité sur la compression enseigne déjà le développement des séquences et le compte de taille stockée. L’opération nouvelle est la recherche de cellule indexée avec phase et appartenance aux frontières internes ; elle ne revendique aucun nouvel encodage ni aller-retour.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "runs": [
      [
        "warp",
        2
      ],
      [
        "weft",
        1
      ],
      [
        "warp",
        3
      ]
    ],
    "indices": [
      0,
      2,
      5,
      6,
      8
    ],
    "phase": 0
  },
  "formula": "reject any run length <=0 or non-integer; period=sum(lengths); offset=(index+phase)%period; choose first cumulative end strictly greater than offset",
  "expected": {
    "status": "valid",
    "period": 6,
    "samples": [
      "warp",
      "weft",
      "warp",
      "warp",
      "weft"
    ]
  },
  "negative_control": {
    "values": {
      "runs": [
        [
          "warp",
          2
        ],
        [
          "weft",
          0
        ],
        [
          "warp",
          3
        ]
      ],
      "indices": [
        0,
        2,
        5,
        6,
        8
      ],
      "phase": 0
    },
    "expected": {
      "status": "invalid_run",
      "period": null,
      "samples": null
    }
  }
}
```

### Exercice 1

Calculez la période.

<details><summary>Réponse 1</summary>

Elle vaut `6`. Additionnez les longueurs en cellules, pas le nombre d’enregistrements de séquence, qui compte un autre objet.

</details>

### Exercice 2

Résolvez la requête sur frontière interne.

<details><summary>Réponse 2</summary>

À l’indice `2`, le symbole est `weft`. L’égalité avec la fin cumulée précédente attribue la cellule à la séquence suivante.

</details>

### Exercice 3

Résolvez toutes les cellules demandées.

<details><summary>Réponse 3</summary>

Les symboles sont `[warp,weft,warp,warp,weft]`. Réduisez la répétition globale avant de chercher les séquences inégales.

</details>

### Exercice 4

Appliquez le témoin à longueur nulle.

<details><summary>Réponse 4</summary>

Renvoyez `invalid_run`, avec période et échantillons `null`. Supprimer une séquence de longueur nulle ne change pas sa contribution arithmétique, mais accepter silencieusement le reste masquerait la violation du contrat de longueurs strictement positives.

</details>

### Exercice 5

Faut-il toujours fusionner des symboles adjacents identiques ?

<details><summary>Réponse 5</summary>

Non. Les cellules peuvent être conservées et la provenance perdue. Déclarez l’équivalence permise et conservez une correspondance avant réécriture.

</details>

## Travail avec sources et référence manuelle directe

Développez la bordure à la main avec adresses de cellules et identités des séquences. Comparez les recherches et conservez le refus du témoin au lieu de le réparer. Proposez une note minimale de transfert de motif IX.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Un interpréteur annonçant `valid` pour l’entrée à longueur nulle viole le contrat de longueurs strictement positives. La suppression ne rétablit ni la provenance manquante ni le motif voulu.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: sem-013-align-two-motif-periods-at-a-textile-seam](../../semiotics/sem-013-align-two-motif-periods-at-a-textile-seam/)
- [Prérequis commité: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/inf-011-separate-compressed-size-from-preserved-information/)
- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/streeling/weave-godot/trial.gd)
- [Lecture primaire](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Paquet construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
