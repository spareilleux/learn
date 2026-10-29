---
module_id: gtr-008-count-a-capo-offset-once
department: guitar-studies
course: "Compter une seule fois le décalage du capodastre"
level: intermediate
prerequisites: ["gtr-001-the-fretboard-map", "gtr-003-audit-voicing-playability", "wml-005-declare-note-name-conventions", "gaa-006-separate-capo-shapes-from-sounding-pitches"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Compter une seule fois le décalage du capodastre

> **Périmètre du brouillon.** Calculs pédagogiques de cases et de hauteurs en tempérament égal, lecture du code à une révision fixée et trois réponses réelles d’un outil de transposition d’accords. Aucun nouvel adaptateur de capodastre, aucune exécution native de la compétence, aucune importation MusicXML, aucune mesure d’instrument ni aucun essai de jeu n’ont été réalisés. Les revues humaines techniques, musicales, linguistiques par des personnes maîtrisant la langue et pédagogiques avec des apprenants, ainsi que la vérification du HTML du cours déployé, restent à effectuer.

## La question du projet

Un guitariste demande une forme de C avec le capodastre à la case 2. Une case affichée 3 désigne-t-elle la troisième case physique depuis le sillet ou la troisième case au-dessus du capodastre ? La [définition du capodastre dans MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/capo/) décrit une modification de l’accordage à vide. Sa [définition de la case](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/fret/) commence à zéro pour une corde à vide ; cette seule indication ne détermine pas la politique de coordonnées du capodastre d’un logiciel destinataire.

[GAA-006](../../guitar-alchemist-academy/en/gaa-006-separate-capo-shapes-from-sounding-pitches.md) établit déjà le sens de la transformation entre la fondamentale de la forme et la fondamentale sonore, ainsi que le registre. Cette leçon étend cette distinction aux origines des cases par corde, aux positions invalides et à la couverture partielle.

Posons un capodastre intégral idéal, le tempérament égal à douze sons et des tableaux ordonnés du E grave au E aigu. Les numéros de notes à vide sont `[40,45,50,55,59,64]`, avec C4 égal à 60. La forme de C conçue pour le cours est `[-1,3,2,0,1,0]` : -1 désigne une corde étouffée et les autres nombres sont des distances au-dessus de l’extrémité à vide effective.

## 1. Conserver l’origine des cases

Pour chaque corde sonore, notons `a` la case physique relative au sillet, `c` la case du capodastre, `r` la case relative au capodastre et `T` le numéro de note à vide d’origine. Alors `a=c+r` et le numéro de la note sonore est `T+a=(T+c)+r`. Les deux expressions sont valides dans le modèle déclaré.

Avec le capodastre à la case 2, le tableau physique de la forme de C devient `[-1,5,4,2,3,2]`. Les notes obtenues sont `[null,50,54,57,62,66]`. Ici, null signifie qu’une corde étouffée n’a pas de hauteur sonore dans le relevé pédagogique ; ce n’est pas une observation de fréquence nulle.

### Exercice 1 : convertir la forme complète

Convertissez la forme de C relative au capodastre en cases physiques et en numéros de notes sonores. Où se trouve une corde à vide relative ? Que devient le marqueur de corde étouffée ?

> **Réponse:** Les cases physiques sont `[-1,5,4,2,3,2]` ; les notes sonores sont `[null,50,54,57,62,66]`. La case relative 0 se situe à la case physique 2 avec ce capodastre intégral. Le marqueur -1 reste un statut de corde étouffée ; lui ajouter le capodastre inventerait une case sonore.

## 2. Ne pas réaccorder puis décaler encore les cases physiques

Réaccorder le tableau à vide selon le capodastre donne `[42,47,52,57,61,66]`. Ajouter les cases relatives d’origine produit les mêmes notes correctes. Ajouter à la place le tableau physique déjà décalé produit `[null,52,56,59,64,68]` : chaque note sonore est deux demi-tons trop haute.

### Exercice 2 : repérer le double comptage

Calculez les deux résultats pour la cinquième corde, dont la note à vide d’origine est 45, la case relative 3 et la case physique 5. Quelle quantité a déjà intégré le décalage du capodastre ?

> **Réponse:** Le résultat correct est `45+5=50` ou `(45+2)+3=50`. Le résultat incorrect est `(45+2)+5=52`. La note à vide réaccordée et la case physique incluent toutes deux déjà le décalage ; les combiner revient donc à le compter deux fois.

## 3. Préserver le sens et le registre absolu

Le [CapoSkill de GA](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs) à la révision fixée calcule la fondamentale sonore comme la fondamentale de la forme plus le capodastre, et la fondamentale de la forme comme la fondamentale sonore moins le capodastre, modulo 12. Il conserve la qualité majeure ou mineure dans les cas pris en charge et accepte des positions entières de capodastre de 0 à 12. Le code sélectionné ne contient aucun tableau de cases par corde ni aucun calcul de placement physique.

Trois [sondages réels de l’outil théorique](../../../../code/streeling/evidence/capo-spelling-2026-10-22/theory-tool-probes.json) ont renvoyé D pour C montant de 2, G pour B descendant de 4 et C pour Bb montant de 2. La révision du service est inconnue. Ce ne sont pas des exécutions de la compétence inspectée ni d’un adaptateur de capodastre vers les cases. Avec le capodastre à la case 12, les classes de hauteur d’une forme se répètent, mais ses notes sonores montent d’une octave dans notre modèle.

### Exercice 3 : inverser la demande musicale

Pour obtenir B majeur sonore avec le capodastre à la case 4, quelle fondamentale et quelle qualité la forme doit-elle avoir selon la convention de noms anglaise déclarée ? Une comparaison limitée au modulo détecterait-elle l’octave manquante du capodastre à la case 12 ?

> **Réponse:** La forme est G majeur, car `11-4=7`. Le résultat observé de l’outil pour B descendant de 4 concorde au niveau de la fondamentale ; le code sélectionné de la compétence traite la qualité séparément. Une comparaison limitée au modulo ne peut pas détecter le changement de registre du capodastre à la case 12 : chaque note sonore monte de 12 tout en conservant sa classe de hauteur.

## 4. Distinguer les positions invalides du statut de corde étouffée

Avec le capodastre à la case 2, la case physique 5 correspond à la case relative 3, et la case physique 2 à la case relative 0. La case physique 1 donnerait une distance relative négative et sort de ce modèle à capodastre intégral. Sa différence arithmétique de -1 ne doit pas être réinterprétée comme le marqueur existant de corde étouffée.

Un exemple pédagogique distinct de capodastre partiel décale les cordes de `[0,2,2,2,2,2]`. Appliquez les cases relatives de la forme de E `[0,2,2,1,0,0]` : les notes sonores sont `[40,49,54,58,61,66]`. Un capodastre intégral à la case 2 donne à la place `[42,49,54,58,61,66]`. La corde la plus grave réfute une description par transposition uniforme de cet exemple partiel.

### Exercice 4 : conserver deux contre-exemples

Classez la case physique 1 sous un capodastre à la case 2. Comparez ensuite les deux tableaux de notes sonores de la forme de E et expliquez pourquoi la transposition de la fondamentale de l’accord entier ne peut pas décrire complètement l’exemple partiel.

> **Réponse:** La case physique 1 est derrière le capodastre intégral déclaré et est invalide ici ; ce n’est pas une corde étouffée déduite de la soustraction. L’exemple partiel laisse la note la plus grave à 40, tandis que le capodastre intégral donne 42 ; les autres notes concordent. Un décalage uniforme de la fondamentale ne conserve pas cette distinction par corde. Aucun des tableaux ne prouve la justesse de l’intonation ni la jouabilité physique.

## 5. Lire le contrat de destination

L’[analyseur MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L59-L78) à la révision fixée stocke séparément la corde et la case techniques. Les attributs sélectionnés ne conservent pas de capodastre. Le [type RelativeFret](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Domain.Core/Instruments/Primitives/RelativeFret.cs#L9-L18) représente une distance générique en cases ; son nom n’établit pas une origine au capodastre. L’[analyseur de navigation](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/FretboardNavigationParser.fs#L25-L41) analyse des coordonnées explicites sans appliquer de décalage de capodastre.

### Exercice 5 : préparer un transfert avec l’aide des sources

Lisez ces sources et la [définition de la corde dans MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/string/). Précisez les informations minimales nécessaires pour transférer le tableau pédagogique vers un autre outil sans deviner sa convention.

> **Réponse:** Conservez l’accordage, l’ordre et la numérotation des cordes, la couverture et les décalages du capodastre, l’origine des cases, les statuts étouffé ou invalide, les hauteurs absolues visées et la révision du code. Dans MusicXML, la corde 1 est la corde de pleine longueur la plus aiguë ; notre tableau suit l’ordre physique inverse. Convertissez explicitement cette indexation. Comparez un petit enregistrement typé et des calculs vérifiés avant de proposer un DSL. L’importation, le rendu, la lecture sonore et la revue du jeu par un musicien n’ont pas été effectués.

Le [relevé fixé des coordonnées](../../../../code/streeling/evidence/capo-spelling-2026-10-22/capo-coordinates.json) conserve les huit cas de capodastre intégral et le contrôle partiel distinct.
