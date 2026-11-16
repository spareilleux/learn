---
module_id: gaa-005-repair-a-phrase-without-hiding-the-change
department: guitar-alchemist-academy
course: "Réparer une phrase sans dissimuler la modification"
level: early-intermediate
prerequisites: ["gaa-004-choose-a-useful-voicing"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Réparer une phrase sans dissimuler la modification

> **Périmètre du brouillon.** Réponses réelles des outils d'accordage, nouvelle exécution autonome de fonctions de recherche de hauteurs et variantes de phrase créées pour l'exemple. Les revues techniques humaines, musicales, linguistiques et pédagogiques, ainsi que la vérification du HTML déployé du cours, restent à faire. Aucun solveur temporel de GA, aucune phrase jouée ni préférence d'auditeur n'a été observé.

## La question du projet

Vous demandez à un agent de réaliser une phrase. Il trouve un conflit, change le début d'une note et annonce une réussite. La nouvelle phrase est peut-être utile, mais votre demande a changé. Cette leçon compare des alternatives en conservant les différences musicales entre lesquelles le guitariste doit choisir.

Les [requêtes réelles sur l'accordage](../../../../code/streeling/evidence/phrase-performance-2026-10-22/ga-tuning-probes.json) ont renvoyé Standard et Drop D comme noms disponibles, et les notes Standard `E2,A2,D3,G3,B3,E4`. Ces observations n'attestent ni une révision du code source déployé ni un solveur temporel. Les [fonctions MIDI de GA à la révision fixée](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs) fournissent les positions candidates exécutées séparément. [GTR-005](../../guitar-studies/en/gtr-005-plan-which-string-keeps-ringing.md) explique leur conversion en numéros de corde conventionnels, avec la corde 1 aiguë et la corde 6 grave.

## 1. Conserver une copie de la phrase demandée

Utilisez l'accordage Standard et la case maximale 5. Exigez une tenue indépendante sur une seule corde par événement actif, chaque événement tenu conservant sa corde. La demande créée pour l'exemple est C4 du temps 0 à 4, E4 de 0 à 2, G4 de 1 à 2 et D4 de 1.5 à 3. C4 désigne MIDI 60 ; les autres hauteurs sont 64, 67 et 62.

Entre 1.5 et 2, les quatre événements n'ont ensemble que trois cordes admissibles. Ce modèle ne possède aucune affectation valide. « Aucune affectation avec ces contraintes » est une réponse utile : elle donne au musicien un choix explicite sur ce qui peut changer. Ce n'est pas un jugement sur ses capacités.

### Exercice 1 : préserver la question d'origine

Énumérez le début et la fin d'origine de D4, la limite de case et l'intervalle de conflit. Pourquoi ces valeurs doivent-elles rester dans la comparaison après la proposition de réparation de l'agent ?

> **Réponse:** D4 commence à 1.5 et se termine à 3 ; la limite vaut 5. Le conflit se produit de 1.5 inclus à 2 exclu. Conserver ces valeurs distingue une solution aux contraintes originales d'une phrase ou d'une étendue modifiée. Sinon, une alternative qui fonctionne peut dissimuler l'exigence qui a été assouplie.

## 2. Comparer deux modifications temporelles différentes

Premièrement, retardez le début de D au temps 2 tout en conservant sa fin à 3. Une affectation existe alors avec une limite de 5. Cette attaque plus tardive raccourcit aussi la durée de D de 1.5 temps à 1 temps ; elle ne décale pas simplement la note entière.

Deuxièmement, conservez le début original de D, mais terminez E au temps 1.5 plutôt qu'à 2. Une affectation existe parce que E libère sa corde avant que D commence. Cela raccourcit E au lieu de changer l'attaque de D. Les intervalles semi-ouverts autorisent la réutilisation modélisée exactement à cette limite ; le comportement réel de relâchement et la propreté du jeu n'ont pas été mesurés.

### Exercice 2 : quantifier les modifications musicales

À une cadence constante déclarée de 120 noires par minute, de combien de millisecondes chaque limite se déplace-t-elle ? Quelle note change de durée dans chaque alternative ?

> **Réponse:** Un demi-temps de noire vaut 250 ms. La première alternative retarde le début de D de 250 ms et, avec sa fin fixe, raccourcit D d'autant. La seconde libère E 250 ms plus tôt et raccourcit E. Ce sont des modifications musicales différentes, même si toutes deux possèdent une affectation valide dans le modèle.

## 3. Préserver les instants des notes en changeant l'étendue autorisée

La troisième alternative conserve chaque hauteur, début et fin demandés, mais autorise les cases jusqu'à 10. L'énumération exhaustive donne trois plans. Leurs étendues entre cases strictement positives valent 3, 7 et 7. Le candidat d'étendue 3 utilise C4 sur la corde 4 case 10, E4 sur la corde 1 case 0, G4 sur la corde 2 case 8 et D4 sur la corde 3 case 7.

En ignorant la corde à vide, l'étendue vaut `10-7=3`. C'est un indicateur déclaré fondé sur les numéros de case. Ce n'est ni une mesure en millimètres, ni un modèle complet de la main, ni une note universelle de facilité. L'alternative préserve ces champs temporels et de hauteur, mais change la réalisation sur les cordes et potentiellement le timbre ; un musicien doit l'évaluer. [GTR-003](../../guitar-studies/en/gtr-003-audit-voicing-playability.md) explique pourquoi de tels indicateurs demandent une interprétation.

### Exercice 3 : choisir une affirmation limitée

Que préserve le candidat d'étendue 3 et quelle contrainte assouplit-il ? Pourquoi « l'étendue la plus faible parmi ces trois plans » est-il plus précis que « le meilleur pour le musicien » ?

> **Réponse:** Il préserve les quatre hauteurs demandées et toutes leurs valeurs de début et de fin, tout en portant la case maximale de 5 à 10. Son étendue est la plus faible des trois plans énumérés selon cet indicateur. Le confort, la technique, le son et les préférences du musicien sont des questions supplémentaires non mesurées : l'indicateur ne fait donc pas un choix universel.

## 4. Refuser les réparations qui résolvent discrètement une autre demande

Omettre D laisse un plan valide, mais supprime un événement demandé. Réaccorder la corde grave en Drop D tout en conservant la limite de 5 ne laisse aucun plan valide pour la demande originale de notes aiguës : les positions candidates pertinentes sont inchangées. Une option disponible dans un outil n'est pas automatiquement pertinente pour le conflit détecté.

| Alternative | Plans valides dans le modèle | Modification principale |
| --- | --- | --- |
| Retarder l'attaque de D, conserver sa fin | 1 | Début et durée de D |
| Relâcher E plus tôt | 1 | Fin et durée de E |
| Autoriser les cases jusqu'à 10 | 3 | Étendue autorisée et réalisation sur les cordes |
| Omettre D | 1 | Ensemble des événements demandés |
| Accordage Drop D, limite de 5 | 0 | Accordage de la corde grave ; le conflit demeure |

Ces nombres concernent un modèle d'affectation créé pour l'exemple. Ce ne sont ni des sorties du service, ni des scores d'auditeurs, ni la preuve qu'une modification est autorisée.

### Exercice 4 : diagnostiquer le raccourci proposé

Un agent choisit Drop D parce que l'outil le propose, puis supprime D4 lorsque le conflit persiste. Peut-il annoncer que la demande originale est résolue ? Expliquez les deux décisions.

> **Réponse:** Non. Le changement d'accordage n'ajoute aucune corde admissible pour ces hauteurs aiguës avec une limite de 5 et laisse le conflit intact. Supprimer D4 change l'ensemble des événements requis, même si la phrase restante de trois événements possède un plan valide. Présentez cette alternative et son omission explicitement au lieu de l'appeler une réalisation préservée.

## 5. Proposer des choix que le musicien peut réellement évaluer

Le [relevé fixe des alternatives](../../../../code/streeling/evidence/phrase-performance-2026-10-22/repair-options.json) sépare la faisabilité des champs préservés. Une réponse utile de l'agent peut conserver la demande originale, expliquer l'intervalle en conflit, présenter quelques alternatives explicites et préciser les observations de jeu manquantes. L'objection la plus forte à la réparation automatique est qu'un modèle géométrique restreint risque d'éliminer, au nom de l'optimisation, une articulation, un timbre ou une intention auxquels le musicien tient. L'alternative la plus simple consiste à conserver la demande non résolue et à demander quel changement est acceptable avant d'en appliquer un.

### Exercice 5 : rédiger la proposition de l'agent

Proposez deux alternatives à un guitariste qui n'a pas autorisé de modification temporelle. Incluez ce que chacune préserve, ce qu'elle change et une observation encore nécessaire avant d'affirmer une réussite jouée ou de publier le résultat.

> **Réponse:** Proposez le candidat d'étendue élargie en précisant qu'il préserve les hauteurs et les instants déclarés tout en changeant l'étendue et la réalisation sur les cordes ; son doigté et son son demandent la vérification d'un musicien. Ne proposez une attaque retardée de D ou un relâchement anticipé de E que comme modification musicale explicite, en indiquant la limite et la durée modifiées. Aucune ne doit être appliquée discrètement ni décrite comme une réussite jouée. Le choix accepté par le musicien et son essai réel ne sont pas consignés.
