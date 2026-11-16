---
title: Sélectionner les harmoniques naturelles par un point de contact
description: Sélectionner les harmoniques naturelles par un point de contact — Études de guitare
sidebar:
  label: GTR-012 · Sélectionner les harmoniques naturelles par un point de contact
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-012-select-natural-harmonics-with-a-touch-node.fr.md
---

:::note[Streeling University]
**GTR-012** · Sélectionner les harmoniques naturelles par un point de contact · intermédiaire · 55 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-012-select-natural-harmonics-with-a-touch-node.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-006](../../guitar-acoustics/gas-006-relate-pluck-position-to-string-modes/)
:::

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un repère de manche peut indiquer où presser, mais une harmonique naturelle demande un autre geste : effleurer un nœud en conservant la longueur vibrante entière. Confondre ces actions modifie la hauteur prévue et la consigne. Une table modale idéale explique ici leur différence. Nous ajoutons une contrainte de contact au modèle de pincement du prérequis ; une coordonnée identique ne désigne pas la même opération physique.

## Lire les preuves conservées

La page UNSW décrit les nœuds, les fréquences modales et les harmoniques obtenues par effleurement. Lire ces passages avec les états de voix et d’excitation Rust conservés. Une fréquence stockée n’est pas un modèle de contact ; les partiels du moteur exigent une mesure réelle. Notre table est un calcul construit, sans guitare jouée ni harmonique rendue.

[Prérequis](../../guitar-acoustics/gas-006-relate-pluck-position-to-string-modes/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/vendor/lib.rs)

[Dossier construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.phys.unsw.edu.au/jw/strings.html)

### Exercice 1

Choisir un fondamental de `110 Hz` et les modes `[1,2,3,4,5,6]`. Leur forme idéale est `sin(n*pi*x/L)`. À la fraction de contact `1/3`, un mode respecte le déplacement nul si son numéro est divisible par `3`. Dans cette règle idéale, le contact ne raccourcit pas la corde : il supprime les mouvements incompatibles.

Quels modes candidats ont un nœud au point de contact ?

<details><summary>Réponse 1</summary>

Les modes `[3,6]` subsistent. Les autres modes listés ont un déplacement non nul à `1/3` et sont supprimés par la contrainte déclarée.

</details>

### Exercice 2

Multiplier les numéros conservés par le fondamental donne `[330,660] Hz`, avec minimum `330 Hz`. Plusieurs composantes peuvent être permises, sans que la règle détermine leurs amplitudes. Ne pas transformer la plus basse fréquence autorisée en affirmation mesurée de saillance ou de sonie.

Quelles fréquences subsistent et quelle est la plus basse ?

<details><summary>Réponse 2</summary>

Elles valent `[330,660] Hz`, avec minimum `330 Hz`. Leurs amplitudes relatives et la hauteur perçue n’ont été ni spécifiées ni observées.

</details>

### Exercice 3

Un appui ferme à la même coordonnée créerait une nouvelle extrémité vibrante ; la hauteur dépendrait du côté restant entre appui et chevalet. Notre coordonnée part d’une extrémité déclarée, ce n’est pas un numéro de frette. Il faut préciser origine et geste avant de traduire cette géométrie en diagramme ou en consigne d’agent.

Pourquoi la fraction seule ne définit-elle pas une note frettée ?

<details><summary>Réponse 3</summary>

Effleurement et appui imposent des contraintes différentes. La note frettée demande le côté et la longueur conservés ; la table d’harmoniques garde le fondamental d’origine `110 Hz` comme référence.

</details>

### Exercice 4

Le contrôle négatif déplace le contact à `1/2`. Les modes `[2,4,6]` subsistent, aux fréquences `[220,440,660] Hz`, avec minimum `220 Hz`. Le sixième mode subsiste aux deux positions, mais la composante la plus basse change. Ne rapporter que le partiel aigu commun masquerait une modification importante de la consigne.

Qu’est-ce qui change et qu’est-ce qui reste commun ?

<details><summary>Réponse 4</summary>

Le minimum passe de `330 Hz` à `220 Hz`. Le mode `6`, à `660 Hz`, reste commun. Un partiel partagé n’établit ni gestes ni spectres équivalents.

</details>

### Exercice 5

Un doigt réel a une largeur et une pression finies ; une corde réelle possède amortissement et raideur. La règle prédit des modes permis, sans garantir une excitation propre. Une future tâche doit conserver position, description de pression, pincement et enregistrement brut, puis rechercher la famille prévue sans prendre un autre partiel pour le fondamental.

Qu’est-ce qui réfuterait ce modèle pour une prise donnée ?

<details><summary>Réponse 5</summary>

Une prise contrôlée à position connue dont le motif modal contredit la prédiction rejetterait ce modèle simple pour cette prise. Un contact absent ou une géométrie ambiguë laisse plutôt les prémisses non vérifiées.

</details>

## Tâche avec consultation des sources

Dessiner les deux contacts sur la corde entière et calculer les tables modales à la main. Inspecter l’état de voix conservé et identifier les informations de contact à représenter ailleurs. Proposer une consigne distinguant effleurement et appui, avec origine de coordonnée. Décrire un enregistrement réfutant la prédiction sans prétendre que l’harmonique a déjà été jouée.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
