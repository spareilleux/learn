---
title: Préserver le sens d'un angle de pliage
description: Préserver le sens d'un angle de pliage — Sémiotique
sidebar:
  label: SEM-007 · Préserver le sens d'un angle de pliage
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-007-preserve-the-meaning-of-a-bend-angle.fr.md
---

:::note[Streeling University]
**SEM-007** · Préserver le sens d'un angle de pliage · intermédiaire · 40 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-007-preserve-the-meaning-of-a-bend-angle.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/), [PHY-011](../../physics/phy-011-compute-bend-length-on-a-declared-neutral-layer/)
:::

> **Portée du brouillon.** Lecture des sources FOLD/IX à une révision précise et calculs pédagogiques d'angles et de couches de référence. Les revues humaines technique, artisanale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun adaptateur de format, vérificateur complet, outil de CAO, scène ou pliage physique n'ont été exécutés.

## La question du projet

Deux agents échangent un nombre appelé « angle de pliage ». L'un désigne l'écart signé par rapport à l'état plat ; l'autre, un angle intérieur non signé entre les ailes. Des nombres égaux peuvent donc prescrire des géométries différentes. Une description composable exige le sens de la grandeur avant tout calcul ou rapprochement de noms de champs.

La [spécification FOLD à la révision fixée](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) définit `edges_foldAngle` comme l'écart à l'état plat, en degrés de -180 à 180, positif pour les plis vallée et négatif pour les plis montagne. La [branche de validation IX sélectionnée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/fold.rs#L239-L261) vérifie la plage d'angles et les signes d'affectation. Ce sont les sémantiques du code source, et non une nouvelle conversion exécutée vers des consignes de formage du métal.

## 1. Traduire ce que désigne l'angle

Pour une section plane simple conçue pour le cours, définissez l'angle intérieur par `alpha=180-abs(delta)`, où `delta` est l'écart signé en degrés. C'est notre convention explicite pour comparer les exemples, et non une correspondance universelle pour tout champ de CAO ou assemblage.

Un angle intérieur de 120 degrés correspond donc à un écart d'amplitude 60 degrés. Avec le rayon neutre de 4.8 mm de [PHY-011](../../physics/phy-011-compute-bend-length-on-a-declared-neutral-layer/), l'arc correct est `4.8*pi/3=1.6*pi` mm. Interpréter 120 comme l'écart donnerait plutôt `3.2*pi` mm, soit deux fois plus. La symétrie d'un exemple à 90 degrés peut masquer cette erreur ; utilisez donc un témoin asymétrique.

### Exercice 1 : rejeter un nombre égal trompeur

Convertissez l'angle intérieur de 120 en amplitude d'écart selon la convention déclarée. Calculez l'arc neutre correct et le résultat d'une lecture erronée de 120 comme écart.

> **Réponse:** L'amplitude d'écart est de 60 degrés, soit `pi/3` radians. L'arc correct est `1.6*pi` mm ; la lecture erronée donne `3.2*pi` mm, soit un facteur de 2. La conversion exige la convention d'angle déclarée plutôt qu'un nom de champ commun.

## 2. Préserver le signe même lorsque la longueur utilise l'amplitude

Les écarts signés +60 et -60 ont la même amplitude et produisent la même longueur développée de pli de `1.6*pi` dans ce modèle. Ils n'ont pas le même sens d'affectation dans FOLD. Le code sélectionné attend une valeur positive pour V et négative pour M. Il exige aussi zéro sur les arêtes F, U et B.

Remplacer chaque angle par sa valeur absolue préserverait ces deux longueurs calculées tout en modifiant ou invalidant l'exemple montagne. Inversement, utiliser directement un angle signé négatif comme longueur développée produirait une longueur négative. Portez l'état signé et déduisez la longueur de son amplitude par une opération nommée séparément.

### Exercice 2 : distinguer l'état d'une longueur dérivée

Lesquels de V avec +60, M avec -60 et M avec +60 satisfont la condition de signe examinée ? Quelle information perd-on en ne conservant que la longueur d'arc positive ?

> **Réponse:** V avec +60 et M avec -60 satisfont la condition de signe sélectionnée ; M avec +60 y échoue. La longueur positive commune `1.6*pi` ne préserve pas le caractère vallée ou montagne du pli. La réussite d'une branche numérique n'est ni une acceptation géométrique complète ni un verdict de fabrication.

## 3. Convertir les unités avant de multiplier

La longueur d'arc exige l'amplitude angulaire en radians. Soixante degrés deviennent `pi/3` ; multiplier 4.8 mm par cette valeur donne `1.6*pi`, soit environ 5.026548246 mm. Multiplier plutôt 4.8 par le nombre brut de degrés 60 donne 288 mm, une valeur trop grande d'un facteur `180/pi`, soit environ 57.295779513.

Le type « nombre » seul ne permet pas de distinguer ces représentations. Une valeur nommée angle exige son unité et sa convention à l'interface, et un suffixe affiché ne la convertit pas à lui seul. C'est une discipline de transmission proposée, et non un contrat d'adaptateur implémenté.

### Exercice 3 : diagnostiquer une erreur d'unité

Un adaptateur utilise directement la valeur en degrés 60 dans une expression d'arc fondée sur les radians. Donnez la longueur incorrecte, la longueur correcte et le facteur d'erreur. Ajouter « degrés » à côté de la sortie corrigerait-il le nombre ?

> **Réponse:** La longueur incorrecte est de 288 mm ; la longueur correcte est `1.6*pi`, soit environ 5.026548246 mm. Le facteur est `180/pi`, soit environ 57.295779513. Une étiquette n'effectue pas la conversion requise et ne rend pas correcte une longueur erronée.

## 4. Ne pas fusionner des grandeurs sans rapport partageant un symbole

Dans la [référence des règles de tôlerie de Fusion](https://help.autodesk.com/cloudhelp/ENU/Fusion-Sheet-Metal/files/SM-RULES-REF.htm), le rapport de décalage neutre est sans dimension. Nous l'appelons `k` et posons 0.4. La courbure de Gauss, appelée ici `K_G`, est au contraire le produit de deux courbures principales et possède des unités d'inverse du carré d'une longueur. Un cylindre peut avoir `K_G=0` tandis que ce pli pédagogique d'épaisseur finie utilise `k=0.4`.

Ces grandeurs répondent aussi à des questions différentes. L'une situe une couche neutre de référence dans une règle de pliage choisie. L'autre décrit la géométrie locale d'une surface. Aucune ne peut être copiée dans le champ de l'autre simplement parce qu'un document appelle les deux « K ».

### Exercice 4 : interpréter le zéro

Un agent voit une courbure de Gauss nulle sur un cylindre et remplace le facteur de décalage neutre 0.4 par zéro. Pourquoi cette substitution est-elle invalide, et quelles unités distinguent les deux champs ?

> **Réponse:** Elle substitue une grandeur physique ou géométrique différente. Le facteur de décalage neutre est sans dimension ; la courbure de Gauss possède des unités telles que `mm^-2`. Une courbure nulle ne situe pas la couche neutre à la surface intérieure et n'invalide pas le facteur 0.4 posé séparément.

## 5. Distinguer les métadonnées préservées du sens utilisé

Les [types de repère et de modèle d'IX à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/fold.rs#L82-L108) conservent des tableaux d'angles facultatifs et d'autres champs arbitraires. Préserver une annotation supplémentaire de règle physique comme donnée ne démontre pas que le validateur sélectionné l'utilise pour calculer la longueur développée du pli. Son [ADR sur l'épaisseur](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md#L30-L34) exclut explicitement les refus liés au rayon de pliage et le mouvement.

Un petit relevé consultatif pourrait conserver la révision du code, l'identité de l'arête, l'écart signé en degrés et l'affectation, la convention d'angle intérieur, l'unité physique de longueur, le rayon intérieur, l'épaisseur, l'hypothèse de décalage neutre et les radians et la longueur dérivés. C'est une alternative pédagogique à un nombre ambigu, et non un schéma ratifié ou un nouveau DSL de fabrication. Des formats existants aux champs documentés peuvent suffire ; porter davantage d'annotations coûte aussi du travail de validation et de migration.

### Exercice 5 : borner une transmission réussie

Un agent affirme : « le champ a survécu au JSON, donc le modèle de pliage en aval a été vérifié ». Remplacez cette affirmation et nommez les preuves nécessaires pour dépasser la préservation des métadonnées.

> **Réponse:** Le champ a peut-être été préservé comme donnée. Pour vérifier son sens, identifiez l'implémentation consommatrice et sa correspondance entre champs, unités et conventions, testez des angles asymétriques et des signes par rapport à des cibles connues, et distinguez les hypothèses du modèle du comportement étalonné du matériau. Conservez l'identité du code et de l'arête. Ni le stockage de champs arbitraires ni cet exemple consultatif n'établissent un adaptateur physique implémenté ou une fabrication.

Le [relevé des angles](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/bend-development-2026-10-22/angle-meanings.json) distingue les vérifications numériques prédites par le code des conversions pédagogiques. [FUT-006](../../futurology/fut-006-test-a-no-stretch-craft-automation-claim/) utilise cette distinction pour évaluer une future affirmation d'automatisation.
