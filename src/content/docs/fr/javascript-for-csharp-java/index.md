---
title: JavaScript pour développeurs C#/Java — Mission
description: JavaScript pour les développeurs qui connaissent C# ou Java et ne veulent plus être surpris — chaque exemple, erreur et solution est exécuté avec Node.js 24 en CI sous Windows, Linux et macOS, avec en regard le côté C# et Java.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée]
[Node.js](https://nodejs.org/) **24.21.0**, la version actuelle à support long terme (« Krypton », LTS depuis octobre 2025), avec son moteur [V8](https://v8.dev/) 13.6 et [npm](https://docs.npmjs.com/) 11.19. Le langage lui-même est [ECMAScript](https://tc39.es/ecma262/), le standard qu'implémentent les navigateurs et Node.js. Chaque exemple de ce cours se trouve dans [`code/javascript-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/javascript-for-csharp-java), à côté de sa sortie attendue. [`.github/workflows/javascript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/javascript-examples.yml) installe Node.js 24.21.0, .NET 10 et Java 25 sous Linux, Windows et macOS, exécute chaque exemple, snippet d'erreur et solution, et compare les sorties avec celles collées dans les leçons.
:::

## Pourquoi j'apprends ça

J'écris du C# et je lis beaucoup de Java, et j'écris du JavaScript quand je n'ai pas le choix : un script de build, un composant du front end de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), la configuration de ce site.
À chaque fois, la syntaxe paraît assez familière pour que je cesse d'y prêter attention, et puis quelque chose me surprend : un `0` qui devient `0.5`, une méthode qui perd son objet, une copie qui n'en est pas une.
Je veux apprendre les règles derrière ces surprises, à partir de la spécification et de Node.js lui-même, au lieu de les collectionner un bug à la fois.

## À qui s'adresse ce cours

Tu es à l'aise avec C# ou Java : classes, interfaces, génériques, exceptions, collections, [LINQ](https://learn.microsoft.com/dotnet/csharp/linq/) ou [streams](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/package-summary.html).
Tu as lu ou écrit un peu de JavaScript, et il t'a surpris. Chaque leçon part de ce que tu connais déjà, montre où JavaScript est d'accord et où il diffère, et affiche ce que dit Node.js, y compris ses erreurs.

Ce cours sert de base à deux autres. Les types statiques appartiennent au futur cours **TypeScript pour développeurs C#/Java**, si bien que celui-ci ne mentionne TypeScript que là où il ne change rien à l'exécution. Le DOM, JSX et les composants appartiennent au cours **React (Vite)** qui suit TypeScript, si bien que ce cours exécute JavaScript dans Node.js et ne regarde le navigateur que comme un autre hôte.

## JavaScript en un tableau

| | C# | Java | JavaScript |
|---|---|---|---|
| Spécification | [Spécification du langage C#](https://learn.microsoft.com/dotnet/csharp/language-reference/language-specification/readme) | [Java Language Specification](https://docs.oracle.com/javase/specs/jls/se25/html/index.html) | [ECMAScript](https://tc39.es/ecma262/), une nouvelle édition chaque mois de juin |
| S'exécute sur | le CLR, après compilation en IL | la JVM, après compilation en bytecode | un moteur qui analyse le source : V8 dans Chrome et Node.js, SpiderMonkey dans Firefox, JavaScriptCore dans Safari |
| Types | statiques | statiques | dynamiques : les valeurs ont des types, les variables non |
| Nombres | `int`, `long`, `double`, `decimal`… | `int`, `long`, `double`… | `number` (un `double`) et `bigint` |
| Valeur absente | `null` | `null` | `undefined` et `null` |
| Objets | instances de classes | instances de classes | sacs de propriétés reliés à un prototype ; `class` s'appuie dessus |
| Gestionnaire de packages | NuGet | Maven, Gradle | npm (ou pnpm, Yarn) |
| Fichier de projet | `.csproj` | `pom.xml`, `build.gradle` | `package.json` |
| Modules | assemblies et espaces de noms | packages et modules | un module par fichier, modules ES ou CommonJS |

## Les données

Les leçons prennent du vrai code comme matériau. Quand une leçon cite [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), c'est au commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), dans les front ends React [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) et [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client). Ces fichiers sont en TypeScript ; les leçons réduisent les lignes qu'elles citent à du JavaScript simple, qui est ce qui s'exécute une fois les types retirés. Ce site, construit avec [Astro](https://docs.astro.build/), est l'autre vrai projet JavaScript que regardent les leçons.

## À la fin de ce cours, je saurai

- installer Node.js sous Windows, Linux et macOS, exécuter un fichier, et gérer un projet avec npm ;
- dire si un fichier est un module ES ou un module CommonJS, et faire fonctionner les deux ensemble ;
- prédire ce que font `==`, `+`, `||` et `if` avec n'importe quelle paire de valeurs, et choisir l'opérateur qui ne surprend pas ;
- dire ce qu'est `this` dans n'importe quel appel, et le conserver dans un callback ;
- utiliser les prototypes et les classes, et copier et comparer des objets en connaissance de cause ;
- écrire du code asynchrone avec les promesses et `async`/`await`, et expliquer la boucle d'événements ;
- tester, déboguer et publier un package Node.js.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Node.js, npm et modules](01-node-npm-modules/) | `dotnet run`, NuGet, `java`, Maven, espaces de noms |
| 2 | [Valeurs et types](02-values-and-types/) | `var`, `readonly`/`final`, `double`, `null`, `Equals` |
| 3 | [Fonctions, portée, closures et `this`](03-functions-and-scope/) | méthodes, lambdas, délégués, variables capturées |
| 4 | [Objets, prototypes et classes](04-objects-prototypes-classes/) | classes, héritage, propriétés, records |
| 5 | Tableaux, itération et collections (à venir) | `List<T>`, LINQ, streams, `Dictionary`, `HashMap`, `IEnumerable`, itérateurs |
| 6 | Erreurs et exceptions | `try`/`catch`/`finally`, types d'exceptions, `using` et try-with-resources |
| 7 | JavaScript asynchrone : la boucle d'événements, les promesses, `async`/`await` | `Task`, `async`/`await`, `CompletableFuture` |
| 8 | La bibliothèque standard de Node.js : fichiers, chemins, streams et processus | `System.IO`, `java.nio.file`, `Process` |
| 9 | Tests et débogage : `node:test`, l'inspecteur, ESLint | xUnit, JUnit, les débogueurs de Visual Studio et d'IntelliJ, analyseurs |
| 10 | npm en profondeur : versions, fichiers de verrouillage, workspaces, `exports` et publication | NuGet et Maven Central |
| 11 | Texte, expressions régulières, dates et `Intl` | `Regex`, `DateTime`, `java.time`, `CultureInfo` |
| 12 | De Node.js au navigateur : modules de script, `fetch` et bundlers | fichiers statiques ASP.NET, un build front end |
| — | [Journal](journal/) | |

## Ressources

- [ECMAScript® Language Specification](https://tc39.es/ecma262/), le brouillon évolutif ; les [éditions publiées par Ecma](https://ecma-international.org/publications-and-standards/standards/ecma-262/)
- [MDN — référence JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference) et [guide JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide)
- [Documentation de Node.js 24](https://nodejs.org/docs/latest-v24.x/api/)
- [Documentation de npm](https://docs.npmjs.com/)
- [Calendrier des versions de Node.js](https://github.com/nodejs/Release#release-schedule)
