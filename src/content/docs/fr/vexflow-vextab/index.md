---
title: VexTab et VexFlow — Mission
description: La notation et la tablature de guitare dans le navigateur, pour les développeurs qui connaissent C# ou Java — VexTab, un petit langage texte, et VexFlow, la bibliothèque JavaScript qui le dessine, avec chaque exemple rendu en SVG et comparé en CI sous Windows, Linux et macOS, et le code VexTab de Guitar Alchemist mis à l'épreuve.
sidebar:
  label: Mission
  order: 0
---

:::note[Versions étudiées]
[VexTab](https://github.com/0xfe/vextab) **4.0.5**, publié sur npm le 2026-01-18 et construit à partir du commit [`3a5e00d`](https://github.com/0xfe/vextab/tree/3a5e00d858ae98934ba545f9bef5eb923e17e402) de `0xfe/vextab`, et le [VexFlow](https://www.vexflow.com/) **5.0.0** qu'il embarque, construit à partir du commit [`0ca6f88`](https://github.com/vexflow/vexflow/tree/0ca6f889545c33cce851b420c24945f6eb685aeb) de `vexflow/vexflow`, sur [Node.js](https://nodejs.org/) 24.21.0 avec [jsdom](https://github.com/jsdom/jsdom) 30.1.1 et [opentype.js](https://opentype.js.org/) 2.0.0. Le code du cours est dans [`code/vexflow-vextab`](https://github.com/spareilleux/learn/tree/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab), avec son propre `package.json` et son fichier de verrouillage qui épinglent exactement ces versions. [`.github/workflows/vexflow-vextab-examples.yml`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/.github/workflows/vexflow-vextab-examples.yml) lance [`check.sh`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/check.sh) sous Linux, Windows et macOS : il rend chaque exemple des leçons en SVG, garde chaque message d'erreur que lève VexTab, passe les textes de la leçon 4 dans l'analyseur F# de Guitar Alchemist, et compare le tout avec [`expected/`](https://github.com/spareilleux/learn/tree/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/expected).
:::

## Pourquoi j'apprends cela

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) montre des voicings de guitare, et un voicing se lit plus facilement en tablature que sous la forme `x-3-2-0-1-0`. On demande au chatbot de GA de joindre un bloc `vextab` à chaque doigté qu'il mentionne ; GA a une grammaire VexTab en EBNF, un analyseur et un générateur en F#, un visualiseur React, et des tests de bout en bout qui attendent un SVG. Je voulais savoir ce qu'est VexTab, ce qu'il sait écrire et ce qu'il ne sait pas écrire, et si les morceaux de GA qui le parlent sont d'accord avec l'original. La leçon 4 répond à la dernière question avec des mesures, et la réponse est surtout non.

## À qui s'adresse ce cours

Vous écrivez du C# ou du Java. Vous connaissez le JavaScript de [JavaScript pour les développeurs C#/Java](../javascript-for-csharp-java/) : modules, npm, fonctions, objets. Un peu de [React](../react-vite/) aide pour le second lot. Vous savez lire une tablature de guitare : six lignes, une par corde, des chiffres pour les frettes. La théorie musicale dont les leçons ont besoin, noms des notes, octaves, armures, est rappelée là où elle apparaît, avec des liens vers [Théorie musicale pour Guitar Alchemist](../music-theory-ga/).

## VexTab et VexFlow en un tableau

| | Ce que c'est | Ce que vous connaissez de plus proche |
|---|---|---|
| [VexFlow](https://www.vexflow.com/) | Une bibliothèque JavaScript qui dessine la notation musicale et la tablature, en SVG ou sur un canvas : portées, notes, ligatures, liaisons, bends, texte | Une API de dessin avec un moteur de mise en page, comme le `DrawingContext` de WPF plus un formateur |
| [VexTab](https://github.com/0xfe/vextab) | Un petit langage texte pour la notation et la tablature, et le JavaScript qui l'analyse et appelle VexFlow | Un DSL compilé en appels sur une API objet, comme un modèle Razor compilé en C# |
| `tabstave`, `notes`, `text`, `options` | Les quatre sortes de lignes VexTab | Les instructions du DSL |
| L'Artist | L'objet de VexTab qui transforme les lignes analysées en portées et en notes VexFlow | Le générateur de code d'un compilateur |

## À la fin de ce cours, je saurai

- écrire du VexTab pour des mélodies, des accords et des techniques de guitare, et lire les erreurs qu'il lève ;
- régler armures, chiffrages, clés et accordages, et savoir lesquels changent la notation et lesquels seulement la tablature ;
- rendre du VexTab en SVG sous Node, sans navigateur, et tester le résultat ;
- dire ce que VexTab ne sait pas exprimer, et quand descendre à VexFlow ;
- vérifier un programme qui écrit du VexTab, un chatbot ou un générateur, avec le vrai analyseur ;
- *(second lot)* dessiner la même musique avec les objets de VexFlow lui-même, la rendre en React sans redessiner à chaque jeton, et préparer un passage de VexFlow 4 à 5.

## Plan

| # | Leçon | Ce que vous connaissez déjà |
|---|---|---|
| 1 | [Première portée, première tablature](01-first-stave/) | un DSL compilé vers une API, un arbre syntaxique, `System.Xml.Linq` |
| 2 | [Techniques de guitare](02-guitar-techniques/) | la tablature que vous lisez : bends, glissés, hammer-ons, accords |
| 3 | [Armures, chiffrages, clés et accordages](03-keys-time-tunings/) | les armures, les capodastres, le drop D |
| 4 | [Étude de cas : le chatbot de GA écrit du VexTab](04-ga-chatbot-vextab/) | FParsec ou une bibliothèque de combinateurs d'analyseurs, les prompts de LLM |
| 5 | *Second lot.* `Stave`, `StaveNote`, `Voice`, `Formatter` : ce que VexTab cache, et une voix stricte qui compte les temps | la construction d'objets, une passe de mise en page |
| 6 | *Second lot.* `TabStave` et `TabNote` ; garder notation et tablature en phase | deux vues d'un même modèle |
| 7 | *Second lot.* Rendre en React sans redessiner à chaque jeton reçu en flux, et le tester avec Playwright (le `MemoizedVexTab` de GA) | `memo`, les effets, les tests de bout en bout |
| 8 | *Second lot.* Passer les composants de GA de VexFlow 4 à 5 : ce qui a changé dans l'API, les polices et la mesure du texte | une mise à jour de version majeure |
| — | [Journal](journal/) | |

## Ressources

- Le [tutoriel VexTab](https://vexflow.com/vextab/tutorial.html) de Mohit Cheppudira (0xfe), l'auteur de VexTab, et son [README](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/README.md). La grammaire est [`src/vextab.jison`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/vextab.jison).
- [Le site de VexFlow](https://www.vexflow.com/), son [dépôt](https://github.com/vexflow/vexflow/tree/0ca6f889545c33cce851b420c24945f6eb685aeb) et sa [référence d'API](https://www.vexflow.com/build/docs/).
- [SMuFL](https://w3c.github.io/smufl/latest/), la norme qui numérote les glyphes musicaux, et [Bravura](https://github.com/steinbergmedia/bravura), la police avec laquelle VexFlow 5 les dessine.
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), épinglé sur le commit [`17ccee6`](https://github.com/GuitarAlchemist/ga/tree/17ccee6885851e4b460ebd14d7f4cfb838f5541e) pour la leçon 4.
