---
title: Vérifier l’ambiguïté de mots de code concaténés
description: Vérifier l’ambiguïté de mots de code concaténés — Théorie de l'information
sidebar:
  label: INF-019 · Vérifier l’ambiguïté de mots de code concaténés
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-019-check-concatenated-codeword-ambiguity.fr.md
---

:::note[Streeling University]
**INF-019** · Vérifier l’ambiguïté de mots de code concaténés · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-019-check-concatenated-codeword-ambiguity.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-014](../../information-theory/inf-014-retain-message-codebook-versions/), [INF-018](../../information-theory/inf-018-frame-text-by-utf8-byte-length/)
:::

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un transfert d’agent remplace des symboles d’état par de courtes chaînes binaires. Les deux côtés choisissent le même dictionnaire et les bits arrivent intacts. Le récepteur peut néanmoins ignorer où finit un symbole et où commence le suivant. Accord sur le sens et intégrité des octets ne suffisent pas à donner une séquence décodable de façon unique.

Écrivez chaque mot de code près de son symbole avant de concaténer. Dans un code préfixe, aucun mot complet n’est le début d’un autre. Un décodeur peut donc terminer un symbole sans attendre un séparateur caché. Pour le dictionnaire fixé, suivez le flux fourni et gardez les positions des frontières. C’est un argument élémentaire sur la correspondance finie déclarée, pas une implémentation d’un protocole de compression internet.

Le contrôle donne un flux explicitement ambigu. Il désigne soit un symbole, soit une paire, les deux lectures consommant tous les bits. Retenir la première analyse plausible cacherait l’ambiguïté. Énumérez les analyses complètes avant d’annoncer une lecture unique. Une violation de préfixe avertit d’un risque, mais certains codes non préfixes restent uniquement décodables ; ne transformez pas une condition suffisante en équivalence injustifiée.

La RFC HPACK décrit des codes Huffman concaténés avec leurs propres exigences de cadrage et de remplissage. Notre correspondance reprend la question de communication, sans son format ni sa table. Les prérequis gardent versions de dictionnaire et longueurs en octets ; ici, l’opération porte sur les frontières internes du flux. Une abréviation DSL devrait expliciter séparateurs, longueurs ou convention de décodage. La référence manuelle est assez petite pour examiner toutes les possibilités sans créer de service de transport.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: inf-014-retain-message-codebook-versions](../../information-theory/inf-014-retain-message-codebook-versions/)

[Prérequis: inf-018-frame-text-by-utf8-byte-length](../../information-theory/inf-018-frame-text-by-utf8-byte-length/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://www.rfc-editor.org/rfc/rfc7541.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "codebook": {
      "A": "0",
      "B": "10",
      "C": "11"
    },
    "stream": "01011"
  },
  "formula": "A proper prefix violation is an ordered distinct-symbol pair [s,t] with code(s) a proper prefix of code(t). Enumerate every complete symbol sequence whose concatenated codewords equal stream; lexicographically sort sequences.",
  "expected": {
    "prefix_violations": [],
    "prefix_free": true,
    "decodings": [
      [
        "A",
        "B",
        "C"
      ]
    ],
    "decoding_count": 1
  },
  "negative_control": {
    "values": {
      "codebook": {
        "A": "0",
        "B": "01",
        "C": "1"
      },
      "stream": "01"
    },
    "expected": {
      "prefix_violations": [
        [
          "A",
          "B"
        ]
      ],
      "prefix_free": false,
      "decodings": [
        [
          "A",
          "C"
        ],
        [
          "B"
        ]
      ],
      "decoding_count": 2
    },
    "why": "One bit string now names both a single symbol and a symbol pair."
  },
  "input_types": {
    "codebook": "finite symbol-to-distinct-nonempty-bitstring mapping",
    "stream": "finite bitstring"
  },
  "assumptions": [
    "Codebook version agreed; no corruption; no implicit symbol separators.",
    "Only complete parses that consume every stream bit count."
  ],
  "limits": "Prefix-free is sufficient for instantaneous decoding. Failure of prefix-freeness alone does not prove every code or every stream ambiguous; the explicit witness matters."
}
```

### Exercice 1

Décodez entièrement le flux fixé.

<details><summary>Réponse 1</summary>

La seule séquence complète est `[A,B,C]`. Ses frontières suivent `0`, `10`, `11` ; aucune autre séquence ne consomme le flux.

</details>

### Exercice 2

Repérez la violation de préfixe du contrôle.

<details><summary>Réponse 2</summary>

Le symbole `A` est un préfixe propre de `B`. La liste ordonnée vaut `[[A,B]]` ; le dictionnaire n’est pas préfixe.

</details>

### Exercice 3

Donnez les analyses complètes du contrôle.

<details><summary>Réponse 3</summary>

Le flux `01` donne `[A,C]` ou `[B]`, soit `2` analyses complètes. Gardez les deux ; choisir le verdict préféré inventerait une information.

</details>

### Exercice 4

Toute violation prouve-t-elle un décodage ambigu ?

<details><summary>Réponse 4</summary>

Non. Être préfixe suffit au décodage immédiat. Ici, l’ambiguïté est établie par les séquences réellement concurrentes, pas par une réciproque abusivement généralisée.

</details>

### Exercice 5

Une somme de contrôle résoudrait-elle l’ambiguïté ?

<details><summary>Réponse 5</summary>

Non. Les interprétations utilisent les mêmes bits intacts. Spécifiez frontières ou code adapté avant les contrôles d’intégrité, qui traitent un autre échec.

</details>

## Travail avec consultation des sources

Examinez un alphabet compact proposé pour les états d’un transfert d’agent.

**Référence manuelle directe:** Listez les mots de code et énumérez manuellement les segmentations complètes du petit flux.

**Critère de réfutation:** Un flux intact possède deux séquences complètes avec le même dictionnaire déclaré.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Décodez entièrement le flux fixé. — Décision indéterminée.
- Exercice 2: Repérez la violation de préfixe du contrôle. — Décision indéterminée.
- Exercice 3: Donnez les analyses complètes du contrôle. — Décision indéterminée.
- Exercice 4: Toute violation prouve-t-elle un décodage ambigu ? — Décision indéterminée.
- Exercice 5: Une somme de contrôle résoudrait-elle l’ambiguïté ? — Décision indéterminée.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
