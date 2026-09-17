---
title: React (Vite) pour développeurs C#/Java — Mission
description: React 19 avec TypeScript et Vite 8 pour les développeurs qui connaissent C# ou Java, Blazor, WPF ou JavaFX, et ont suivi les cours JavaScript et TypeScript — chaque composant, erreur de compilation et test est vérifié par tsc 7, construit par Vite et exécuté par Vitest en CI sous Windows, Linux et macOS.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée]
[React](https://react.dev/) **19.3.0**, publié en septembre 2026, construit avec [Vite](https://vite.dev/) **8.3.0** et [`@vitejs/plugin-react`](https://github.com/vitejs/vite-plugin-react/tree/b0a014da31be23c7806ffb0b997ec53b52ab68f2/packages/plugin-react) 6.1.1, vérifié avec [TypeScript](https://www.typescriptlang.org/) 7.0.2 et testé avec [Vitest](https://vitest.dev/) 5.0.0, [React Testing Library](https://testing-library.com/docs/react-testing-library/intro) 16.3.3 et jsdom 30.0.1, sur [Node.js](https://nodejs.org/) 24.21.0. L'application du cours se trouve dans [`code/react-vite`](https://github.com/spareilleux/learn/tree/3f7a5df/code/react-vite), avec son propre `package.json` et un fichier de verrouillage qui fixent ces versions et [oxlint](https://oxc.rs/docs/guide/usage/linter) 1.83.0. [`.github/workflows/react-vite-examples.yml`](https://github.com/spareilleux/learn/blob/f6417a9/.github/workflows/react-vite-examples.yml) exécute [`check.sh`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/check.sh) sous Linux, Windows et macOS : il génère un projet avec `create-vite`, démarre le serveur de développement et reçoit une mise à jour à chaud, vérifie l'application et chaque extrait d'erreur avec `tsc`, la construit avec Vite, la passe au linter, exécute chaque fichier Vitest, et compare toutes les sorties avec celles collées dans les leçons.
:::

## Pourquoi j'apprends ça

Les front ends de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) sont des applications React construites avec Vite. Le [cours TypeScript](../typescript-for-csharp-java/) a lu leurs types ; ce cours lit leurs composants. En développeur C#, je connais Blazor et XAML, où un composant est une classe avec des propriétés, le framework garde ses champs, et un binding met l'écran à jour. React a l'air semblable au début, puis un composant se révèle être une fonction qui s'exécute à nouveau à chaque changement, une liste a besoin de clés, un objet dans l'état doit être remplacé au lieu d'être modifié, et deux composants innocents peuvent se rendre l'un l'autre à l'infini.

## À qui s'adresse ce cours

Tu es à l'aise avec C# ou Java, et avec au moins un framework d'interface parmi [Blazor](https://learn.microsoft.com/aspnet/core/blazor/), [WPF](https://learn.microsoft.com/dotnet/desktop/wpf/overview/) ou [JavaFX](https://openjfx.io/). Tu as suivi [JavaScript pour développeurs C#/Java](../javascript-for-csharp-java/) et [TypeScript pour développeurs C#/Java](../typescript-for-csharp-java/), ou tu connais leur contenu : modules et npm, fonctions et closures, objets et tableaux, types structurels, unions et narrowing, génériques. Les leçons renvoient à leurs pages au lieu de réexpliquer le langage. Ce cours parle des composants, de JSX, du DOM, et des outils qui les construisent et les testent.

## React (Vite) en un tableau

| | Blazor | WPF / XAML | JavaFX | React avec Vite |
|---|---|---|---|---|
| Un composant | un fichier `.razor`, compilé en classe | un `UserControl` : XAML et code-behind | une sous-classe de `Node`, ou FXML et un contrôleur | une fonction qui renvoie du JSX |
| Balisage | Razor | XAML | FXML | JSX, compilé en appels de fonction |
| Entrées | des propriétés `[Parameter]` | des propriétés de dépendance | des propriétés JavaFX | les props, un seul objet |
| État local | des champs, rendus à nouveau après un gestionnaire d'événement | des propriétés avec `INotifyPropertyChanged` | des propriétés observables | `useState`, une valeur par rendu |
| Mettre l'écran à jour | un arbre de rendu comparé au précédent | les bindings mettent les contrôles à jour | bindings et écouteurs | rendre à nouveau, comparer, appliquer les différences |
| Binding bidirectionnel | `@bind` | `{Binding Mode=TwoWay}` | `bindBidirectional` | aucun : `value` et `onChange` |
| Build | MSBuild | MSBuild | Maven ou Gradle | Vite : un serveur de développement, et Rolldown pour la production |
| Tests de composants | [bUnit](https://bunit.dev/) | automatisation d'interface | [TestFX](https://github.com/TestFX/TestFX) | Vitest et Testing Library |

## Les données

Les leçons s'appuient sur du vrai code. [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) est cité au commit [`8cc8c5a`](https://github.com/GuitarAlchemist/ga/commit/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41), dans [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components), son application React principale, et dans [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/Apps/ga-client), que son propre script `dev` appelle l'ancien client de démonstration. Les deux demandent React 18.3 et Vite 5.4 dans leur `package.json` ; `Apps/ga-dashboard` est une application Angular, hors du champ de ce cours. J'ai lu leurs composants, lancé sur eux les règles React d'oxlint, et réduit ce que j'ai trouvé à des composants que les tests du cours rendent, avec un lien vers les lignes d'origine. Les constats sont dans le [journal](journal/).

## À la fin de ce cours, je saurai

- créer un projet React avec Vite, expliquer ce que font son serveur de développement et son build de production, et faire échouer le build sur les erreurs de type ;
- écrire des composants fonctions typés, les composer avec des props et des enfants, et rendre des listes avec des clés stables ;
- garder un état minimal, le mettre à jour sans mutation, et expliquer quand et pourquoi React rend à nouveau un composant ;
- gérer les événements et construire des formulaires contrôlés avec validation ;
- synchroniser un composant avec le monde extérieur grâce aux effets, et reconnaître les effets qui ne devraient pas exister ;
- charger des données avec des états de chargement et d'erreur, l'annulation et la mise en cache ;
- partager l'état avec le contexte et des hooks personnalisés, et naviguer entre les pages ;
- tester les composants comme un utilisateur s'en sert, et mesurer et améliorer les performances de rendu ;
- déployer une application React statique devant une API ASP.NET Core ou Spring.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Un projet Vite](01-vite-project/) | `dotnet new`, `dotnet watch`, MSBuild, Maven, le rechargement à chaud |
| 2 | [Composants et JSX](02-components-and-jsx/) | les composants Blazor, les user controls XAML, `[Parameter]`, `RenderFragment`, `@foreach` |
| 3 | [État et rendu](03-state-and-rendering/) | les champs, `StateHasChanged`, `INotifyPropertyChanged`, les records immuables |
| 4 | [Événements et formulaires](04-events-and-forms/) | les gestionnaires d'événements, `EventCallback`, `@bind`, `EditForm`, les attributs de validation |
| 5 | Les effets : `useEffect`, les dépendances, le nettoyage, le double montage du Strict Mode, et quand ne pas utiliser d'effet (la prochaine) | `IDisposable`, `OnAfterRenderAsync`, les abonnements aux événements |
| 6 | Les données : `fetch`, états de chargement et d'erreur, annulation, Suspense, TanStack Query | `HttpClient`, `CancellationToken`, `async` dans `OnInitializedAsync` |
| 7 | La composition : le contexte, les hooks personnalisés, props contre contexte contre store | l'injection de dépendances, les paramètres en cascade, les services |
| 8 | Le routage avec React Router | `@page` et `NavigationManager` de Blazor, le routage d'ASP.NET Core |
| 9 | Les tests : Vitest, Testing Library, tests de composants, Playwright de bout en bout | xUnit, bUnit, JUnit, Selenium |
| 10 | Les performances : React Compiler, `memo`, le Profiler, le découpage du bundle | les profileurs, la virtualisation, le chargement différé |
| 11 | Styles et accessibilité : CSS Modules, ARIA, règles de lint | les styles XAML, l'isolation CSS de Blazor, les analyseurs |
| 12 | React 19 : les Actions, `use`, les Server Components, et ce qui s'applique à une SPA Vite | Razor Pages, les modes de rendu de Blazor |
| 13 | Le déploiement : un build statique, les variables d'environnement, GitHub Pages, et une API ASP.NET Core ou Spring derrière | `dotnet publish`, la configuration, les reverse proxies |
| — | [Journal](journal/) | |

## Ressources

- [react.dev](https://react.dev/) : [Learn React](https://react.dev/learn), la [référence de l'API](https://react.dev/reference/react), et [Using TypeScript](https://react.dev/learn/typescript)
- [L'annonce de React 19.3](https://react.dev/blog/2026/09/09/react-19-3) et le [changelog de React](https://github.com/facebook/react/blob/main/CHANGELOG.md)
- [Le guide de Vite](https://vite.dev/guide/), [Why Vite](https://vite.dev/guide/why), et l'[annonce de Vite 8](https://vite.dev/blog/announcing-vite8)
- [Le guide de Vitest](https://vitest.dev/guide/) et [React Testing Library](https://testing-library.com/docs/react-testing-library/intro)
- [Le manuel TypeScript — JSX](https://www.typescriptlang.org/docs/handbook/jsx.html) et [`@types/react`](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/28fd9030495005fd55f5a7eb3523a84046af8a01/types/react)
