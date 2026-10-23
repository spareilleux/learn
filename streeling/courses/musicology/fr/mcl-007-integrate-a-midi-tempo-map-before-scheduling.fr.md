---
module_id: mcl-007-integrate-a-midi-tempo-map-before-scheduling
department: musicology
course: "Intégrer une carte de tempo MIDI avant de planifier la lecture"
level: intermediate
prerequisites: ["mcl-004-model-timing-without-inventing-a-style", "mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Intégrer une carte de tempo MIDI avant de planifier la lecture

> **Portée du brouillon.** Modèles d'événements pédagogiques, calculs rationnels exacts et inspection statique du code. Les revues humaines technique, musicale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun fichier MIDI n'a été analysé ou joué, et aucun parseur ou ordonnanceur de GA n'a été modifié.

## La question du projet

Un guitariste importe une phrase d'entraînement qui change de tempo. À quelles secondes les limites de ses notes doivent-elles se situer ? Les [Standard MIDI Files](https://midi.org/standard-midi-files) échangent des données d'événements temporisés, mais une étiquette d'événement conservée n'est pas une chronologie reconstruite. [MCL-004](mcl-004-model-timing-without-inventing-a-style.md) examine déjà une expression de tempo entier ; [MCL-006](mcl-006-preserve-meter-grouping-and-tempo-units.md) distingue groupements et unités de pulsation. Ce cours ajoute les positions d'événements, l'intégration du tempo et une vérification du flux de contrôle avant de revendiquer une importation réussie.

## 1. Déclarer la division et cumuler les ticks

Utilisez un exemple pédagogique à une seule piste, fondé sur la noire, avec une résolution Q = 480 ticks par noire. La [documentation des fichiers de Mido](https://mido.readthedocs.io/en/stable/files/midi.html) distingue les deltas en ticks des pistes de ses autres coordonnées d'itération. Cumulez le delta de chaque événement dans sa piste avant d'éliminer ou de projeter des événements. La fusion de pistes multiples et la priorité d'événements simultanés exigent des règles supplémentaires ; elles ne sont pas implémentées ici.

La carte de tempo pédagogique est de 500000 microsecondes par noire à partir du tick 0, de 1000000 à partir du tick 480 et de 250000 à partir du tick 960. Un changement de tempo affecte les intervalles de ticks positifs suivants. L'ordre sélectionné est explicite à une limite commune. Dans un intervalle à tempo constant :

```text
delta_seconds = delta_ticks*microseconds_per_quarter / (Q*1000000)
```

### Exercice 1 — Retrouver la coordonnée d'horloge

Pour des limites de notes aux ticks 0, 240, 480, 720, 960 et 1200, calculez les secondes à partir de cette carte. Pourquoi multiplier chaque tick par le dernier tempo est-il invalide ?

> **Réponse:** Les secondes sont 0, 0.25, 0.5, 1, 1.5 et 1.625. Le raccourci du dernier tempo donne seulement 0.625 seconde au tick 1200, car il applique le tempo final à des intervalles régis par les tempos précédents. Une valeur de tempo exige sa position et une division temporelle déclarée.

## 2. Découper une note aux changements de tempo

Une note commence au tick 240 et se termine au tick 1200. Sa durée traverse trois segments à tempo constant, de longueurs en ticks 240, 480 et 240. Leurs durées écoulées sont 0.25, 1 et 0.125 seconde. Ce sont des calculs pédagogiques de passage de la partition au temps, et non une interprétation enregistrée ou un modèle de swing.

### Exercice 2 — Intégrer l'intervalle

Calculez la durée de la note en additionnant ces segments puis en soustrayant les temps absolus des extrémités. Prendre le tempo au début de la note et l'appliquer à toute la note donne-t-il le même résultat ?

> **Réponse:** Les deux méthodes correctes donnent 1.375 seconde : 0.25 + 1 + 0.125, ou 1.625 - 0.25. Appliquer le tempo initial de 500000 microsecondes à l'ensemble des 960 ticks donne 1 seconde et manque les changements intermédiaires. L'intervalle de note doit utiliser toute la carte de tempo pertinente.

## 3. Ne pas appliquer la formule de la noire à une division fondée sur les images

La [référence Microsoft sur la temporisation MIDI](https://learn.microsoft.com/en-us/windows/win32/multimedia/timing-information) distingue les divisions fondées sur la noire et les divisions SMPTE. Pour l'exemple limité sans saut de numéros d'images présenté ici, 25 images par seconde et 40 ticks par image donnent 1000 ticks par seconde. Un événement de tempo ne modifie pas cette durée du tick.

L'octet de poids fort encodé pour l'étiquette de format négative -25 est 231. Avec l'octet de poids faible 40, le mot de division est `E728`. À la révision de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`, le [parseur d'en-tête](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L13-L17) lit un mot positif ou nul ; sa [branche SMPTE](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L73-L85) prend l'opposé de l'octet de poids fort décalé sans d'abord le décoder comme signé. Le calcul statique prédit -231 pour cette expression du code, et non l'étiquette positive de format 25. Ce n'est ni une nouvelle capture d'échec F# ni un décodeur SMPTE complet.

### Exercice 3 — Vérifier la représentation avant de l'utiliser

Selon le modèle déclaré à 25 images et 40 ticks, convertissez 750 ticks en secondes. Expliquez la distinction entre l'octet encodé 231, l'étiquette signée -25 et l'étiquette positive de format 25. Peut-on utiliser l'expression du code comme décodeur vérifié ?

> **Réponse:** Un tick dure 0.001 seconde ; 750 ticks durent donc 0.75 seconde. L'octet 231 représente -25 signé après un décodage explicite d'octet signé ; son opposé donne l'étiquette de format 25. Le code sélectionné prédit plutôt -231 parce qu'il prend l'opposé d'une valeur non signée de l'octet de poids fort. Cette lecture ne vérifie pas un décodeur fonctionnel. La conversion avec saut de numéros d'images est hors de cet exemple.

## 4. Une représentation d'événement peut perdre la position du tempo

Les [types MIDI](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MidiTypes.fs#L19-L46) conservent un delta temporel dans les enregistrements de notes, tandis que l'alternative de tempo ne porte qu'un entier. Le [corps sélectionné de construction du tempo](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L197-L207) ne fournit aucune enveloppe de temps d'événement. Considérez deux flux pédagogiques avec un tempo initial et un début de note au tick 0 :

| Flux | Delta avant le passage à 1000000 microsecondes par noire | Delta de ce changement à la fin de note | Tick absolu de fin de note | Secondes de fin de note |
| --- | --- | --- | --- | --- |
| A | 480 | 480 | 960 | 1.5 |
| B | 240 | 480 | 720 | 1.25 |

Le tempo initial est de 500000 microsecondes par noire. Si des corps de construction correctement routés projetaient ces événements seulement en entiers de tempo et en deltas locaux aux notes, les deux listes modélisées contiendraient les mêmes valeurs de tempo et les mêmes deltas de notes. La perte du delta de l'événement de tempo empêche de retrouver la différence. Ces listes hypothétiques ne sont **pas des sorties réelles du parseur**.

### Exercice 4 — Montrer ce que la projection oublie

Calculez les ticks absolus de fin de note et les secondes dans les deux cas. Pourquoi un agent ultérieur ne peut-il pas retrouver quel flux a été fourni à partir des seules listes projetées hypothétiques ?

> **Réponse:** A se termine à 480 + 480 = 960 ticks, après 0.5 + 1 = 1.5 seconde. B se termine à 240 + 480 = 720 ticks, après 0.25 + 1 = 1.25 seconde. Éliminer le delta de l'événement de tempo rend les listes modélisées identiques bien que les positions visées diffèrent. Un calcul ultérieur ne peut pas retrouver de façon unique une entrée effacée. Un routage correct seul ne corrigerait pas cette perte de représentation.

## 5. Vérifier si un corps sélectionné peut être atteint

Le [répartiteur d'événements](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L98-L173) masque d'abord le statut avec un masque de demi-octet de poids fort, puis cherche plus loin une valeur complète de méta-événement. Pour un statut de méta-événement :

```text
0xFF & 0xF0 = 0xF0
0xF0 != 0xFF
```

La branche de méta-événement est donc inaccessible par cette sélection. Le [dossier fixé](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/parser-boundaries.json) énumère les 256 octets d'entrée ; aucun ne produit l'étiquette complète de méta-événement après ce masque. C'est un témoin du flux de contrôle, et non une exécution du parseur sur un fichier valide. Les deux révisions de parseur utilisées dans MCL-004 et MCL-006 possèdent ici des octets identiques ; leurs exemples de métadonnées sont désormais explicitement des interprétations conditionnelles de corps.

### Exercice 5 — Énoncer la prochaine affirmation admissible

Un agent cite le corps de tempo et déclare un parcours fidèle du MIDI à la lecture. Donnez l'objection du masque d'octet, distinguez le second problème de représentation et précisez ce qu'une véritable validation doit conserver et exécuter.

> **Réponse:** Le statut masqué ne peut pas sélectionner la branche de méta-événement ; le parcours présenté n'établit donc pas une analyse réussie du tempo. Même avec le routage réparé, conserver des entiers de tempo sans leurs positions d'événements perd de l'information. Un parcours validé exige des événements temporisés, les unités brutes de tempo, une division déclarée, des règles d'ordre et de fusion et l'identité exacte du code, puis de véritables vérifications du parseur et de la chronologie sur des cas limites avant de mesurer la lecture. Un parcours utilisant une autre bibliothèque exigerait ses propres preuves. Aucune correction du parseur ou importation fonctionnelle n'ont été produites ici.

## Travail de l'apprenant avec accès aux sources

Préparez une revue temporelle avec les six limites converties, la durée de la note traversant les changements de tempo, la conversion fondée sur les images et la vérification de l'octet signé, les deux flux témoins et la preuve du masque de répartition. Proposez un enregistrement minimal d'événement à conserver et un test réfutant une future implémentation. Traitez cet enregistrement comme un candidat, et non un contrat ratifié de GA. Consignez l'aide et les inconnues. La [grille d'évaluation de la revue](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/reviewer-rubric.json) est préparée ; aucune tentative d'apprenant n'est enregistrée.

Le [relevé des sources](../../../../code/streeling/evidence/tempo-clocks-2026-10-22/primary-readback.json) lie les fichiers réels. Le PDF complet de la spécification MIDI n'a pas été lu ; aucune conformité, temporisation de navigateur, style culturel, bénéfice d'écoute ou version HTML déployée n'est certifiée.
