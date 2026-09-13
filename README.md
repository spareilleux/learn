# learn

Learning in public — courses written as I learn, in English and French.

**Site:** https://spareilleux.github.io/learn/ · [Français](https://spareilleux.github.io/learn/fr/)

[![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

## Courses

| Course | Status |
|---|---|
| [WSL containers](src/content/docs/wsl-containers/) | in progress |

## Structure

```
src/content/docs/
├── index.mdx              home (English, source language)
├── method.md              how the courses are built
├── <course>/
│   ├── index.md           mission, prerequisites, outline, resources
│   ├── 01-….md            numbered lessons
│   └── journal.md         dated progress notes
└── fr/                    French translation, identical file names
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
