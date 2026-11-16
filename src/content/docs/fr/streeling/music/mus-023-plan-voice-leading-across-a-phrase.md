---
title: Planifier la conduite des voix sur une phrase entière
description: Planifier la conduite des voix sur une phrase entière — Musique
sidebar:
  label: MUS-023 · Planifier la conduite des voix sur une phrase entière
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/music/fr/mus-023-plan-voice-leading-across-a-phrase.fr.md
---

:::note[Streeling University]
**MUS-023** · Planifier la conduite des voix sur une phrase entière · intermédiaire · 60 minutes

Généré par le département *Musique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/music/fr/mus-023-plan-voice-leading-across-a-phrase.fr.md) · [Mon journal](../../journal/)

Prérequis: [MUS-005](../../music/mus-005-jazz-harmony/), [MUS-016](../../music/mus-016-recover-voice-correspondence/)
:::

## Question du projet et livrable

Un guitariste souhaite atteindre un registre précis à la fin d'une phrase. Choisir à chaque étape le voicing le plus proche peut reporter un grand saut sur le dernier accord. Comparez les chemins complets et expliquez dans quels cas un choix localement plus coûteux améliore l'ensemble de la phrase.

La version de référence d'[AdvancedTabSolver](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L52) de GA construit des positions candidates à chaque étape et utilise une table de programmation dynamique pour conserver des chemins. Cette leçon calcule un exemple construit beaucoup plus petit. Elle n'exécute pas ce solveur, ne reproduit pas son objectif physique et stylistique et n'affirme pas que GA a généré ces candidats. Le [jeu de données conservé](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/phrase-paths.json) rend explicites toutes les entrées et tous les résultats.

## 1. Fixer la tâche musicale et les étiquettes des voix

Utilisez C4 = 60 et deux voix étiquetées dont le registre est précisé. Faites correspondre les entrées par étiquette et additionnez leurs déplacements absolus en demi-tons. Ne ramenez pas les notes à une même octave et ne réattribuez pas les voix. Il s'agit de voicings réduits aux notes guides, et non d'accords complets ni de propositions de doigtés :

| Étape | Contexte d'accord | Hauteurs avec registre | Noms des notes |
|---|---|---|---|
| Départ | Cmaj7 | 52, 59 | E3, B3 |
| Suivant | Dm7 | 53, 60 | F3, C4 |
| Choix grave | G7 | 53, 59 | F3, B3 |
| Choix aigu | G7 | 59, 65 | B3, F4 |
| Arrivée imposée | Cmaj7 | 64, 71 | E4, B4 |

La tierce et la septième définissent le rôle de chaque voicing réduit dans le contexte d'accord donné ; ces seules notes ne suffisent pas nécessairement à déterminer le nom de l'accord. MUS-005 enseigne les notes guides. Ici, l'exigence supplémentaire porte sur le registre d'arrivée et la comparaison des chemins complets.

### Exercice pratique 1

Calculez le déplacement du départ à Dm7, puis de Dm7 à chacun des choix de G7. Gardez les étiquettes des voix fixes.

> **Réponse :** Le déplacement du départ à Dm7 coûte 1 + 1 = 2. De Dm7 à G7-grave, il coûte 0 + 1 = 1. De Dm7 à G7-aigu, il coûte 6 + 5 = 11. À ce stade, le choix grave a le préfixe le moins coûteux : 3 plutôt que 13.

## 2. Inclure l'arrivée imposée

De G7-grave à l'arrivée, le coût est de 11 + 12 = 23. De G7-aigu à la même arrivée, il est de 5 + 6 = 11. Ce jeu de données n'autorise que deux chemins complets :

| Choix de G7 | Coûts des trois transitions | Coût de la phrase entière |
|---|---|---:|
| Grave | 2, 1, 23 | 26 |
| Aigu | 2, 11, 11 | 24 |

La règle du choix suivant le plus proche sélectionne le grave, puis supporte le plus grand saut final. L'énumération des chemins complets sélectionne l'aigu, au coût de 24. Ce chemin est optimal parmi ces deux chemins construits, selon l'objectif déclaré. Cela ne constitue pas une affirmation sur toutes les harmonisations possibles, la préférence musicale ou le confort de jeu.

### Exercice pratique 2

Écrivez les deux lignes étiquetées du chemin dont le coût total est le plus faible. Un total plus petit garantit-il que chaque saut est plus petit ?

> **Réponse :** Les lignes sont E3 → F3 → B3 → E4 et B3 → C4 → F4 → B4. Leurs déplacements absolus totalisent 12 et 12, soit 24. Non : le mouvement de Dm7 à G7 est plus grand que dans le chemin grave. Nous avons optimisé la somme sur la phrase, pas chaque transition séparément.

## 3. Conserver le meilleur préfixe pour chaque état

Dans cet exemple fini à coûts additifs, les coûts des transitions futures dépendent de l'état courant. Conservez le préfixe connu le moins coûteux aboutissant à chaque état. Le préfixe de Dm7 vaut 2 ; ceux de G7-grave et G7-aigu valent 3 et 13. À l'arrivée imposée, comparez 3 + 23 à 13 + 11.

Conserver un meilleur préfixe **par état** préserve les deux états de G7. Ne conserver que l'unique état globalement le moins coûteux élimine l'état aigu et fait perdre la meilleure arrivée. La [table de GA dans la version de référence](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L113) conserve jusqu'à `k` chemins pour chaque candidat courant avant de sélectionner les chemins finaux. Fixer `k` à 1 n'est donc pas la même opération que ne conserver qu'un seul candidat courant au total.

### Exercice pratique 3

Quels préfixes de G7 survivent à une limite de 1 par état ? Que perd-on dans cet exemple avec une limite d'un seul état au total ?

> **Réponse :** Les deux survivent : le grave à 3 et l'aigu à 13, soit un préfixe pour chaque état. Une limite d'un seul état au total conserve le grave et produit 26 au lieu du 24 disponible. Cet exemple n'établit pas qu'une politique d'élagage particulière échoue lors d'une exécution de GA.

## 4. Changer la destination et recalculer

Si l'arrivée est plutôt le voicing réduit grave de Cmaj7 `[52,59]`, les dernières transitions coûtent 1 depuis G7-grave et 13 depuis G7-aigu. Les totaux complets deviennent 4 et 26. Les mêmes candidats favorisent désormais le chemin grave. Un planificateur de phrase a besoin de la destination et des états autorisés pour que le mot « meilleur » ait un sens précis.

L'étape réelle de génération des candidats de GA [conserve au plus 40 positions par étape après évaluation](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L94). Une recherche de chemins dans un ensemble de candidats conservés n'établit pas un minimum parmi tous les doigtés possibles. De même, notre calcul exhaustif de deux chemins reste limité à l'ensemble de candidats déclaré.

### Exercice pratique 4

Calculez les deux totaux avec la nouvelle arrivée grave. Quelle hypothèse a changé et quelle règle de coût est restée identique ?

> **Réponse :** Le grave donne 2 + 1 + 1 = 4 ; l'aigu donne 2 + 11 + 13 = 26. La destination imposée a changé. La règle du déplacement absolu par voix étiquetée, avec registre préservé, est restée identique. La recommandation précédente du chemin aigu ne doit pas être réutilisée sans vérifier cette nouvelle arrivée.

## 5. Rapporter l'objectif effectivement mesuré

La somme interne du solveur dans la version de référence comprend des termes de transition, de coût physique statique, de style, d'inertie de position et de ML. Sa [méthode distincte de mise en forme des solutions](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L23) rapporte `TotalPhysicalCost` en additionnant les sorties de la méthode de transition le long du chemin choisi. Ce rapport ne recalcule pas tous les termes de la somme interne utilisée pour la recherche. Il s'agit d'une inspection du code source, pas d'une exécution numérique observée du solveur.

Remettez les tableaux, les étiquettes des voix, l'arrivée, la règle de coût des transitions, les deux chemins complets et le périmètre de comparaison. Utilisez le [dossier d'exercices](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/learner-task.md) pour consigner une réponse avant d'ouvrir sa grille d'évaluation séparée. Ces calculs ne fournissent aucun résultat obtenu auprès d'un participant ou lors d'un essai à l'instrument.

### Exercice pratique 5

Un agent présente 24 comme « le coût physique total mesuré par GA ». Reformulez cette affirmation pour qu'elle corresponde aux éléments disponibles.

> **Réponse :** « Dans le jeu de données construit à deux chemins, 24 est la somme minimale des déplacements absolus avec registre préservé pour l'arrivée aiguë imposée. » Ni le solveur de GA ni son rapport de coût formaté n'ont été exécutés ici ; aucun confort physique ni coût de doigté réel n'a été mesuré.
