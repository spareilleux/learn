---
module_id: mcl-006-preserve-meter-grouping-and-tempo-units
department: musicology
course: "Préserver les groupements métriques et les unités de tempo"
level: intermediate
prerequisites: ["mcl-004-model-timing-without-inventing-a-style", "mcl-005-preserve-written-and-sounding-pitch"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Préserver les groupements métriques et les unités de tempo

> **Portée du brouillon.** Calculs de mesures complètes conçus pour le cours, lecture de spécifications primaires et inspection du code à une révision précise. Les revues humaines technique, musicale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun parseur, importateur de partitions, moteur de lecture ou musicien n'ont fait l'objet d'un essai.

## La question du projet

Un guitariste demande à GA de préserver un groupement écrit lors de l'importation d'un motif d'exercice. Conserver la durée totale est nécessaire, mais ne suffit pas à préserver les débuts des groupes. Ce cours distingue l'indication de mesure, la suite des groupes, les unités de durée de la partition et l'unité du métronome avant de suivre les limites des représentations réelles du projet.

La [référence MusicXML de time](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/time/) autorise un numérateur additif dans une paire numérateur/dénominateur, ainsi que plusieurs paires pour des dénominateurs mixtes. Une simple indication 7/8 et une indication explicite 2+2+3 sur 8 portent donc des informations de groupement différentes, même si leurs durées totales de mesure concordent. Aucun accent joué ni aucune identité culturelle ne découlent automatiquement de ces champs écrits.

## 1. Nommer ce qui se répète par minute

Posez une mesure complète à 7/8, un tempo constant à la noire de 120 par minute, sans anacrouse ni changement de tempo. Chaque noire dure 0.5 seconde et chaque croche 0.25 seconde. La mesure dure 1.75 seconde. Si le métronome compte plutôt les croches à 120 par minute, chaque croche dure 0.5 seconde et la mesure 3.5 secondes.

La [référence MusicXML de metronome](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/metronome/) associe un groupe beat-unit à une valeur per-minute pour une indication ordinaire. La [définition de beat-unit](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/beat-unit/) identifie sa valeur graphique de note ; [per-minute](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/per-minute/) peut aussi contenir du texte. Ici, la valeur numérique 120 est une prémisse explicite, et non une interprétation universelle d'un texte d'indication arbitraire. Le dénominateur de l'indication de mesure ne précise pas à lui seul l'unité du métronome.

### Exercice 1 : lever l'ambiguïté du tempo

Comparez une mesure à 7/8 au tempo à la noire de 120 avec la même mesure au tempo à la croche de 120. Donnez chaque durée et identifiez le champ manquant dans une consigne indiquant seulement « 7/8, 120 BPM ».

> **Réponse:** La première dure 1.75 seconde ; la seconde 3.5 secondes. La valeur de note nommée pour le métronome manque. Un dénominateur de 8 ne résout pas à lui seul cette omission.

## 2. Préserver un groupement autant qu'une somme

Utilisez les groupes pédagogiques de 2+2+3 croches. Leurs débuts dans la mesure sont aux positions de pulsation de croche 0, 2 et 4. Une indication composite 2/4+3/8 a le même total de sept croches, mais sépare explicitement quatre croches de trois. Les débuts de ses composantes sont 0 et 4. Réduire les deux au total 7/8 efface cette distinction.

Ce sont des groupements déclarés dans la partition. Qualifier chaque début d'accent fort joué ajouterait une réalisation non observée. Un rapport utile d'importation peut présenter le texte métrique saisi, la suite de groupes conservée et toute approximation séparément des retours audio ou du musicien.

### Exercice 2 : comparer des totaux égaux

Donnez les longueurs des groupes et leurs débuts en unités de pulsation de croche pour 2+2+3 sur 8 et pour 2/4+3/8. L'égalité de durée totale établit-elle un groupement égal ou des accents joués égaux ?

> **Réponse:** Le premier a les longueurs 2, 2, 3 et les débuts 0, 2, 4. Le second a les longueurs 4, 3 et les débuts 0, 4. Tous deux totalisent 7 croches ; ni l'égalité des groupements ni celle des accents joués ne découle de cette somme.

## 3. Distinguer les divisions de la partition du dénominateur

Posez 24 divisions par noire. La [définition MusicXML de divisions](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/divisions/) fixe la noire comme référence pour ces unités. Une croche occupe 12 divisions ; la mesure de sept croches en occupe donc 84. Ses limites 2+2+3 sont à 0, 24, 48 et 84 divisions. Les limites des composantes à dénominateurs mixtes sont à 0, 48 et 84.

Avec la même référence de divisions et un tempo à la noire de 120, une mesure à 6/8 et une mesure à 3/4 couvrent toutes deux 72 divisions et 1.5 seconde. Ce calcul ne précise pas le même groupement ou la même pulsation battue. La [référence de duration](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/) comporte aussi des règles de position dans la partition : compter chaque élément de note comme une avancée indépendante n'est pas un algorithme général de placement temporel pour les voix multiples ou les accords. Aucun algorithme de ce type n'a été exécuté ici.

### Exercice 3 : reconstruire les unités

À 24 divisions par noire, calculez une croche, une mesure à 7/8 et le total de chacune des mesures à 6/8 et à 3/4. Quelle équivalence plus forte la dernière égalité ne prouve-t-elle pas ?

> **Réponse:** Une croche vaut 12 divisions ; 7/8 en vaut 84 ; 6/8 et 3/4 en valent chacune 72. Des totaux égaux n'établissent pas la même structure de groupes, unité de métronome, accent joué ou interprétation musicale. Les divisions de la partition ne sont pas automatiquement la résolution en ticks du fichier MIDI.

## 4. Suivre la limite exacte de l'importateur

À la révision de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`, le [type MusicXML de mesure](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L115-L138) conserve un numérateur entier et un dénominateur entier. Le [parseur de mesure](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L123-L138) sélectionne le premier enfant de chaque nom et tente d'analyser leurs textes comme des entiers.

Pour les entrées sélectionnées fixes, l'inspection statique prédit 7 et 8 pour une simple mesure à 7/8 ; aucune valeur de mesure pour le texte de numérateur `2+2+3` ; et seulement 2 et 4 pour l'entrée à deux paires 2/4+3/8. Cette dernière prédiction élimine la seconde paire au lieu de conserver une somme de 7/8. Ce sont des prédictions déduites du code, et non des résultats d'importation nouvellement exécutés. Elles identifient des cas limites concrets à tester avant de promettre une importation fidèle.

### Exercice 4 : éviter une fausse affirmation de normalisation

Énoncez les trois résultats prédits. Pourquoi l'affirmation « l'importateur normalise fidèlement les deux formes composites en 7/8 » ne serait-elle pas étayée par ce code ?

> **Réponse:** Une simple mesure à 7/8 prédit les entiers 7 et 8. Le texte de numérateur additif `2+2+3` prédit l'absence de valeur de mesure. Deux paires 2/4 et 3/8 prédisent seulement 2 et 4. La branche examinée ne conserve pas l'expression additive et ne somme pas les paires ; aucun nouveau résultat à l'exécution n'a été obtenu.

## 5. Expliciter la vérification du transfert

Les [types MIDI](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MidiTypes.fs#L19-L46) représentent de même un événement d'indication de mesure par deux entiers. Le [corps sélectionné de la branche des métadonnées](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L208-L217) élève 2 à l'exposant du dénominateur et ignore les deux octets restants de la charge utile. Si ce corps était atteint, une charge utile pédagogique avec les octets 7, 3, 24, 8 construirait 7/8. Il ne fournirait pas de groupement ordonné 2+2+3 conservé.

**Correction d'accessibilité du code.** Le répartiteur environnant masque le statut pour ne garder que son demi-octet de poids fort avant de chercher un statut complet de méta-événement ; cette branche de méta-événement est donc inaccessible par la sélection présentée. L'exemple de charge utile ci-dessus est une interprétation conditionnelle du corps, et non une prédiction valide d'analyse MIDI réussie. [MCL-007](mcl-007-integrate-a-midi-tempo-map-before-scheduling.md) explicite cette distinction. Les prédictions de la branche MusicXML dans la section précédente sont des observations distinctes du code.

### Exercice 5 : préciser une vérification d'importation utile

Que peut conserver cette branche MIDI sélectionnée de la charge utile pédagogique ? Nommez la comparaison supplémentaire nécessaire avant qu'un agent affirme que l'exercice groupé d'un guitariste a survécu à un parcours d'importation et d'exportation.

> **Réponse:** Si ce corps sélectionné était atteint, il construirait le numérateur 7 et le dénominateur 8 et ignorerait les octets de charge utile 24 et 8. Le routage réel environnant ne l'atteint pas ; ne qualifiez donc pas ces valeurs de sortie du parseur. La représentation d'événement ne possède pas non plus l'ordre des groupes pédagogiques. Comparez les textes métriques saisis et récupérés, les limites de groupes, les unités de durée et l'unité de métronome nommée sur un parcours fixé à une révision et exécuté ; examinez séparément la partition affichée et la lecture visée. Aucune perte à l'échelle du système ni aucun aller-retour réussi n'ont été mesurés ici.

Le [dossier fixé](../../../../code/streeling/evidence/meter-picking-2026-10-22/README.md) conserve les calculs exacts, les prédictions déduites du code et les empreintes du code public. [WML-006](../../world-music-languages/en/wml-006-preserve-the-origin-of-an-additive-cycle.md) suit les effets d'un changement d'origine du cycle sur le même groupement.
