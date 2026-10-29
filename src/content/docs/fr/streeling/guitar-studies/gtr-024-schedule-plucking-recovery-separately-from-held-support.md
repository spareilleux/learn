---
title: Planifier la récupération du doigt qui pince séparément de l’appui tenu
description: Planifier la récupération du doigt qui pince séparément de l’appui tenu — Études de guitare
sidebar:
  label: GTR-024 · Planifier la récupération du doigt qui pince séparément de l’appui tenu
  order: 24
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-024-schedule-plucking-recovery-separately-from-held-support.fr.md
---

:::note[Streeling University]
**GTR-024** · Planifier la récupération du doigt qui pince séparément de l’appui tenu · avancé · 55 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-024-schedule-plucking-recovery-separately-from-held-support.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-005](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une note qui résonne longtemps occupe un intervalle acoustique sans monopoliser le doigt qui l’a pincée. Utiliser la durée de note comme temps d’occupation peut rejeter un motif possible. À l’inverse, des notes courtes ne garantissent pas une récupération suffisante pour des attaques répétées par le même doigt. Conservez une table des attaques et des récupérations stipulées, distincte de l’appui fretté tenu. C’est une règle finie pour expliquer une pratique [GA](https://github.com/GuitarAlchemist/ga), pas une limite physiologique mesurée ni une vitesse maximale recommandée.

## Hypothèses et limites propres au cas

Les attaques sont triées dans une unité commune. Les doigts sont disponibles au départ ; une attaque à l’échéance exacte est admise. La récupération est stipulée pour ce cas et ne fournit aucune mesure physiologique ni de vitesse maximale.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "attacks": [
      [
        "i",
        0
      ],
      [
        "m",
        1
      ],
      [
        "i",
        2
      ]
    ],
    "recovery": {
      "i": 2,
      "m": 2
    },
    "held_support": [
      0,
      8
    ]
  },
  "formula": "a finger is ready iff attack_time>=previous_attack_same_finger+recovery[finger]; initial fingers ready; support is recorded but not a recovery resource",
  "expected": {
    "ready": [
      true,
      true,
      true
    ],
    "violations": []
  },
  "negative_control": {
    "values": {
      "attacks": [
        [
          "i",
          0
        ],
        [
          "m",
          1
        ],
        [
          "i",
          1.5
        ]
      ],
      "recovery": {
        "i": 2,
        "m": 2
      },
      "held_support": [
        0,
        8
      ]
    },
    "expected": {
      "ready": [
        true,
        true,
        false
      ],
      "violations": [
        2
      ]
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** Toutes les attaques sont disponibles ; la dernière attaque du même doigt atteint exactement son échéance.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** L’appui tenu `[0,8]` décrit le soutien de la note, pas l’occupation du doigt qui pince.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Les récupérations sont des entrées stipulées ; elles n’établissent pas les capacités physiques d’une personne.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** La dernière attaque témoin arrive à 1.5, avant la disponibilité à 2 ; l’indice 2 viole la règle.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Une attaque du même doigt avant son instant disponible réfute la faisabilité selon la règle déclarée.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
