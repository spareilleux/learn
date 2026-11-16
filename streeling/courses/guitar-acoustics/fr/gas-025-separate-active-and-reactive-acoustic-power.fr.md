---
module_id: gas-025-separate-active-and-reactive-acoustic-power
department: guitar-acoustics
course: "Distinguer puissances acoustiques active et réactive"
level: advanced
prerequisites: ["gas-018-account-for-energy-at-an-impedance-junction"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer puissances acoustiques active et réactive

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une pression et un débit oscillants élevés ne garantissent pas une forte puissance moyenne transférée. Leur phase relative compte. Multipliez la pression par le débit conjugué en conservant le facteur des phaseurs de crête avant de prendre la partie réelle. La partie imaginaire décrit l’échange réactif selon le signe choisi ; ce n’est pas une puissance moyenne dissipée supplémentaire. Ce calcul de port aide à examiner un diagnostic de caisse, sans étalonner ni mesurer la pression réelle. Ne remplacez pas le débit par la vitesse locale sans changer de grandeur.

## Hypothèses et limites propres au cas

Utilisez des phaseurs de crête avec la convention temporelle exponentielle complexe positive, et pression et débit au même port. Le débit entre dans le port. Aucun champ spatial d’intensité ni aucune mesure étalonnée de puissance n’a été obtenu.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue [GA](https://github.com/GuitarAlchemist/ga) avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-acoustics/en/gas-018-account-for-energy-at-an-impedance-junction.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "pressure": [
      2,
      0
    ],
    "volume_velocity": [
      0,
      1
    ],
    "phasor_kind": "peak"
  },
  "formula": "S=0.5*P*conj(U) for peak phasors; active=real(S); reactive=imag(S)",
  "expected": {
    "complex_power": [
      0,
      -1
    ],
    "active": 0,
    "reactive": -1
  },
  "negative_control": {
    "values": {
      "pressure": [
        2,
        0
      ],
      "volume_velocity": [
        1,
        0
      ],
      "phasor_kind": "peak"
    },
    "expected": {
      "complex_power": [
        1,
        0
      ],
      "active": 1,
      "reactive": 0
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** La puissance complexe principale vaut `-1j`, avec une puissance active de 0 et réactive de -1.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** La puissance réactive ne s’ajoute pas à la dissipation moyenne ; elle décrit l’échange en quadrature selon la convention.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Le facteur 0.5 appartient aux phaseurs de crête ; des phaseurs efficaces demanderaient une autre normalisation.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** En phase, la puissance complexe vaut 1, l’active 1 et la réactive 0 malgré les modules inchangés.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Une règle fondée seulement sur les modules prédisant la même puissance moyenne est réfutée par leur phase différente.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
