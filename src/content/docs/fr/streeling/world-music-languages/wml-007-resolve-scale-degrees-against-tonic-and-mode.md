---
title: Résoudre les degrés d’une gamme selon la tonique et le mode
description: Résoudre les degrés d’une gamme selon la tonique et le mode — Musiques et langues du monde
sidebar:
  label: WML-007 · Résoudre les degrés d’une gamme selon la tonique et le mode
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-007-resolve-scale-degrees-against-tonic-and-mode.fr.md
---

:::note[Streeling University]
**WML-007** · Résoudre les degrés d’une gamme selon la tonique et le mode · intermédiaire · 40 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-007-resolve-scale-degrees-against-tonic-and-mode.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/), [MCL-005](../../musicology/mcl-005-preserve-written-and-sounding-pitch/)
:::

> **Périmètre du brouillon.** Tables de degrés et contrôles de conventions conçus pour le cours, avec lecture de documents primaires et de code. Aucun nouveau résolveur de degrés, aucune interface de solfège, aucun détecteur de tonalité, aucune expérience de chant ni aucun essai avec un apprenant n’ont été réalisés. Les revues humaines techniques, musicales, linguistiques par des personnes maîtrisant la langue et pédagogiques avec des apprenants, ainsi que la vérification du HTML du cours déployé, restent à effectuer.

## La question du projet

Un agent d’entraînement demande « 1, 3, 5 » ou « do, re, mi ». Ces étiquettes ne désignent pas de hauteurs absolues tant que leurs conventions et leur référence musicale ne sont pas connues. [WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/) distingue les conventions de noms de hauteur ; [MCL-005](../../musicology/mcl-005-preserve-written-and-sounding-pitch/) conserve le registre et la transposition. Ici, la référence manquante est une tonique et une forme de gamme déclarées.

Le [texte d’Open Music Theory sur les degrés de gamme, publié par ses auteurs](https://openmusictheory.github.io/scales.html), définit les degrés relativement à une gamme et décrit l’usage du do mobile. Nous avons lu cet ancien texte, pas la page plus récente qui a renvoyé une erreur d’accès. Nos exemples utilisent un vocabulaire délimité majeur et mineur naturel en tempérament égal à douze sons ; ils ne classent pas toutes les traditions musicales et ne déduisent pas une convention de la nationalité d’un musicien.

## 1. Un degré est un indice, pas un nombre de demi-tons

Pour cet exercice, les degrés ascendants de 1 à 7 utilisent les décalages majeurs `[0,2,4,5,7,9,11]` ou mineurs naturels `[0,2,3,5,7,8,10]`. Ajoutez le décalage choisi à un numéro explicite de note tonique. D4 vaut 62 ; ses degrés majeurs 1, 3 et 5 sont donc `[62,66,69]` : D4, F#4 et A4.

Utiliser le degré moins un comme décalage en demi-tons transformerait au contraire le degré 3 en `62+2=64`, soit E4. Une position numérotée dans une gamme déclarée n’est pas un intervalle chromatique mesuré en demi-tons.

### Exercice 1 : résoudre l’accord parfait majeur

Calculez les degrés 1, 3 et 5 au-dessus de la tonique D4 dans la forme majeure stipulée. Analysez l’erreur d’un résolveur qui produit 64 pour le degré 3.

> **Réponse:** Les décalages sont 0, 4 et 7, donnant `[62,66,69]`. Le degré 3 devrait être F#4 à 66. Renvoyer 64 revient à traiter l’indice du degré moins un comme un décalage en demi-tons et à ignorer la table de gamme majeure.

## 2. Garder explicites la forme de gamme et le registre de la tonique

En D mineur naturel, les mêmes degrés deviennent `[62,65,69]`, avec F4 au lieu de F#4. Changer la forme de gamme modifie la tierce sans changer la tonique. Le terme générique « mineur » ne précise pas tous les degrés susceptibles d’être haussés ou abaissés ; cette table choisit délibérément le mineur naturel.

La classe de hauteur de tonique 2 ne choisit pas non plus D4 plutôt que D3. Un résolveur qui a besoin de notes absolues doit recevoir le registre ou une règle explicite pour le choisir. Une destination limitée aux classes de hauteur peut conserver cette limite au lieu d’inventer une octave.

### Exercice 2 : changer une donnée déclarée

Comparez les accords parfaits majeur et mineur naturel avec la tonique D4. Si seule la classe de tonique 2 est fournie, l’un ou l’autre accord absolu est-il déterminé de manière unique ?

> **Réponse:** Le majeur donne `[62,66,69]` ; le mineur naturel donne `[62,65,69]`. Leur tierce diffère d’un demi-ton. Une classe de tonique seule ne fournit ni D4 ni un autre registre, et la forme de gamme doit également être déclarée. Aucun des deux accords absolus ne découle uniquement de la classe 2.

## 3. Le nombre d’altérations à l’armure ne fournit pas toutes les références

Le [champ fifths de MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/fifths/) compte les dièses ou les bémols d’une armure traditionnelle. Le [champ mode](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/mode/), distinct, différencie le majeur, le mineur et d’autres modes nommés.

Avec deux dièses, D majeur et B mineur donnent déjà des classes de tonique différentes, 2 et 11, dans une comparaison limitée au majeur et au mineur. Un mode absent ne peut pas être remplacé silencieusement par le majeur. Même une tonalité et un mode choisis ne fournissent pas le registre de la tonique et ne prescrivent pas chaque note chromatique d’une mélodie.

### Exercice 3 : préserver le contexte tonal non résolu

Une tonalité stockée possède un nombre de quintes de 2 et aucun mode. Un agent suppose D4 majeur et résout tous les degrés. Identifiez les données devinées et proposez un compte rendu délimité.

> **Réponse:** L’agent a deviné le majeur plutôt qu’un autre contexte compatible, et a deviné le registre 4. Même parmi les possibilités majeures et mineures, B mineur a la classe de tonique 11 plutôt que 2. Conservez le mode et le registre manquants comme non résolus ; obtenez la tonique et la forme de gamme visées ainsi que la politique de registre avant de renvoyer des notes absolues. Le nombre d’altérations à l’armure seul ne suffit pas.

## 4. Interpréter une syllabe selon son vocabulaire déclaré

Posons un vocabulaire syllabique relatif majeur où do, re et mi sont les degrés 1, 2 et 3 au-dessus de la tonique D4. Il donne `[62,64,66]`. Posons séparément un vocabulaire fixe de noms de notes naturelles au registre 4, où ces mêmes syllabes désignent C4, D4 et E4, donnant `[60,62,64]`.

Ce sont des contrôles explicitement déclarés, pas un dictionnaire universel de syllabes ni une attribution de systèmes à des pays. Un « do » sans précision ne fournit ni le vocabulaire visé ni un registre absolu. Ce dossier définit seulement les degrés de 1 à 7 ; le degré 8 sort du vocabulaire choisi, sauf si une extension est précisée.

### Exercice 4 : distinguer les deux demandes

Résolvez do, re et mi selon les deux contrôles déclarés. Que doit-il se passer pour un do non précisé ou un degré 8 ? Rejeter le degré 8 ici signifie-t-il qu’aucun système musical ne peut l’utiliser ?

> **Réponse:** Le contrôle relatif majeur donne `[62,64,66]` ; le contrôle à noms naturels fixes donne `[60,62,64]`. Un do non précisé nécessite sa convention et son registre ; le degré 8 sort de cette interface déclarée à sept degrés. Cette limite est un choix de conception circonscrit, pas une interdiction universelle des notations de degrés étendues.

## 5. Lire ce que conservent les interfaces sélectionnées de GA

L’[analyseur de tonalité MusicXML](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L140-L153) à la révision fixée stocke le nombre de quintes et une chaîne de mode facultative. Le code sélectionné ne résout pas ce vocabulaire de degrés. L’[analyseur de hauteurs](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs#L5-L8), distinct, attend une lettre absolue, un unique dièse ou bémol facultatif et une octave. À cette révision, ses motifs sont ancrés ; ce fait ne doit pas être projeté sur une autre révision utilisée dans une leçon antérieure.

### Exercice 5 : préparer un transfert d’étiquettes avec l’aide des sources

Lisez ces interfaces et le [relevé fixé des degrés](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/capo-spelling-2026-10-22/degree-context.json). Précisez ce qu’un agent proposé devrait conserver avant de traduire un degré de gamme ou une syllabe en hauteur absolue.

> **Réponse:** Conservez le jeton d’origine, le vocabulaire déclaré, l’identité et le registre de la tonique, la forme exacte de la gamme, la politique de sens et d’étendue, la convention d’accordage, l’orthographe visée et la révision du code. Préservez les entrées non résolues ou non prises en charge au lieu de leur attribuer une note plausible. Les interfaces sélectionnées de hauteur absolue et de stockage de tonalité ne prouvent pas l’existence d’un résolveur de syllabes implémenté. Comparez un contexte typé explicite et une recherche dans une table avant de proposer un nouveau DSL ; les revues par des musiciens, linguistiques, avec des apprenants et dans l’application réelle restent à effectuer.
