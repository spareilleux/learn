---
title: Préserver la hauteur écrite et la hauteur réelle lors de l'importation d'une partition
description: Préserver la hauteur écrite et la hauteur réelle lors de l'importation d'une partition — Musicologie
sidebar:
  label: MCL-005 · Préserver la hauteur écrite et la hauteur réelle lors de l'importation d'une partition
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/musicology/fr/mcl-005-preserve-written-and-sounding-pitch.fr.md
---

:::note[Streeling University]
**MCL-005** · Préserver la hauteur écrite et la hauteur réelle lors de l'importation d'une partition · intermédiaire · 35 minutes

Généré par le département *Musicologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/musicology/fr/mcl-005-preserve-written-and-sounding-pitch.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/)
:::

> **Portée du brouillon.** Nouvelle exécution sur CPU de deux fichiers F# publics inchangés sur dix entrées XML conçues pour le cours, documentation primaire de MusicXML et calculs explicites. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Aucune validation de schéma, importation dans l'application, restitution de la notation, lecture audio ni correction du parseur de production n'a été réalisée.

## La question du projet

Un guitariste compare une partition, une tablature et les étiquettes de notes de GA. Un écart d'octave peut provenir de la représentation utilisée dans la notation plutôt que de l'interprétation musicale. L'élément [pitch de MusicXML 4.0](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/pitch/) stocke un degré, une altération chromatique facultative et une octave. Son [élément transpose](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/transpose/) décrit séparément l'ajustement entre la hauteur écrite et la hauteur réelle. Un parseur peut conserver les champs de la note tout en perdant le contexte qui leur donne leur interprétation prévue.

[WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/) a établi une convention de nommage des notes. Ce cours suit l'étape suivante : que signifie le registre encodé ? Les exemples sont des cas pédagogiques conçus pour le cours et ne prétendent pas que tous les fichiers pour guitare utilisent le même encodage.

## 1. Calculer la transposition déclarée par le fichier

Pour un cas ordinaire comportant une seule note, sans instruction de doublure, utilisez la coordonnée numérique de la note encodée, plus le [décalage chromatique](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/chromatic/), plus 12 fois le [changement d'octave](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/octave-change/). Le champ chromatique exclut la contribution du changement d'octave. Ces jeux d'essai utilisent des demi-tons entiers et la convention selon laquelle C4 correspond au numéro MIDI 60.

Les [calculs fixés](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/transposition-arithmetic.json) donnent 52 pour E3 encodé. Avec chromatic à 0 et octave-change à -1, la hauteur réelle est `52+0+12*(-1) = 40`, soit E2. Un autre fichier peut encoder directement E2 comme 40 sans transposition ; il représente déjà la même hauteur réelle. Le nom de l'instrument ne permet pas à lui seul de choisir entre ces représentations.

### Exercice 1 : suivre le décalage déclaré

Comparez E3 encodé avec chromatic à 0 et octave-change à -1 à E2 encodé sans transposition. Donnez le numéro de la note réelle dans chaque cas. Pourquoi le seul mot « guitare » ne doit-il pas déclencher une nouvelle soustraction d'octave ?

> **Réponse:** Les deux donnent 40, soit E2. Le premier exige son décalage déclaré ; le second possède déjà ce registre. Appliquer un autre décalage automatique pour la guitare compterait une seconde fois le même ajustement prévu ou modifierait une représentation déjà à hauteur réelle.

## 2. Observer ce que le parseur de la révision fixée préserve réellement

La révision publique de GA `dc2e74cbd992a298f67efb928b5b3754615e1924` fournit [MusicXmlTypes](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MusicXmlTypes.fs) et [MusicXmlParser](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs). Un nouveau chargement autonome avec le SDK installé 10.0.113 a exécuté leurs fonctions inchangées sur les [dix entrées](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/authored-xml-inputs.json). Les [résultats enregistrés](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/native-parser-results.json) et le [compte rendu d'exécution](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/execution.json) en conservent la portée.

Une partition contenant E3 et une partition E3 identique à ceci près qu'elle déclare la transposition descendante ont produit des partitions analysées structurellement égales. Toutes deux ont conservé E3 et converti cette hauteur conservée en 52. Le type Attributes obtenu après analyse n'a aucun champ de transposition. Il s'agit d'une perte d'information reproduite dans cet utilitaire à la révision fixée, et non d'un test complet de l'application ni d'une preuve concernant le service actuellement déployé.

### Exercice 2 : distinguer acceptation et préservation

L'analyse des deux partitions réussit et donne le même numéro de note stocké, 52. L'enregistrement analysé permet-il à lui seul de déterminer que la seconde partition devrait sonner à 40 ? Quelle information manque ?

> **Réponse:** Non. Les enregistrements conservés sont égaux, mais la seconde partition d'origine déclare une transposition d'une octave vers le bas. L'enregistrement analysé a perdu cette déclaration. Un résultat réussi ne suffit pas à prouver que l'interprétation de la hauteur réelle a été préservée.

## 3. Distinguer l'apparence de la clé et la transposition déclarée

MusicXML possède également [clef-octave-change](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/clef-octave-change/), qui appartient à une clé. L'essai pédagogique a ajouté la valeur -1 à la clé tout en conservant E3 encodé. Son enregistrement analysé était encore égal à celui de la partition de base : l'utilitaire conserve le signe de la clé, mais pas ces métadonnées d'octave. Cela établit une autre perte ; cela ne règle pas à lui seul la politique de hauteur de chaque logiciel produisant des partitions.

Traitez la hauteur encodée, la transposition de l'instrument et les informations de notation de la clé comme des entrées distinctes à examiner. N'additionnez pas aveuglément les deux champs évoquant une octave comme des décalages indépendants de hauteur réelle. Le logiciel consommateur a besoin d'une politique d'encodage explicite et de tests d'importation représentatifs. Avec la transposition déclarée du premier jeu d'essai, soustraire deux fois l'octave ferait passer 52 à 28, soit E1, au lieu de 40.

### Exercice 3 : repérer une double application

Le cas pédagogique avec E3 écrit déclare un seul ajustement d'une octave vers le bas. Un importateur soustrait 12 une fois pour cette déclaration et une autre fois parce qu'il reconnaît une partie de guitare. Donnez sa sortie et la sortie prévue. La présence de métadonnées d'octave dans une clé justifie-t-elle cette règle ?

> **Réponse:** Il produit 28, soit E1 ; la valeur prévue est 40, soit E2. Les métadonnées d'octave de la clé ne justifient pas l'application aveugle d'un second décalage lié à l'instrument. Établissez comment le fichier encode les hauteurs et appliquez une seule fois la transformation prévue.

## 4. Examiner les pertes à l'intérieur d'une note acceptée

La [définition officielle d'alter](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/alter/) autorise les altérations en fractions de demi-ton. L'entrée pédagogique C4 avec alter à 0.5 a conservé une hauteur dont l'altération était absente et dont le numéro de note calculé par l'utilitaire était 60. Le parseur à la révision fixée utilise une conversion en entier ; l'altération fractionnaire de l'entrée n'a pas été conservée. Un alter entier à 0 a produit, lui, un 0 explicitement stocké, donnant également 60 après conversion. L'égalité des nombres convertis n'établit ni l'égalité des enregistrements conservés ni une interprétation sans perte.

Deux témoins négatifs utilisaient le degré H et une octave absente. L'analyse des deux partitions complètes a tout de même réussi et conservé une note, mais cette note n'avait aucune hauteur. Les valeurs -999 du tableau d'observation sont des sentinelles de l'essai signalant des champs absents, et non des notes musicales renvoyées par GA. Ces entrées volontairement incomplètes n'ont pas fait l'objet d'une validation de schéma et ne doivent pas être présentées comme des documents MusicXML valides.

### Exercice 4 : examiner le résultat imbriqué

Dans le cas de l'altération fractionnaire, quelle distinction a disparu ? Dans le cas H, combien de notes et de hauteurs ont été conservées ? Le succès du résultat global peut-il certifier la préservation ?

> **Réponse:** L'altération 0.5 a disparu ; une altération absente a pris la valeur par défaut 0 lors de la conversion. Le cas H a conservé une note et aucune hauteur. Le succès global ne certifie ni la préservation de l'altération fractionnaire ni la présence d'une hauteur valide dans chaque note conservée.

## 5. Choisir une comparaison capable de détecter l'erreur réelle

E3 à 52 et E2 à 40 ont tous deux la classe de hauteur 4. Une comparaison limitée aux classes de hauteur ne peut donc pas détecter cette erreur d'octave. Préservez le registre absolu lorsque la question porte sur les notes entendues, tout en conservant la graphie et la provenance de la transposition pour les questions de notation. La tablature exige aussi l'accordage et les conventions de cordes et de cases ; un numéro de note ne permet pas à lui seul de tout reconstruire.

Les exercices proposent des critères d'acceptation d'importation sans modifier le contrat de production de GA. Une implémentation ultérieure devrait préserver ou rejeter explicitement le contexte non pris en charge et valider le parcours dans l'application. Aucune correction de ce type ni comparaison de partitions affichées n'est incluse ici.

### Exercice 5 : concevoir une vérification discriminante

Une vérification d'importation compare uniquement les classes de hauteur et accepte 52 là où 40 était prévu. Expliquez pourquoi elle réussit et proposez une vérification qui échoue dans ce cas. Indiquez une limite qui reste non testée.

> **Réponse:** Les deux valeurs se réduisent à la classe 4 ; la vérification élimine donc l'octave qui les distingue. Comparer le numéro absolu réel prévu 40 au numéro effectif 52 détecte l'erreur. L'importation complète dans l'application, la restitution de la notation, la lecture audio et la validation de schéma restent non testées ici.

## Travail de l'apprenant avec accès aux sources

Utilisez le [travail préparé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/learner-task.md) pour reconstruire les deux encodages, expliquer l'égalité des enregistrements analysés et proposer une vérification d'importation. Distinguez l'exécution de l'utilitaire, l'interprétation de la spécification et le comportement de l'application. Les résultats des apprenants et de la revue humaine restent à recueillir.
