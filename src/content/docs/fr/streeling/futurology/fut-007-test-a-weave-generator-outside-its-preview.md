---
title: Tester un générateur de tissage au-delà de son aperçu
description: Tester un générateur de tissage au-delà de son aperçu — Futurologie
sidebar:
  label: FUT-007 · Tester un générateur de tissage au-delà de son aperçu
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/fr/fut-007-test-a-weave-generator-outside-its-preview.fr.md
---

:::note[Streeling University]
**FUT-007** · Tester un générateur de tissage au-delà de son aperçu · intermédiaire · 45 minutes

Généré par le département *Futurologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/fr/fut-007-test-a-weave-generator-outside-its-preview.fr.md) · [Mon journal](../../journal/)

Prérequis: [FUT-003](../../futurology/fut-003-agent-substitution-readiness-drill/), [VC-007](../../visual-computing/vc-007-weave-seams-as-scene-contracts/), [SEM-008](../../semiotics/sem-008-interpret-layer-order-relative-to-the-reference-normal/)
:::

> **Portée du brouillon.** Grilles finies pédagogiques, décomptes exacts et lecture d'un évaluateur et d'une scène à une révision précise. Aucun agent n'a été entraîné ou évalué, et aucun nouvel essai Godot, IX ou de fabrication n'a eu lieu. Les revues humaines technique, artisanale, linguistique et par de véritables apprenants restent à effectuer. Les sources publiques et le HTML du cours déployé ont des critères de vérification distincts.

## La question du projet

Un aperçu parfait justifie-t-il de remplacer une règle de création par un agent ? [FUT-003](../../futurology/fut-003-agent-substitution-readiness-drill/) demande quelles preuves exige une substitution ; [VC-007](../../visual-computing/vc-007-weave-seams-as-scene-contracts/) vérifie les croisements et les raccords. Ce cours construit deux règles qui concordent sur tout un aperçu et divergent ailleurs. Il montre ensuite exactement ce qu'une hypothèse structurelle supplémentaire peut prouver.

L'[évaluateur de Demerzel à la révision fixée](https://github.com/GuitarAlchemist/Demerzel/blob/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) accepte deux variantes nommées de parité. Son [jeu d'essai](https://github.com/GuitarAlchemist/Demerzel/blob/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json) définit un essai fini particulier. La règle adversariale ci-dessous a été conçue pour ce cours ; elle n'est ni une variante prise en charge par l'évaluateur ni un modèle appris observé.

## 1. Expliciter le domaine non observé

Utilisez des coordonnées entières positives ou nulles sur une grille cible de 8 par 8. L'aperçu contient la région de 6 par 6 à son origine, dont les 36 booléens de croisement sont tous connus exactement. Cela fournit des preuves plus fortes qu'une image seule.

Définissez `G(x,y)=((x+y)%2==0)`. Définissez `H` comme égale à `G` dans l'aperçu et renvoyant vrai ailleurs dans cette cible finie. Les deux règles concordent sur chaque croisement de l'aperçu. À la coordonnée `(6,1)`, cependant, `G` est faux et `H` est vrai.

### Exercice 1 : produire un témoin hors de l'aperçu

Évaluez les deux règles à `(6,1)`. Pourquoi vérifier tous les booléens de l'aperçu manquerait-il encore cet échec ? Cela démontre-t-il l'échec d'un véritable agent entraîné ?

> **Réponse:** La somme vaut 7, donc `G` est faux ; la coordonnée est hors de l'aperçu, donc `H` est vrai. Les 36 étiquettes d'aperçu concordent par construction. C'est un contre-exemple pédagogique à une déduction fondée sur l'accord dans l'aperçu, et non un échec observé d'agent entraîné.

## 2. Compter l'ambiguïté sans inventer de probabilités

La cible possède 64 cases, dont 28 hors de l'aperçu. Sans règle contraignant ces booléens, il existe `2^28=268435456` façons compatibles de compléter la grille. Ce décompte d'affectations finies ne donne ni la probabilité que l'une soit correcte ni un taux d'erreur attendu pour un agent.

### Exercice 2 : identifier l'hypothèse derrière le décompte

Déduisez le nombre de cases non observées et de façons compatibles de compléter la grille. Ce décompte resterait-il approprié si chaque paire de voisins devait avoir des valeurs différentes ?

> **Réponse:** Il existe `64-36=28` cases non observées et `2^28=268435456` façons de compléter la grille sans contrainte. Exiger des valeurs différentes pour chaque paire de voisins couple les cases ; ce ne sont donc plus des choix binaires indépendants. Cette restriction structurelle définit une autre classe d'hypothèses.

## 3. Examiner la cible finie complète

Une grille de 8 par 8 possède 112 paires de voisins horizontaux ou verticaux. Le [relevé pédagogique de grille](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-material-2026-10-22/generator-scope.json) donne 14 désaccords de croisements entre les règles, tous hors de l'aperçu. `G` n'a aucune violation pour voisins égaux ; `H` en a 46. Le nombre de désaccords de croisements et celui de violations d'adjacence mesurent des choses différentes.

Pour ce dernier décompte, la bande non observée de deux colonnes apporte 14 paires verticales égales et 8 horizontales. La bande inférieure restante, large de 6 colonnes et haute de 2 lignes, apporte 10 paires horizontales et 6 verticales. Entre ces deux bandes se trouvent 2 paires égales supplémentaires ; leurs interfaces avec l'aperçu en ajoutent 6, pour un total de 46. Ces bandes partitionnent la région non observée sans double comptage. C'est un calcul fini pédagogique, et non une sortie de l'évaluateur ou de la scène existants.

### Exercice 3 : choisir le bon décompte d'échecs

Un agent annonce « 14 violations » après avoir comparé les étiquettes de croisements. Corrigez ce rapport, déduisez le nombre total de paires adjacentes et justifiez les 46 paires de voisins égaux par la partition en bandes. Que doivent préciser les preuves concernant l'exécution des outils ?

> **Réponse:** Il existe 14 désaccords d'étiquettes avec la règle cible, mais 46 violations pour voisins égaux dans `H`. La grille possède `8*7+8*7=112` paires de voisins. La partition en bandes donne `14+8+10+6+2+6=46` paires égales, interfaces comprises. Le rapport doit nommer la métrique et préciser qu'il s'agit de vérifications finies pédagogiques ; ni l'évaluateur Demerzel ni Godot n'ont été exécutés sur `H`.

## 4. Ajouter une règle et ne prouver que ses conséquences

Imposez maintenant une prémisse distincte : chaque paire de voisins doit avoir des valeurs différentes. Le graphe de la grille est connexe et biparti. Choisir la valeur à l'origine détermine toutes les autres par la parité des chemins, donnant exactement 2 affectations complètes. La phase observée à l'origine en sélectionne 1. Un parcours de graphe peut construire ces affectations ; il n'est pas nécessaire d'énumérer toutes les grilles cibles binaires.

C'est une preuve conditionnelle pour la classe choisie d'alternance binaire. Elle ne montre ni qu'un générateur entraîné a découvert la règle, ni que tout textile doit alterner, ni que tout motif obtenu peut être fabriqué. [SEM-008](../../semiotics/sem-008-interpret-layer-order-relative-to-the-reference-normal/) explique pourquoi le sens d'une étiquette d'ordre exige aussi sa référence et ses rôles.

### Exercice 4 : distinguer une preuve des preuves d'apprentissage

Pourquoi existe-t-il 2 façons structurelles de compléter la grille avant d'observer l'origine et 1 après ? Énoncez les hypothèses et une affirmation de capacité que la preuve n'établit pas.

> **Réponse:** La connexité propage une valeur choisie à l'origine à travers toutes les contraintes d'adjacence ; le caractère biparti rend la propagation cohérente. Chaque valeur d'origine donne une façon de compléter la grille, et la phase observée fixe laquelle. Cela suppose la grille connexe déclarée, des étiquettes binaires et la règle complète d'alternance des voisins. Cela n'établit aucun apprentissage réel, faisabilité physique de tissage ou capacité de création sans restriction.

## 5. Concevoir un essai de substitution réfutable

L'évaluateur existant rapporte des décomptes de violations ; un nombre non nul n'est pas en soi une exception qui rejette une variante. Ses noms pris en charge et ses vérifications de dimensions sont distincts. Le [contrôleur de Learn à la révision fixée](https://github.com/spareilleux/learn/blob/eebf49cb0b69a314bd13015340335a983aa64bfe/code/streeling/weave-godot/trial.gd) admet un manifeste particulier de 36 croisements. Notre tableau pédagogique plus grand ne devient pas pour autant une entrée acceptée de la scène.

### Exercice 5 : préparer une future expérience avec accès aux sources

Lisez l'évaluateur, le jeu d'essai et le contrôleur. Proposez une comparaison délimitée pour un agent ou un DSL composable de création, avec une référence simple, une condition de rejet et une limite honnête des affirmations.

> **Réponse:** Fixez le programme, la révision, le domaine d'entrée, le sens des étiquettes et les règles d'admission. Figez avant la comparaison des tailles non observées, des raccords et des transformations de rôles et de repères. Comparez à la règle simple de parité globale accompagnée d'un validateur indépendant ; conservez séparément les contre-exemples et les métriques de désaccord et d'adjacence, ainsi que le coût et l'évaluation humaine artisanale. Rejetez un avantage annoncé s'il disparaît hors de l'aperçu ou échoue aux critères d'acceptation déclarés. Une scène plus grande exige aussi un adaptateur ou un changement d'admission et son propre test. Les calculs actuels prouvent seulement les exemples finis et le résultat structurel conditionnel ; aucun agent entraîné, nouveau DSL, intégration à l'exécution, bénéfice pour l'apprenant ou réussite de fabrication n'ont été démontrés.
