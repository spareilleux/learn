---
title: Choisir ce qu’une distance de conduite des voix ignore
description: Choisir ce qu’une distance de conduite des voix ignore — Musique
sidebar:
  label: MUS-015 · Choisir ce qu’une distance de conduite des voix ignore
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/music/fr/mus-015-choose-voice-leading-equivalences.fr.md
---

:::note[Streeling University]
**MUS-015** · Choisir ce qu’une distance de conduite des voix ignore · intermédiaire · 60 minutes

Généré par le département *Musique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/music/fr/mus-015-choose-voice-leading-equivalences.fr.md) · [Mon journal](../../journal/)

Prérequis: [MUS-014](../../music/mus-014-inversions-bass-line/)
:::

## Question du projet et livrable

Un guitariste demande à GA un voicing proche. Le terme « proche » préserve-t-il l’ordre des voix, le registre ou seulement la collection de classes de hauteurs ? Rédigez un contrat de comparaison avant d’interpréter le score. Cette leçon produit un tableau de calcul à quatre lignes et un compte rendu de laboratoire reproductible.

Le [code source de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Atonal/VoiceLeadingSpace.cs) étudié ici est figé à la révision `dc2e74cbd992a298f67efb928b5b3754615e1924`. Ses [options](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Atonal/VoiceLeadingOptions.cs) distinguent les équivalences d’octave, de permutation, de transposition et d’inversion. Nous garderons la transposition et l’inversion désactivées, sauf indication explicite dans un cas. Les hauteurs numériques sont espacées par demi-tons et suivent la convention C4 = 60 ; elles ne portent aucune identité de corde ou de doigt.

## 1. Déclarer les informations conservées

Lorsque l’équivalence d’octave est désactivée, le coût d’une paire appariée est la valeur absolue de sa différence en demi-tons. Lorsqu’elle est activée, réduisez cette différence modulo 12 et prenez la plus courte distance sur le cercle des classes de hauteurs. Ainsi, passer de 60 à 72 coûte 12 dans la première comparaison et 0 dans la seconde. C’est un choix d’équivalence mathématique : cela ne signifie pas que le musicien a maintenu la même note sonore.

L’équivalence de permutation détermine si les entrées cibles peuvent être réaffectées aux entrées sources. Lorsqu’elle est désactivée, les entrées sont appariées selon leur position. Lorsqu’elle est activée, l’implémentation figée trie les hauteurs avec leur registre ; si l’équivalence d’octave est également activée, elle essaie des décalages cycliques de ces tableaux triés. La section 4 montre pourquoi ce détail d’implémentation compte.

### Exercice pratique 1

Dans un exercice qui suit une voix mélodique identifiée de C4 à C5, l’équivalence d’octave doit-elle masquer le saut ?

> **Réponse :** Non. Conservez le registre et signalez un mouvement de 12 demi-tons. Une comparaison des classes de hauteurs peut indiquer 0 séparément, mais elle répond à une autre question. Aucun de ces scores ne dit si un doigté de guitare donné est confortable.

## 2. Calculer les quatre comparaisons

Utilisez la source `[60,64,67]` et la cible `[67,64,60]`. Les notes sources sont C4, E4 et G4. Lorsque les positions des entrées sont fixes, la première et la dernière voix se déplacent de 7 demi-tons dans des directions opposées. Avec l’équivalence d’octave, chaque paire coûte plutôt 5. Autoriser la réaffectation permet d’apparier chaque hauteur à elle-même.

| Équivalence d’octave | Équivalence de permutation | Scalaire natif |
|---|---|---:|
| Désactivée | Désactivée | 14 |
| Activée | Désactivée | 10 |
| Désactivée | Activée | 0 |
| Activée | Activée | 0 |

Ces valeurs ont été reproduites en compilant la classe figée sans modification dans le [laboratoire autonome](https://github.com/spareilleux/learn/tree/codex/streeling-craft-transfer-20261022/code/streeling/voice-leading). Un adaptateur d’annotations servant uniquement à la compilation y est documenté ; il ne s’agit ni de l’assembly GA d’origine ni de sa suite de tests complète.

### Exercice pratique 2

Un agent cite 0 pour ces tableaux et conclut que la première voix identifiée n’a pas bougé. Quelles informations manquent ?

> **Réponse :** Les paramètres d’équivalence et la correspondance entre les voix. Un zéro obtenu après réaffectation ne conserve pas la première entrée comme première voix. La comparaison absolue à positions fixes vaut 14 ; ses mouvements signés sont +7, 0 et −7 demi-tons.

## 3. Des classes de hauteurs communes ne signifient pas des notes tenues

Comparez `[60,64,67]` à `[72,76,79]`. Les collections ne partagent aucune hauteur dans le même registre, mais les trois classes de hauteurs concordent. Les comptages d’intersection pédagogiques du laboratoire donnent 0 hauteur commune avec le registre pris en compte et 3 classes de hauteurs communes. Ces comptages sont de simples calculs ensemblistes, et non des résultats du service de notes communes de GA. La distance absolue à positions fixes vaut 36 ; la distance avec équivalence d’octave à positions fixes vaut 0.

### Exercice pratique 3

Rédigez une annotation exacte pour ce déplacement d’octave, en incluant les deux distances et la distinction entre les types de notes communes.

> **Réponse :** « Distance tenant compte du registre : 36 ; distance avec équivalence d’octave : 0 ; 0 hauteur commune avec le registre pris en compte et 3 classes de hauteurs communes. » Ne décrivez pas les notes comme tenues ni la main comme immobile. La durée, l’articulation et le placement physique n’ont pas été mesurés.

## 4. Reproduire une limite de l’implémentation figée

Pour `[60,63,65]` et `[60,65,75]`, activez les équivalences d’octave et de permutation et désactivez la transposition et l’inversion. Les deux collections ont le même multiensemble de classes de hauteurs. L’implémentation figée renvoie 4. Les coûts de ses candidats cycliques sont 4, 10 et 6. L’énumération exhaustive de toutes les permutations de la cible trouve l’affectation `[60,75,65]`, dont la somme des coûts circulaires vaut 0. Trier les hauteurs avec leur registre avant de restreindre la recherche d’affectations peut faire manquer cet appariement.

Utilisez [Node.js](https://nodejs.org/api/cli.html) et le [SDK .NET 10.0.113](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) déjà installés. Depuis la copie de travail de Learn, choisissez un nouveau répertoire de sortie voisin ; son parent doit déjà exister. Cette commande s’écrit de la même façon sous Windows, Linux / WSL et macOS, mais seul Windows a été évalué :

```sh
node code/streeling/voice-leading/run.mjs ../streeling-voiceleading-new-run
```

Le contrôleur vérifie les empreintes des sources, compile hors de la copie de travail et écrit `results.json` et `commands.json`. Les sources de paquets sont vidées et les [téléchargements en arrière-plan des manifestes de charges de travail sont désactivés](https://learn.microsoft.com/dotnet/core/tools/dotnet-environment-variables). L’exécution enregistrée a réussi 40 vérifications de caractérisation. Cela signifie qu’elle a reproduit les observations déclarées, y compris le désaccord ; `original_expected_equivalence_satisfied` reste faux. Examinez les [résultats conservés](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/native-results.json), pas seulement le code de sortie du processus.

### Exercice pratique 4

Calculez les coûts circulaires de l’affectation `[60,75,65]`. La réussite du laboratoire doit-elle certifier l’implémentation d’équivalence d’origine ?

> **Réponse :** Les différences appariées valent 0, 12 et 0, ce qui donne des coûts circulaires de 0, 0 et 0. Non : la caractérisation réussit en reproduisant le résultat natif de 4 contre le résultat exhaustif de 0. Ce laboratoire n’a pas corrigé la méthode de production.

## 5. Soumettre un contrat de comparaison

Conservez dans votre compte rendu la révision source figée, les tableaux, les quatre choix d’équivalence, le tableau de calcul, le scalaire observé et son interprétation. Joignez les résultats exécutables lorsqu’ils sont disponibles. Si vous ne pouvez pas exécuter le SDK, faites les calculs à la main et indiquez que l’exécution n’a pas été évaluée. La [tâche de l’apprenant et la grille de revue](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/learner-task.md) distinguent la vérification à l’aide des sources d’un essai d’apprentissage avec une personne.

### Exercice pratique 5

Quelles preuves supplémentaires permettraient de qualifier un voicing recommandé de physiquement facile à jouer ?

> **Réponse :** Une affectation réelle aux cordes et aux cases, les contraintes du musicien et un essai instrumental avec un critère déclaré. Les calculs scalaires, l’inspection du code source et l’exécution autonome ne fournissent aucune de ces observations. Poursuivez avec la [correspondance entre les voix](../../music/mus-016-recover-voice-correspondence/) avant de traiter un minimum comme un plan d’exécution instrumentale.
