---
title: Délimiter les textes par leur longueur en octets UTF-8
description: Délimiter les textes par leur longueur en octets UTF-8 — Théorie de l'information
sidebar:
  label: INF-018 · Délimiter les textes par leur longueur en octets UTF-8
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-018-frame-text-by-utf8-byte-length.fr.md
---

:::note[Streeling University]
**INF-018** · Délimiter les textes par leur longueur en octets UTF-8 · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-018-frame-text-by-utf8-byte-length.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-014](../../information-theory/inf-014-retain-message-codebook-versions/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un transfert joint les messages avec un séparateur qui peut aussi figurer dans leur contenu. Le destinataire ne peut pas retrouver les frontières à partir du texte joint seul. Partager un vocabulaire de verdicts ne répare pas cette ambiguïté. Le cours sur les codes fixe les significations ; cette opération fixe la fin de chaque message encodé.

Le RFC 8949 compte explicitement les octets des chaînes de longueur définie et précise UTF-8. Notre notation longueur décimale puis deux-points ne reprend que cette distinction ; ce n’est pas du CBOR. Comptez les octets UTF-8 de chaque contenu, inscrivez son préfixe, puis consommez exactement ce nombre d’octets. Un séparateur interne reste du contenu.

Le caractère accentué sert de contrôle parce que le nombre de caractères diffère du nombre d’octets. Les traductions doivent conserver cette donnée littérale. Une implémentation réelle devrait aussi traiter limites de taille, préfixes incorrects et troncature, absents de ce cas fini. Le DSL doit préciser son unité de représentation avant d’annoncer des frontières non ambiguës.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: inf-014-retain-message-codebook-versions](../../information-theory/inf-014-retain-message-codebook-versions/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://www.rfc-editor.org/rfc/rfc8949.html)

## Modèle fixé et contrôle

```json
{
  "values": {
    "messages": [
      "é",
      "A|B"
    ],
    "declared_lengths": [
      2,
      3
    ]
  },
  "formula": "actual_lengths=count UTF-8 bytes per message; valid iff declared lengths equal actual lengths; if valid frame=concatenate(decimal_length+colon+message), else null.",
  "expected": {
    "actual_lengths": [
      2,
      3
    ],
    "valid": true,
    "frame": "2:é3:A|B",
    "naive_delimited": "é|A|B"
  },
  "negative_control": {
    "values": {
      "messages": [
        "é",
        "A|B"
      ],
      "declared_lengths": [
        1,
        3
      ]
    },
    "expected": {
      "actual_lengths": [
        2,
        3
      ],
      "valid": false,
      "frame": null,
      "naive_delimited": "é|A|B"
    },
    "why": "Counting Unicode characters for the first length understates its UTF-8 byte span."
  },
  "assumptions": [
    "Decimal nonnegative byte length terminated by colon; valid UTF-8 payload.",
    "Read exactly that many bytes after each length; no stream truncation or malformed prefix."
  ],
  "limits": "Toy framing is not CBOR, an escaping implementation, authentication or arbitrary-stream parser.",
  "input_types": {
    "messages": "list<Unicode string>",
    "declared_lengths": "list<nonnegative integer> of same size"
  }
}
```

### Exercice 1

Comptez les octets UTF-8.

<details><summary>Réponse 1</summary>

Les nombres valent `[2,3]` pour `[é,A|B]`. Un caractère affiché n’occupe pas forcément un seul octet.

</details>

### Exercice 2

Écrivez la trame valide.

<details><summary>Réponse 2</summary>

Elle vaut `2:é3:A|B`. Les séparateurs internes restent dans le contenu, car la longueur fixe les frontières.

</details>

### Exercice 3

Pourquoi la concaténation naïve est-elle ambiguë ?

<details><summary>Réponse 3</summary>

`é|A|B` correspond aussi aux messages `[é|A,B]`. Les octets joints n’identifient pas la partition voulue.

</details>

### Exercice 4

Appliquez le contrôle en caractères.

<details><summary>Réponse 4</summary>

Les longueurs `[1,3]` diffèrent de `[2,3]` ; `valid=false` et `frame=null`. Ne réparez pas le préfixe en silence.

</details>

### Exercice 5

Que manque-t-il pour une implémentation en flux ?

<details><summary>Réponse 5</summary>

Longueurs incorrectes, entrée tronquée, limites de taille et récupération demandent d’autres contrats. Aucun décodeur réel n’a été exercé ici.

</details>

## Travail avec consultation des sources

Préparez une note de délimitation de messages multilingues fictifs et contestez l’hypothèse de comptage.

**Référence manuelle directe:** Inscrivez les longueurs en octets UTF-8 et suivez les frontières à la main avant toute abréviation.

**Critère de réfutation:** Le caractère accentué est compté comme un octet ou un séparateur interne crée une nouvelle frontière.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
