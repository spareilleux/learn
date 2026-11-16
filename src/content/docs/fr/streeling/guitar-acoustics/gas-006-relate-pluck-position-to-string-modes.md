---
title: Relier la position de pincement aux modes de la corde
description: Relier la position de pincement aux modes de la corde — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-006 · Relier la position de pincement aux modes de la corde
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-006-relate-pluck-position-to-string-modes.fr.md
---

:::note[Streeling University]
**GAS-006** · Relier la position de pincement aux modes de la corde · intermédiaire · 40 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-006-relate-pluck-position-to-string-modes.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-002](../../guitar-acoustics/gas-002-brightness-control-and-evaluation-gate/), [GAS-005](../../guitar-acoustics/gas-005-separate-a-partial-peak-from-a-period/), [PHY-004](../../physics/phy-004-velocity-pick-position-guitar-engine/)
:::

> **Portée du brouillon.** Inspection du code source public à une révision précise et calculs fixés sur une corde idéale. Les revues humaines technique, linguistique, musicale et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucune guitare, aucun moteur natif/WASM, navigateur ou flux de travail [ComfyUI](https://docs.comfy.org/) n'ont été utilisés pour ce cours.

## La question du projet

Déplacer un médiator peut modifier le spectre d'une guitare sans changer sa hauteur nominale. Une future commande de GA pourrait-elle exprimer directement ce déplacement ? Il faut d'abord distinguer une condition initiale physique de l'heuristique existante du moteur. Le [code Rust d'excitation examiné](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L294-L396) est fixé à la révision de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`. Ses octets publics sont consignés dans le [relevé du code source](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pluck-coordinates-2026-10-22/primary-readback.json).

[PHY-004](../../physics/phy-004-velocity-pick-position-guitar-engine/) établit déjà le couplage de la vélocité et la formule proportionnelle des modes idéaux. Ce cours approfondit ce travail avec des coefficients normalisés et des rapports signés à déplacement maximal h fixé, des vérifications indépendantes de 80 coefficients et une comparaison avec le code source actuel à la révision indiquée.

## 1. Déclarer une forme initiale idéale

Utilisez une corde souple et uniforme à extrémités fixes, avec un petit déplacement transversal linéaire, sans amortissement ni raideur. Déclarez le chevalet comme origine des coordonnées, la longueur vibrante comme L et la position normalisée comme `u=x/L`. Un pincement ponctuel atteint son sommet en `p`, strictement entre les extrémités, avec un déplacement fixé h et une vitesse initiale nulle. La forme initiale divisée par h croît selon `u/p` jusqu'à p, puis décroît selon `(1-u)/(1-p)` jusqu'à l'autre extrémité.

Ces hypothèses suivent le [modèle de corde pincée idéale](https://dsprelated.com/freebooks/pasp/Ideal_Plucked_String.html). Elles excluent un contact du médiator de largeur finie, une force entretenue et la réponse de la caisse d'un instrument observé. Un déplacement maximal n'est ni une consigne de vitesse ni un tampon de bruit arbitraire.

### Exercice 1 : identifier l'état

À `p=1/5`, quel est le déplacement normalisé au chevalet, au point de pincement et à l'extrémité opposée ? Quelle vitesse initiale suppose-t-on ? Dire « attaque brillante » suffit-il à spécifier entièrement le modèle ?

> **Réponse:** Les déplacements divisés par h sont 0, 1 et 0. La vitesse initiale est nulle partout. « Attaque brillante » ne fournit ni cette forme ni ses coordonnées et sa vitesse initiale ; cette expression ne spécifie donc pas la condition initiale.

## 2. Projeter cette forme sur les modes

Notons B_n notre coefficient de déplacement du mode n. La [démonstration du cours de Princeton](https://kirkmcd.princeton.edu/examples/Ph205/ph205l21.pdf#page=5), à la page 5 du PDF, donne les coefficients de la série de sinus du déplacement triangulaire ; sa notation les appelle A_n. Dans notre notation :

`B_n/h = 2*sin(n*pi*p)/(pi^2*n^2*p*(1-p))`

Ce résultat s'obtient en intégrant sur l'intervalle unité le produit de deux fois la forme normalisée par `sin(n*pi*u)`. Un mode est absent de ce déplacement initial idéal lorsque `n*p` est entier. Au milieu, à `p=1/2`, tous les modes pairs s'annulent. Le troisième coefficient divisé par le premier vaut `-1/9` ; sa valeur absolue est `1/9`. Le signe représente la phase du déplacement modal au relâchement, et non une sonie mesurée négative.

### Exercice 2 : situer les annulations

Quelles familles de modes s'annulent à `p=1/5` et à `p=1/10` ? Au milieu, supprimer les modes pairs supprime-t-il aussi le troisième mode ?

> **Réponse:** Les multiples de 5 s'annulent à `p=1/5` ; les multiples de 10 s'annulent à `p=1/10`. Le milieu supprime les modes pairs, tandis que le troisième subsiste avec un rapport signé de `-1/9` à la fondamentale. Ce sont des coefficients idéaux de déplacement, et non des amplitudes mesurées au microphone.

## 3. Comparer un rapport sans changer de modèle

Avec le même sommet h, le rapport signé du deuxième coefficient au premier vaut `cos(pi*p)/2`. Le [tableau modal fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pluck-coordinates-2026-10-22/ideal-pluck-modes.json) donne environ 0.40450849718747367 à `p=1/5` et 0.4755282581475768 à `p=1/10`. Les deux sont positifs. Ce rapport choisi augmente vers le chevalet dans ces deux cas conçus pour le cours ; il ne prouve pas un classement universel de la brillance perçue.

Maintenir le déplacement h ne maintient pas la force de pincement ou l'énergie initiale constantes. Le rayonnement lié à la force au chevalet, l'emplacement du micro, le transfert de la caisse, l'amortissement et les conditions d'écoute ajouteraient d'autres transformations. Une annulation exacte dans ce modèle est une prédiction sous ses hypothèses, et non la promesse d'une harmonique inaudible sur une guitare enregistrée.

### Exercice 3 : énoncer la comparaison

Comparez les deux rapports du deuxième coefficient au premier. Quelle position donne la plus grande valeur dans ce calcul ? Peut-on qualifier le résultat de préférence mesurée ou de comparaison à énergie constante ?

> **Réponse:** Le rapport à `p=1/10` vaut environ 0.4755282581475768, soit plus qu'environ 0.40450849718747367 à `p=1/5`. Il s'agit d'un calcul idéal de déplacement modal avec un sommet h fixé. Aucune préférence d'auditeur, aucun spectre rayonné ni aucune énergie initiale égale n'ont été mesurés ou imposés.

## 4. Lire l'excitation différente du moteur

L'[heuristique de médiator et sa fenêtre](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs#L354-L379) choisissent un rapport de tampon de retard dépendant de la vélocité, l'arrondissent en un décalage entier et multiplient un bruit lissé récursivement par une fenêtre triangulaire tronquée. L'expression du rapport est `0.18+0.60*(1-velocity)` avant son bornage. Le commentaire mentionne les cordes aiguës, mais l'expression contient la vélocité, sans identité de corde ni entrée de frette. La longueur du tampon affecte aussi le décalage quantifié.

Pour une longueur de tampon pédagogique de 100 et une vélocité de 0.5, la transcription en arithmétique réelle donne un rapport de 0.48, un décalage de 48 et une position quantifiée de 0.48. À l'indice de tampon 88, la fenêtre triangulaire est nulle, tandis que le triangle idéal à extrémités fixes avec `p=0.48` y possède un déplacement normalisé d'environ 0.23076923076923075. Plus fondamentalement, le moteur multiplie sa fenêtre par du bruit. Ni la fenêtre ni le tampon obtenu ne sont le déplacement triangulaire physique ci-dessus, et cette expression du rapport ne documente aucune orientation relative au chevalet.

### Exercice 4 : rejeter une fausse substitution

Pour cet exemple de longueur 100, un agent peut-il substituer la fenêtre triangulaire du moteur dans la formule des coefficients du triangle idéal et annoncer une annulation exacte du cinquième mode ? Donnez les différences pertinentes entre le code et le modèle.

> **Réponse:** Non. Le code utilise une fenêtre triangulaire compacte qui multiplie un bruit lissé récursivement, avec une coordonnée quantifiée du tampon de retard. Le calcul idéal exige le déplacement triangulaire déclaré sur toute la longueur, des extrémités fixes et une vitesse initiale nulle. Ces conditions et une origine physique au chevalet n'ont pas été établies pour ce tampon du moteur.

## 5. Concevoir une commande sans revendiquer son résultat

Une expérience proposée sur la position de pincement exige ses propres coordonnées, unités et politique aux extrémités, séparément de la vélocité. Modifier la vélocité pour déplacer l'heuristique existante modifie aussi l'amplitude d'excitation et le niveau d'attaque ; ce n'est donc pas une comparaison isolée de positions. [GTR-006](../../guitar-studies/gtr-006-keep-picking-distance-relative-to-frets/) établit comment le sens d'une distance au chevalet change lorsque la corde est frettée.

Le triangle idéal possède un angle vif et une infinité de modes. Une implémentation échantillonnée finie exige une limite de bande déclarée ; la source citée sur la corde idéale explique cette exigence. Le lissage récursif du code ne garantit pas une coupure antirepliement stricte. Toute implémentation aurait besoin de ses propres tests d'excitation finie, d'accordage et de spectre, suivis d'une écoute à niveau contrôlé. Ce cours fournit une cible analytique et un contre-exemple à une interprétation incorrecte du code source.

### Exercice 5 : proposer l'expérience suivante

Un agent modifie uniquement la vélocité et présente le résultat comme un test isolé de la position physique du médiator. Identifiez les facteurs confondants et rédigez une meilleure comparaison proposée. Cette comparaison a-t-elle été exécutée ici ?

> **Réponse:** La vélocité modifie ensemble l'amplitude, le rapport heuristique du tampon et le niveau d'attaque. Proposez une commande séparée de position relative au chevalet, explicitement définie, maintenez la vélocité et les autres réglages de synthèse fixes, précisez la limitation de bande, puis effectuez le rendu et comparez les positions demandées avec des contrôles d'accordage et de niveau. Cette commande et cette comparaison restent non implémentées et non exécutées ici ; aucun résultat de qualité sonore ne découle de ces calculs.
