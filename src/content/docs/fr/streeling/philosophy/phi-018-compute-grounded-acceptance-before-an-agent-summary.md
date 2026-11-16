---
title: Calculer l’acceptation fondée avant un résumé agentique
description: Calculer l’acceptation fondée avant un résumé agentique — Philosophie
sidebar:
  label: PHI-018 · Calculer l’acceptation fondée avant un résumé agentique
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/fr/phi-018-compute-grounded-acceptance-before-an-agent-summary.fr.md
---

:::note[Streeling University]
**PHI-018** · Calculer l’acceptation fondée avant un résumé agentique · avancé · 50 minutes

Généré par le département *Philosophie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/fr/phi-018-compute-grounded-acceptance-before-an-agent-summary.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHI-001](../../philosophy/phi-001-how-to-argue-well/), [PHI-008](../../philosophy/phi-008-separate-a-test-oracle-from-a-specification/)
:::

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un débat agentique proposé contient des arguments et des attaques orientées, mais son résumé compte les soutiens. Calculez plutôt la défense : un ensemble défend un argument lorsqu’il attaque chacun de ses attaquants. Partez de l’ensemble vide, puis rassemblez les arguments défendus jusqu’au point fixe fini. Cette extension fondée dépend du graphe fourni, pas du nombre de voix ni de la confiance. Le graphe est construit ; son acceptation ne vérifie ni contenu, ni crédibilité, ni attaques manquantes, ni autorisation. Un désaccord cyclique peut rester indéterminé sans rendre tous les arguments faux.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "arguments": [
      "A",
      "B",
      "C"
    ],
    "attacks": [
      [
        "A",
        "B"
      ],
      [
        "B",
        "C"
      ]
    ]
  },
  "formula": "F(S)={a: every b attacking a is attacked by some s in S}; iterate S0=empty,S_next=F(S) until equality; out={a attacked by grounded}; undecided=remaining arguments",
  "expected": {
    "iterations": [
      [],
      [
        "A"
      ],
      [
        "A",
        "C"
      ],
      [
        "A",
        "C"
      ]
    ],
    "grounded": [
      "A",
      "C"
    ],
    "out": [
      "B"
    ],
    "undecided": []
  },
  "negative_control": {
    "values": {
      "arguments": [
        "A",
        "B",
        "C"
      ],
      "attacks": [
        [
          "A",
          "B"
        ],
        [
          "B",
          "C"
        ],
        [
          "C",
          "A"
        ]
      ]
    },
    "expected": {
      "iterations": [
        [],
        []
      ],
      "grounded": [],
      "out": [],
      "undecided": [
        "A",
        "B",
        "C"
      ]
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Une attaque est orientée ; la défense exige une contre-attaque de chaque attaquant.

</details>

### Exercice 2

Listez les itérations de défense et leur point fixe fondé.

<details><summary>Réponse 2</summary>

> **Réponse:** L’itération donne `[[],[A],[A,C],[A,C]]`, pour l’ensemble fondé `[A,C]`.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** L’ensemble rejeté `[B]` traduit les attaques d’arguments acceptés, pas une preuve de fausseté d’une source.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Le contrôle a des ensembles fondé et rejeté vides ; `[A,B,C]` restent indéterminés.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Le contenu réel, l’exhaustivité des attaques et l’autorité exigent une revue distincte avant adoption.

</details>

## Tâche avec sources et référence manuelle directe

Dessinez le graphe d’attaques proposé et chaque itération de défense près de la portée des preuves consultatives conservées.

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

- [Prérequis versionné: phi-001-how-to-argue-well](../../philosophy/phi-001-how-to-argue-well/)
- [Prérequis versionné: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/phi-008-separate-a-test-oracle-from-a-specification/)
- [Artefact local conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Lecture primaire](https://cse-robotics.engr.tamu.edu/dshell/cs631/papers/dung95acceptability.pdf)
- [Dossier du cas construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
