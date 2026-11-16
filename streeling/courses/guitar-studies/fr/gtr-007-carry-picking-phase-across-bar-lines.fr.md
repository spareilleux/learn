---
module_id: gtr-007-carry-picking-phase-across-bar-lines
department: guitar-studies
course: "Conserver la phase d'aller-retour au-delà des barres de mesure"
level: intermediate
prerequisites: ["gtr-005-plan-which-string-keeps-ringing", "mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver la phase d'aller-retour au-delà des barres de mesure

> **Portée du brouillon.** Modèles d'attaques et d'horloge de mouvement conçus pour le cours, traces exactes et inspection du code de notation à une révision précise. Les revues humaines technique, musicale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun guitariste, importateur de partitions, moteur de rendu audio ou technique physique n'ont fait l'objet d'un essai.

## La question du projet

Un agent de guitare écrit une mesure d'aller-retour au médiator et la répète. Recommencer les directions à chaque mesure préserve-t-il l'alternance ? Que se passe-t-il en présence d'un silence ou d'une prolongation liée ? Une consigne de pratique utile précise les événements qui font avancer son état de direction au lieu de traiter silencieusement la barre de mesure comme une remise à zéro.

Nous utilisons une corde, sept pulsations de croche régulièrement espacées par mesure et une règle pédagogique : les attaques consécutives alternent D et U, en commençant par D à la pulsation absolue 0. D et U désignent les directions vers le bas et vers le haut. Elles ne prescrivent ni sonie, accent, vitesse, changement de corde, effort ou technique préférée. Le [symbole down-bow de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/down-bow/) représente aussi un coup vers le bas sur les instruments à cordes pincées ; le [symbole up-bow](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/up-bow/) inclut de même le coup vers le haut. Un symbole de notation est distinct d'un mouvement de main mesuré.

## 1. Conserver l'état à travers une mesure impaire

Placez d'abord une attaque à chaque pulsation. Les directions aux pulsations absolues de 0 à 6 sont D, U, D, U, D, U, D. L'attaque à la pulsation 7 doit être U selon la règle déclarée. Les débuts de mesure aux pulsations 0, 7, 14 et 21 ont donc les directions D, U, D et U.

Repartir plutôt de D à chaque mesure crée D suivi de D aux frontières entre les pulsations 6 et 7, 13 et 14, puis 20 et 21. Cela peut être une consigne intentionnellement différente, mais ce n'est pas une alternance stricte entre ces attaques. Le décalage symbolique n'implique aucun jugement sur la stratégie de médiator préférée d'un musicien.

### Exercice 1 : vérifier la mesure répétée

Donnez la direction à la pulsation 7 avec une alternance continue des attaques et avec une remise à D à chaque mesure. Identifiez la première frontière où la direction se répète et le premier début de mesure qui rétablit l'état initial de mesure et de direction.

> **Réponse:** L'alternance continue donne U à la pulsation 7 ; la remise à zéro donne D. La première frontière de remise à zéro est la pulsation 6 D suivie de la pulsation 7 D. La phase de mesure et la direction de médiator initiales reviennent ensemble à la pulsation 14, après deux mesures.

## 2. Inclure chaque horloge pertinente dans une affirmation de répétition

Ajoutez un repère pédagogique indépendant qui se répète toutes les quatre pulsations de croche. C'est un repère visuel d'exercice, et non un accent joué. Un état complet inclut maintenant la position modulo 7 dans la mesure, modulo 4 dans le repère et modulo 2 dans le cycle de médiator. Le premier retour strictement positif des trois à leurs phases de départ se produit à la pulsation 28, après quatre mesures.

La pulsation 14 rétablit l'état de mesure et de médiator, mais se trouve à la phase 2 du repère. Au tempo explicitement déclaré de 120 à la noire, chaque pulsation de croche dure 0.25 seconde ; la pulsation 28 survient donc 7 secondes après la pulsation 0. Le calcul de phase n'établit pas à lui seul le placement temporel réel de la lecture.

### Exercice 2 : tester une répétition complète

À la pulsation 14, quelle phase n'est pas revenue ? Donnez le premier retour complet et son temps écoulé au tempo déclaré. Répéter seulement le motif de directions sur deux mesures suffit-il à réinitialiser chaque repère ?

> **Réponse:** Le repère de quatre pulsations est à la phase 2. Le retour complet est à la pulsation 28, soit 7 secondes au tempo de 120 à la noire. Une répétition de deux mesures ne rétablit pas le repère ; l'affirmation de retour doit nommer les composantes d'état comparées.

## 3. Préciser ce qu'un silence fait avancer

Rendez maintenant silencieuse la pulsation 3 de chaque mesure. Avec une alternance commandée par les attaques, un silence ne produit aucune attaque et ne fait pas avancer le compteur d'attaques. Les pulsations attaquées 0, 1, 2, 4, 5, 6 de la première mesure ont les directions D, U, D, U, D, U. Six attaques ont eu lieu ; la première attaque de la mesure suivante, à la pulsation absolue 7, est donc D.

Une politique distincte d'horloge de pulsation conçue pour le cours alterne plutôt le mouvement D/U à chaque pulsation de croche, y compris les pulsations silencieuses. Son attaque à la pulsation 4 est D et celle à la pulsation 7 est U. Ces politiques concordent avant le premier silence puis divergent. Le choix dépend de l'exercice visé ; aucune n'est une consigne universelle pour toutes les techniques de guitare.

### Exercice 3 : distinguer silence et remise à zéro d'un état

Donnez les directions d'attaque aux pulsations 4 et 7 pour les politiques commandée par les attaques et commandée par l'horloge de pulsation avec ce silence répété. Quelles informations l'agent doit-il ajouter avant d'affirmer que ses directions sont sans ambiguïté ?

> **Réponse:** Les directions commandées par les attaques sont U à la pulsation 4 et D à la pulsation 7. Les directions de l'horloge de pulsation sont D à la pulsation 4 et U à la pulsation 7. Précisez si les pulsations silencieuses font avancer une horloge de mouvement ou si seules les attaques réelles font avancer l'alternance, ainsi que la phase de départ et toute remise à zéro intentionnelle.

## 4. Ne pas créer d'attaque sur une prolongation

Revenez à la grille entièrement attaquée, sauf que la pulsation absolue 7 prolonge la note attaquée à la pulsation 6. Selon le modèle d'attaques de ce cours, elle n'est pas frappée à nouveau. Après l'attaque D à la pulsation 6, l'attaque suivante à la pulsation 8 est U. Inventer une attaque à la pulsation 7 consommerait ce U et ferait passer la pulsation 8 à D.

Le [type de note MusicXML de GA à la révision fixée](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L93-L109) possède un champ de liaison de prolongation, tandis que le [parseur de notes sélectionné](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L85-L115) ne lui attribue aucune valeur. Cette limite statique justifie de tester une importation réelle avant de déduire le nombre d'attaques de son résultat. Ce n'est pas un nouveau défaut de lecture reproduit.

### Exercice 4 : préserver l'identité des attaques

Si la pulsation 7 est une prolongation liée, quelle direction appartient à l'attaque à la pulsation 8 ? Comment une fausse réattaque changerait-elle la réponse, et qu'est-ce que le champ examiné du parseur ne certifie pas ?

> **Réponse:** L'attaque réelle suivante à la pulsation 8 est U. Une fausse attaque à la pulsation 7 rendrait la pulsation 8 D. Le champ de liaison de prolongation non renseigné du parseur examiné ne certifie pas la préservation de l'identité d'une prolongation dans un véritable parcours d'importation ou de lecture ; aucun parcours de ce type n'a été exécuté ici.

## 5. Vérifier une direction de notation à la frontière

Les [types Guitar Pro du projet](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/GuitarProTypes.fs#L45-L96) distinguent l'accent des effets de coup et de coup de médiator, avec des chaînes de direction. Dans le [parseur d'effets examiné](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/GuitarProParser.fs#L129-L147), le cas sélectionné 7 construit un coup de médiator vers le bas. Cette branche n'est ni un planificateur de phase continue entre les mesures ni une preuve de conformité à tous les fichiers binaires réels.

Le [parseur technique MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L55-L80) énumère la corde, la frette et plusieurs techniques, mais pas les symboles haut/bas liés ci-dessus ; les noms d'enfants non reconnus sont éliminés. Ne déduisez pas la prise en charge d'un symbole de l'existence de la norme, ni le comportement de tous les parcours de GA de cette seule branche.

### Exercice 5 : préparer un essai utile d'aller-retour

Pourquoi un type de données capable de porter une direction ou un seul cas de parseur de coup vers le bas ne suffisent-ils pas à affirmer la préservation de l'exercice ? Nommez les observations nécessaires pour une prochaine vérification concrète.

> **Réponse:** La capacité à stocker une direction ne démontre pas la lecture des deux directions, leur continuité entre les mesures ou leur récupération après exportation. Utilisez un parcours fixé à une révision avec des signes D/U explicites, une mesure impaire à sept attaques, un silence assorti d'une politique déclarée de compteur et une prolongation liée. Comparez les identités d'événements, les directions récupérées et les points de remise à zéro ; examinez séparément la partition produite et l'exécution par le musicien. Aucun aller-retour réussi, technique préférée ou jouabilité physique n'ont été observés ici.

Le [relevé de médiator fixé](../../../../code/streeling/evidence/meter-picking-2026-10-22/picking-phase.json) conserve toutes les politiques et les témoins négatifs. [GTR-005](gtr-005-plan-which-string-keeps-ringing.md) vérifie séparément l'occupation des cordes ; une trace de directions correcte ne prouve pas la faisabilité d'une affectation de notes tenues.
