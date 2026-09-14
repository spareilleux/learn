---
title: Method
description: How the courses on this site are organized and written.
---

Each course lives in its own folder and follows the same structure.

## Structure of a course

| Page | Role |
|---|---|
| `index.md` — **Mission** | Why I'm learning the topic, what I want to be able to do by the end, prerequisites, outline and resources. |
| `01-…`, `02-…` — **Lessons** | One idea per lesson. Real commands, a summary, exercises with collapsible solutions. |
| `journal.md` — **Journal** | Dated progress notes: attempts, errors, open questions, "to verify" items. |

## Writing rules

1. **Test before claiming.** Anything not yet verified on my machine is marked *to verify*.
2. **Cite primary sources.** Official documentation, repositories, release notes — no second-hand blogs when it can be avoided.
3. **Keep the failures.** An error encountered (and its cause) is often more instructive than the ideal path.
4. **Date what changes fast.** Preview tools evolve: each course states the version studied.
5. **Trilingual.** English is the reference language; the French version follows under `/fr/` and the Spanish version under `/es/`.

## Adding a course

1. Create `src/content/docs/<topic>/` (English), `src/content/docs/fr/<topic>/` (French) and `src/content/docs/es/<topic>/` (Spanish), with identical file names.
2. Write `index.md` (mission), the numbered lessons and `journal.md`.
3. Order the pages with `sidebar: { order: N }` in the frontmatter.
4. Add the group in `astro.config.mjs`:

```js
{ label: 'My topic', items: [{ autogenerate: { directory: 'my-topic' } }] }
```
