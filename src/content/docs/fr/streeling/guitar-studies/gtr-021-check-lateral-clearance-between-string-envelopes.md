---
title: Vérifier le dégagement latéral entre cordes
description: Vérifier le dégagement latéral entre cordes — Études de guitare
sidebar:
  label: GTR-021 · Vérifier le dégagement latéral entre cordes
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-021-check-lateral-clearance-between-string-envelopes.fr.md
---

:::note[Streeling University]
**GTR-021** · Vérifier le dégagement latéral entre cordes · avancé · 55 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-021-check-lateral-clearance-between-string-envelopes.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-013](../../guitar-studies/gtr-013-judge-a-bend-with-an-uncertainty-budget/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une hauteur de bend correcte ne garantit pas le dégagement par rapport à la corde voisine. Conservez rayons et déplacements balayés des deux cordes avant de comparer leurs enveloppes. L’écart des intervalles représente le rapprochement maximal autorisé, pas seulement la distance des centres au repos. Ce contrôle géométrique conservateur peut aider une explication de doigté [GA](https://github.com/GuitarAlchemist/ga) ou une surimpression [Godot](https://godotengine.org/). Il ne reproduit ni soulèvement vertical, ni technique, ni collision élastique, ni forme sur toute la corde. Un écart positif reste conditionnel.

## Hypothèses et limites propres au cas

Le contrôle porte sur une seule coupe latérale avec des plages de déplacement indépendantes. Le contact n’est pas un dégagement ; toutes les longueurs partagent une unité. Évitement vertical, géométrie complète et essai instrumental sont absents.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-studies/gtr-013-judge-a-bend-with-an-uncertainty-budget/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "centers": [
      0,
      10
    ],
    "radii": [
      1,
      1
    ],
    "displacements": [
      [
        0,
        6
      ],
      [
        -1,
        0
      ]
    ]
  },
  "formula": "interval_i=[center_i+min_displacement_i-radius_i,center_i+max_displacement_i+radius_i]; gap=interval_1.low-interval_0.high; clear=gap>0",
  "expected": {
    "intervals": [
      [
        -1,
        7
      ],
      [
        8,
        11
      ]
    ],
    "gap": 1,
    "clear": true
  },
  "negative_control": {
    "values": {
      "centers": [
        0,
        10
      ],
      "radii": [
        1,
        1
      ],
      "displacements": [
        [
          0,
          8
        ],
        [
          -1,
          0
        ]
      ]
    },
    "expected": {
      "intervals": [
        [
          -1,
          9
        ],
        [
          8,
          11
        ]
      ],
      "gap": -1,
      "clear": false
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** Les intervalles balayés sont `[-1,7]` et `[8,11]` ; l’écart vaut 1 et le dégagement est vrai.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** La distance des centres au repos n’est pas le dégagement des bords ; rayons et mouvements la réduisent.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Les plages indépendantes donnent une enveloppe conservatrice ; des mouvements corrélés dans le temps demandent des trajectoires.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** L’écart témoin vaut -1 : les enveloppes se recouvrent et le dégagement annoncé échoue.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Un déplacement admis créant une intersection réfute le dégagement latéral universel dans cette coupe.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
