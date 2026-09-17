---
title: React (Vite) for C#/Java developers — Mission
description: React 19 with TypeScript and Vite 8 for developers who know C# or Java, Blazor, WPF or JavaFX, and have taken the JavaScript and TypeScript courses — every component, compiler error and test checked by tsc 7, built by Vite and run by Vitest in CI on Windows, Linux and macOS.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied]
[React](https://react.dev/) **19.3.0**, released in September 2026, built with [Vite](https://vite.dev/) **8.3.0** and [`@vitejs/plugin-react`](https://github.com/vitejs/vite-plugin-react/tree/b0a014da31be23c7806ffb0b997ec53b52ab68f2/packages/plugin-react) 6.1.1, checked with [TypeScript](https://www.typescriptlang.org/) 7.0.2 and tested with [Vitest](https://vitest.dev/) 5.0.0, [React Testing Library](https://testing-library.com/docs/react-testing-library/intro) 16.3.3 and jsdom 30.0.1, on [Node.js](https://nodejs.org/) 24.21.0. The course's application is in [`code/react-vite`](https://github.com/spareilleux/learn/tree/3f7a5df/code/react-vite), with its own `package.json` and lock file that pin those versions and [oxlint](https://oxc.rs/docs/guide/usage/linter) 1.83.0. [`.github/workflows/react-vite-examples.yml`](https://github.com/spareilleux/learn/blob/f6417a9/.github/workflows/react-vite-examples.yml) runs [`check.sh`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/check.sh) on Linux, Windows and macOS: it scaffolds a project with `create-vite`, starts the dev server and receives a hot update, checks the application and every error snippet with `tsc`, builds it with Vite, lints it, runs every Vitest file, and compares all the outputs with the ones pasted in the lessons.
:::

## Why I'm learning this

The front ends of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) are React applications built with Vite. The [TypeScript course](../typescript-for-csharp-java/) read their types; this course reads their components. As a C# developer I know Blazor and XAML, where a component is a class with properties, the framework keeps its fields, and a binding updates the screen. React looks similar at first, then a component turns out to be a function that runs again on every change, a list needs keys, an object in state must be replaced instead of changed, and two innocent components can render each other forever.

## Who this course is for

You are comfortable with C# or Java, and with at least one UI framework among [Blazor](https://learn.microsoft.com/aspnet/core/blazor/), [WPF](https://learn.microsoft.com/dotnet/desktop/wpf/overview/) or [JavaFX](https://openjfx.io/). You have followed [JavaScript for C#/Java developers](../javascript-for-csharp-java/) and [TypeScript for C#/Java developers](../typescript-for-csharp-java/), or know their content: modules and npm, functions and closures, objects and arrays, structural types, unions and narrowing, generics. The lessons link to their pages instead of explaining the language again. This course is about components, JSX, the DOM, and the tools that build and test them.

## React (Vite) in one table

| | Blazor | WPF / XAML | JavaFX | React with Vite |
|---|---|---|---|---|
| A component | a `.razor` file, compiled to a class | a `UserControl`: XAML and code-behind | a `Node` subclass, or FXML and a controller | a function that returns JSX |
| Markup | Razor | XAML | FXML | JSX, compiled to function calls |
| Inputs | `[Parameter]` properties | dependency properties | JavaFX properties | props, one object |
| Local state | fields, rendered again after an event handler | properties with `INotifyPropertyChanged` | observable properties | `useState`, a value per render |
| Updating the screen | a render tree compared with the previous one | bindings update the controls | bindings and listeners | render again, compare, commit the differences |
| Two-way binding | `@bind` | `{Binding Mode=TwoWay}` | `bindBidirectional` | none: `value` and `onChange` |
| Build | MSBuild | MSBuild | Maven or Gradle | Vite: a dev server, and Rolldown for production |
| Component tests | [bUnit](https://bunit.dev/) | UI automation | [TestFX](https://github.com/TestFX/TestFX) | Vitest and Testing Library |

## The data

The lessons use real code as material. [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) is quoted at commit [`8cc8c5a`](https://github.com/GuitarAlchemist/ga/commit/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41), in [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components), its main React application, and [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/Apps/ga-client), which its own `dev` script calls the legacy demo client. Both ask for React 18.3 and Vite 5.4 in their `package.json`; `Apps/ga-dashboard` is an Angular application, outside this course. I read their components, ran oxlint's React rules on them, and reduced what I found to components that the course's tests render, with a link to the original lines. The findings are in the [journal](journal/).

## By the end of this course, I will be able to

- create a React project with Vite, explain what its dev server and its production build do, and make type errors fail the build;
- write typed function components, compose them with props and children, and render lists with stable keys;
- keep state minimal, update it without mutation, and explain when and why React renders a component again;
- handle events and build controlled forms with validation;
- synchronize a component with the outside world with effects, and recognize the effects that shouldn't exist;
- load data with loading and error states, cancellation and caching;
- share state with context and custom hooks, and route between pages;
- test components the way a user uses them, and measure and improve rendering performance;
- deploy a static React application in front of an ASP.NET Core or Spring API.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [A Vite project](01-vite-project/) | `dotnet new`, `dotnet watch`, MSBuild, Maven, hot reload |
| 2 | [Components and JSX](02-components-and-jsx/) | Blazor components, XAML user controls, `[Parameter]`, `RenderFragment`, `@foreach` |
| 3 | [State and rendering](03-state-and-rendering/) | fields, `StateHasChanged`, `INotifyPropertyChanged`, immutable records |
| 4 | [Events and forms](04-events-and-forms/) | event handlers, `EventCallback`, `@bind`, `EditForm`, validation attributes |
| 5 | Effects: `useEffect`, dependencies, cleanup, Strict Mode's double mount, and when not to use an effect (coming next) | `IDisposable`, `OnAfterRenderAsync`, event subscriptions |
| 6 | Data: `fetch`, loading and error states, cancellation, Suspense, TanStack Query | `HttpClient`, `CancellationToken`, `async` in `OnInitializedAsync` |
| 7 | Composition: context, custom hooks, props against context against a store | dependency injection, cascading parameters, services |
| 8 | Routing with React Router | Blazor's `@page` and `NavigationManager`, ASP.NET Core routing |
| 9 | Tests: Vitest, Testing Library, component tests, Playwright end to end | xUnit, bUnit, JUnit, Selenium |
| 10 | Performance: React Compiler, `memo`, the Profiler, splitting the bundle | profilers, virtualization, lazy loading |
| 11 | Styles and accessibility: CSS Modules, ARIA, lint rules | XAML styles, CSS isolation in Blazor, analyzers |
| 12 | React 19: Actions, `use`, Server Components, and what applies to a Vite SPA | Razor Pages, Blazor render modes |
| 13 | Deployment: a static build, environment variables, GitHub Pages, and an ASP.NET Core or Spring API behind it | `dotnet publish`, configuration, reverse proxies |
| — | [Journal](journal/) | |

## Resources

- [react.dev](https://react.dev/): [Learn React](https://react.dev/learn), the [API reference](https://react.dev/reference/react), and [Using TypeScript](https://react.dev/learn/typescript)
- [React 19.3 release post](https://react.dev/blog/2026/09/09/react-19-3) and the [React changelog](https://github.com/facebook/react/blob/main/CHANGELOG.md)
- [Vite guide](https://vite.dev/guide/), [Why Vite](https://vite.dev/guide/why), and the [Vite 8 announcement](https://vite.dev/blog/announcing-vite8)
- [Vitest guide](https://vitest.dev/guide/) and [React Testing Library](https://testing-library.com/docs/react-testing-library/intro)
- [TypeScript handbook — JSX](https://www.typescriptlang.org/docs/handbook/jsx.html) and [`@types/react`](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/28fd9030495005fd55f5a7eb3523a84046af8a01/types/react)
