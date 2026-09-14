# learn

Learning in public — courses written as I learn, in English, French and Spanish.

**Site:** https://spareilleux.github.io/learn/ · [Français](https://spareilleux.github.io/learn/fr/) · [Español](https://spareilleux.github.io/learn/es/)

[![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

## Courses

| Area | Course | Status |
|---|---|---|
| Software Engineering › Languages & frameworks | [Rust for C#/Java developers](src/content/docs/rust-for-csharp-java/) | complete (15 lessons) |
| Software Engineering › Languages & frameworks | [Java for C# developers](src/content/docs/java-for-csharp/) | in progress (lessons 1–12 of 14) |
| Software Engineering › Languages & frameworks | [V for C#/Java developers](src/content/docs/v-for-csharp-java/) | in progress (lessons 1–8 of 12, English only) |
| Software Engineering › Infrastructure & tooling | [WSL containers](src/content/docs/wsl-containers/) | in progress |
| Other | [Streeling University](src/content/docs/streeling/) | 31 imported modules, journal started |

Streeling modules are imported from [GuitarAlchemist/Demerzel](https://github.com/GuitarAlchemist/Demerzel) with `npm run sync:streeling` (pin a revision with `-- --ref <sha>`); the imported commit is recorded in `streeling.lock.json`.

## Structure

```
src/content/docs/
├── index.mdx              home (English, source language)
├── method.md              how the courses are built
├── <course>/
│   ├── index.md           mission, prerequisites, outline, resources
│   ├── 01-….md            numbered lessons
│   └── journal.md         dated progress notes
├── fr/                    French translation, identical file names
└── es/                    Spanish translation, identical file names
```

See [Method](src/content/docs/method.md) for the writing rules.

## Commands

| Command | Action |
|---|---|
| `npm install` | install dependencies |
| `npm run dev` | local server at `localhost:4321/learn/` |
| `npm run build` | build the site into `./dist/` |
| `npm run preview` | preview the build |

Every push to `main` deploys the site to GitHub Pages (`.github/workflows/deploy.yml`).
