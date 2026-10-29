---
title: Reconnaître des repères ordonnés malgré des événements intercalés
description: Reconnaître des repères ordonnés malgré des événements intercalés — Musiques et langues du monde
sidebar:
  label: WML-023 · Reconnaître des repères ordonnés malgré des événements intercalés
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-023-accept-ordered-landmarks-with-intervening-events.fr.md
---

:::note[Streeling University]
**WML-023** · Reconnaître des repères ordonnés malgré des événements intercalés · avancé · 55 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-023-accept-ordered-landmarks-with-intervening-events.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-012](../../world-music-languages/wml-012-preserve-direction-in-a-melodic-inventory/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une phrase pédagogique peut exiger des repères ordonnés tout en autorisant des ornements entre eux. Une recherche contiguë est trop stricte, mais l’appartenance sans ordre est trop permissive. N’avancez le repère attendu que lorsque son étiquette apparaît ; conservez les indices comme témoin. Un repère répété demande un événement ultérieur distinct. La règle est construite pour un exercice [GA](https://github.com/GuitarAlchemist/ga). Elle ne définit pas les ornements d’une tradition, ne juge pas le style et ne décide pas quelles notes ajoutées un musicien accepterait.

## Hypothèses et limites propres au cas

Le parcours fini consomme chaque événement au plus une fois et ignore librement les autres étiquettes selon la règle stipulée. Un repère répété exige un événement ultérieur distinct. Aucun jugement de style, tolérance temporelle ni reconnaisseur de performance n’est fourni.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../world-music-languages/wml-012-preserve-direction-in-a-melodic-inventory/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "landmarks": [
      "a",
      "c",
      "e"
    ],
    "events": [
      "a",
      "b",
      "c",
      "d",
      "e"
    ]
  },
  "formula": "scan events left to right; advance next landmark on equality; witness stores consumed event indices; accepted iff all landmarks consumed",
  "expected": {
    "witness": [
      0,
      2,
      4
    ],
    "consumed": 3,
    "accepted": true
  },
  "negative_control": {
    "values": {
      "landmarks": [
        "a",
        "c",
        "e"
      ],
      "events": [
        "e",
        "b",
        "c",
        "d",
        "a"
      ]
    },
    "expected": {
      "witness": [
        4
      ],
      "consumed": 1,
      "accepted": false
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** Le témoin vaut `[0,2,4]` ; les 3 repères sont consommés malgré les événements intercalés.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** Une sous-séquence ordonnée diffère d’un motif contigu et d’une appartenance sans ordre.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Ignorer toutes les étiquettes supplémentaires est une règle stipulée, pas un jugement musical sur les ornements.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Le témoin d’ordre inversé ne consomme que l’indice 4 et échoue malgré les mêmes étiquettes repères.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Un enregistrement accepté sans témoin complet strictement croissant réfute la reconnaissance ordonnée annoncée.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
