---
title: Écouter et examiner le mouvement parallèle sur deux cordes de guitare
description: Écouter et examiner le mouvement parallèle sur deux cordes de guitare — Études de guitare
sidebar:
  label: GTR-004 · Écouter et examiner le mouvement parallèle sur deux cordes de guitare
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-004-hear-and-audit-parallel-motion.fr.md
---

:::note[Streeling University]
**GTR-004** · Écouter et examiner le mouvement parallèle sur deux cordes de guitare · intermédiaire · 35 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-004-hear-and-audit-parallel-motion.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-003](../../guitar-studies/gtr-003-audit-voicing-playability/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/voicing-learning-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'études de la guitare** | Niveau : intermédiaire | Stade : Albedo | Durée : 35 minutes | Brouillon français ; révision en attente

## Objectifs

Après cette leçon, vous saurez convertir un petit jeu de données sur deux cordes de guitare en hauteurs de notes, prévoir quand l'analyseur de progressions de GA signale des quintes parallèles, distinguer ce signalement d'un jugement sur le son ou le confort, et mener un essai de jeu reproductible. Vous identifierez aussi un cas que l'algorithme d'appariement des cordes n'évalue pas.

## La question du projet

[GAA-004](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/) explique comment examiner un voicing candidat ; [GTR-003](../../guitar-studies/gtr-003-audit-voicing-playability/) distingue la géométrie des frettes du confort du guitariste. Une progression ajoute une question : **qu'est-ce qui change entre deux voicings successifs ?** Le [`ProgressionVoiceLeadingAnalyzer`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingAnalyzer.cs) de GA, à la révision fixée, détecte un motif défini de quintes justes ou d'octaves parallèles entre des notes jouées appariées par corde. Son [`ProgressionVoiceLeadingReport`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingReport.cs) consigne les problèmes et expose des indicateurs. Ces liens, comme les autres sources GA de cette leçon, pointent vers le commit `dc2e74cbd992a298f67efb928b5b3754615e1924`.

Le code peut déterminer si ses propres conditions sont remplies. Il ne peut ni entendre l'articulation du guitariste, ni déduire une voix musicale indépendante qui passe d'une corde à l'autre, ni décider si le mouvement parallèle convient à un genre. Cette leçon utilise un **nouveau jeu de frettes synthétique** construit à partir de l'[accordage par défaut de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs), et non une réponse capturée du générateur. Il est physiquement possible de poser les doigts et de pincer les cordes indiquées, mais nous ne prétendons pas que quelqu'un l'a fait. Le rapport prévu est déduit du code source fixé, sans mesure issue d'un analyseur en cours d'exécution.

## 1. Définir les cordes et les notes

L'accordage par défaut de GA est `E2 A2 D3 G3 B3 E4`, présenté du grave à l'aigu dans `Tuning.Default` ; les numéros de corde de l'analyseur vont dans l'autre sens, de 1 pour le E aigu à 6 pour le E grave. Notre paire utilise la **corde 4**, D3 à vide, et la **corde 3**, G3 à vide. Dans le calcul des notes MIDI, D3 vaut 50 et G3 vaut 55. Chaque frette positive élève la note à vide d'un demi-ton. Nous ne ferons sonner que ces deux cordes et étoufferons les autres.

| Dyade | Corde 4 (corde D) | Corde 3 (corde G) | Rôle |
|---|---|---|---|
| A | frette 2 : E3, MIDI 52 | frette 4 : B3, MIDI 59 | paire de départ |
| B | frette 4 : F♯3, MIDI 54 | frette 6 : C♯4, MIDI 61 | les deux voix montent |
| C | frette 4 : F♯3, MIDI 54 | frette 2 : A3, MIDI 57 | les voix vont en sens opposés |

Ce sont des **dyades** ; nous n'affirmons pas que GA a généré une progression d'accords portant un nom. Dans tout relevé d'essai, notez les deux frettes et les deux hauteurs. Un simple nom comme « A vers B » ne permettra pas de reproduire l'exercice si le tableau en est séparé. Si votre guitare n'utilise pas l'accordage par défaut de GA, réaccordez-la avec précaution ou calculez un nouveau jeu de données en indiquant les hauteurs réelles des cordes à vide ; le corrigé ci-dessous suppose D3 et G3.

### Exercice 1 — Convertir les frettes en hauteurs

À partir de D3 = MIDI 50 et G3 = MIDI 55, calculez les deux notes de A et de B. Quelle corde produit la note la plus aiguë dans chaque dyade ?

> **Réponse :** A donne la corde 4 : `50 + 2 = 52` (E3), et la corde 3 : `55 + 4 = 59` (B3). B donne la corde 4 : `50 + 4 = 54` (F♯3), et la corde 3 : `55 + 6 = 61` (C♯4). La corde 3 est la plus aiguë dans les deux cas. Ces calculs supposent l'accordage standard et un demi-ton par frette ; ce ne sont pas des observations de jeu.

## 2. Calculer le test d'intervalle du code source

L'analyseur associe chaque **numéro de corde jouée** à la note MIDI fournie. Il prend l'intersection des clés de corde des deux associations. Si moins de deux cordes figurent dans les deux voicings, il ne renvoie aucun problème pour cette transition. Sinon, il vérifie chaque paire de cordes communes. Pour une paire donnée, il détermine d'abord si les deux notes MIDI se déplacent et dans le même sens. Il calcule ensuite `abs(noteB - noteA) % 12` avant et après. Une valeur de `7` dans les deux cas produit un problème `Fifths` ; une valeur de `0` dans les deux cas produit un problème `Octaves`. La classe `0` comprend les intervalles équivalents à l'octave : cette étiquette demande donc de la prudence lorsque les notes réelles sont à l'unisson.

Dans A, `59 - 52 = 7` demi-tons. Dans B, `61 - 54 = 7`. Il existe une paire commune, les cordes 3 et 4, et aucune note n'est étouffée. La condition d'intervalle du test des quintes est donc satisfaite. L'opération modulo du code montre qu'il vérifie une classe d'intervalle, sans mener une analyse harmonique ou stylistique complète. Pour l'exercice physique, les valeurs MIDI doivent correspondre aux frettes et à l'accordage réels ; l'analyseur, lui, utilise les valeurs MIDI fournies. Cette distinction compte, car un appelant pourrait fournir des positions et des notes incohérentes.

Les [tests unitaires](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.Core.Tests/Fretboard/Voicings/ProgressionVoiceLeadingAnalyzerTests.cs) à la révision fixée couvrent la détection des quintes et des octaves, les mouvements contraire et oblique, une progression de trois accords, ainsi que les entrées vides ou réduites à un élément. Leur fonction auxiliaire construit des positions jouées à la frette zéro avec des numéros MIDI choisis ; ce sont des données de test de l'algorithme, qui ne correspondent pas nécessairement à l'accordage de la guitare. Le tableau de frettes de cette leçon est un jeu pédagogique distinct et physiquement cohérent. Les tests constituent une preuve consignée dans le code source, sans nouvelle exécution pour ce cours.

### Exercice 2 — Vérifier les deux intervalles

Calculez la classe d'intervalle utilisée par le code pour A et B : `abs(string 3 MIDI - string 4 MIDI) % 12`. La seule condition d'intervalle suffirait-elle à signaler des quintes parallèles ?

> **Réponse :** Pour A, `abs(59 - 52) % 12 = 7` ; pour B, `abs(61 - 54) % 12 = 7`. La condition d'intervalle est satisfaite. L'analyseur doit aussi retrouver les deux mêmes cordes jouées dans les deux voicings et vérifier que les deux notes se sont déplacées dans le même sens, avec un déplacement non nul.

## 3. Comparer les mouvements, pas seulement deux instantanés

De A vers B, la corde 4 passe de `52 → 54`, soit une montée de deux demi-tons. La corde 3 passe de `59 → 61`, soit également une montée de deux demi-tons. Avec deux cordes communes, deux déplacements positifs et des intervalles `7 → 7`, l'algorithme à la révision fixée prévoit **un problème `Fifths`**. Dans le rapport, `HasParallelFifths` vaudrait vrai et `IsClean` faux pour une progression de deux voicings constituée d'objets `Voicing` cohérents avec ce tableau. Nous n'avons ni construit ni exécuté ces objets ici ; il s'agit d'une prédiction tirée du code source.

Comparez maintenant A à C. La corde 4 passe toujours de `52 → 54`, mais la corde 3 passe de `59 → 57`, soit une descente de deux demi-tons. Les directions diffèrent et l'intervalle d'arrivée vaut `abs(57 - 54) = 3`. Cette transition n'est donc pas une quinte parallèle selon le détecteur. Elle ne conserve **pas** la même harmonie d'arrivée que B. Ne jugez pas C meilleur sur le plan musical pour la seule raison qu'il évite cet indicateur. En musique, les intervalles justes parallèles peuvent être intentionnels, et une solution en mouvement contraire peut changer l'accord ou la mélodie. L'exercice porte sur la classification du rapport, pas sur une règle universelle de composition.

### Exercice 3 — Prévoir le rapport pour A→B

Indiquez les deux déplacements et l'indicateur de quintes du rapport pour une progression ordonnée `[A, B]` représentée par les deux cordes jouées et les notes MIDI du tableau. Combien de problèmes de quintes cette paire de deux cordes peut-elle produire ?

> **Réponse :** La corde 4 monte de `52 → 54` (+2) ; la corde 3 monte de `59 → 61` (+2). Les deux intervalles valent 7 demi-tons ; l'analyseur prévoit donc `HasParallelFifths = true` et `IsClean = false`. Il existe une seule paire de cordes communes, qui produit donc un problème `Fifths`.

### Exercice 4 — Prévoir l'autre transition avec prudence

Pour `[A, C]`, indiquez les directions, l'intervalle final et la valeur prévue de `IsClean`. C peut-il remplacer B sans changer la cible musicale ?

> **Réponse :** La corde 4 monte de 2 ; la corde 3 descend de 2. L'intervalle de C vaut `57 - 54 = 3` demi-tons. Le code ignore les paires dont les déplacements sont de sens opposés ; ce jeu de deux dyades prévoit donc `IsClean = true`. C diffère de B par sa note supérieure et son harmonie d'arrivée ; le résultat sans problème du détecteur n'en fait pas un remplacement musical interchangeable.

## 4. Jouer une transition dont la réussite peut être réfutée

Si vous avez une guitare en accordage standard, faites sonner A uniquement sur les cordes 4 et 3. Pincez chaque note séparément, puis ensemble. Passez à B et recommencez. Réglez un métronome lent à **60 battements par minute** : jouez A sur un temps, déplacez-vous, puis faites sonner B sur le suivant et laissez-le résonner pendant un temps. Faites dix tentatives A→B. Relevez les deux hauteurs d'arrivée, à l'aide d'un accordeur ou d'un enregistrement vérifié note par note, si chaque note a sonné nettement pendant le temps et si des cordes non prévues ont résonné. Définissez une tentative réussie ainsi : **les deux notes d'arrivée ont les hauteurs attendues et résonnent nettement pendant tout le temps d'arrivée**. Fixez à l'avance un seuil de pratique de 8 réussites sur 10 ; indiquez le numérateur observé, même s'il est inférieur à huit. Arrêtez si vous avez mal à la main. Ce seuil est un critère de cours, pas un score du modèle GA ni une norme validée pour une population.

L'essai peut échouer : un mauvais accordage, une note supérieure étouffée ou qui frise, une troisième corde involontaire ou moins de huit dyades d'arrivée réussies réfutent tous l'affirmation « j'ai atteint aujourd'hui l'objectif de pratique annoncé ». Sans outil de mesure de la hauteur, écrivez « hauteur non vérifiée indépendamment » et conservez séparément le nombre de notes nettes. Aucune tentative physique n'a été enregistrée pour ce brouillon. Un corrigé ne peut pas remplacer les observations de l'apprenant. Comparez à l'écoute A→B et A→C, sans affirmer que l'une doit mieux sonner que l'autre.

## 5. Comprendre ce qu'omet un rapport sans problème

La liste des problèmes de l'analyseur ne contient que les motifs détectables selon sa règle d'appariement des cordes. Imaginez A suivi d'une nouvelle dyade D jouée sur les cordes 4 et 2, avec la corde 3 étouffée. Seule la corde 4 est commune avec A. Le détecteur ne renvoie aucun problème avant même de comparer les intervalles, car il lui faut au moins deux cordes jouées communes. Dans ce cas, `IsClean` signifie `Issues.Count == 0`, sans garantir un bon contrepoint, une transition facile ou l'absence de sons indésirables. Un musicien pourrait entendre une voix se prolonger de la corde 3 à la corde 2, mais cet algorithme ne suit pas cette continuité entre cordes.

La même distinction vaut pour une entrée d'un seul accord. `Analyze` renvoie un rapport sans problème lorsque moins de deux voicings sont fournis : aucune transition n'est à examiner. Une liste vide devrait être présentée comme « aucun motif défini de quintes ou d'octaves parallèles détecté dans les appariements de cordes analysés », en indiquant la portée de l'entrée. Utilisez ce rapport comme un diagnostic limité, aux côtés du jugement musical, plutôt que comme une note complète de conduite des voix.

### Exercice 5 — Examiner la comparaison manquante

En partant de A sur les cordes 4 et 3, supposez que D ne joue que les cordes 4 et 2. Combien de clés de corde sont communes, que renvoie l'analyseur pour A→D et qu'est-ce que ce résultat ne permet pas d'établir ?

> **Réponse :** Seule la corde 4 est commune ; il existe donc une clé commune de corde jouée. Le détecteur ne renvoie aucun problème avant d'évaluer une paire d'intervalles, et le rapport obtenu indique `IsClean = true`. Cela n'établit ni l'absence de mouvement parallèle entre des voix passant d'une corde à l'autre, ni le confort de la transition, ni sa supériorité musicale.

## Preuves, limites et prochaine vérification

Les prédictions ci-dessus découlent de l'[analyseur](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingAnalyzer.cs), du [rapport](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/ProgressionVoiceLeadingReport.cs), de l'[accordage](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs) et du [code des tests](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.Core.Tests/Fretboard/Voicings/ProgressionVoiceLeadingAnalyzerTests.cs) de GA à la révision fixée. Les tableaux de frettes et les notes MIDI ont été construits pour ce cours ; ce ne sont pas des sorties capturées de GA. Nous ne revendiquons aucune exécution de l'analyseur, aucun enregistrement d'apprenant, aucune évaluation par un enseignant ni aucune nouvelle exécution des tests C#. Le code utilise les cordes de guitare comme identifiants de voix, emploie des classes d'intervalle modulo douze et ne mesure ni qualité du son, ni précision rythmique, ni effort de la main, ni pertinence musicale. Une prochaine vérification devrait exécuter ces objets `Voicing` exacts et cohérents sur la version fixée, conserver le rapport et recueillir le relevé des dix tentatives de jeu. La révision du contenu par un spécialiste, les essais auprès d'apprenants, la révision linguistique et la publication restent en attente.
