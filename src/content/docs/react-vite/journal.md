---
title: Journal
description: Dated progress notes for the React (Vite) course — pinning React 19.3, Vite 8.3 and Vitest 5, capturing the dev server and an HMR update in a script, surprises in Vite, Vitest and @types/react, what the course found in GuitarAlchemist/ga's React components, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] React 19.3.0, Vite 8.3.0, TypeScript 7.0.2, Vitest 5.0.0, Testing Library and oxlint pinned in the course's own `package.json` and lock file
- [x] `check.sh`: `create-vite`, the dev server, an HMR update, `tsc`, `vite build`, oxlint, every error snippet and every test, compared with `expected/`
- [ ] CI on three OSes (see below)
- [x] Lesson 1: a Vite project
- [x] Lesson 2: components and JSX
- [x] Lesson 3: state and rendering
- [x] Lesson 4: events and forms
- [ ] Lesson 5: effects

## 2026-09-15 — Versions

- `npm view` gives React and React DOM 19.3.0, released on 9 September 2026, Vite 8.3.0, `@vitejs/plugin-react` 6.1.1, Vitest 5.0.0, jsdom 30.0.1, `@testing-library/react` 16.3.3, `@testing-library/dom` 10.4.2, `@testing-library/user-event` 14.6.7, oxlint 1.83.0 and `create-vite` 9.2.1. The course pins them exactly in [`code/react-vite/package.json`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/package.json), and uses the site's other courses' Node.js 24.21.0 and TypeScript 7.0.2.
- `create-vite` 9.2.1's `react-ts` template asks for TypeScript `~6.0.2`, not 7.0: a range with `~` allows 6.0.x only. The course uses 7.0.2, and `tsc -b` checks the template's two projects without a change. Its `strict` is absent, because it has been the default since TypeScript 6.0, and its lint tool is oxlint rather than ESLint, with an `--eslint` option to get ESLint back.
- Vite 8 bundles with Rolldown and transforms with Oxc. The [TypeScript course's lesson 1](../../typescript-for-csharp-java/01-compiler-and-tooling/#in-real-projects) says that Vite strips types with esbuild: that is true of GA's Vite 5, and no longer of Vite 8. `@vitejs/plugin-react` 6 has no Babel dependency either; Fast Refresh is done by Oxc.
- The lock file written on Windows lists the native packages of every platform as optional dependencies: `@rolldown/binding-*`, `@oxlint/*` and `@typescript/typescript-*`.

## 2026-09-15 — Capturing the dev server

- The dev server, the modules it serves and the HMR message are captured by scripts, not by hand: [`dev-start.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/scripts/dev-start.mjs) starts `vite` and stops it when the URL is printed, [`dev-module.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/scripts/dev-module.mjs) requests one URL through Vite's JavaScript API, and [`hmr.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/scripts/hmr.mjs) connects to the HMR WebSocket, edits a copy of `App.tsx` and prints the messages.
- When the output isn't a terminal, Vite prints no `press h + enter to show help` line. My first `dev-start.mjs` waited for that line, never saw it, and left a server running on port 5199; it now waits for `use --host to expose`.
- On Windows, `server.close()` called right after the first module request never settled: Node.js printed "Detected unsettled top-level await" and exited with code 13. The request had started the dependency optimizer, which was still running. Awaiting `server.environments.client.waitForRequestsIdle()` before `close()` fixed it. I haven't checked whether Linux or macOS behave the same (*to verify*), nor looked for an existing Vite issue.
- Git Bash on Windows rewrites arguments that start with `/`: `vite build --base /learn/react-vite/` built pages that asked for `/Program Files/Git/learn/react-vite/assets/…`. `check.sh` sets `MSYS_NO_PATHCONV=1`, and the scripts take module paths without their leading slash.
- The outputs are normalized by [`normalize.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/normalize.mjs): durations, the `?v=` hash of pre-bundled dependencies, HMR timestamps and inline source maps. The production file names, such as `index-BQ_Vbf-Q.js`, are content hashes and are kept as they are.
- Fast Refresh keeping state is not in `check.sh`, which only sees the WebSocket message. I checked it by hand in a browser: three clicks on the counter, two on the capo, then an edit of the heading in `App.tsx`. The heading changed, the counter and the capo kept their values, and a variable set on `window` before the edit survived, so the page hadn't reloaded. For lesson 1, I also served the build with a type error with `vite preview` and clicked its button twice: `Count is 01`, then `Count is 011`.

## 2026-09-15 — Vitest and Testing Library

- React Testing Library unmounts rendered components after each test only when the test framework exposes a global `afterEach`. Vitest doesn't, unless `globals: true` is set, so the DOM of one test stayed in the next and queries found two forms. [`src/testing/setup.ts`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/src/testing/setup.ts) calls `cleanup` in `afterEach`, as the [Testing Library documentation](https://testing-library.com/docs/react-testing-library/api#cleanup) describes.
- Vitest's default reporter prints console output grouped by timing, not by test, and the grouping changed between runs. The course's [`reporter.mjs`](https://github.com/spareilleux/learn/blob/3f7a5df/code/react-vite/scripts/reporter.mjs) collects each log with its test and prints them in order at the end, and `check.sh` runs one test file per Vitest run.
- React's development warnings, the missing key or the controlled input, go to `console.error`, and the reporter prints them with a `console.error:` prefix, so the lessons quote them from the tests.
- A counter at module level, in a first version of lesson 3's StrictMode test, kept counting from one test to the next: Vitest isolates test files, not tests. The impure component now receives the array it changes as a prop.
- `tsconfig.app.json` first had the lib `DOM.Iterable`, to spread a `NodeList` in a test. With TypeScript 7.0.2, `DOM` alone accepts it; the course's configuration now has the template's `["ES2023", "DOM"]`.

## 2026-09-15 — @types/react and React 19.3

- `@types/react` 19.3.0 marks `FormEvent` and `FormEventHandler` as `@deprecated`, with the comment "FormEvent doesn't actually exist", and points to `ChangeEvent`, `InputEvent` and `SubmitEvent`. `ChangeEvent` has two type parameters, the current target and the target. Lesson 4 uses `SubmitEvent<HTMLFormElement>` for `onSubmit`.
- A component's return type, in `tsc`'s message, is `Promise<ReactNode> | ReactNode`: the types accept async components, for Server Components.
- In StrictMode, React 19.3 renders an impure component twice on mount, and the DOM shows the second render's output, "Played so far: G G".

## 2026-09-15 — The CI

- [`react-vite-examples.yml`](https://github.com/spareilleux/learn/blob/f6417a9/.github/workflows/react-vite-examples.yml) runs `npm ci` and `bash check.sh` on Ubuntu, Windows and macOS with Node.js 24.21.0. `check.sh` takes about 50 seconds on my Windows machine.
- The first push was refused: the GitHub token used for pushing lacks the `workflow` scope, which GitHub requires to create a file under `.github/workflows`. The code was pushed without the workflow, and the three-OS run is still to do (*to verify*: cross-OS differences, such as the order of `create-vite`'s file list or oxlint's output format).

## 2026-09-15 — What the course found in GuitarAlchemist/ga

At commit [`8cc8c5a`](https://github.com/GuitarAlchemist/ga/commit/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41), in `ReactComponents/ga-react-components` and `Apps/ga-client`; `Apps/ga-dashboard` is an Angular 21 application, outside this course. Nothing here has been reported to GA.

- **Expanded rows remembered by index.** [`DynamicPanel.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/PrimeRadiant/DynamicPanel.tsx#L76-L120) keeps its expanded rows in a `Set<number>` of positions in the filtered, polled data. After a filter or a poll that changes the order, another row is expanded. Lesson 3 reproduces it in `ExpandableList.tsx`. The panel's data is `unknown[]`; which field could serve as an identity depends on the panel definitions (*to verify*).
- **A render loop between two components.** [`NotesSelector.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/NotesSelector.tsx#L15-L18) calls `onNotesChange` from an effect that depends on it, and [`ScaleSelector.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/ScaleSelector.tsx#L18-L21) passes a new handler at each render, which stores a new array. The reduction in lesson 4 ends with "Maximum update depth exceeded". `ScaleSelector` also stores `scale`, derived from the notes, in state. It is exported from `components/index.ts`, and no GA application renders it at this commit, so the loop is latent. I haven't mounted GA's component itself (*to verify*).
- **A sliding window keyed by index.** [`DemerzelCriticOverlay.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/PrimeRadiant/DemerzelCriticOverlay.tsx#L179-L189) draws the last ten scores with `key={i}`, and its bars have `transition: height 0.3s ease`: once the window is full, each new score changes and animates every bar. Lesson 2's exercise 3 shows the element reuse; I haven't watched the animation (*to verify*).
- **oxlint's React rules.** oxlint 1.83.0 with `react/no-array-index-key`, `react/exhaustive-deps` and `typescript/no-explicit-any` reports, in `ga-react-components/src`, 85 index keys, 34 effect or callback dependency lists that don't match what the function reads, and 11 explicit `any`; in `ga-client/src`, 6 index keys. `react/jsx-key` and `react/rules-of-hooks` report nothing. The counts are lint results, not bugs: most index keys are on lists that never change.
- **Effects without cleanup.** A rough scan of the `useEffect` calls that start a timer, a listener or a subscription and return no cleanup found one: [`ChatWidget.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/PrimeRadiant/ChatWidget.tsx#L810-L815) starts a 300 ms `setTimeout` that isn't cleared if the component unmounts first. The scan is a text search, not a parser (*to verify* before drawing conclusions).
- **Scene options.** [`SceneOptions.tsx`](https://github.com/GuitarAlchemist/ga/blob/8cc8c5a17c685c779c46cd5e6d0a3f5d5036cc41/ReactComponents/ga-react-components/src/components/PrimeRadiant/SceneOptions.tsx#L119) also notifies its parent from an effect, once at mount, with the dependency rule turned off. Its merge of URL parameters and saved options is already the subject of the open pull request [GuitarAlchemist/ga#683](https://github.com/GuitarAlchemist/ga/pull/683), from the JavaScript course; this course doesn't fix it again.
- **Build and dev server.** `ga-react-components`' `build` script is `vite build` without `tsc`, and its `vite.config.ts`, 3,005 lines, adds middleware for dozens of `/dev-data/` endpoints behind a Cloudflare tunnel (lesson 1). `Apps/ga-client`'s `dev` script refuses to start, and says to use `ga-react-components` instead. The repository also tracks generated files: `tsconfig.app.tsbuildinfo`, `playwright-report` and `test-results` in `ga-react-components`.

## To verify

- The `server.close()` hang on Linux and macOS, and whether Vite has an issue for it.
- GA's `ScaleSelector` and `NotesSelector` mounted with Material UI, and the DemerzelCriticOverlay animation.
- An identity field for `DynamicPanel`'s rows in GA's panel definitions.
- The course's outputs on Linux and macOS, once the CI runs.
