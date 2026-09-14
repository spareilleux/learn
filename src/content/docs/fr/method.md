---
title: Méthode
description: Comment les cours de ce site sont organisés et rédigés.
---

Chaque cours vit dans son propre dossier et suit la même structure.

## Structure d'un cours

| Page | Rôle |
|---|---|
| `index.md` — **Mission** | Pourquoi j'apprends ce sujet, ce que je veux savoir faire à la fin, prérequis, plan et ressources. |
| `01-…`, `02-…` — **Leçons** | Une idée par leçon. Des commandes réelles, un résumé, des exercices avec solution repliable. |
| `journal.md` — **Journal** | Notes de progression datées : essais, erreurs, questions ouvertes, points « à vérifier ». |

## Règles de rédaction

1. **Tester avant d'affirmer.** Ce qui n'a pas encore été vérifié sur ma machine est marqué *à vérifier*.
2. **Citer des sources primaires.** Documentation officielle, dépôts, notes de version — pas de blogs de seconde main quand on peut l'éviter.
3. **Garder les échecs.** Une erreur rencontrée (et sa cause) est souvent plus instructive que le chemin idéal.
4. **Dater ce qui change vite.** Les outils en préversion évoluent : chaque cours indique la version étudiée.
5. **Trilingue.** L'anglais est la langue de référence ; la version française suit sous `/fr/` et la version espagnole sous `/es/`.

## Ajouter un cours

1. Créer `src/content/docs/<sujet>/` (anglais), `src/content/docs/fr/<sujet>/` (français) et `src/content/docs/es/<sujet>/` (espagnol), avec les mêmes noms de fichiers.
2. Écrire `index.md` (mission), les leçons numérotées et `journal.md`.
3. Ordonner les pages avec `sidebar: { order: N }` dans le frontmatter.
4. Ajouter le groupe dans `astro.config.mjs` :

```js
{ label: 'Mon sujet', items: [{ autogenerate: { directory: 'mon-sujet' } }] }
```
