---
title: Conserver la correspondance circulaire entre étiquettes d’événements
description: Conserver la correspondance circulaire entre étiquettes d’événements — Musiques et langues du monde
sidebar:
  label: WML-022 · Conserver la correspondance circulaire entre étiquettes d’événements
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-022-retain-circular-correspondence-between-event-labels.fr.md
---

:::note[Streeling University]
**WML-022** · Conserver la correspondance circulaire entre étiquettes d’événements · avancé · 55 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-022-retain-circular-correspondence-between-event-labels.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-006](../../world-music-languages/wml-006-preserve-the-origin-of-an-additive-cycle/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une phrase cyclique peut commencer sur un autre événement sans changer l’ordre circulaire des étiquettes. Comparez tous les décalages et conservez chaque correspondance valide. Des répétitions peuvent admettre plusieurs solutions : choisir la première invente un ancrage. Un renversement change l’ordre et n’équivaut pas automatiquement à une rotation. C’est une règle finie d’étiquettes pour les échanges de pratique [GA](https://github.com/GuitarAlchemist/ga), sans identification culturelle, inférence temporelle ni équivalence des accents.

## Hypothèses et limites propres au cas

Utilisez des suites non vides de même longueur, une égalité exacte des étiquettes et le sens du décalage affiché. Le renversement est distinct. Accent et temps ne sont pas encodés : l’égalité circulaire ne juge pas l’équivalence des performances.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../world-music-languages/wml-006-preserve-the-origin-of-an-additive-cycle/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "source": [
      "a",
      "b",
      "c",
      "d"
    ],
    "target": [
      "c",
      "d",
      "a",
      "b"
    ]
  },
  "formula": "shifts=[s in range(N) where target[i]==source[(i+s)%N] for every i]; unique=len(shifts)==1",
  "expected": {
    "shifts": [
      2
    ],
    "unique": true
  },
  "negative_control": {
    "values": {
      "source": [
        "a",
        "b",
        "a",
        "b"
      ],
      "target": [
        "a",
        "b",
        "a",
        "b"
      ]
    },
    "expected": {
      "shifts": [
        0,
        2
      ],
      "unique": false
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** Le décalage unique vaut 2 selon le sens d’indexation déclaré de cible vers source.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** Équivalence circulaire et ancrage unique diffèrent ; plusieurs décalages peuvent satisfaire l’équivalence.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Les étiquettes omettent accent et durée ; l’ordre circulaire ne conserve pas des propriétés musicales non enregistrées.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Le témoin répété donne `[0,2]` ; choisir une correspondance inventerait une origine unique.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Plusieurs décalages valides réfutent l’ancrage unique même si l’équivalence circulaire tient.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
