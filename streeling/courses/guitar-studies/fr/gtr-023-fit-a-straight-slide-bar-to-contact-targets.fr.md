---
module_id: gtr-023-fit-a-straight-slide-bar-to-contact-targets
department: guitar-studies
course: "Ajuster un bottleneck droit à des cibles de contact"
level: advanced
prerequisites: ["gtr-019-declare-the-coordinate-of-a-continuous-slide"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Ajuster un bottleneck droit à des cibles de contact

> Modèle fini construit et lecture bornée des sources. Les décisions techniques humaines, linguistiques, musicales et des apprenants restent en attente. Aucun nouveau rendu, essai d’écoute, jeu instrumental, parseur exécuté ni adoption en production n’est revendiqué.

Un diagramme peut montrer des positions de slide valides séparément mais inaccessibles simultanément à une barre droite rigide. Ajustez la coordonnée de contact par une fonction affine de la position transversale. Les moindres carrés donnent une référence explicite, puis le résidu absolu maximal teste la tolérance géométrique. La proximité des hauteurs est un autre objectif, avec d’autres poids. L’ajustement construit contraint une future suggestion [GA](https://github.com/GuitarAlchemist/ga) ou une scène pédagogique ; il ne simule ni main ni contact du bottleneck.

## Hypothèses et limites propres au cas

Les coordonnées transversales sont distinctes ; les moindres carrés sont non pondérés et exprimés en longueur physique. La barre rigide est droite. Le résidu signé vaut cible moins contact ajusté. Déformation, optimisation de hauteur et essai de jeu sont exclus.

## Partir de la représentation directe

Écrivez la table principale avant de consulter les réponses préparées. Précisez pour chaque champ le repère, l’unité physique ou logique, le support et l’ordre. Une valeur privée de sa convention ne peut pas circuler fidèlement entre graphe audio, scène et message d’agent. Dérivez les grandeurs intermédiaires autant que la décision finale. Le paquet distingue volontairement entrées et résultats attendus : une autre personne doit pouvoir recalculer, pas seulement reconnaître une étiquette familière.

Répétez l’opération avec le témoin négatif en gardant visibles les entrées modifiées. Expliquez quel invariant subsiste et quelle affirmation échoue. Un témoin utile cible le mécanisme étudié ; un autre exemple simplement plausible peut ignorer la frontière risquée. L’accord du seul cas principal ne prouve pas qu’une abstraction conserve l’opération. À l’inverse, le rejet du témoin est un résultat prévu du modèle pédagogique, pas un défaut observé dans un produit existant.

Lisez le prérequis complet et l’artefact conservé ci-dessous. Le prérequis établit une opération antérieure avec ses limites. Le programme conservé fournit un vrai processus de comparaison audio et sépare échantillons bruts, sortie codée et décisions d’acceptation. Il n’implémente pas le nouveau modèle de ce cours. Les empreintes locales identifient les octets complets à la révision indiquée ; elles ne transforment pas une inspection en exécution. Une référence primaire liée ne soutient que la définition bornée consignée dans le paquet.

## Préparer une transmission de projet avec les sources

Rédigez une courte note de revue GA avec votre calcul manuel, la convention et le témoin de rejet. Gardez ce résultat direct comme référence avant de proposer un nœud DSL, une instruction d’agent ou un contrôle de scène. La proposition doit préciser les informations préservées en entrée et l’observation qui réfuterait sa fidélité. Si une entrée manque, laissez le résultat indécis au lieu d’inventer une valeur commode.

Conservez la réponse sans aide avant de révéler les corrections. Notez calculatrice, consultation de source et assistance d’agent, puis gardez correction et original avec l’explication du changement. Le paquet prépare un critère par exercice, sans décision d’acceptation d’apprenant. Retrouver un corrigé ne prouve ni rappel autonome ni essai réussi. Consignez commandes, entrées, sorties, échecs et reprises réellement exécutés dans le journal de validation. Revue technique humaine, revue linguistique, jugement musical, exécution en production et publication exigent chacun leurs propres éléments.

[Prérequis](../../guitar-studies/en/gtr-019-declare-the-coordinate-of-a-continuous-slide.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "transverse": [
      0,
      1,
      2
    ],
    "targets": [
      3,
      4,
      5
    ],
    "tolerance": 0.1
  },
  "formula": "b=sum((y-mean(y))*(x-mean(x)))/sum((y-mean(y))^2); a=mean(x)-b*mean(y); residual=target-(a+b*y); fits=max(abs(residual))<=tolerance",
  "expected": {
    "intercept": 3,
    "slope": 1,
    "residuals": [
      0,
      0,
      0
    ],
    "fits": true
  },
  "negative_control": {
    "values": {
      "transverse": [
        0,
        1,
        2
      ],
      "targets": [
        3,
        4,
        6
      ],
      "tolerance": 0.1
    },
    "expected": {
      "intercept": 2.8333333333333335,
      "slope": 1.5,
      "residuals": [
        0.16666666666666666,
        -0.3333333333333333,
        0.16666666666666666
      ],
      "fits": false
    }
  }
}
```

### Exercice 1

Calculez le résultat principal et nommez sa convention.

> **Réponse:** L’ordonnée à l’origine vaut 3 et la pente 1 ; chaque résidu vaut 0.

### Exercice 2

Quelle grandeur faut-il distinguer ?

> **Réponse:** Erreur géométrique et erreur de hauteur sont des objectifs différents ; cet ajustement ne minimise pas des cents.

### Exercice 3

Quelle hypothèse limite la conclusion ?

> **Réponse:** Une barre droite rigide impose une ligne affine ; des contacts courbes ou articulés demandent un autre modèle.

### Exercice 4

Expliquez le témoin négatif.

> **Réponse:** Les résidus témoins sont `[1/6,-1/3,1/6]` ; leur amplitude maximale dépasse 0.1.

### Exercice 5

Quelle observation réfuterait la proposition ?

> **Réponse:** Un résidu maximal conservé supérieur à la tolérance réfute un ajustement simultané selon cette règle.

## Tâche d’apprenant avec les sources

Appliquez la transmission directe ci-dessus aux deux cas fixes. Conservez table d’entrée typée, résultats intermédiaires, explication du témoin négatif et témoin final de rejet. Les corrigés sont des vérifications préparées, pas des observations de votre travail.
