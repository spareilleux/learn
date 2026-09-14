---
title: 3. Chemins
description: Motifs à plusieurs sauts, OPTIONAL MATCH et sous-requêtes COUNT, puis relations de longueur variable — marches, pistes et chemins acycliques —, plus courts chemins, filtres le long d'un chemin et limite de profondeur, vérifiés avec une CTE récursive.
sidebar:
  order: 3
---

Le graphe de la leçon 2, des nœuds `Page` et des relations `LINKS_TO`, est chargé en tête de [`cypher/03-paths.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/03-paths.cypher) avec les mêmes instructions `COPY`. Cette leçon lui pose des questions sur les chemins (*paths*) : combien de clics, par quelles pages.

## Plusieurs sauts

Un motif peut enchaîner des relations. Les leçons du cours DuckDB, atteintes depuis la page d'accueil en passant par l'index du cours ([lignes 9-12](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L9-L12)) :

```cypher
MATCH (home:Page {url: '/'})-[:LINKS_TO]->(course:Page)-[:LINKS_TO]->(lesson:Page)
WHERE course.course = 'duckdb'
RETURN course.url, lesson.url
ORDER BY lesson.url;
```

```text
┌────────────┬───────────────────────────┐
│ course.url │ lesson.url                │
│ STRING     │ STRING                    │
├────────────┼───────────────────────────┤
│ /duckdb/   │ /duckdb/01-first-queries/ │
│ /duckdb/   │ /duckdb/02-friendly-sql/  │
│ /duckdb/   │ /duckdb/03-nested-data/   │
│ /duckdb/   │ /duckdb/04-files/         │
│ /duckdb/   │ /duckdb/05-csharp/        │
│ /duckdb/   │ /duckdb/06-java/          │
│ /duckdb/   │ /duckdb/07-performance/   │
│ /duckdb/   │ /duckdb/08-persistence/   │
│ /duckdb/   │ /duckdb/journal/          │
│ /duckdb/   │ /github-actions/          │
└────────────┴───────────────────────────┘
```

En SQL, deux jointures de la table des liens avec elle-même, et deux jointures avec les pages. La dernière ligne n'est pas une leçon DuckDB : l'index DuckDB pointe vers le cours GitHub Actions, dont il interroge les exécutions. Le filtre porte sur la page du milieu, pas sur la leçon.

## `OPTIONAL MATCH` : le `LEFT JOIN`

`MATCH` écarte les lignes où le motif ne correspond pas. [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/) les garde avec `NULL`, comme un `LEFT JOIN` ([lignes 15-20](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L15-L20)) :

```cypher
MATCH (p:Page)
WHERE p.locale = 'en' AND p.course = 'github-actions'
OPTIONAL MATCH (p)-[:LINKS_TO]->(target:Page)
RETURN p.url, count(target) AS links
ORDER BY links, p.url
LIMIT 4;
```

```text
┌────────────────────────────────────┬───────┐
│ p.url                              │ links │
│ STRING                             │ INT64 │
├────────────────────────────────────┼───────┤
│ /github-actions/journal/           │ 0     │
│ /github-actions/02-build-and-test/ │ 1     │
│ /github-actions/09-debugging/      │ 1     │
│ /github-actions/01-first-workflow/ │ 2     │
└────────────────────────────────────┴───────┘
```

`count(target)` compte les valeurs non `NULL`, donc le journal, qui ne pointe vers aucune page du site, obtient 0. Avec `MATCH` au lieu de `OPTIONAL MATCH`, il manquerait au résultat ; avec `count(*)`, il compterait 1.

## Sous-requêtes `COUNT`

Les pages anglaises qui ont au moins cinq liens entrants. Une [sous-requête `COUNT { … }`](https://docs.ladybugdb.com/cypher/subquery/) compte les lignes d'un motif pour chaque page, dans le filtre et dans le résultat ([lignes 23-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L23-L26)) :

```cypher
MATCH (p:Page)
WHERE p.locale = 'en' AND COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } >= 5
RETURN p.url, COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } AS incoming
ORDER BY incoming DESC, p.url;
```

```text
┌──────────────────────────────────────────────────────┬──────────┐
│ p.url                                                │ incoming │
│ STRING                                               │ INT64    │
├──────────────────────────────────────────────────────┼──────────┤
│ /streeling/journal/                                  │ 32       │
│ /wsl-containers/journal/                             │ 13       │
│ /streeling/music/mus-001-what-is-a-chord/            │ 8        │
│ /github-actions/01-first-workflow/                   │ 6        │
│ /github-actions/05-caches-and-artifacts/             │ 6        │
│ /github-actions/07-security/                         │ 6        │
│ /streeling/guitar-studies/gtr-001-the-fretboard-map/ │ 6        │
│ /github-actions/04-expressions-and-outputs/          │ 5        │
└──────────────────────────────────────────────────────┴──────────┘
```

C'est la sous-requête corrélée `(SELECT count(*) FROM links WHERE target = p.url)` de SQL. Le journal de Streeling arrive en tête : 32 pages Streeling anglaises pointent vers lui.

## Longueur variable : marches (*walks*)

`-[e:LINKS_TO*1..4]->` correspond à une chaîne de 1 à 4 relations `LINKS_TO`. Toutes les façons d'aller de l'index GitHub Actions à sa leçon 7 en quatre clics au plus ([lignes 29-31](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L29-L31)) :

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS walks
ORDER BY links;
```

```text
┌───────┬───────┐
│ links │ walks │
│ INT64 │ INT64 │
├───────┼───────┤
│ 1     │ 1     │
│ 2     │ 5     │
│ 3     │ 12    │
│ 4     │ 29    │
└───────┴───────┘
```

`e` est la chaîne entière, une *relation récursive*, et [`length(e)`](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) son nombre de relations.

**Par défaut, la chaîne est une marche : elle peut passer plusieurs fois par la même page, et même par le même lien.** Parmi les 29 marches de quatre liens, certaines vont à la leçon 7, la quittent pour une autre leçon, puis reviennent. C'est la principale [différence avec Neo4j](https://docs.ladybugdb.com/cypher/difference/), dont les motifs ne répètent jamais une relation. C'est aussi ce qui rend la borne supérieure nécessaire : dans un graphe avec des cycles, le nombre de marches croît sans fin.

Le même décompte en SQL, avec une CTE récursive dans DuckDB ([`sql/03-walks.sql`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/sql/03-walks.sql), comparé par la CI lui aussi) :

```sql
WITH RECURSIVE
  links AS (
    SELECT l."from" AS source, l."to" AS target
    FROM 'data/links.csv' l
    WHERE l."to" IN (SELECT url FROM 'data/pages.csv')
  ),
  walks(page, length) AS (
    SELECT target, 1 FROM links WHERE source = '/github-actions/'
    UNION ALL
    SELECT links.target, walks.length + 1
    FROM walks JOIN links ON links.source = walks.page
    WHERE walks.length < 4
  )
SELECT length AS links, count(*) AS walks
FROM walks
WHERE page = '/github-actions/07-security/'
GROUP BY length
ORDER BY length;
```

```text
links,walks
1,1
2,5
3,12
4,29
```

Les mêmes nombres. Une CTE récursive calcule elle aussi des marches : elle ne se souvient pas de là où elle est passée, et le `WHERE walks.length < 4` est sa borne supérieure. Le filtre `IN` écarte les 64 liens vers des pages absentes, que `COPY … IGNORE_ERRORS` a ignorés dans LadybugDB.

## Pistes (*trails*) et chemins acycliques

`TRAIL` après l'étoile interdit de répéter une relation ([lignes 34-36](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L34-L36)) :

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO* TRAIL 1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS trails
ORDER BY links;
```

```text
┌───────┬────────┐
│ links │ trails │
│ INT64 │ INT64  │
├───────┼────────┤
│ 1     │ 1      │
│ 2     │ 5      │
│ 3     │ 12     │
│ 4     │ 26     │
└───────┴────────┘
```

Trois marches de quatre liens empruntent deux fois un lien. Index → leçon 1 → leçon 7 → leçon 1 → leçon 7 emprunte deux fois le lien de la leçon 1 vers la leçon 7. Index → leçon 4 → leçon 7 → leçon 4 → leçon 7 fait de même avec le lien de la leçon 4 vers la leçon 7, et compte double, car la leçon 7 pointe vers la leçon 4 à deux endroits : deux relations, deux marches. Pour interdire de répéter une *page*, la fonction de chemin [`is_acyclic`](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) filtre le chemin entier, nommé avec `p =` ([lignes 40-43](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L40-L43)) :

```cypher
MATCH p = (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4]->(b:Page {url: '/github-actions/07-security/'})
WHERE is_acyclic(p)
RETURN length(e) AS links, count(*) AS acyclic_paths
ORDER BY links;
```

```text
┌───────┬───────────────┐
│ links │ acyclic_paths │
│ INT64 │ INT64         │
├───────┼───────────────┤
│ 1     │ 1             │
│ 2     │ 5             │
│ 3     │ 9             │
│ 4     │ 10            │
└───────┴───────────────┘
```

De 29 marches à 10 chemins qui ne visitent jamais deux fois une page, extrémités comprises. Un script Python qui énumère les chemins de `links.csv` trouve les mêmes 29, 26 et 10.

La [documentation de `MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/) décrit aussi un mot-clé `ACYCLIC`, qui s'emploie comme `TRAIL` et ne vérifie que les nœuds entre les deux extrémités : il devrait trouver ici 25 chemins de quatre liens. **Ce n'est pas le cas en 0.20.4** : `LINKS_TO* ACYCLIC 1..4` renvoie 14 sous Windows, dont un chemin qui passe deux fois par la même page, et 29, toutes les marches, sous Linux et macOS. C'est pourquoi cette leçon utilise `is_acyclic` ; le [journal](../journal/) donne les détails.

## Plus courts chemins

`SHORTEST` garde, pour chaque paire de nœuds, un chemin de longueur minimale. Combien de clics de la page d'accueil à chaque page anglaise ([lignes 46-56](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L46-L56)) :

```cypher
MATCH (home:Page {url: '/'})-[e:LINKS_TO* SHORTEST 1..10]->(p:Page)
WHERE p.locale = 'en'
RETURN length(e) AS clicks, count(*) AS pages
ORDER BY clicks;

MATCH (p:Page)
WHERE p.locale = 'en' AND p.url <> '/'
  AND NOT EXISTS { MATCH (:Page {url: '/'})-[:LINKS_TO* SHORTEST 1..10]->(p) }
RETURN p.url
ORDER BY p.url;
```

```text
┌────────┬───────┐
│ clicks │ pages │
│ INT64  │ INT64 │
├────────┼───────┤
│ 1      │ 7     │
│ 2      │ 77    │
│ 3      │ 32    │
└────────┴───────┘
┌────────┐
│ p.url  │
│ STRING │
├────────┤
└────────┘
```

7 + 77 + 32 = 116 : toutes les pages anglaises sauf la page d'accueil elle-même sont à trois clics au plus, et la seconde requête, vide, confirme qu'aucune n'est inaccessible. La même question en SQL est une CTE récursive qui garde la longueur minimale par page et qu'il faut arrêter à la main ; dans LadybugDB, c'est un mot-clé.

Quelles pages sont sur le trajet ? [Lignes 59-63](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L59-L63) :

```cypher
MATCH (a:Page {url: '/github-actions/09-debugging/'})-[e:LINKS_TO* SHORTEST 1..10]->(b:Page {url: '/github-actions/02-build-and-test/'})
RETURN length(e) AS links, size(nodes(e)) AS pages_between;
MATCH (a:Page {url: '/github-actions/09-debugging/'})-[e:LINKS_TO* ALL SHORTEST 1..10]->(b:Page {url: '/github-actions/02-build-and-test/'})
RETURN cast(properties(nodes(e), 'url') AS STRING) AS through
ORDER BY through;
```

```text
┌───────┬───────────────┐
│ links │ pages_between │
│ INT64 │ INT64         │
├───────┼───────────────┤
│ 4     │ 3             │
└───────┴───────────────┘
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ through                                                                                                                   │
│ STRING                                                                                                                    │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [/github-actions/04-expressions-and-outputs/,/github-actions/01-first-workflow/,/github-actions/05-caches-and-artifacts/] │
│ [/github-actions/04-expressions-and-outputs/,/github-actions/07-security/,/github-actions/05-caches-and-artifacts/]       │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

- `nodes(e)` renvoie les nœuds *entre* les deux extrémités, pas les extrémités : 3 pages pour 4 liens.
- `properties(nodes(e), 'url')` extrait une propriété d'une liste de nœuds, sous forme de `STRING[]`.
- `ALL SHORTEST` renvoie tous les chemins de longueur minimale : deux ici, qui diffèrent par la page du milieu.
- La première requête ne renvoie pas les pages de son chemin : avec deux candidats, celui que choisit `SHORTEST` n'est pas spécifié, et une sortie comparée ne peut pas en dépendre. Le cast en `STRING` est là parce que `ORDER BY` sur un `STRING[]` échoue en 0.20.4 (`Binder exception`).

## Sens

D'une leçon DuckDB au cours Rust ([lignes 66-69](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L66-L69)) :

```cypher
MATCH (a:Page {url: '/duckdb/04-files/'})-[e:LINKS_TO* SHORTEST 1..10]->(b:Page {url: '/rust-for-csharp-java/'})
RETURN length(e) AS links;
MATCH (a:Page {url: '/duckdb/04-files/'})-[e:LINKS_TO* SHORTEST 1..10]-(b:Page {url: '/rust-for-csharp-java/'})
RETURN length(e) AS links;
```

```text
┌───────┐
│ links │
│ INT64 │
├───────┤
└───────┘
┌───────┐
│ links │
│ INT64 │
├───────┤
│ 3     │
└───────┘
```

En suivant les liens, le cours Rust est inaccessible depuis cette leçon : le Markdown d'aucune page ne renvoie à la page d'accueil (l'en-tête du site, oui, mais il n'est pas dans les données). Sans la pointe de flèche, `-[…]-`, les relations peuvent être suivies dans les deux sens, et trois étapes suffisent : la leçon est liée *depuis* l'index DuckDB, lui-même lié depuis la page d'accueil, qui pointe vers le cours Rust.

## Un filtre à chaque étape

Une relation de longueur variable peut filtrer les relations et les nœuds qu'elle traverse : `(r, n | WHERE …)`, où `r` désigne chaque relation et `n` chaque nœud intermédiaire. Les deux extrémités ne sont pas filtrées : avec `n.url <> '/github-actions/'`, la requête ci-dessous trouve encore ses marches. Les marches de la première requête à longueur variable, sans passer par la leçon 4 ([lignes 72-74](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L72-L74)) :

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4 (r, n | WHERE n.url <> '/github-actions/04-expressions-and-outputs/')]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS walks
ORDER BY links;
```

```text
┌───────┬───────┐
│ links │ walks │
│ INT64 │ INT64 │
├───────┼───────┤
│ 1     │ 1     │
│ 2     │ 4     │
│ 3     │ 7     │
│ 4     │ 14    │
└───────┴───────┘
```

De 29 marches de quatre liens à 14, le nombre que trouve aussi le script Python.

## La limite de profondeur

[Lignes 77-78](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L77-L78) :

```cypher
MATCH (a:Page {url: '/'})-[e:LINKS_TO*1..50]->(b:Page {url: '/duckdb/journal/'})
RETURN count(*);
```

```text
Error: Binder exception: Upper bound of rel e exceeds maximum: 30.
```

Une borne supérieure au-delà de 30 est refusée avant l'exécution de la requête, et `*` sans bornes signifie `*1..30`. La limite est le paramètre `var_length_extend_max_depth` ([`client_config.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/main/client_config.h#L32)), que `CALL var_length_extend_max_depth = 100;` relève pour la connexion ([configuration](https://docs.ladybugdb.com/cypher/configuration/)). La leçon 4 en a besoin : l'historique Git est une chaîne de 74 commits. Avant de relever la limite, demande-toi si tu veux des marches ou `SHORTEST` : sur ma machine, les marches de la première requête avec `*` au lieu de `*1..4`, donc jusqu'à 30 liens, étaient encore en cours de comptage au bout de cinq minutes, alors que `* SHORTEST` répond aussitôt.

## À retenir

- `OPTIONAL MATCH` est le `LEFT JOIN` ; `COUNT { MATCH … }` et `EXISTS { MATCH … }` sont des sous-requêtes corrélées.
- `-[:LINKS_TO*1..4]->` correspond par défaut à des marches : pages et liens peuvent se répéter. `TRAIL` interdit les relations répétées, `is_acyclic(p)` les nœuds répétés.
- `ACYCLIC` renvoie des décomptes faux en 0.20.4, et différents sous Windows et sous Linux ou macOS.
- `SHORTEST` et `ALL SHORTEST` calculent les plus courts chemins dans le motif ; `nodes(e)` renvoie les nœuds entre les extrémités.
- Sans pointe de flèche, un motif suit les relations dans les deux sens ; `(r, n | WHERE …)` filtre chaque étape.
- La profondeur est limitée à 30, sauf si `var_length_extend_max_depth` est relevé.

## Exercices

Les solutions sont dans [`cypher/03-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/03-exercises.cypher), vérifiées par la CI.

1. Les 32 pages anglaises à trois clics de la page d'accueil : dans quels cours sont-elles ?

<details>
<summary>Solution</summary>

Extrait de [`03-exercises.cypher`, lignes 9-12](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L9-L12) :

```cypher
MATCH (home:Page {url: '/'})-[e:LINKS_TO* SHORTEST 1..10]->(p:Page)
WHERE p.locale = 'en' AND length(e) = 3
RETURN p.course, count(*) AS pages
ORDER BY pages DESC, p.course;
```

```text
┌───────────┬───────┐
│ p.course  │ pages │
│ STRING    │ INT64 │
├───────────┼───────┤
│ streeling │ 31    │
│ method    │ 1     │
└───────────┴───────┘
```

Les modules Streeling (page d'accueil → index Streeling → département → module) et la page Méthode, vers laquelle la page d'accueil ne pointe pas directement. Chaque leçon de cours est à deux clics, par l'index de son cours.

</details>

2. Quelles pages anglaises pointent vers une page d'un autre cours ? Compte les liens par paire de cours.

<details>
<summary>Solution</summary>

Extrait de [`03-exercises.cypher`, lignes 15-18](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L15-L18) :

```cypher
MATCH (a:Page)-[:LINKS_TO]->(b:Page)
WHERE a.locale = 'en' AND b.locale = 'en' AND a.course <> b.course AND a.course <> '' AND b.course <> ''
RETURN a.course AS from_course, b.course AS to_course, count(*) AS links
ORDER BY links DESC, from_course, to_course;
```

```text
┌────────────────┬─────────────────┬───────┐
│ from_course    │ to_course       │ links │
│ STRING         │ STRING          │ INT64 │
├────────────────┼─────────────────┼───────┤
│ duckdb         │ github-actions  │ 2     │
│ duckdb         │ java-for-csharp │ 1     │
│ github-actions │ method          │ 1     │
└────────────────┴─────────────────┴───────┘
```

Quatre liens, dont trois depuis le cours DuckDB, qui s'appuie sur les exécutions GitHub Actions et renvoie au cours Java. Les cours sont des îles reliées par la page d'accueil : c'est pourquoi le chemin non orienté de la leçon passe par elle.

</details>

3. À deux liens de l'index DuckDB : combien de marches, combien de pages distinctes ? Trouve la page atteinte deux fois, et par quelles pages.

<details>
<summary>Solution</summary>

Extrait de [`03-exercises.cypher`, lignes 21-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L21-L26) :

```cypher
MATCH (a:Page {url: '/duckdb/'})-[:LINKS_TO*2..2]->(b:Page)
RETURN count(*) AS walks, count(DISTINCT b) AS pages;
MATCH (a:Page {url: '/duckdb/'})-[e:LINKS_TO*2..2]->(b:Page)
WITH b, count(*) AS walks, collect(properties(nodes(e), 'url')[1]) AS through
WHERE walks > 1
RETURN b.url, walks, cast(list_sort(through) AS STRING) AS through;
```

```text
┌───────┬───────┐
│ walks │ pages │
│ INT64 │ INT64 │
├───────┼───────┤
│ 16    │ 15    │
└───────┴───────┘
┌──────────────────────────┬───────┬────────────────────────────────────────────┐
│ b.url                    │ walks │ through                                    │
│ STRING                   │ INT64 │ STRING                                     │
├──────────────────────────┼───────┼────────────────────────────────────────────┤
│ /github-actions/journal/ │ 2     │ [/duckdb/03-nested-data/,/github-actions/] │
└──────────────────────────┴───────┴────────────────────────────────────────────┘
```

16 marches atteignent 15 pages : le journal GitHub Actions est atteint par la leçon 3 de DuckDB et par l'index GitHub Actions. `WITH … WHERE` filtre sur un agrégat, le `HAVING` de SQL. Les listes sont indexées à partir de 1, donc `[1]` est la seule page entre les deux extrémités ; `collect` les rassemble dans une liste, et `list_sort` rend la sortie stable.

</details>

## Sources

- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/) : relations de longueur variable, sémantique des chemins, plus courts chemins, filtres
- [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/) et [sous-requêtes](https://docs.ladybugdb.com/cypher/subquery/)
- [Fonctions de relations récursives](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) : `length`, `nodes`, `is_trail`, `is_acyclic`
- [Différences entre LadybugDB et Neo4j](https://docs.ladybugdb.com/cypher/difference/) : sémantique des marches, borne supérieure par défaut
- [Configuration](https://docs.ladybugdb.com/cypher/configuration/) : `var_length_extend_max_depth`
- [CTE récursives de DuckDB](https://duckdb.org/docs/current/sql/query_syntax/with)
