---
title: Préserver l'origine d'un cycle additif
description: Préserver l'origine d'un cycle additif — Musiques et langues du monde
sidebar:
  label: WML-006 · Préserver l'origine d'un cycle additif
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-006-preserve-the-origin-of-an-additive-cycle.fr.md
---

:::note[Streeling University]
**WML-006** · Préserver l'origine d'un cycle additif · intermédiaire · 40 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-006-preserve-the-origin-of-an-additive-cycle.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-003](../../world-music-languages/wml-003-term-preservation-and-cultural-review/), [MCL-006](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/)
:::

> **Portée du brouillon.** Groupes de pulsations conçus pour le cours, énumération finie exacte et lecture de spécifications et de code primaires. Les revues humaines technique, culturelle, musicale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun enregistrement, tradition jouée, groupe de traduction ou outil audio n'ont fait l'objet d'un essai.

## La question du projet

Un exercice localisé de GA préserve les nombres d'un rythme additif mais change le groupe qui commence la mesure. A-t-il préservé le motif demandé ? Un motif circulaire et une consigne d'exercice ancrée répondent à des questions différentes. Ce cours donne à la personne chargée de la revue un témoin numérique du changement sans prétendre qu'un de ces motifs inventés appartient à une culture musicale particulière.

[MCL-006](../../musicology/mcl-006-preserve-meter-grouping-and-tempo-units/) distingue le groupement de la durée totale et des unités de métronome. La [référence MusicXML de time](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/time/) autorise un texte de numérateur additif. Elle n'autorise pas un traducteur à changer le point de départ d'un exercice pédagogique ou à attribuer son exécution à une tradition.

## 1. Garder l'origine de la mesure attachée au motif

Définissez sept positions de pulsation de croche régulièrement espacées, numérotées de 0 à 6, et répétez le cycle. Dans le motif pédagogique A, les longueurs des groupes sont 2, 2, 3 ; les débuts de groupes sont 0, 2, 4. Le motif B utilise les longueurs 3, 2, 2 et les débuts 0, 3, 5. Le motif C utilise les longueurs 2, 3, 2 et les débuts 0, 2, 5.

Les trois totalisent sept pulsations. À l'origine fixe de la mesure, ils demandent des débuts différents. Ces débuts sont des repères mathématiques de groupement, et non des observations de sonie, d'accentuation, de syllabes ou du placement temporel d'un musicien. Un traducteur peut les préserver en adaptant le texte de comptage, mais a besoin d'une consigne explicite avant d'en changer l'origine.

### Exercice 1 : repérer un changement dans la traduction

Un exercice source demande A et sa traduction demande B, tous deux à partir de la même barre de mesure. Donnez les ensembles de débuts et précisez ce qui a été préservé et modifié.

> **Réponse:** A commence à 0, 2, 4 ; B à 0, 3, 5. Le cycle total de sept pulsations a été préservé. Les groupes ordonnés et leurs débuts ancrés ont changé. L'égalité de durée totale ne suffit pas pour déclarer la consigne traduite identique.

## 2. Changer explicitement l'origine d'un motif circulaire

Conservez les événements circulaires de A, mais déclarez son ancienne pulsation 4 comme nouvelle origine. Soustrayez 4 de chaque ancien début et réduisez modulo 7. Les nouveaux débuts sont 0, 3, 5, avec des écarts circulaires successifs de 3, 2, 2 : c'est B. Prendre plutôt l'ancienne pulsation 2 comme origine donne C.

Ce calcul explique une équivalence particulière : les motifs possèdent la même suite circulaire d'écarts à un choix cyclique du début de groupe près. Cela ne les rend pas interchangeables face à une barre de mesure, un accompagnement, des paroles ou une autre piste inchangés. Préservez à la fois l'équivalence choisie et la transformation d'origine lorsque vous comparez les relevés.

### Exercice 2 : retrouver la transformation d'origine

Quel ancien début de groupe de A devient l'origine de B ? Calculez le nouvel ensemble de débuts, puis expliquez pourquoi appliquer silencieusement cette transformation à une seule piste peut changer un arrangement.

> **Réponse:** L'ancienne pulsation 4 devient l'origine. Soustraire 4 modulo 7 à 0, 2, 4 donne 3, 5, 0, soit les débuts triés 0, 3, 5. Changer l'origine d'une seule piste modifie son alignement avec les pistes et les repères de mesure dont l'origine n'a pas changé. Une comparaison circulaire n'efface pas cette phase relative.

## 3. Distinguer les rotations de pulsations des choix de début de groupe

Il existe sept décalages entiers possibles de A en pulsations. Les sept donnent des ensembles de débuts distincts. Seuls trois de ces ensembles incluent la pulsation 0 comme début de groupe, correspondant aux trois choix de limite de groupe d'origine. Décaler A vers l'avant de 1 donne les débuts 1, 3, 5 : le cycle se répète toujours toutes les sept pulsations, mais sa nouvelle pulsation 0 n'est pas un début de groupe.

Le [relevé d'énumération](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/meter-picking-2026-10-22/anchored-cycles.json) conserve les décalages et les changements d'origine aux débuts de groupes, étiquetés séparément. Assimiler « trois permutations cycliques de la liste des groupes » à « l'ensemble des sept phases de pulsation » confondrait deux ensembles de comparaisons différents.

### Exercice 3 : compter les bonnes transformations

Combien de décalages distincts de pulsations A possède-t-il ? Combien placent un début de groupe à la pulsation 0 ? Donnez les débuts après un décalage vers l'avant de 1.

> **Réponse:** Il existe sept décalages distincts, et trois incluent un début de groupe à 0. Le décalage de 1 donne les débuts 1, 3, 5. Une nouvelle origine n'a pas à coïncider avec un événement de groupement, sauf si cette condition est exigée séparément.

## 4. Énoncer ce qu'un code circulaire classe

Choisissez trois positions de début distinctes parmi les sept positions de pulsation étiquetées. L'énumération exacte donne 35 ensembles ancrés. Les comparer seulement à une rotation entière près les répartit en cinq classes contenant chacune sept ensembles. C'est un résultat combinatoire fini pour cette population pédagogique. Ce n'est ni une distribution de rythmes dans des enregistrements ni une taxonomie de cinq traditions.

La restriction à trois débuts compte. Comme témoins négatifs, un ensemble vide et un ensemble contenant les sept pulsations n'ont chacun qu'une seule rotation distincte. « Tout motif possède sept phases distinctes » devient donc faux quand la population change. Des étiquettes, des multiplicités d'événements, un espacement inégal ou des données d'exécution musicale plus riches définiraient aussi un autre problème de classification.

### Exercice 4 : borner la classification

Donnez le nombre d'ensembles ancrés à trois débuts et de classes de rotation dans cette population à sept pulsations. Pourquoi le témoin du motif vide réfute-t-il une affirmation universelle de sept phases, et pourquoi les cinq classes n'établissent-elles aucune classification culturelle ?

> **Réponse:** Il existe 35 ensembles ancrés et cinq classes de sept. Le motif vide reste inchangé à chaque décalage et n'a qu'une rotation distincte. Ces classes proviennent de positions abstraites sélectionnées et d'une équivalence choisie, et non de preuves concernant des communautés, des répertoires, des musiciens ou des pratiques d'exécution.

## 5. Préserver séparément notation et attribution

La [représentation métrique de GA à la révision fixée](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L115-L138) conserve un numérateur et un dénominateur entiers ; elle ne conserve pas dans ces champs la liste ordonnée de groupes ou la transformation d'origine de ce cours. Le [parseur sélectionné](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L123-L138) présente aussi la limite du texte additif examinée dans MCL-006. Cela ne prouve pas que tous les sous-systèmes de GA sont dépourvus de données plus riches.

### Exercice 5 : rédiger un compte rendu de localisation

Que devrait conserver un relevé de revue lorsqu'un traducteur change intentionnellement A en B ? Un code circulaire identique peut-il autoriser une affirmation culturelle nommée ou d'équivalence musicale ?

> **Réponse:** Conservez les groupes ordonnés d'origine et traduits, l'unité de pulsation, le repère de mesure commun, la transformation de l'ancienne origine vers la nouvelle, les pistes affectées, le motif du changement et la décision de revue. L'exemple de A vers B prend l'ancienne pulsation 4 comme origine. L'égalité circulaire seule n'autorise aucune affirmation culturelle, perceptive ou d'équivalence d'arrangement. De telles affirmations exigent des preuves adaptées concernant le répertoire, les musiciens et la langue ; aucune n'a été recueillie ici.

Le [travail préparé pour l'apprenant](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/meter-picking-2026-10-22/learner-task.md) demande une comparaison explicite d'origines. Son existence n'est pas un résultat observé d'apprenant ou de revue culturelle.
