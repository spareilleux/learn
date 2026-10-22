---
module_id: mus-024-preserve-attacks-and-harmonic-boundaries
department: music
course: Préserver les attaques et les frontières harmoniques
level: intermediate
alchemical_stage: albedo
prerequisites: [mus-003-functional-harmony, mus-004-rhythm-and-groove]
estimated_duration: "60 minutes"
produced_by: codex-project-analysis
version: "1.0.0"
---

# Préserver les attaques et les frontières harmoniques

## Question du projet et livrable

Un planificateur d'accords reçoit une séquence d'ensembles de hauteurs. Quelles notes viennent d'être attaquées, lesquelles continuent de sonner et où l'harmonie a-t-elle changé ? Reconstituez un registre des événements et montrez ce qu'une transmission limitée aux hauteurs ne permet pas de retrouver. Il s'agit d'appliquer le vocabulaire des durées de MUS-004 à une frontière concrète entre représentations dans GA.

Le [solveur de tablatures de GA dans la version de référence](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L52) accepte une séquence d'ensembles de hauteurs. Les arguments de cette méthode ne contiennent aucun champ de début, de durée ou de liaison de prolongation. D'autres modèles de GA portent ces informations : [ProgressionStep](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Harmony/Progressions/ProgressionStep.cs) possède `DurationMs`, et, pour [MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/), son [modèle de note](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L93) importé comprend des champs de durée, de voix et de liaison de prolongation. Cette leçon examine ces types ; elle n'exécute pas d'intégration et n'établit pas que tous les parcours de GA perdent les informations temporelles.

## 1. Distinguer les événements de note des étiquettes d'accord

Le [jeu de données construit](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/timed-events.json) utilise une position temporelle absolue en temps de noire et C4 = 60. Un événement est actif de son début inclus à sa fin exclue. Son identifiant préserve la continuité d'une même note dans les instantanés suivants.

| Événement | Hauteur | Début | Fin |
|---|---:|---:|---:|
| G à la basse | 43 | 0 | 2 |
| B commun | 59 | 0 | 4 |
| D intérieur | 62 | 0 | 2 |
| F intérieur | 65 | 0 | 2 |
| E anticipé | 76 | 1.5 | 4 |
| C à la basse | 48 | 2 | 4 |
| E intérieur | 64 | 2 | 4 |
| G intérieur | 67 | 2 | 4 |

Les annotations harmoniques sont définies séparément : G7 de 0 à 2, Cmaj7 de 2 à 4. Qualifier E5 à 1.5 d'anticipation de la tierce de la tonique est une interprétation de l'auteur. Les mêmes notes à un instant donné pourraient suggérer une autre lecture harmonique ; le tableau seul ne prouve pas cette étiquette.

### Exercice pratique 1

Dressez la liste des hauteurs qui sonnent sur les trois intervalles commençant à 0, 1.5 et 2. Chaque nouveau début de note exige-t-il une nouvelle étiquette d'accord définie par l'auteur ?

> **Réponse :** Les ensembles sont `[43,59,62,65]`, `[43,59,62,65,76]` et `[48,59,64,67,76]`, contenant 4, 5 et 5 notes. Non. Le début de note à 1.5 modifie l'ensemble des notes qui sonnent, tandis que l'intervalle de G7 défini par l'auteur se poursuit jusqu'à 2. La segmentation harmonique est une interprétation supplémentaire.

## 2. Examiner le changement à la frontière

Au temps 2, les hauteurs 43, 62 et 65 cessent de sonner. Les hauteurs 48, 64 et 67 commencent. Les événements B3 de hauteur 59 et E5 de hauteur 76 continuent de sonner ; ils ne constituent pas de nouvelles attaques à cette frontière. Ainsi, l'ensemble limité aux attaques contient un accord parfait de C majeur, tandis que l'ensemble complet des notes qui sonnent contient le B de Cmaj7 ainsi qu'un E doublé.

Les intervalles semi-ouverts rendent la frontière explicite : les anciens événements finissant à 2 sont absents à 2, et les nouveaux événements commençant à 2 sont présents. Tous les événements sont absents à 4. Il s'agit de la convention mathématique du jeu de données, pas d'une mesure du comportement de relâchement d'un moteur de rendu.

### Exercice pratique 2

Au temps 2, écrivez trois listes distinctes : les hauteurs relâchées, les nouvelles attaques et les hauteurs tenues. Pourquoi un analyseur d'accords limité aux attaques manquerait-il une note de l'accord qui continue de sonner ?

> **Réponse :** Relâchées : 43, 62, 65. Attaques : 48, 64, 67. Tenues : 59, 76. B3 = 59 est la septième majeure tenue de Cmaj7 selon l'annotation de l'auteur. Un ensemble limité aux attaques l'omet alors qu'elle reste active. Ni cette omission ni un nom d'accord qui en serait déduit n'ont été observés lors d'une exécution réelle de GA.

## 3. Ne pas transformer chaque instantané en nouvelle attaque

Le jeu de données contient 8 événements de note. Une conversion volontairement erronée qui réattaquerait chaque hauteur dans chaque instantané des notes qui sonnent créerait 4 + 5 + 5 = 14 attaques. Le B commun serait attaqué 3 fois au lieu de l'unique attaque définie par l'auteur. Il s'agit d'un contre-exemple calculé à cette règle de conversion, pas d'une sortie enregistrée de GA ou d'un moteur de lecture.

Un instantané répond à « qu'est-ce qui sonne maintenant ? ». Un registre des attaques répond à « qu'est-ce qui a commencé maintenant ? ». Une annotation harmonique répond à « quel accord l'auteur entend-il sur cet intervalle ? ». Gardez ces questions distinctes, même lorsque leurs frontières coïncident dans une partition simple.

### Exercice pratique 3

Combien d'attaques supplémentaires la conversion hypothétique des instantanés en attaques ajoute-t-elle ? La seule appartenance d'une hauteur à ces ensembles permet-elle d'identifier l'événement B tenu d'origine ?

> **Réponse :** Elle ajoute 14 − 8 = 6 attaques. Non. La répétition de la hauteur 59 dans des instantanés adjacents peut représenter un événement tenu ou des réattaques distinctes. Préservez l'identité et les bornes des événements pour les distinguer ; les ensembles de hauteurs seuls ne suffisent pas.

## 4. Déclarer l'unité de temps avant de convertir

À 120 noires par minute, un temps de noire dure 500 millisecondes. Le début à 1.5 se situe à 750 millisecondes ; la frontière harmonique à 2 se situe à 1000 millisecondes ; la phrase se termine à 2000 millisecondes. Chacune des deux étapes harmoniques définies par l'auteur dure 1000 millisecondes à ce tempo.

Le champ `DurationMs` de GA est explicitement une durée en millisecondes, avec une valeur par défaut de 1000. Cette valeur par défaut ne détermine pas un tempo. Dans [MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/), les durées sont exprimées en unités de division. Ce ne sont pas des millisecondes par défaut. La conversion des temps de noire en unités de division exige de connaître le [nombre de divisions par noire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/divisions/) ; convertir les durées en millisecondes exige en plus le tempo. Des valeurs numériques identiques peuvent être correctes lorsque les échelles déclarées concordent. Vérifiez cette concordance au lieu de la supposer.

### Exercice pratique 4

Convertissez le début 1.5 et la durée 2 en millisecondes au tempo déclaré. Recopier directement le nombre 2 dans `DurationMs` préserverait-il la durée harmonique voulue ?

> **Réponse :** Ils deviennent 750 et 1000 millisecondes. Non : une valeur de 2 dans `DurationMs` signifie 2 millisecondes, pas 2 temps de noire. Le jeu de données déclare son unité de temps et son tempo ; aucun importateur ni exportateur n'a été exécuté.

## 5. Préserver la continuité lors des changements de représentation

L'[élément tie](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/tie/) de MusicXML décrit une liaison de prolongation sonore ; son élément distinct tied décrit la notation. Scinder une durée notée ne doit pas nécessairement créer une nouvelle attaque. Un modèle qui ne conserve que les hauteurs ne peut pas, à lui seul, préserver cette distinction. Gardez une correspondance avec les événements d'origine lorsque vous transmettez à un planificateur des instantanés de hauteurs sélectionnés.

Remettez les identifiants des événements, les unités de début et de fin, les listes de notes tenues et d'attaques, ainsi que l'annotation harmonique séparée. Le [dossier d'exercices préparé](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/learner-task.md) vérifie le raisonnement sans prétendre qu'une écoute ou qu'un aller-retour d'importation et d'exportation a eu lieu.

### Exercice pratique 5

Un agent conserve les trois instantanés de hauteurs et promet une articulation exacte à l'exportation. Quelles preuves et quelles données manquent ?

> **Réponse :** Les identités des événements d'origine, les bornes d'attaque et de relâchement, le contexte d'unité et de tempo ainsi que les informations de liaison et d'articulation manquent dans cette transmission limitée aux hauteurs. Une exportation exacte exigerait également une conversion effectivement testée. Les types du code source et ce registre d'événements construit n'établissent pas l'existence d'une telle implémentation.
