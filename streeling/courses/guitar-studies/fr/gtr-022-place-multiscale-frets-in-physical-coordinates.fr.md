---
module_id: gtr-022-place-multiscale-frets-in-physical-coordinates
department: guitar-studies
course: "Placer les frettes multidiapasons dans l’espace physique"
level: advanced
prerequisites: ["gtr-006-keep-picking-distance-relative-to-frets"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Placer les frettes multidiapasons dans l’espace physique

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Le même numéro de frette ne correspond pas forcément à la même coordonnée sur chaque corde d’une guitare multidiapason. Chaque corde conserve son origine au sillet et son diapason. Appliquez la fraction tempérée localement, puis revenez à l’axe commun de la scène. La ligne joignant les contacts peut être oblique malgré le même intervalle musical. Cette construction aide à examiner une scène de manche [GA](https://github.com/GuitarAlchemist/ga) sans confondre ligne affichée et frette fabriquée compensée.

## Hypothèses et limites propres au cas

Supposez des axes de cordes droits et parallèles, une unité commune et des rapports de frettes tempérés idéaux. Le témoin réutilise volontairement le premier diapason partout. Compensation, ajustement des frettes et tolérances de fabrication restent à tester.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-studies/en/gtr-006-keep-picking-distance-relative-to-frets.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/fret/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "nuts": [
      0,
      20
    ],
    "scales": [
      600,
      660
    ],
    "transverse": [
      0,
      10
    ],
    "fret": 12,
    "use_common_scale": false
  },
  "formula": "x_i=nut_i+L_i*(1-2^(-fret/12)); slope=(x_1-x_0)/(y_1-y_0)",
  "expected": {
    "positions": [
      300,
      350
    ],
    "slope": 5
  },
  "negative_control": {
    "values": {
      "nuts": [
        0,
        20
      ],
      "scales": [
        600,
        660
      ],
      "transverse": [
        0,
        10
      ],
      "fret": 12,
      "use_common_scale": true
    },
    "expected": {
      "positions": [
        300,
        320
      ],
      "slope": 2
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** Les positions valent `[300,350]` et la pente de la ligne vaut 5 dans les axes communs.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** Origine au sillet et diapason vibrant sont indépendants ; modifier l’un ne modifie pas automatiquement l’autre.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Les rapports idéaux omettent raideur, action et compensation ; ces coordonnées ne certifient pas la justesse.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Le témoin à diapason commun donne `[300,320]` et une pente de 2 ; le second contact est déplacé.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Un contact de scène différent du calcul indépendant par corde réfute la fidélité de la transformation.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
