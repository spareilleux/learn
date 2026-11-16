---
title: Conserver les lignées alternatives et leur multiplicité
description: Conserver les lignées alternatives et leur multiplicité — Sémiotique
sidebar:
  label: SEM-021 · Conserver les lignées alternatives et leur multiplicité
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-021-retain-alternative-lineages-and-their-multiplicity.fr.md
---

:::note[Streeling University]
**SEM-021** · Conserver les lignées alternatives et leur multiplicité · avancé · 50 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-021-retain-alternative-lineages-and-their-multiplicity.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-003](../../semiotics/sem-003-status-signs-and-evidence/)
:::

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un nœud de preuve artisanal proposé fusionne les dérivations en un ensemble de noms de sources. Cet ensemble perd la conjonction et les répétitions des façons de produire une sortie. Représentez chaque dérivation par un produit de jetons, puis additionnez les alternatives sans éliminer les produits répétés par idempotence. Regroupez les monômes égaux avec des coefficients naturels. Le polynôme décrit l’usage des sources, pas leur fiabilité. W3C PROV fournit un contexte général, pas cette algèbre ; l’article primaire sur les semi-anneaux fournit l’interprétation symbolique. Répéter une dérivation ne crée pas de témoin indépendant.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "derivations": [
      [
        "a",
        "b"
      ],
      [
        "a",
        "b"
      ],
      [
        "c"
      ]
    ],
    "valuation": {
      "a": 1,
      "b": 1,
      "c": 0
    }
  },
  "formula": "sort tokens inside products; collect equal monomials with integer multiplicity; evaluate sum over products of supplied token values; do not erase repeated derivations",
  "expected": {
    "coefficients": {
      "a*b": 2,
      "c": 1
    },
    "evaluated_multiplicity": 2
  },
  "negative_control": {
    "values": {
      "derivations": [
        [
          "a",
          "b"
        ],
        [
          "c"
        ]
      ],
      "valuation": {
        "a": 1,
        "b": 1,
        "c": 0
      }
    },
    "expected": {
      "coefficients": {
        "a*b": 1,
        "c": 1
      },
      "evaluated_multiplicity": 1
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les jetons désignent des occurrences de source dans une algèbre déclarée, pas des probabilités fiables.

</details>

### Exercice 2

Regroupez le polynôme principal et évaluez sa multiplicité.

<details><summary>Réponse 2</summary>

> **Réponse:** Le polynôme regroupé est `2*a*b+c` et sa multiplicité évaluée vaut `2`.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Un ensemble `[a,b,c]` perd la distinction entre usage conjoint et alternatif, ainsi que les dérivations répétées.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Le polynôme du contrôle est `a*b+c` et vaut `1` ; les noms de sources présents ne changent pas.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Cette algèbre ne fournit ni corroboration indépendante ni implémentation déployée de traçabilité.

</details>

## Tâche avec sources et référence manuelle directe

Dessinez les chemins de dérivation d’un transfert de preuves et conservez les répétitions avant de regrouper les monômes.

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

- [Prérequis versionné: sem-003-status-signs-and-evidence](../../semiotics/sem-003-status-signs-and-evidence/)
- [Artefact local conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Lecture primaire](https://www.cs.ucdavis.edu/~green/papers/pods07.pdf)
- [W3C PROV](https://www.w3.org/TR/prov-dm/)
- [Dossier du cas construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
