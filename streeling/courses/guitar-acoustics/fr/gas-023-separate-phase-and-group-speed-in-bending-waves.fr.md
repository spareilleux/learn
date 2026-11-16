---
module_id: gas-023-separate-phase-and-group-speed-in-bending-waves
department: guitar-acoustics
course: "Distinguer vitesses de phase et de groupe en flexion"
level: advanced
prerequisites: ["gas-010-distinguish-stiff-string-partials-from-harmonics"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer vitesses de phase et de groupe en flexion

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une animation d’onde de caisse peut déplacer crêtes et enveloppe à la même vitesse par défaut. Une loi idéale de dispersion en flexion leur donne des vitesses différentes. Dérivez la fréquence angulaire par rapport au nombre d’onde au lieu de les diviser. L’interprétation en paquet étroit suppose une bande locale et une faible déformation ; elle ne promet pas un déplacement rigide de toute impulsion. Le calcul propose un diagnostic pour une visualisation acoustique [Godot](https://godotengine.org/) ; maillages, matériaux et propagation réelle restent à tester.

## Hypothèses et limites propres au cas

Utilisez un nombre d’onde et un coefficient positifs dans la loi de puissance affichée. La vitesse de groupe est la dérivée locale pour une bande étroite. Aucun solveur de matériau, réponse de caisse étalonnée, paquet large ni simulation de scène n’a été exécuté.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue [GA](https://github.com/GuitarAlchemist/ga) avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-acoustics/en/gas-010-distinguish-stiff-string-partials-from-harmonics.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.dsprelated.com/freebooks/pasp/Stiff_String.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "coefficient": 2,
    "wavenumber": 3,
    "power": 2
  },
  "formula": "omega=C*k^p; phase_speed=omega/k; group_speed=C*p*k^(p-1)",
  "expected": {
    "omega": 18,
    "phase_speed": 6,
    "group_speed": 12
  },
  "negative_control": {
    "values": {
      "coefficient": 2,
      "wavenumber": 3,
      "power": 1
    },
    "expected": {
      "omega": 6,
      "phase_speed": 2,
      "group_speed": 2
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** La fréquence angulaire vaut 18, la vitesse de phase 6 et celle de groupe 12, dans des unités cohérentes stipulées.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** Une crête suit la phase ; une enveloppe étroite suit la dérivée locale dans l’approximation déclarée.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Un paquet large peut se disperser ; lui attribuer une vitesse d’enveloppe inchangée exige d’autres preuves.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Le témoin linéaire donne deux vitesses égales à 2 ; il isole la courbure de la dispersion.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Une animation déclarée quadratique qui égalise vitesse des crêtes et vitesse locale de groupe contredit ce modèle.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
