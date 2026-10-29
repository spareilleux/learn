---
module_id: gas-022-scale-a-helmholtz-cavity-with-effective-neck-length
department: guitar-acoustics
course: "Redimensionner une cavité de Helmholtz avec sa longueur effective"
level: advanced
prerequisites: ["gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Redimensionner une cavité de Helmholtz avec sa longueur effective

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Une modification de caisse change l’aire de l’ouverture, le volume et la correction d’extrémité du col. Le volume seul ne prédit pas le déplacement fréquentiel. Utilisez le rapport de Helmholtz pour séparer ces contributions. Des formes semblables agrandies uniformément suivent une fréquence inversement proportionnelle à la longueur. Il s’agit d’une approximation de cavité seule : tables flexibles et rayonnement peuvent s’y coupler. Le rapport direct sert de référence pour un futur paramètre acoustique de scène, pas de pôle identifié.

## Hypothèses et limites propres au cas

Supposez une célérité inchangée, de faibles mouvements acoustiques et une cavité petite devant la longueur d’onde. Les rapports sont positifs et la longueur du col est effective. Ni vibration de table, ni pertes de rayonnement, ni résonance mesurée ne sont incluses.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue [GA](https://github.com/GuitarAlchemist/ga) avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Lecture primaire](https://www.phys.unsw.edu.au/jw/Helmholtz.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "area_ratio": 4,
    "volume_ratio": 8,
    "effective_length_ratio": 2
  },
  "formula": "frequency_ratio=sqrt(area_ratio/(volume_ratio*effective_length_ratio))",
  "expected": {
    "frequency_ratio": 0.5
  },
  "negative_control": {
    "values": {
      "area_ratio": 4,
      "volume_ratio": 8,
      "effective_length_ratio": 1
    },
    "expected": {
      "frequency_ratio": 0.7071067811865476
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** Le rapport fréquentiel vaut 0.5 avec les rapports géométriques déclarés.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** La longueur effective inclut l’air extérieur entraîné ; elle ne se réduit pas forcément à l’épaisseur de la paroi.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** L’approximation de cavité compacte exclut des variations de pression arbitraires et le couplage à une caisse flexible.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Garder un rapport de longueur de 1 donne `sqrt(0.5)`, différent du résultat de similitude 0.5.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Un rapport indépendant incompatible avec aire, volume et longueur effective réfute le redimensionnement annoncé.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
