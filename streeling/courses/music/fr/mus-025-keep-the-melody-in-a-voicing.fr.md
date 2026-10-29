---
module_id: mus-025-keep-the-melody-in-a-voicing
department: music
course: Garder la mélodie imposée dans un voicing
level: intermediate
alchemical_stage: albedo
prerequisites: [mus-012-chord-formulas-essential-tones-doubling, mus-016-recover-voice-correspondence, mus-024-preserve-attacks-and-harmonic-boundaries]
estimated_duration: "60 minutes"
produced_by: codex-project-analysis
version: "1.0.0"
---

# Garder la mélodie imposée dans un voicing

## Question du projet et livrable

Une suggestion d'accompagnement contient les bonnes notes de l'accord, mais la mélodie s'y perd. Pour cet exercice d'arrangement, la mélodie imposée doit être la **hauteur sonore la plus aiguë, dans le registre demandé**. Filtrez les candidats selon cette exigence explicite avant de comparer une pénalité secondaire de position. Il s'agit d'un contrat d'arrangement choisi, pas d'une règle universelle voulant que toute mélodie soit la voix la plus aiguë.

Le [point d'entrée du solveur de tablatures de GA dans la version de référence](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L52) reçoit des ensembles de hauteurs et génère des positions, sans argument explicite de rôle mélodique dans la signature de cette méthode. N'en déduisez pas une garantie sur la voix la plus aiguë. Cette observation du code source a une portée plus restreinte qu'une affirmation sur toutes les fonctionnalités de GA. La requête de voicings en direct a [échoué](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/ga-voicings-probe.json) ; chaque candidat ci-dessous est donc volontairement construit et n'est pas attribué à cet outil.

## 1. Décoder les candidats avant de les classer

Utilisez l'[accordage standard de la version de référence](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs), exprimé ici du E grave au e aigu par `[40,45,50,55,59,64]`, avec C4 = 60. L'[indexation interne de l'accordage dans GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs#L82) commence par la corde la plus aiguë ; ce jeu de données utilise explicitement l'ordre du grave à l'aigu. Un numéro de case ajoute autant de demi-tons ; −1 signifie corde étouffée et 0 signifie corde à vide dans ce jeu de données. Les [données conservées](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/melody-constraints.json) détaillent chaque corde et chaque hauteur.

| Candidat | Cases, du E grave au e aigu | Hauteur sonore la plus aiguë |
|---|---|---:|
| A | −1, 3, 2, 0, 0, 0 | 64 |
| B | −1, 3, 5, 4, 5, 3 | 67 |
| C | −1, 3, 2, 0, 0, −1 | 59 |
| D | −1, 3, 5, 4, 8, 0 | 67 |

Tous les quatre contiennent les classes de hauteur C, E, G, B : Cmaj7 avec des registres et des doublures différents. Le seul contenu de l'accord ne détermine pas quelle hauteur se trouve au sommet.

### Exercice pratique 1

Décodez les hauteurs sonores de A et B dans l'ordre des cordes. Lequel place E4 au sommet ?

> **Réponse :** A donne `[48,52,55,59,64]` ; B donne `[48,55,59,64,67]`. Seul A a E4 = 64 au sommet. B contient E4, mais aussi G4 = 67, plus aigu. Ce sont des vérifications arithmétiques de placements construits, pas des essais de jeu enregistrés ni des voicings générés.

## 2. Distinguer trois questions sur la mélodie

Chaque candidat contient la classe de hauteur 4, E. Les candidats A, B et D contiennent la hauteur 64 dans son registre précis. Seul A a 64 comme hauteur sonore la plus aiguë. Ces tests répondent à des questions différentes : l'appartenance aux notes de l'accord, la présence dans le registre demandé et le contrat précis portant sur la voix supérieure.

Dans [MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/), le [modèle de note](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L93) peut conserver une étiquette de voix. Cette étiquette identifie une voix notée ; elle ne doit pas être remplacée implicitement par un tri des hauteurs. Si la tâche musicale attribue plutôt la mélodie à une voix intérieure, le prédicat de hauteur maximale de cette leçon n'est pas le bon contrat.

### Exercice pratique 2

Quels candidats satisfont chaque test : contient E à une octave quelconque ; contient E4 ; place E4 au sommet ?

> **Réponse :** E à une octave quelconque : A, B, C et D. E4 présent : A, B et D. E4 au sommet : A seulement. Le candidat C contient E3 = 52 plutôt que E4, et sa hauteur la plus aiguë est B3 = 59. Ne remplacez pas un test par un autre.

## 3. Une corde plus aiguë ne porte pas nécessairement la hauteur la plus aiguë

Dans D, la corde de B à la case 8 produit 59 + 8 = 67, tandis que la corde de e aigu à vide produit 64. La dernière corde non étouffée du tableau ne contient donc pas la hauteur la plus aiguë. Pour ce contrat, calculez le maximum des hauteurs qui sonnent au lieu de prendre la dernière entrée du tableau.

Cela est possible parce que l'ordre des cordes et celui des hauteurs sonores sont différents. L'exemple n'affirme ni que le doigté est confortable, ni qu'un croisement de cordes a été joué, ni qu'une mélodie particulière a une continuité physique sur une phrase. MUS-016 distingue l'identité des voix des cordes ; MUS-024 distingue les notes tenues des attaques.

### Exercice pratique 3

Pour D, identifiez la hauteur la plus aiguë et sa corde, puis la hauteur de la dernière corde qui sonne. Conserver la dernière entrée sonore imposerait-il la condition E4 au sommet ?

> **Réponse :** La hauteur la plus aiguë est G4 = 67 sur la corde de B, case 8. La dernière entrée sonore est le e aigu à vide = 64. Non : accepter D sur la base de cette entrée ignorerait le G4 plus aigu. Une position dans l'ordre des cordes ne garantit pas l'ordre des hauteurs.

## 4. Appliquer l'exigence musicale avant la préférence souple

Pour définir une préférence secondaire volontairement grossière, prenez comme position d'un candidat son plus petit numéro de case strictement positif. Avec une position précédente de 3, définissez la pénalité comme la différence absolue entre les positions. Les positions de A, B, C et D sont 2, 3, 2 et 3 ; les pénalités sont 1, 0, 1 et 0.

Cette pénalité construite n'est ni le score de difficulté de GA, ni son terme d'inertie, ni son objectif physique complet. Elle ignore de nombreux aspects du jeu. Le minimum sans contrainte inclut B et D, qui enfreignent tous deux l'exigence E4 au sommet. Filtrer d'abord ne laisse que A, dont la pénalité secondaire est de 1. Une pénalité souple plus faible ne doit pas prendre implicitement le pas sur une exigence musicale impérative.

### Exercice pratique 4

Appliquez la condition mélodique impérative, puis la pénalité secondaire de position. Quel candidat subsiste, et quelle affirmation sur le jeu reste sans justification ?

> **Réponse :** Seul A subsiste et sa pénalité vaut 1. Ni le calcul de la plus petite case strictement positive ni le test mélodique n'établissent le choix des doigts, le confort des écarts ou la facilité d'exécution. Ces points exigent un essai concret à l'instrument et un critère explicite pour le musicien.

## 5. Préserver le registre lorsque l'ensemble de candidats est vide

Remplacez la mélodie supérieure imposée par E5 = 76. Aucun candidat conservé ne l'atteint. Un test limité aux classes de hauteur accepterait encore le E4 au sommet de A, mais celui-ci est une octave sous la note demandée. Signalez que l'ensemble des solutions admissibles est vide ; obtenir d'autres candidats ou modifier l'exigence d'arrangement relève d'une décision distincte.

Remettez la hauteur et le rôle de la mélodie, l'accordage, les candidats décodés, les résultats exacts du filtrage, l'objectif secondaire et les questions de jeu restantes. Le [dossier d'exercices](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/learner-task.md) vérifie ces affirmations sans fournir de résultat de participant ni prétendre qu'une extension de GA tenant compte du rôle mélodique a été livrée.

### Exercice pratique 5

Un agent répond à la demande de E5 par A parce que sa hauteur la plus aiguë possède la même classe de hauteur. Que devrait indiquer la transmission à la place ?

> **Réponse :** « Aucun des quatre candidats construits n'a 76 comme hauteur sonore la plus aiguë. A a 64, une octave plus bas, et ne satisfait pas l'exigence énoncée. » Gardez la contrainte exacte de registre, sauf si une nouvelle décision d'arrangement la modifie. Aucun voicing renvoyé en direct ni résultat d'essai à l'instrument ne justifie de l'assouplir ici.
