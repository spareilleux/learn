---
title: Conserver le tempo en comparant les rapports d’attaque
description: Conserver le tempo en comparant les rapports d’attaque — Guitar Alchemist Academy
sidebar:
  label: GAA-022 · Conserver le tempo en comparant les rapports d’attaque
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/fr/gaa-022-retain-tempo-while-comparing-onset-ratios.fr.md
---

:::note[Streeling University]
**GAA-022** · Conserver le tempo en comparant les rapports d’attaque · avancé · 50 minutes

Généré par le département *Guitar Alchemist Academy* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/fr/gaa-022-retain-tempo-while-comparing-onset-ratios.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAA-010](../../guitar-alchemist-academy/gaa-010-define-a-practice-pass-before-counting-success/), [MCL-017](../../musicology/mcl-017-integrate-a-tempo-ramp-in-beat-coordinates/)
:::

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Une tentative conserve les proportions d’un rythme tout en durant davantage. Diviser les intervalles entre attaques par leur somme retire l’échelle temporelle globale ; conservez donc cette somme séparément. Calculez les écarts absolus des intervalles normalisés et leur somme. C’est un écart de forme volontairement invariant à l’échelle, pas un alignement complet sur une horloge de battements ni une règle de réussite. Il ignore la position absolue de la première attaque et ne mesure ni articulation ni écoute. Une forme parfaite peut coexister avec un tempo inadéquat pour une autre tâche déclarée.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "target_ioi": [
      1,
      2,
      1
    ],
    "attempt_ioi": [
      2,
      4,
      2
    ]
  },
  "formula": "normalize each positive IOI vector by its own sum; errors=abs(target_normalized-attempt_normalized); shape_L1=sum(errors); duration_ratio=sum(attempt)/sum(target)",
  "expected": {
    "target_normalized": [
      0.25,
      0.5,
      0.25
    ],
    "attempt_normalized": [
      0.25,
      0.5,
      0.25
    ],
    "errors": [
      0,
      0,
      0
    ],
    "shape_L1": 0,
    "duration_ratio": 2
  },
  "negative_control": {
    "values": {
      "target_ioi": [
        1,
        2,
        1
      ],
      "attempt_ioi": [
        2,
        3,
        3
      ]
    },
    "expected": {
      "target_normalized": [
        0.25,
        0.5,
        0.25
      ],
      "attempt_normalized": [
        0.25,
        0.375,
        0.375
      ],
      "errors": [
        0,
        0.125,
        0.125
      ],
      "shape_L1": 0.25,
      "duration_ratio": 2
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les intervalles positifs ne sont pas des dates absolues d’attaque ; normalisez chaque vecteur séparément.

</details>

### Exercice 2

Normalisez les vecteurs principaux d’intervalles et calculez leur erreur de forme.

<details><summary>Réponse 2</summary>

> **Réponse:** Les deux vecteurs principaux normalisés sont `[0.25,0.5,0.25]`, donnant une erreur de forme de `0`.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Le rapport de durée `2` reste nécessaire ; la normalisation seule cache l’exécution plus lente.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** L’erreur de forme du contrôle vaut `0.25` tandis que le rapport de durée reste `2`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Déclarez une tolérance de tempo et recueillez des attaques observées avant de noter un guitariste.

</details>

## Tâche avec sources et référence manuelle directe

Calculez un score de forme rythmique avec son rapport de durée en gardant le dossier d’événements comme contexte historique.

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

- [Prérequis versionné: gaa-010-define-a-practice-pass-before-counting-success](../../guitar-alchemist-academy/gaa-010-define-a-practice-pass-before-counting-success/)
- [Prérequis versionné: mcl-017-integrate-a-tempo-ramp-in-beat-coordinates](../../musicology/mcl-017-integrate-a-tempo-ramp-in-beat-coordinates/)
- [Artefact local conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)
- [Lecture primaire](https://docs.python.org/3/library/math.html)
- [Dossier du cas construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
