---
title: React (Vite) para desarrolladores C#/Java — Misión
description: React 19 con TypeScript y Vite 8 para desarrolladores que conocen C# o Java, Blazor, WPF o JavaFX, y han seguido los cursos de JavaScript y TypeScript — cada componente, error del compilador y prueba verificado por tsc 7, construido por Vite y ejecutado por Vitest en CI en Windows, Linux y macOS.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada]
[React](https://react.dev/) **19.3.0**, publicado en septiembre de 2026, construido con [Vite](https://vite.dev/) **8.3.0** y [`@vitejs/plugin-react`](https://github.com/vitejs/vite-plugin-react/tree/main/packages/plugin-react) 6.1.1, verificado con [TypeScript](https://www.typescriptlang.org/) 7.0.2 y probado con [Vitest](https://vitest.dev/) 5.0.0, [React Testing Library](https://testing-library.com/docs/react-testing-library/intro) 16.3.3 y jsdom 30.0.1, sobre [Node.js](https://nodejs.org/) 24.21.0. La aplicación del curso está en [`code/react-vite`](https://github.com/spareilleux/learn/tree/3f7a5df/code/react-vite), con su propio `package.json` y su archivo de bloqueo, que fijan esas versiones y [oxlint](https://oxc.rs/docs/guide/usage/linter) 1.83.0. [`.github/workflows/react-vite-examples.yml`](https://github.com/spareilleux/learn/blob/f6417a9/.github/workflows/react-vite-examples.yml) ejecuta [`check.sh`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/check.sh) en Linux, Windows y macOS: genera un proyecto con `create-vite`, arranca el servidor de desarrollo y recibe una actualización en caliente, verifica la aplicación y cada fragmento de error con `tsc`, la construye con Vite, le pasa el linter, ejecuta cada archivo de Vitest y compara todas las salidas con las que se pegan en las lecciones.
:::

## Por qué aprendo esto

Los front ends de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) son aplicaciones React construidas con Vite. El [curso de TypeScript](../typescript-for-csharp-java/) leyó sus tipos; este curso lee sus componentes. Como desarrollador C# conozco Blazor y XAML, donde un componente es una clase con propiedades, el framework conserva sus campos y un binding actualiza la pantalla. React parece similar al principio, y luego resulta que un componente es una función que se ejecuta de nuevo en cada cambio, que una lista necesita claves, que un objeto en el estado debe reemplazarse en lugar de modificarse, y que dos componentes inocentes pueden renderizarse el uno al otro para siempre.

## A quién va dirigido este curso

Te manejas bien con C# o Java, y con al menos un framework de interfaz entre [Blazor](https://learn.microsoft.com/aspnet/core/blazor/), [WPF](https://learn.microsoft.com/dotnet/desktop/wpf/overview/) o [JavaFX](https://openjfx.io/). Has seguido [JavaScript para desarrolladores C#/Java](../javascript-for-csharp-java/) y [TypeScript para desarrolladores C#/Java](../typescript-for-csharp-java/), o conoces su contenido: módulos y npm, funciones y closures, objetos y arrays, tipos estructurales, uniones y narrowing, genéricos. Las lecciones enlazan a sus páginas en lugar de explicar el lenguaje otra vez. Este curso trata de componentes, de JSX, del DOM y de las herramientas que los construyen y los prueban.

## React (Vite) en una tabla

| | Blazor | WPF / XAML | JavaFX | React con Vite |
|---|---|---|---|---|
| Un componente | un archivo `.razor`, compilado a una clase | un `UserControl`: XAML y code-behind | una subclase de `Node`, o FXML y un controlador | una función que devuelve JSX |
| Marcado | Razor | XAML | FXML | JSX, compilado a llamadas de función |
| Entradas | propiedades `[Parameter]` | propiedades de dependencia | propiedades JavaFX | props, un solo objeto |
| Estado local | campos, renderizados de nuevo tras un manejador de eventos | propiedades con `INotifyPropertyChanged` | propiedades observables | `useState`, un valor por render |
| Actualizar la pantalla | un árbol de render comparado con el anterior | los bindings actualizan los controles | bindings y listeners | renderizar de nuevo, comparar, confirmar las diferencias |
| Binding bidireccional | `@bind` | `{Binding Mode=TwoWay}` | `bindBidirectional` | ninguno: `value` y `onChange` |
| Build | MSBuild | MSBuild | Maven o Gradle | Vite: un servidor de desarrollo, y Rolldown para producción |
| Pruebas de componentes | [bUnit](https://bunit.dev/) | automatización de UI | [TestFX](https://github.com/TestFX/TestFX) | Vitest y Testing Library |

## Los datos

Las lecciones usan código real como material. [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) se cita en el commit [`8cc8c5a`](https://github.com/GuitarAlchemist/ga/commit/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41), en [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components), su aplicación React principal, y en [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/Apps/ga-client), que su propio script `dev` llama el cliente de demostración heredado. Ambas piden React 18.3 y Vite 5.4 en su `package.json`; `Apps/ga-dashboard` es una aplicación Angular, fuera de este curso. Leí sus componentes, les pasé las reglas React de oxlint y reduje lo que encontré a componentes que las pruebas del curso renderizan, con un enlace a las líneas originales. Los hallazgos están en el [diario](journal/).

## Al final de este curso, sabré

- crear un proyecto React con Vite, explicar qué hacen su servidor de desarrollo y su build de producción, y hacer que los errores de tipo rompan el build;
- escribir componentes de función tipados, componerlos con props y children, y renderizar listas con claves estables;
- mantener el estado mínimo, actualizarlo sin mutación, y explicar cuándo y por qué React renderiza un componente de nuevo;
- manejar eventos y construir formularios controlados con validación;
- sincronizar un componente con el mundo exterior mediante efectos, y reconocer los efectos que no deberían existir;
- cargar datos con estados de carga y de error, cancelación y caché;
- compartir estado con contexto y hooks personalizados, y navegar entre páginas;
- probar los componentes como los usa un usuario, y medir y mejorar el rendimiento del renderizado;
- desplegar una aplicación React estática delante de una API ASP.NET Core o Spring.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Un proyecto Vite](01-vite-project/) | `dotnet new`, `dotnet watch`, MSBuild, Maven, hot reload |
| 2 | [Componentes y JSX](02-components-and-jsx/) | componentes Blazor, user controls XAML, `[Parameter]`, `RenderFragment`, `@foreach` |
| 3 | [Estado y renderizado](03-state-and-rendering/) | campos, `StateHasChanged`, `INotifyPropertyChanged`, records inmutables |
| 4 | [Eventos y formularios](04-events-and-forms/) | manejadores de eventos, `EventCallback`, `@bind`, `EditForm`, atributos de validación |
| 5 | Efectos: `useEffect`, dependencias, limpieza, el doble montaje de Strict Mode, y cuándo no usar un efecto (próximamente) | `IDisposable`, `OnAfterRenderAsync`, suscripciones a eventos |
| 6 | Datos: `fetch`, estados de carga y de error, cancelación, Suspense, TanStack Query | `HttpClient`, `CancellationToken`, `async` en `OnInitializedAsync` |
| 7 | Composición: contexto, hooks personalizados, props frente a contexto frente a un store | inyección de dependencias, parámetros en cascada, servicios |
| 8 | Enrutamiento con React Router | `@page` y `NavigationManager` de Blazor, enrutamiento de ASP.NET Core |
| 9 | Pruebas: Vitest, Testing Library, pruebas de componentes, Playwright de extremo a extremo | xUnit, bUnit, JUnit, Selenium |
| 10 | Rendimiento: React Compiler, `memo`, el Profiler, dividir el bundle | profilers, virtualización, carga diferida |
| 11 | Estilos y accesibilidad: CSS Modules, ARIA, reglas de lint | estilos XAML, aislamiento de CSS en Blazor, analizadores |
| 12 | React 19: Actions, `use`, Server Components, y lo que aplica a una SPA con Vite | Razor Pages, modos de render de Blazor |
| 13 | Despliegue: un build estático, variables de entorno, GitHub Pages, y una API ASP.NET Core o Spring detrás | `dotnet publish`, configuración, proxies inversos |
| — | [Diario](journal/) | |

## Recursos

- [react.dev](https://react.dev/): [Learn React](https://react.dev/learn), la [referencia de la API](https://react.dev/reference/react), y [Using TypeScript](https://react.dev/learn/typescript)
- [Anuncio de React 19.3](https://react.dev/blog/2026/09/09/react-19-3) y el [changelog de React](https://github.com/facebook/react/blob/main/CHANGELOG.md)
- [Guía de Vite](https://vite.dev/guide/), [Why Vite](https://vite.dev/guide/why), y el [anuncio de Vite 8](https://vite.dev/blog/announcing-vite8)
- [Guía de Vitest](https://vitest.dev/guide/) y [React Testing Library](https://testing-library.com/docs/react-testing-library/intro)
- [Manual de TypeScript — JSX](https://www.typescriptlang.org/docs/handbook/jsx.html) y [`@types/react`](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/react)
