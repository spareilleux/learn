---
title: Séparer le coût d’apprentissage unitaire du coût moyen cumulé
description: Séparer le coût d’apprentissage unitaire du coût moyen cumulé — Futurologie
sidebar:
  label: FUT-017 · Séparer le coût d’apprentissage unitaire du coût moyen cumulé
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/fr/fut-017-separate-unit-learning-cost-from-cumulative-average.fr.md
---

:::note[Streeling University]
**FUT-017** · Séparer le coût d’apprentissage unitaire du coût moyen cumulé · avancé · 50 minutes

Généré par le département *Futurologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/fr/fut-017-separate-unit-learning-cost-from-cumulative-average.fr.md) · [Mon journal](../../journal/)

Prérequis: [FUT-013](../../futurology/fut-013-bound-a-future-craft-workflow-by-its-serial-fraction/)
:::

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un futur pipeline artisanal promet des exports moins coûteux avec l’expérience. Déclarez une courbe de coût unitaire : chaque doublement de l’indice cumulé multiplie le coût de cette unité par le rapport annoncé. Il s’agit ici d’une courbe d’apprentissage unitaire déclarée, et non de la convention du coût moyen cumulé. Il faut sommer les coûts individuels pour obtenir celui du lot retenu. Le rapport est une hypothèse construite ; une borne de parallélisation n’estime pas cet apprentissage, et répéter une tâche ne garantit pas un progrès.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "first_cost": 16,
    "doubling_ratio": 0.5,
    "units": [
      1,
      2,
      3,
      4
    ]
  },
  "formula": "b=log(doubling_ratio)/log(2); unit_cost[n]=first_cost*n**b; total=sum(unit_cost); average=total/count(units)",
  "expected": {
    "exponent": -1,
    "unit_costs": [
      16,
      8,
      5.333333333333333,
      4
    ],
    "total": 33.33333333333333,
    "average": 8.333333333333332
  },
  "negative_control": {
    "values": {
      "first_cost": 16,
      "doubling_ratio": 1,
      "units": [
        1,
        2,
        3,
        4
      ]
    },
    "expected": {
      "exponent": 0,
      "unit_costs": [
        16,
        16,
        16,
        16
      ],
      "total": 64,
      "average": 16
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** La formule attribue un coût à chaque indice d’unité, pas directement au coût moyen cumulé.

</details>

### Exercice 2

Calculez l’exposant et les coûts de chaque unité.

<details><summary>Réponse 2</summary>

> **Réponse:** L’exposant vaut `-1` ; les coûts unitaires sont `[16,8,5.333333333333333,4]`.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Le total vaut environ `33.33333333333333` ; le coût final `4` n’est pas la moyenne du lot.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** L’exposant du contrôle vaut `0`, pour un total de `64` et une moyenne de `16`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Une estimation réelle exige des coûts unitaires comparables et une convention ajustée, révisable.

</details>

## Tâche avec sources et référence manuelle directe

Rédigez un suivi des coûts d’export Atlas en distinguant coût unitaire, total du lot et moyenne.

En masquant les réponses, dessinez un tableau ou un schéma propre à l’opération, puis calculez le résultat principal à la main. Cette première tentative conservée constitue la référence manuelle directe. Indiquez les entrées, les intermédiaires, la règle de chaque étape et la raison de tout refus ou résultat indéterminé. Énoncez le critère de réfutation avant de demander à un assistant de simplifier le travail. Un tableau ordinaire peut suffire au projet ; un DSL composable ou un nœud agentique doit apporter un bénéfice supplémentaire démontré.

Consultez ensuite l’artefact local et le passage primaire liés. Notez l’emplacement, la révision, la définition utilisée et ce qu’elle ne permet pas d’établir. Demandez à un assistant de contester une hypothèse et conservez la question et sa réponse. Déclarez comme aide tout usage de calculatrice, de traduction ou de recherche documentaire. Comparez le résultat aidé à la référence initiale avec les mêmes entrées. Rejetez une explication plus courte si elle supprime une identité, une condition ou la distinction entre exemple construit et observation du projet.

Traitez le contrôle négatif comme un enregistrement séparé. Prédisez son résultat avant de lire la correction, puis comparez les champs modifiés et les invariants. En cas de désaccord, distinguez erreur de calcul, erreur de sens et limite des hypothèses. Conservez l’échec, son diagnostic, sa correction et sa reprise ; n’effacez pas la première tentative. Remettez ces traces avec l’explication documentée et les incertitudes restantes. Cette petite boucle d’amélioration pourra servir au dogfooding, mais aucune amélioration réelle d’apprentissage ou d’exécution n’a été mesurée ici.

Le dossier prépare un critère par exercice sans remplir les décisions pédagogiques. La réponse réelle, l’historique d’aide, la correction personnelle et la décision restent vides tant qu’aucune tentative n’existe. Revue technique, revue linguistique, exécution dans le moteur, validation matérielle, adoption et publication nécessitent des preuves distinctes. Le calcul fini n’établit que la relation annoncée sous ses hypothèses. Avant de l’utiliser dans une scène ou un outil de pratique, précisez l’observation supplémentaire et son seuil de rejet ; un corrigé préparé ne vaut pas acceptation.

## Critère prospectif de réfutation

Une réponse proposée est rejetée si l’application de l’opération affichée à une entrée conservée contredit le résultat attendu, ou si son explication présente ce cas construit comme une observation déjà réalisée dans le projet.

## Critères préparés pour l’apprenant

- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 1, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 2, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 3, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 4, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 5, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.

## Sources et portée des affirmations

- [Prérequis versionné: fut-013-bound-a-future-craft-workflow-by-its-serial-fraction](../../futurology/fut-013-bound-a-future-craft-workflow-by-its-serial-fraction/)
- [Artefact local conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.python.org/3/library/math.html)
- [Dossier du cas construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
