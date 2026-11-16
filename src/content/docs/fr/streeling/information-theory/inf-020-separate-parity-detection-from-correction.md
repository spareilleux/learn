---
title: Distinguer détection par parité et correction
description: Distinguer détection par parité et correction — Théorie de l'information
sidebar:
  label: INF-020 · Distinguer détection par parité et correction
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-020-separate-parity-detection-from-correction.fr.md
---

:::note[Streeling University]
**INF-020** · Distinguer détection par parité et correction · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-020-separate-parity-detection-from-correction.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-014](../../information-theory/inf-014-retain-message-codebook-versions/)
:::

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un agent reçoit une étiquette compacte de preuve et constate que l’enregistrement est analysable. Cela n’établit pas que les bits transmis ont été préservés. Le cours sur les dictionnaires traite d’un autre problème : des bits intacts interprétés avec la mauvaise correspondance. Ici, les parties s’accordent sur le sens, mais le canal change certains bits avant le décodage.

Ajoutez un bit pour rendre pair le nombre total de bits à l’état haut. À la réception, recalculez cette condition de parité. Modifier un seul bit change la parité et permet de détecter la violation. Cela ne révèle pas sa position. Plusieurs messages initiaux pourraient respecter la condition ; choisir une réparation sans information supplémentaire serait deviner.

L’entrée fixée change une position de données. Le contrôle en change deux et passe le test de parité malgré un message différent. Gardez syndrome et distance de Hamming réelle dans le dossier pédagogique : la comparaison avec l’émetteur connaît les bits modifiés, mais un récepteur ordinaire n’a pas cette référence. Un syndrome nul indique seulement que ce contrôle n’a détecté aucune violation.

Le cours de l’Université du Nouveau-Brunswick expose la détection simple et la limite des erreurs en nombre pair. Notre petit mot rend ces frontières vérifiables à la main. Il ne fournit ni empreinte cryptographique ni recommandation de transport pour Demerzel. Une preuve de production doit traiter séparément identité, autorisation et lien avec la révision sémantique. Avant d’ajouter une étape composable, nommez le modèle d’erreur et faites-lui rapporter la détection, sans prétendre que le message est juste, fiable ou réparé.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: inf-014-retain-message-codebook-versions](../../information-theory/inf-014-retain-message-codebook-versions/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://www.ece.unb.ca/tervo/ece4253/ecc.shtml)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "data": [
      1,
      0,
      1,
      1
    ],
    "flip_indices": [
      1
    ]
  },
  "formula": "Append p=sum(data)%2, giving even total parity. Flip each distinct zero-based index in codeword. syndrome=sum(received)%2; detected iff syndrome=1. hamming_distance counts changed bits; no correction attempted.",
  "expected": {
    "parity_bit": 1,
    "codeword": [
      1,
      0,
      1,
      1,
      1
    ],
    "received": [
      1,
      1,
      1,
      1,
      1
    ],
    "syndrome": 1,
    "detected": true,
    "hamming_distance": 1
  },
  "negative_control": {
    "values": {
      "data": [
        1,
        0,
        1,
        1
      ],
      "flip_indices": [
        1,
        2
      ]
    },
    "expected": {
      "parity_bit": 1,
      "codeword": [
        1,
        0,
        1,
        1,
        1
      ],
      "received": [
        1,
        1,
        0,
        1,
        1
      ],
      "syndrome": 0,
      "detected": false,
      "hamming_distance": 2
    },
    "why": "Two substitutions preserve even parity despite altering the message."
  },
  "input_types": {
    "data": "finite binary integer list",
    "flip_indices": "distinct valid zero-based codeword indices"
  },
  "assumptions": [
    "Known codeword boundary; only bit substitutions, no insertions or deletions.",
    "Receiver checks parity but has no additional information about error location."
  ],
  "limits": "This toy parity check is not a production integrity mechanism, semantic validation, authentication or error correction."
}
```

### Exercice 1

Encodez les données avec parité paire.

<details><summary>Réponse 1</summary>

Le bit de parité vaut `1` et le mot complet est `[1,0,1,1,1]`. Le bit ajouté fait partie du mot vérifié, pas des symboles de données.

</details>

### Exercice 2

Vérifiez la substitution simple.

<details><summary>Réponse 2</summary>

Le mot reçu est `[1,1,1,1,1]`, le syndrome `1` et la détection `true`. La distance à la référence vaut `1` ; le syndrome seul n’indique pas la position.

</details>

### Exercice 3

Appliquez le contrôle à double substitution.

<details><summary>Réponse 3</summary>

Le mot reçu est `[1,1,0,1,1]`, le syndrome `0`, la détection `false` et la distance `2`. Une parité conforme peut accompagner des données modifiées.

</details>

### Exercice 4

Le récepteur peut-il corriger l’erreur détectée ?

<details><summary>Réponse 4</summary>

Pas avec ce seul syndrome, qui n’identifie pas le bit modifié. Refusez de deviner la correction et demandez l’information nécessaire au vrai protocole du canal.

</details>

### Exercice 5

Réussir le contrôle établit-il une preuve fiable ?

<details><summary>Réponse 5</summary>

Non. Il traite un motif restreint de corruption, sans établir identité de l’émetteur, sens de la révision, autorisation ni vérité de l’affirmation encodée.

</details>

## Travail avec consultation des sources

Expliquez la portée exacte d’une étape de parité proposée pour un transfert de preuve illustratif.

**Référence manuelle directe:** Comptez les bits et marquez manuellement les positions modifiées face au mot de référence construit.

**Critère de réfutation:** Un syndrome nul est présenté comme preuve de données inchangées ou authentifiées.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Encodez les données avec parité paire. — Décision indéterminée.
- Exercice 2: Vérifiez la substitution simple. — Décision indéterminée.
- Exercice 3: Appliquez le contrôle à double substitution. — Décision indéterminée.
- Exercice 4: Le récepteur peut-il corriger l’erreur détectée ? — Décision indéterminée.
- Exercice 5: Réussir le contrôle établit-il une preuve fiable ? — Décision indéterminée.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
