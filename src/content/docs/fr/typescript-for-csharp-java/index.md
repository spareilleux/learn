---
title: TypeScript pour développeurs C#/Java — Mission
description: TypeScript pour les développeurs qui connaissent C# ou Java et ont suivi le cours JavaScript — chaque exemple, erreur de compilation et solution est vérifié par tsc 7.0.2 et exécuté par Node.js 24 en CI sous Windows, Linux et macOS, avec en regard le côté C# et Java.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée]
[TypeScript](https://www.typescriptlang.org/) **7.0.2**, la première version stable du compilateur porté en Go, publiée le 2026-07-08, et [Node.js](https://nodejs.org/) **24.21.0**, dont la suppression des types (*type stripping*) exécute les fichiers `.ts` du cours sans étape de build. Chaque exemple se trouve dans [`code/typescript-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/typescript-for-csharp-java), avec son propre `package.json` et un fichier de verrouillage qui fixent `typescript` 7.0.2, `@types/node` 24.13.4 et tsx 4.23.13. [`.github/workflows/typescript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/typescript-examples.yml) installe Node.js 24.21.0, .NET 10 et Java 25 sous Linux, Windows et macOS, exécute `tsc` sur le projet et sur chaque extrait d'erreur, exécute chaque exemple et solution avec Node.js, compile les comparaisons C# et Java, et compare toutes les sorties avec celles collées dans les leçons.
:::

## Pourquoi j'apprends ça

Les front ends de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) sont écrits en TypeScript, tout comme les fichiers de configuration de ce site. Je lis ce code en développeur C#, et il ressemble à du C# avec les types au mauvais endroit, jusqu'au moment où ce n'est plus le cas : un objet est accepté là où une classe était attendue, un cast ne convertit rien, un générique n'a pas de `T` à l'exécution, et un programme qui a des erreurs de type s'exécute quand même.
Le [cours JavaScript](../javascript-for-csharp-java/) a couvert ce qui se passe à l'exécution. Celui-ci couvre ce que `tsc` vérifie, ce qu'il ne peut pas vérifier, et l'endroit où les deux se rejoignent.

## À qui s'adresse ce cours

Tu es à l'aise avec C# ou Java, y compris les génériques, les interfaces et les types référence nullables ou `Optional`, et tu as suivi le cours [JavaScript pour développeurs C#/Java](../javascript-for-csharp-java/), ou tu connais son contenu : modules et npm, valeurs et conversions, fonctions et `this`, prototypes et classes. Les leçons renvoient à ses pages au lieu de réexpliquer JavaScript.

Les composants, JSX et le DOM appartiennent au cours **React (Vite)** qui suit celui-ci. Ce cours exécute TypeScript dans Node.js, où chaque exemple peut être vérifié et exécuté en CI, et ne regarde le code React que comme des données tirées du dépôt de GA.

## TypeScript en un tableau

| | C# | Java | TypeScript |
|---|---|---|---|
| Compilateur | `csc`, via `dotnet build` | `javac` | `tsc`, qui vérifie et peut écrire du JavaScript |
| Fichier de projet | `.csproj` | `pom.xml`, `build.gradle` | `tsconfig.json`, à côté de `package.json` |
| Types à l'exécution | réifiés : `typeof(T)`, `is T` | génériques effacés, casts vérifiés | aucun : chaque type est effacé, casts compris |
| Compatibilité | nominale : héritage déclaré | nominale | structurelle : la même forme est le même type |
| Une erreur de type | arrête le build | arrête le build | n'arrête rien, sauf si le build fait appel à `tsc` |
| Valeur absente | `string?` avec des avertissements | `Optional<T>`, annotations | `string \| undefined`, des erreurs sous `strictNullChecks` |
| Un cas parmi plusieurs | hiérarchie de classes, `switch` avec motifs | `sealed interface`, `switch` avec motifs | types union et *narrowing*, le rétrécissement du type |
| Génériques | réifiés, variance sur les interfaces | effacés, wildcards | effacés, variance structurelle, types calculés à partir de types |

## Les données

Les leçons prennent du vrai code comme matériau. [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) est cité au commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), dans ses deux front ends React, [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) et [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client), que j'ai installés et vérifiés avec `tsc` 5.9.3 et 7.0.2. Ce site, construit avec [Astro](https://docs.astro.build/), est l'autre projet TypeScript, au commit [`8ba378e`](https://github.com/spareilleux/learn/commit/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3). Les leçons réduisent les lignes qu'elles citent à des fichiers qui s'exécutent seuls, et indiquent d'où vient chacune. Ce que `tsc` a trouvé dans ces projets se trouve dans le [journal](journal/).

## À la fin de ce cours, je saurai

- configurer un projet TypeScript pour Node.js, lire son `tsconfig.json`, et faire échouer le build sur les erreurs de type ;
- lire un diagnostic de `tsc` et relier son code à ce qu'auraient dit C# ou Java ;
- prédire quand deux types sont compatibles, et donner un nom à un type quand la structure ne suffit pas ;
- modéliser des données sous forme d'unions, les restreindre, et obtenir une erreur de compilation quand un cas manque ;
- vérifier à la frontière les données venues de l'extérieur du programme, au lieu d'affirmer leur type ;
- écrire des fonctions et des types génériques, et expliquer pourquoi `new T()` et `instanceof T` n'existent pas ;
- calculer des types à partir d'autres types avec `keyof`, les types mappés et les types conditionnels ;
- typer une bibliothèque JavaScript, un package Node.js et un front end construit avec Vite, et migrer un projet JavaScript vers `strict`.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Le compilateur et l'outillage](01-compiler-and-tooling/) | `csc`, `javac`, `.csproj`, les avertissements et les erreurs du compilateur |
| 2 | [Typage structurel](02-structural-typing/) | interfaces, `var`, `readonly`/`final`, `object`, `dynamic`, types référence nullables |
| 3 | [Unions et narrowing](03-unions-and-narrowing/) | hiérarchies de classes, `switch` avec motifs, interfaces scellées, casts |
| 4 | [Génériques](04-generics/) | `List<T>`, contraintes, `IEnumerable<out T>`, wildcards, effacement de type |
| 5 | Programmation au niveau des types : types conditionnels, `infer`, *template literal types* et `satisfies` (à venir) | résolution des surcharges, `typeof`, attributs |
| 6 | Les classes en TypeScript : modificateurs, `abstract`, `implements`, décorateurs | classes, modificateurs d'accès, attributs et annotations |
| 7 | Modules et fichiers de déclaration : `.d.ts`, `@types`, `declare module`, typer du JavaScript avec JSDoc | assemblies de référence, `extern`, métadonnées des JAR |
| 8 | Code asynchrone et erreurs : `Promise<T>`, erreurs typées, types résultat | `Task<T>`, exceptions, `CompletableFuture`, exceptions vérifiées |
| 9 | Les données à la frontière : `fetch`, JSON, validation par schéma et types générés depuis OpenAPI | `System.Text.Json`, Jackson, NSwag, OpenAPI Generator |
| 10 | Tester le code et les types : Vitest, `@ts-expect-error`, tests de types | xUnit, JUnit, analyseurs |
| 11 | Projets à grande échelle : références de projet, `tsc -b`, monorepos, typescript-eslint | solutions, builds Maven multimodules, analyseurs |
| 12 | Migrer vers `strict` : les front ends de GuitarAlchemist/ga, et de TypeScript 6 à 7 | activer les types référence nullables sur un projet existant |
| — | [Journal](journal/) | |

## Ressources

- Le [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) et la [référence TSConfig](https://www.typescriptlang.org/tsconfig/)
- Les [notes de version de TypeScript](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html), et l'[annonce de TypeScript 7](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/)
- [microsoft/TypeScript](https://github.com/microsoft/TypeScript), dont [`diagnosticMessages.json`](https://github.com/microsoft/TypeScript/blob/v6.0.3/src/compiler/diagnosticMessages.json) liste chaque code d'erreur, et [microsoft/typescript-go](https://github.com/microsoft/typescript-go), le portage en Go
- [Node.js 24 — Modules : TypeScript](https://nodejs.org/docs/latest-v24.x/api/typescript.html)
- [ECMAScript® Language Specification](https://tc39.es/ecma262/), le langage auquel TypeScript ajoute des types
