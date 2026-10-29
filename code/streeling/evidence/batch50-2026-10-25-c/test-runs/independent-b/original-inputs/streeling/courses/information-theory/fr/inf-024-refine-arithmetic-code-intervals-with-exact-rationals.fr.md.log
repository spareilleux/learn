---
module_id: "inf-024-refine-arithmetic-code-intervals-with-exact-rationals"
department: "information-theory"
course: "Raffiner les intervalles de codage arithmétique en rationnels exacts"
title: "Raffiner les intervalles de codage arithmétique en rationnels exacts"
level: "intermediate"
prerequisites: ["inf-019-check-concatenated-codeword-ambiguity", "inf-014-retain-message-codebook-versions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Raffiner les intervalles de codage arithmétique en rationnels exacts

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un artefact agentique peut contenir un flux symbolique répétitif dont les fréquences déclarées suggèrent une représentation compacte. Le codage arithmétique attribue un intervalle à la séquence entière plutôt qu’un mot binaire à chaque symbole. Ce cours examine la sémantique exacte des intervalles avant toute compression pratique. La table de fréquences fait partie du contrat de décodage.

Découpez l’intervalle semi-ouvert courant selon les fréquences cumulées ordonnées. Choisissez le sous-intervalle du symbole suivant, puis recommencez avec les deux anciennes bornes. Les rationnels exacts empêchent un arrondi de frontière d’admettre silencieusement un autre symbole. La borne gauche appartient à l’intervalle et la droite en est exclue ; une valeur sur une frontière a donc un propriétaire déclaré.

La séquence fixée et son contrôle partagent un préfixe, puis aboutissent à des intervalles disjoints. Une valeur intérieure décode la séquence correspondante si sa longueur est connue. Coût de représentation, terminaison, renormalisation et précision finie restent hors du modèle. Une largeur d’intervalle n’est pas une taille de fichier mesurée. Conservez ordre de l’alphabet, fréquences et longueur : une valeur numérique isolée ne décrit pas son propre décodage.

## Sources et périmètre du projet

[Prérequis: inf-019-check-concatenated-codeword-ambiguity](../../information-theory/en/inf-019-check-concatenated-codeword-ambiguity.md)

[Prérequis: inf-014-retain-message-codebook-versions](../../information-theory/en/inf-014-retain-message-codebook-versions.md)

[Artefact du projet conservé](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://www.ece.unb.ca/tervo/ece4253/arith.shtml)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "alphabet": [
      "A",
      "B"
    ],
    "frequencies": [
      1,
      3
    ],
    "sequence": "ABA",
    "tag": "3/32"
  },
  "formula": "Start [L,U)=[0,1). For each symbol with cumulative fraction c and probability p, replace by [L+(U-L)*c,L+(U-L)*(c+p)). Compute with exact rational strings. Decode tag for the declared sequence length using the same half-open partitions.",
  "expected": {
    "intervals": [
      [
        "0",
        "1/4"
      ],
      [
        "1/16",
        "1/4"
      ],
      [
        "1/16",
        "7/64"
      ]
    ],
    "width": "3/64",
    "tag_inside": true,
    "decoded": "ABA"
  },
  "negative_control": {
    "values": {
      "alphabet": [
        "A",
        "B"
      ],
      "frequencies": [
        1,
        3
      ],
      "sequence": "ABB",
      "tag": "3/16"
    },
    "expected": {
      "intervals": [
        [
          "0",
          "1/4"
        ],
        [
          "1/16",
          "1/4"
        ],
        [
          "7/64",
          "1/4"
        ]
      ],
      "width": "9/64",
      "tag_inside": true,
      "decoded": "ABB"
    },
    "why": "A changed suffix selects a different final half-open interval under the same frequency model."
  },
  "input_types": {
    "alphabet": "ordered distinct symbol strings",
    "frequencies": "same-length positive integers",
    "sequence": "nonempty string over the single-character alphabet",
    "tag": "exact rational string inside the unit interval"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No bitstream length, finite-precision coder, entropy guarantee, compressed artifact or production decoder is measured."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Raffiner les bornes rationnelles et décoder une valeur intérieure avec la longueur déclarée.

**Critère de réfutation:** Codeur et décodeur utilisent des ordres, fréquences, longueurs ou conventions de bornes différents.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Trouvez l’intervalle final fixé.

> **Réponse:** L’intervalle final est `[1/16,7/64)` et sa largeur vaut `3/64`. La valeur `3/32` est intérieure et décode `ABA`.

### Exercice 2

Appliquez le contrôle de suffixe modifié.

> **Réponse:** La séquence `ABB` aboutit à `[7/64,1/4)`, de largeur `9/64` ; la valeur `3/16` décode `ABB`.

### Exercice 3

À qui appartient la frontière commune ?

> **Réponse:** La frontière `7/64` est exclue de l’intervalle `ABA` et incluse dans celui de `ABB`. Les intervalles semi-ouverts évitent l’ambiguïté.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: L’intervalle final est `[1/16,7/64)` et sa largeur vaut `3/64`. La valeur `3/32` est intérieure et décode `ABA`.
- Exercice 2: La séquence `ABB` aboutit à `[7/64,1/4)`, de largeur `9/64` ; la valeur `3/16` décode `ABB`.
- Exercice 3: La frontière `7/64` est exclue de l’intervalle `ABA` et incluse dans celui de `ABB`. Les intervalles semi-ouverts évitent l’ambiguïté.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
