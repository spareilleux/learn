---
title: TypeScript avancé — Mission
description: Le système de types, l'outillage et TypeScript à grande échelle, pour les développeurs qui écrivent du TypeScript strict tous les jours — chaque test de types, erreur de compilation et exemple est vérifié par tsc 7.0.2 et exécuté par Node.js 24, avec en regard le côté C# et Java, sur le front end et le hub de Guitar Alchemist.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque sortie des leçons vient de [`code/typescript-advanced`](https://github.com/spareilleux/learn/tree/main/code/typescript-advanced), qui a son propre `package.json` et son propre fichier de verrouillage : [TypeScript](https://www.typescriptlang.org/) **7.0.2**, `@types/node` 24.13.4, [Zod](https://zod.dev/) 4.6.5, [Valibot](https://valibot.dev/) 1.5.0, [ArkType](https://arktype.io/) 2.2.3, `@standard-schema/spec` 1.1.0 et [esbuild](https://esbuild.github.io/) 0.28.2. [`check.sh`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/check.sh) exécute `tsc` sur le projet, dont les tests de types doivent passer, et sur chaque extrait d'erreur pris seul ; exécute chaque exemple et chaque solution avec [Node.js](https://nodejs.org/) 24.21.0 ; construit un bundle du même schéma avec chaque bibliothèque de validation ; compile et exécute les comparaisons C# et Java ; et compare le tout avec les fichiers de `expected/`. Un workflow qui fait la même chose sous Linux, Windows et macOS est écrit et n'a pas encore tourné (*à vérifier*). Sorties capturées en septembre 2026.
:::

## Pourquoi j'apprends ça

Après le cours [TypeScript pour développeurs C#/Java](../typescript-for-csharp-java/), je sais lire et écrire du TypeScript strict. Ce que je ne sais pas encore faire, c'est lire les types dont sont faites les bibliothèques : un schéma Zod dont le type est calculé à partir de sa définition, un routeur qui connaît les paramètres d'un chemin à partir de la chaîne du chemin, un émetteur d'événements qui vérifie le nom d'un événement et la forme de sa charge utile. Ces types sont des programmes, exécutés par le vérificateur, et ils ont leur propre flot de contrôle, leur propre récursion et leurs propres limites.

L'autre moitié, c'est ce qui se passe autour du vérificateur : ce que promet un type quand les données arrivent d'un socket, comment un grand projet est compilé, ce que disent les fichiers de déclaration d'un package, et ce qui a changé quand le compilateur a été réécrit en Go. Ce cours démonte chacun de ces points, sur du vrai code : le front end de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) et le hub SignalR avec lequel il communique.

## À qui s'adresse ce cours

Tu écris du TypeScript avec `strict` activé, et tu es à l'aise avec les unions, le *narrowing*, les génériques, `keyof` et un premier type mappé, soit les leçons 2 à 4 du cours de base. Tu connais bien C# ou Java, puisque les comparaisons se font avec eux. Tu n'as pas besoin d'avoir déjà écrit un type conditionnel ou un fichier de déclaration.

Le cours de base présente chaque outil là où un développeur C# ou Java en a besoin pour la première fois. Ce cours suppose que tu t'en sers, et regarde comment le vérificateur les évalue, où ils cessent de fonctionner, et comment les bibliothèques sont construites dessus. Les composants, JSX et le DOM appartiennent au cours [React (Vite)](../react-vite/).

## TypeScript avancé en un tableau

| | C# | Java | TypeScript |
|---|---|---|---|
| Calculer un type à partir d'un autre | générateurs de source, T4 | processeurs d'annotations | types conditionnels, mappés et *template literal types*, exécutés par le vérificateur |
| Une chaîne qui porte un type | non : un objet clé typé | non : un jeton `Class<T>` | un type littéral : `'NodeChanged'` est un type |
| Variance déclarée | `in`/`out` sur les interfaces et les délégués, vérifiés | `? extends`, `? super` au point d'utilisation | mesurée à partir de la structure ; `in`/`out` facultatifs, partiellement vérifiés |
| Un wrapper nominal | `readonly record struct`, sans allocation | un record, un objet | un brand, effacé : coût nul, aucune vérification à l'exécution |
| Vérifier les données venues de l'extérieur | les types existent à l'exécution : `System.Text.Json` peut les vérifier | Jackson, Bean Validation | une bibliothèque de schémas, dont le type est dérivé du schéma |
| Échecs attendus | exceptions, ou un type résultat | exceptions vérifiées | une union résultat, et des exceptions pour les bugs |

## Les données

Les leçons utilisent [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381) : la bibliothèque de composants [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381/ReactComponents/ga-react-components), en particulier sa vue de gouvernance Prime Radiant, et le hub C# qui l'alimente, [`Apps/ga-server/GaApi/Hubs/GovernanceHub.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c866c126338b332e384e4a615cd4b44381/Apps/ga-server/GaApi/Hubs/GovernanceHub.cs). Les leçons réduisent les lignes qu'elles citent à des fichiers qui s'exécutent seuls, et indiquent d'où vient chacune. Le code source du vérificateur lui-même est cité depuis [microsoft/typescript-go](https://github.com/microsoft/typescript-go) au tag `typescript/v7.0.2` (commit [`2bd066d`](https://github.com/microsoft/typescript-go/tree/2bd066d87f5bafd315be9f40889d0a60b9e58e0b)). Ce que les leçons ont trouvé dans GA se trouve dans le [journal](journal/).

## À la fin de ce cours, je saurai

- écrire et tester des types qui calculent d'autres types : types conditionnels, `infer`, types mappés avec remappage des clés, *template literal types*, types récursifs, et connaître les limites auxquelles le vérificateur abandonne ;
- prédire la variance que mesure `tsc`, repérer où elle n'est pas sûre, et contrôler l'inférence avec `satisfies`, les paramètres de type `const` et `NoInfer` ;
- modéliser un domaine pour que les erreurs soient des erreurs de compilation : brands, types opaques, unions sans états impossibles, machines à états typées ;
- vérifier les données à la frontière du programme avec une bibliothèque de schémas, et renvoyer des erreurs typées au lieu de les lever ;
- écrire et publier des fichiers de déclaration, configurer la résolution des modules pour Node.js et les bundlers, et publier un package pour ESM et CommonJS ;
- compiler un grand projet avec des références de projet, mesurer où le vérificateur passe son temps, et faire passer un projet à TypeScript 7 ;
- utiliser les décorateurs standard, l'API du compilateur et des règles de lint typées, et tester les types en CI ;
- lire comment sont construites les bibliothèques typées : builders, API fluides, routes typées et query builders.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Programmation au niveau des types](01-type-level-programming/) | génériques, résolution des surcharges, générateurs de source |
| 2 | [Variance et assignabilité](02-variance-and-assignability/) | `IEnumerable<out T>`, wildcards, inférence de type |
| 3 | [Modéliser avec les types](03-modeling-with-types/) | records, value objects, hiérarchies scellées, le pattern État |
| 4 | [Frontières à l'exécution : schémas et erreurs typées](04-runtime-borders/) | `System.Text.Json`, Jackson, Bean Validation, exceptions |
| 5 | Fichiers de déclaration : `.d.ts`, `declare module`, augmentation de module et augmentation globale, typer une bibliothèque JavaScript, DefinitelyTyped | assemblies de référence, fichiers de documentation XML |
| 6 | Modules et résolution : `moduleResolution` `nodenext` et `bundler`, `exports` et `imports`, packages doubles ESM/CommonJS, `isolatedDeclarations`, `verbatimModuleSyntax` | chargement des assemblies, le module path de Java |
| 7 | À grande échelle : références de projet, `tsc -b`, workspaces npm et pnpm, `--generateTrace`, les performances du vérificateur | solutions, builds incrémentaux, builds Maven multimodules |
| 8 | Décorateurs : le standard ECMAScript, les métadonnées, et ce qui a changé depuis `experimentalDecorators` | attributs, annotations |
| 9 | L'API du compilateur et l'outillage : transformations, le language service, une règle typescript-eslint typée | analyseurs Roslyn, processeurs d'annotations |
| 10 | Le compilateur natif : TypeScript 7, ce qui a changé, la compatibilité, des mesures | le passage des compilateurs du .NET Framework à Roslyn |
| 11 | Tests de types : `expect-type`, `tsd`, `vitest --typecheck` | tests d'une API publique, tests d'analyseurs |
| 12 | Patterns de bibliothèques : builders typés, API fluides, inférence des routes, query builders typés | LINQ, Entity Framework, jOOQ |
| — | [Journal](journal/) | |

Les leçons 5 à 12 sont prévues et pas encore écrites.

## Prérequis

- [Node.js 24](https://nodejs.org/) et [Git](https://git-scm.com/downloads). Sous Windows, exécute le script du cours depuis Git Bash : `npm ci`, puis `bash check.sh` dans `code/typescript-advanced`.
- Le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) et un [JDK 25](https://openjdk.org/projects/jdk/25/), seulement pour les comparaisons ; `check.sh` les saute quand `dotnet` ou `java` manque.

## Cours liés sur ce site

- [TypeScript pour développeurs C#/Java](../typescript-for-csharp-java/) : le langage sur lequel ce cours s'appuie.
- [JavaScript pour développeurs C#/Java](../javascript-for-csharp-java/) : ce qui s'exécute une fois les types effacés.
- [C# avancé](../csharp-advanced/) : le même genre de cours pour C#, sur le même dépôt de GA.

## Ressources

- Le [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html), en particulier [Type Manipulation](https://www.typescriptlang.org/docs/handbook/2/types-from-types.html), et la [référence TSConfig](https://www.typescriptlang.org/tsconfig/).
- Les [notes de version de TypeScript](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html) : la plupart des fonctionnalités de ce cours sont arrivées dans une version entre 4.1 et 5.4, et chaque leçon renvoie à celle qui les a introduites.
- [microsoft/typescript-go](https://github.com/microsoft/typescript-go), le compilateur en Go, dont `internal/checker/checker.go` contient les limites citées dans la leçon 1, et [microsoft/TypeScript](https://github.com/microsoft/TypeScript), le compilateur en TypeScript jusqu'à la version 6.
- [Standard Schema](https://standardschema.dev/), l'interface commune aux bibliothèques de validation de la leçon 4.
- [ECMAScript® Language Specification](https://tc39.es/ecma262/), et [Node.js 24 — Modules : TypeScript](https://nodejs.org/docs/latest-v24.x/api/typescript.html).
