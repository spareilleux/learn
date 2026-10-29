---
module_id: gas-024-track-avoided-crossings-through-detuning
department: guitar-acoustics
course: "Suivre un croisement évité en faisant varier le désaccord"
level: advanced
prerequisites: ["gas-012-distinguish-coupling-from-parallel-resonance"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Suivre un croisement évité en faisant varier le désaccord

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Deux pics peuvent échanger leur caractère physique dominant lorsqu’un paramètre de caisse traverse une résonance de corde. Trier les pics par fréquence ne conserve pas l’identité d’un composant. Suivez les branches propres d’une matrice symétrique de fréquences au carré pendant un balayage du désaccord. Le couplage ouvre un écart minimal entre ces valeurs propres. Cet écart n’est pas une largeur d’amortissement ; les racines carrées ont une autre séparation. La table construite sert au diagnostic [GA](https://github.com/GuitarAlchemist/ga) sans ajuster une vraie guitare.

## Hypothèses et limites propres au cas

La matrice est réelle symétrique et les valeurs propres de fréquence au carré restent positives. L’amortissement est absent. Le minimum porte sur le balayage fini fourni ; aucun couplage physique ajusté n’est revendiqué.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-acoustics/en/gas-012-distinguish-coupling-from-parallel-resonance.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "center": 10,
    "detunings": [
      -3,
      0,
      3
    ],
    "coupling": 2
  },
  "formula": "matrix=[[c+d,g],[g,c-d]]; eigenvalues=c+-sqrt(d*d+g*g); gap=2*sqrt(d*d+g*g)",
  "expected": {
    "lower": [
      6.39444872453601,
      8,
      6.39444872453601
    ],
    "upper": [
      13.60555127546399,
      12,
      13.60555127546399
    ],
    "gaps": [
      7.211102550927978,
      4,
      7.211102550927978
    ],
    "minimum_gap": 4
  },
  "negative_control": {
    "values": {
      "center": 10,
      "detunings": [
        -3,
        0,
        3
      ],
      "coupling": 0
    },
    "expected": {
      "lower": [
        7,
        10,
        7
      ],
      "upper": [
        13,
        10,
        13
      ],
      "gaps": [
        6,
        0,
        6
      ],
      "minimum_gap": 0
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** Au désaccord nul, les branches de fréquence au carré valent 8 et 12 ; leur écart vaut 4.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** L’écart des fréquences au carré diffère d’un écart fréquentiel ; conservez la coordonnée avant de prendre les racines.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Ce balayage fini contient le minimum symétrique, mais n’identifie ni amortissement ni couplage d’une vraie guitare.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Avec un couplage de 0, les branches se rejoignent à 10 et l’écart minimal vaut 0.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Un écart de 0 au désaccord nul avec le couplage non nul conservé réfuterait la prédiction affichée.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
