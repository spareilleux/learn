---
title: Composer des capodastres sélectifs par une borne supérieure composante par composante
description: Composer des capodastres sélectifs par une borne supérieure composante par composante — Études de guitare
sidebar:
  label: GTR-025 · Composer des capodastres sélectifs par une borne supérieure composante par composante
  order: 25
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-025-compose-selective-capos-with-a-componentwise-join.fr.md
---

:::note[Streeling University]
**GTR-025** · Composer des capodastres sélectifs par une borne supérieure composante par composante · avancé · 55 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-025-compose-selective-capos-with-a-componentwise-join.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-008](../../guitar-studies/gtr-008-count-a-capo-offset-once/)
:::

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Un agent peut vouloir combiner deux capodastres sélectifs sans dépendre de l’ordre des messages. Pour chaque corde, la frette active la plus haute devient l’origine effective idéale. Le maximum composante par composante est commutatif, associatif et idempotent. Ces lois ne rendent pas le retrait inversible. Une fois l’arrêt inférieur perdu dans l’agrégat, enlever le plus haut ne permet pas de le retrouver. Conservez les dispositifs actifs si le retrait compte. L’abstraction porte sur des origines idéales, sans certifier la compatibilité physique des capodastres.

## Hypothèses et limites propres au cas

Les tableaux ont même longueur et des arrêts physiques entiers non négatifs. Zéro conserve l’origine au sillet. L’arrêt effectif est le plus haut arrêt actif de chaque corde. Gardez les dispositifs et leur multiplicité pour le retrait ; aucun dégagement physique n’est certifié.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue [GA](https://github.com/GuitarAlchemist/ga) avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-studies/gtr-008-count-a-capo-offset-once/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/capo/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "a": [
      2,
      0,
      4
    ],
    "b": [
      0,
      3,
      2
    ],
    "c": [
      1,
      1,
      1
    ],
    "alternate_a": [
      2,
      0,
      0
    ]
  },
  "formula": "join(x,y)[i]=max(x[i],y[i]); compare commutativity, associativity and idempotence; removal requires original active records",
  "expected": {
    "join_ab": [
      2,
      3,
      4
    ],
    "join_abc": [
      2,
      3,
      4
    ],
    "commutative": true,
    "associative": true,
    "idempotent": true,
    "alternate_join": [
      2,
      3,
      2
    ],
    "aggregate_distinguishes": true
  },
  "negative_control": {
    "values": {
      "a": [
        2,
        0,
        2
      ],
      "b": [
        0,
        3,
        4
      ],
      "c": [
        1,
        1,
        1
      ],
      "alternate_a": [
        2,
        0,
        0
      ]
    },
    "expected": {
      "join_ab": [
        2,
        3,
        4
      ],
      "join_abc": [
        2,
        3,
        4
      ],
      "commutative": true,
      "associative": true,
      "idempotent": true,
      "alternate_join": [
        2,
        3,
        4
      ],
      "aggregate_distinguishes": false
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** La borne supérieure principale vaut `[2,3,4]` ; ajouter c laisse `[2,3,4]`.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** L’arrêt effectif diffère de la provenance des dispositifs ; un maximum élimine les contributions inférieures.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Le maximum scalaire satisfait les trois lois ; chaque composante aussi, d’où les lois vectorielles.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Le témoin donne le même agrégat pour des a différents ; retirer b ne révèle pas le a masqué.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Deux états sous-jacents distincts de même agrégat réfutent un inverse unique du retrait.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
