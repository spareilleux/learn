---
title: Relier la géométrie du frettage à la tension élastique
description: Relier la géométrie du frettage à la tension élastique — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-016 · Relier la géométrie du frettage à la tension élastique
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-016-couple-fretting-geometry-to-elastic-tension.fr.md
---

:::note[Streeling University]
**GAS-016** · Relier la géométrie du frettage à la tension élastique · avancé · 60 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-016-couple-fretting-geometry-to-elastic-tension.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-013](../../guitar-acoustics/gas-013-retune-with-an-explicit-tension-assumption/)
:::

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Raccourcir une corde et l’étirer deviennent des opérations liées lorsque le contact dévie son trajet. La prévision d’une simple demi-longueur peut alors différer d’un modèle élastique, avant même la dispersion due à la raideur. Ce cours construit une géométrie simplifiée pour une explication [GA](https://github.com/GuitarAlchemist/ga). Ses dimensions arbitraires ne sont pas des consignes de réglage d’instrument.

## Lire les éléments conservés

La source sur l’élasticité limite la proportionnalité entre contrainte et déformation au régime linéaire. Nous choisissons un ressort axial explicitement construit. Le prérequis décrit l’effet de la tension et de la longueur ; le champ de fréquence du moteur ne mesure aucune de ces grandeurs physiques.

[Prérequis](../../guitar-acoustics/gas-013-retune-with-an-explicit-tension-assumption/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/vendor/lib.rs)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://openstax.org/books/university-physics-volume-1/pages/12-3-stress-strain-and-elastic-modulus)

[Lecture principale](https://www.phys.unsw.edu.au/jw/strings.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "length_m": 1,
    "midpoint_displacement_m": 0.01,
    "axial_stiffness_n_per_m": 1000,
    "initial_tension_n": 10,
    "linear_density_kg_per_m": 0.001
  },
  "formula": "segment=sqrt((L/2)^2+h^2); extension=2*segment-L; tension=T0+K*extension; f=sqrt(tension/mu)/(2*segment); ideal_f=sqrt(T0/mu)/L; cents=1200*log2(f/ideal_f)",
  "expected": {
    "extension_m": 0.0001999800039989008,
    "tension_n": 10.1999800039989,
    "ideal_f_hz": 100,
    "frequency_hz": 100.9747574562156,
    "error_cents": 16.79361678856818
  },
  "negative_control": {
    "values": {
      "length_m": 1,
      "midpoint_displacement_m": 0,
      "axial_stiffness_n_per_m": 1000,
      "initial_tension_n": 10,
      "linear_density_kg_per_m": 0.001
    },
    "expected": {
      "extension_m": 0,
      "tension_n": 10,
      "ideal_f_hz": 100,
      "frequency_hz": 100,
      "error_cents": 0
    }
  }
}
```

## Séparer les hypothèses géométriques et matérielles

Le calcul du trajet est géométrique. Passer de l’allongement à la tension suppose une loi matérielle pour le ressort choisi. Un dessin précis peut donc coexister avec un mauvais modèle de matériau. Séparer les étapes permet de rejeter l’étalonnage du ressort tout en gardant l’observation utile : déplacer le contact change le trajet total.

La masse linéique reste fixe ici pour isoler ce couplage. Une corde réelle étirée redistribue aussi sa masse sur une longueur modifiée ; le contact peut introduire frottement ou tensions inégales. Un modèle plus détaillé devrait préciser comment ces effets sont mesurés ou approchés. Ajouter ces détails sans données rallongerait le calcul en masquant l’incertitude. Le résultat présent reste volontairement conditionnel à des hypothèses simples.

La fréquence de comparaison correspond à la demi-longueur projetée sous tension initiale, et non au fondamental à vide. Confondre ces références créerait un écart en cents bien plus grand et attribuerait mal la hausse de fréquence. Inscrivez la référence près du rapport avant le logarithme. Pour une explication GA, le dessin et l’équation constituent la référence directe. Un étalonnage physique exigerait en plus géométrie, réponse axiale et hauteur de sortie mesurées avec leurs incertitudes ; modifier un champ numérique de fréquence ne fournit aucune de ces observations.

### Exercice 1

Trouvez la longueur du segment dévié et l’allongement total. Pourquoi compter les segments ?

<details><summary>Réponse 1</summary>

Le trajet comporte la paire symétrique, même si une seule moitié est déclarée vibrante. Oublier l’autre segment sous-estime l’allongement élastique total.

</details>

### Exercice 2

Déduisez la tension de l’allongement et de la raideur axiale. Cette raideur est-elle un module de Young ?

<details><summary>Réponse 2</summary>

La tension affichée suit la loi du ressort déclaré. La raideur s’exprime en force par longueur ; il faudrait une section et une longueur de référence pour la relier au module de Young.

</details>

### Exercice 3

Comparez la fréquence modélisée à celle de la demi-longueur idéale. Quels effets se compensent ?

<details><summary>Réponse 3</summary>

La tension supplémentaire augmente la célérité, tandis que le segment dévié dépasse sa projection. Les effets entrent dans la formule ; l’écart net en cents correspond à ce cas construit.

</details>

### Exercice 4

Appliquez un déplacement nul. Quel résidu doit disparaître ?

<details><summary>Réponse 4</summary>

L’allongement, l’accroissement de tension et l’écart en cents s’annulent. Un résidu non nul dans ce témoin réfute le calcul géométrique ou sa référence.

</details>

### Exercice 5

Ce calcul permet-il de choisir une hauteur de corde réelle ou de valider un réglage physique de GA ?

<details><summary>Réponse 5</summary>

Non. Il faut mesurer la compliance, la variation de densité, le contact et la réponse du matériau. Le paramètre de fréquence du logiciel ne fournit pas ces données.

</details>

## Travail avec consultation des sources

Dessinez les segments et déduisez les valeurs à la main, puis repérez le champ logiciel qui reste une fréquence demandée. Formulez un critère de réfutation fondé sur des mesures géométriques et fréquentielles, avec une incertitude déclarée avant tout étalonnage proposé.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
