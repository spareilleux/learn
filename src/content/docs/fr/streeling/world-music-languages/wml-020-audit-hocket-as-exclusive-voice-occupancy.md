---
title: Vérifier le hoquet par l’occupation exclusive des voix
description: Vérifier le hoquet par l’occupation exclusive des voix — Musiques et langues du monde
sidebar:
  label: WML-020 · Vérifier le hoquet par l’occupation exclusive des voix
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-020-audit-hocket-as-exclusive-voice-occupancy.fr.md
---

:::note[Streeling University]
**WML-020** · Vérifier le hoquet par l’occupation exclusive des voix · avancé · 55 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-020-audit-hocket-as-exclusive-voice-occupancy.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-019](../../world-music-languages/wml-019-distribute-onsets-with-a-floor-lattice/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une liste d’attaques fusionnée peut masquer alternance, collision ou trou entre voix. Conservez l’identité des voix et comptez l’occupation de chaque pulsation déclarée. La règle stricte construite demande exactement une voix à chaque position. C’est un exercice de planification inspiré du hoquet, pas une définition historique ou culturelle complète ni une évaluation de performance. Un générateur [GA](https://github.com/GuitarAlchemist/ga) peut vérifier l’occupation avant d’ajouter articulation ou attribution culturelle. Le nombre d’attaques ne conserve pas l’allocation aux voix.

## Hypothèses et limites propres au cas

La grille est finie, avec des positions entières uniques dans chaque voix. L’occupation désigne la présence instantanée d’une attaque, sans inférence de chevauchement des tenues. La règle construite ne vaut pas acceptation historique, culturelle ou expressive.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../world-music-languages/wml-019-distribute-onsets-with-a-floor-lattice/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/voice/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "slots": 4,
    "voices": {
      "A": [
        0,
        2
      ],
      "B": [
        1,
        3
      ]
    }
  },
  "formula": "occupancy[t]=number of voices containing t; collisions=slots with count>1; gaps=slots with count==0; exclusive_complete=all(count==1)",
  "expected": {
    "occupancy": [
      1,
      1,
      1,
      1
    ],
    "collisions": [],
    "gaps": [],
    "exclusive_complete": true
  },
  "negative_control": {
    "values": {
      "slots": 4,
      "voices": {
        "A": [
          0,
          2
        ],
        "B": [
          2,
          3
        ]
      }
    },
    "expected": {
      "occupancy": [
        1,
        0,
        2,
        1
      ],
      "collisions": [
        2
      ],
      "gaps": [
        1
      ],
      "exclusive_complete": false
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** L’occupation vaut `[1,1,1,1]` ; la grille principale est exclusive et complète.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** L’allocation aux voix diffère du compte fusionné ; conservez la voix de chaque attaque.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** L’occupation instantanée ne garantit pas l’absence de chevauchement des notes tenues ; les durées demandent une autre règle.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Le témoin crée une collision à 2 et un trou à 1 malgré le même total d’événements.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Toute position dont le compte diffère de l’unité réfute la règle stricte d’exclusivité complète.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
