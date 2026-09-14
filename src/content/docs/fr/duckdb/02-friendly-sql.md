---
title: 2. Friendly SQL
description: Intervalles et fuseaux horaires, fonctions de fenêtrage avec QUALIFY, PIVOT, et les raccourcis que DuckDB ajoute à SQL — sur l'historique des exécutions de ce site.
sidebar:
  order: 2
---

Toutes les requêtes de cette leçon sont dans [`sql/02-friendly-sql.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/02-friendly-sql.sql), exécutées depuis `code/duckdb` comme dans la [leçon 1](../01-first-queries/). Le script commence par charger les exécutions dans une table :

```sql
CREATE TABLE runs AS FROM 'data/runs.json';
```

## Durées : timestamps et intervalles

Soustraire deux valeurs `TIMESTAMP` donne un [`INTERVAL`](https://duckdb.org/docs/current/sql/functions/interval), que `avg` et `max` acceptent :

```sql
SELECT workflowName, count(*) AS runs, avg(updatedAt - startedAt) AS avg_took, max(updatedAt - startedAt) AS max_took
FROM runs
GROUP BY ALL
HAVING runs >= 4
ORDER BY avg_took DESC;
```

```text
┌────────────────────────┬───────┬─────────────────┬──────────┐
│      workflowName      │ runs  │    avg_took     │ max_took │
│        varchar         │ int64 │    interval     │ interval │
├────────────────────────┼───────┼─────────────────┼──────────┤
│ Java course examples   │     7 │ 00:03:18.857148 │ 00:04:48 │
│ Rust course examples   │    18 │ 00:01:32.888904 │ 00:02:33 │
│ Deploy to GitHub Pages │    65 │ 00:00:47.230784 │ 00:02:29 │
│ GHA 03: triggers       │     5 │ 00:00:33.4      │ 00:01:25 │
│ GHA 07: security       │     4 │ 00:00:10.25     │ 00:00:11 │
└────────────────────────┴───────┴─────────────────┴──────────┘
```

`HAVING runs >= 4` utilise l'alias du `SELECT` : DuckDB l'autorise dans `WHERE`, `GROUP BY` et `HAVING`, là où SQL Server t'oblige à répéter `count(*)`. Les exemples Java sont les plus longs, car le [cours Java](../../java-for-csharp/) compile et exécute le code de chaque leçon sur trois systèmes d'exploitation.

Deux choses que les données ne te disent pas directement :

- `updatedAt` est le dernier moment où l'exécution a changé, et `startedAt` le début de la **dernière tentative**. L'exécution de `GHA 09: debugging` relancée deux fois a été créée à 13:40:10 et a démarré à 13:44:02 : sa durée ne compte que la troisième tentative. La leçon 3 utilise plutôt les horodatages des jobs.
- `sum` n'accepte pas les intervalles, alors que `avg` les accepte :

```text
Binder Error: No function matches the given name and argument types 'sum(INTERVAL)'. You might need to add explicit type casts.
	Candidate functions:
	sum(DECIMAL) -> DECIMAL
```

Convertis d'abord en secondes avec `epoch(interval)` ou `date_diff('second', startedAt, updatedAt)`, puis reviens à un intervalle avec `to_seconds(…)` si tu en veux un : `to_seconds(sum(epoch(updatedAt - startedAt)))` donne `00:51:10` pour les 65 déploiements de ce site.

### Tronquer : exécutions par heure

```sql
SELECT date_trunc('hour', createdAt) AS hour, count(*) AS runs
FROM runs
GROUP BY ALL
ORDER BY hour
LIMIT 5;
```

```text
┌─────────────────────┬───────┐
│        hour         │ runs  │
│      timestamp      │ int64 │
├─────────────────────┼───────┤
│ 2026-09-13 15:00:00 │     1 │
│ 2026-09-13 16:00:00 │    10 │
│ 2026-09-13 17:00:00 │    16 │
│ 2026-09-13 18:00:00 │     7 │
│ 2026-09-13 19:00:00 │     9 │
└─────────────────────┴───────┘
```

[`date_trunc`](https://duckdb.org/docs/current/sql/functions/timestamp) s'appelle `DATETRUNC` dans SQL Server 2022. Un cast en `DATE` (`createdAt::DATE`) tronque au jour ; `hour(…)`, `dayofweek(…)` et les autres [parties de date](https://duckdb.org/docs/current/sql/functions/datepart) extraient un nombre.

## Fuseaux horaires

GitHub écrit `2026-09-13T15:53:16Z` : de l'UTC. DuckDB l'a lu comme un [`TIMESTAMP`](https://duckdb.org/docs/current/sql/data_types/timestamp), une date et une heure sans fuseau, comme `datetime2` dans SQL Server. `TIMESTAMP WITH TIME ZONE` (`TIMESTAMPTZ`) est un instant, comme `DateTimeOffset` en C# ou `Instant` en Java, **affiché dans le fuseau horaire de la session**. `AT TIME ZONE 'UTC'` indique dans quel fuseau était un `TIMESTAMP`, et le transforme en `TIMESTAMPTZ` :

```sql
SET TimeZone = 'Europe/Paris';
SELECT createdAt, createdAt AT TIME ZONE 'UTC' AS created_utc, hour(createdAt AT TIME ZONE 'UTC') AS hour_in_paris
FROM runs
ORDER BY createdAt
LIMIT 1;
```

```text
┌─────────────────────┬──────────────────────────┬───────────────┐
│      createdAt      │       created_utc        │ hour_in_paris │
│      timestamp      │ timestamp with time zone │     int64     │
├─────────────────────┼──────────────────────────┼───────────────┤
│ 2026-09-13 15:53:16 │ 2026-09-13 17:53:16+02   │            17 │
└─────────────────────┴──────────────────────────┴───────────────┘
```

Sans le `SET`, la CLI utilise le fuseau horaire du système d'exploitation. C'est pour ça que le script le fixe : les runners GitHub sont en UTC, et la sortie attendue ne correspondrait nulle part ailleurs. Toute sortie qui affiche un `TIMESTAMPTZ` dépend d'un paramètre, pas seulement des données. La prise en charge des fuseaux horaires vient de l'[extension ICU](https://duckdb.org/docs/current/core_extensions/icu), intégrée à la CLI.

## Fonctions de fenêtrage

Les [fonctions de fenêtrage](https://duckdb.org/docs/current/sql/functions/window_functions) fonctionnent comme dans SQL Server et PostgreSQL. La clause `WINDOW` nomme une fenêtre une seule fois, pour plusieurs fonctions :

```sql
SELECT createdAt, conclusion,
       lag(conclusion) OVER w AS previous,
       createdAt - lag(createdAt) OVER w AS since_previous
FROM runs
WHERE workflowName = 'Rust course examples'
WINDOW w AS (PARTITION BY workflowName ORDER BY createdAt)
ORDER BY createdAt
LIMIT 9;
```

```text
┌─────────────────────┬────────────┬──────────┬────────────────┐
│      createdAt      │ conclusion │ previous │ since_previous │
│      timestamp      │  varchar   │ varchar  │    interval    │
├─────────────────────┼────────────┼──────────┼────────────────┤
│ 2026-09-13 16:20:06 │ success    │ NULL     │ NULL           │
│ 2026-09-13 16:21:09 │ success    │ success  │ 00:01:03       │
│ 2026-09-13 16:45:55 │ success    │ success  │ 00:24:46       │
│ 2026-09-13 17:13:25 │ success    │ success  │ 00:27:30       │
│ 2026-09-13 17:40:34 │ failure    │ success  │ 00:27:09       │
│ 2026-09-13 17:41:56 │ failure    │ failure  │ 00:01:22       │
│ 2026-09-13 17:42:49 │ success    │ failure  │ 00:00:53       │
│ 2026-09-13 19:09:08 │ failure    │ success  │ 01:26:19       │
│ 2026-09-13 19:12:56 │ success    │ failure  │ 00:03:48       │
└─────────────────────┴────────────┴──────────┴────────────────┘
```

L'histoire de la CI du cours Rust se lit dans les écarts : un échec à 17:40, un second 82 secondes plus tard, corrigé 53 secondes après. La leçon 3 découvre quel step a échoué.

## `QUALIFY` : filtrer sur une fonction de fenêtrage

Quels workflows sont rouges en ce moment, c'est-à-dire lesquels ont une **dernière** exécution qui n'a pas réussi ? Dans SQL Server, une fonction de fenêtrage ne peut pas apparaître dans `WHERE`, il faut donc une sous-requête ou une CTE. [`QUALIFY`](https://duckdb.org/docs/current/sql/query_syntax/qualify) est un `WHERE` évalué après les fonctions de fenêtrage :

```sql
SELECT workflowName, conclusion, createdAt
FROM runs
QUALIFY row_number() OVER (PARTITION BY workflowName ORDER BY createdAt DESC) = 1
    AND conclusion <> 'success'
ORDER BY workflowName;
```

```text
┌─────────────────────────────────────┬─────────────────┬─────────────────────┐
│            workflowName             │   conclusion    │      createdAt      │
│               varchar               │     varchar     │      timestamp      │
├─────────────────────────────────────┼─────────────────┼─────────────────────┤
│ GHA 04: data between steps and jobs │ failure         │ 2026-09-14 12:47:40 │
│ GHA 04: exercise checks             │ failure         │ 2026-09-14 13:05:23 │
│ GHA 05: exercise checks             │ failure         │ 2026-09-14 13:18:20 │
│ GHA 06: exercise checks             │ failure         │ 2026-09-14 13:24:13 │
│ GHA 06: undeclared input            │ startup_failure │ 2026-09-14 13:24:30 │
│ GHA 09: debugging                   │ cancelled       │ 2026-09-14 13:40:10 │
│ GHA 10: exercise checks             │ failure         │ 2026-09-14 13:53:12 │
└─────────────────────────────────────┴─────────────────┴─────────────────────┘
```

Les deux conditions ne peuvent pas passer dans `WHERE` : `conclusion <> 'success'` dans `WHERE` retirerait les exécutions vertes **avant** la numérotation, et tous les workflows ayant au moins un échec apparaîtraient. Les sept sont des exercices du cours GitHub Actions, rouges exprès.

## `PIVOT`

[`PIVOT`](https://duckdb.org/docs/current/sql/statements/pivot) transforme les valeurs d'une colonne en colonnes. Contrairement au [`PIVOT` de SQL Server](https://learn.microsoft.com/sql/t-sql/queries/from-using-pivot-and-unpivot), il n'a pas besoin de la liste des valeurs :

```sql
PIVOT (FROM runs WHERE workflowName IN ('Deploy to GitHub Pages', 'Rust course examples', 'Java course examples', 'GHA 03: triggers'))
ON conclusion
USING count(*)
GROUP BY workflowName
ORDER BY workflowName;
```

```text
┌────────────────────────┬───────────┬─────────┬─────────┐
│      workflowName      │ cancelled │ failure │ success │
│        varchar         │   int64   │  int64  │  int64  │
├────────────────────────┼───────────┼─────────┼─────────┤
│ Deploy to GitHub Pages │         0 │       2 │      63 │
│ GHA 03: triggers       │         2 │       2 │       1 │
│ Java course examples   │         0 │       0 │       7 │
│ Rust course examples   │         0 │       3 │      15 │
└────────────────────────┴───────────┴─────────┴─────────┘
```

- Les colonnes sont les valeurs trouvées dans les données, donc elles changent avec les données : `startup_failure` existe dans `runs`, mais aucun de ces quatre workflows n'en a eu, et la colonne n'est pas là. Du code qui lit un pivot par nom de colonne doit s'y attendre.
- Sans `ORDER BY`, l'ordre des lignes n'est pas défini. Un premier essai de `PIVOT runs ON event USING count(*) GROUP BY conclusion` a renvoyé `success`, `cancelled`, `startup_failure`, `failure`, dans un ordre sans intérêt. Les scripts du cours se terminent toujours par `ORDER BY`, sinon leur sortie ne pourrait pas être comparée.

## Raccourcis pour les colonnes

```sql
SELECT headSha[1:7] AS sha, min(COLUMNS('.*At'))
FROM runs
GROUP BY ALL
ORDER BY ALL
LIMIT 3;
```

```text
┌─────────┬─────────────────────┬─────────────────────┬─────────────────────┐
│   sha   │      createdAt      │      startedAt      │      updatedAt      │
│ varchar │      timestamp      │      timestamp      │      timestamp      │
├─────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ 04c8770 │ 2026-09-13 17:52:33 │ 2026-09-13 17:52:33 │ 2026-09-13 17:53:19 │
│ 1adf60f │ 2026-09-13 16:50:10 │ 2026-09-13 16:50:10 │ 2026-09-13 16:50:43 │
│ 1de721b │ 2026-09-14 12:46:38 │ 2026-09-14 12:46:38 │ 2026-09-14 12:47:29 │
└─────────┴─────────────────────┴─────────────────────┴─────────────────────┘
```

- `headSha[1:7]` extrait une tranche d'une chaîne, bornes incluses, en comptant à partir de 1 : le hash court du commit.
- [`COLUMNS('.*At')`](https://duckdb.org/docs/current/sql/expressions/star) se développe en chaque colonne dont le nom correspond à l'expression régulière, et `min(COLUMNS(…))` applique `min` à chacune : un agrégat écrit, trois calculés.
- `ORDER BY ALL` trie par toutes les colonnes, de gauche à droite.
- `SELECT * EXCLUDE (headSha, status)` sélectionne tout sauf certaines colonnes, et `SELECT * REPLACE (headSha[1:7] AS headSha)` en modifie une en gardant sa place.

## À retenir

- La soustraction de timestamps donne des intervalles ; `avg` et `max` acceptent les intervalles, `sum` non : passe par `epoch`.
- Un `TIMESTAMP` n'a pas de fuseau ; un `TIMESTAMPTZ` s'affiche dans le fuseau de la session, donc fixe `TimeZone` dans tout ce que tu compares.
- `QUALIFY` filtre sur des fonctions de fenêtrage sans sous-requête.
- `PIVOT` trouve ses colonnes dans les données ; trie les lignes toi-même.
- `GROUP BY ALL`, `ORDER BY ALL`, `COLUMNS`, `EXCLUDE` et les alias dans `HAVING` suppriment les répétitions.

## Exercices

Les solutions sont dans [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/02-exercises.sql), vérifiées par la CI.

1. Pour chaque jour UTC, combien d'exécutions, et quel pourcentage n'a pas réussi, à une décimale près ?

<details>
<summary>Solution</summary>

```sql
SELECT createdAt::DATE AS day, count(*) AS runs,
       round(100 * count(*) FILTER (conclusion <> 'success') / count(*), 1) AS not_green_pct
FROM runs
GROUP BY ALL
ORDER BY day;
```

```text
┌────────────┬───────┬───────────────┐
│    day     │ runs  │ not_green_pct │
│    date    │ int64 │    double     │
├────────────┼───────┼───────────────┤
│ 2026-09-13 │    43 │           7.0 │
│ 2026-09-14 │    82 │          22.0 │
└────────────┴───────┴───────────────┘
```

Le second jour est celui du cours GitHub Actions et de ses exercices en échec. Remarque `100 * … / count(*)` : dans DuckDB, `/` entre deux entiers renvoie un `DOUBLE` (`7 / 2` vaut `3.5`), et `//` est la division entière. Dans SQL Server et en C#, la même expression aurait tronqué à `6` et `21`.

</details>

2. Pour chaque exécution en échec, combien de temps son workflow est-il resté rouge, c'est-à-dire jusqu'à la prochaine exécution réussie du même workflow ? Liste d'abord les échecs qui n'ont jamais été corrigés.

<details>
<summary>Solution</summary>

```sql
SELECT workflowName, createdAt AS failed_at,
       min(createdAt) FILTER (conclusion = 'success') OVER (
           PARTITION BY workflowName ORDER BY createdAt
           ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) - createdAt AS red_for
FROM runs
QUALIFY conclusion = 'failure'
ORDER BY red_for DESC NULLS FIRST, workflowName, failed_at;
```

```text
┌─────────────────────────────────────┬─────────────────────┬──────────┐
│            workflowName             │      failed_at      │ red_for  │
│               varchar               │      timestamp      │ interval │
├─────────────────────────────────────┼─────────────────────┼──────────┤
│ GHA 04: data between steps and jobs │ 2026-09-14 12:47:40 │ NULL     │
│ GHA 04: exercise checks             │ 2026-09-14 13:05:23 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:12:27 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:16:06 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:18:20 │ NULL     │
│ GHA 06: exercise checks             │ 2026-09-14 13:24:13 │ NULL     │
│ GHA 10: exercise checks             │ 2026-09-14 13:53:12 │ NULL     │
│ Rust course examples                │ 2026-09-13 19:09:08 │ 00:03:48 │
│ Deploy to GitHub Pages              │ 2026-09-14 13:36:16 │ 00:03:46 │
│ Rust course examples                │ 2026-09-13 17:40:34 │ 00:02:15 │
│ GHA 09: exercise checks             │ 2026-09-14 13:46:43 │ 00:02:13 │
│ GHA 03: triggers                    │ 2026-09-14 12:45:24 │ 00:02:05 │
│ GHA 03: triggers                    │ 2026-09-14 12:45:38 │ 00:01:51 │
│ GHA 10: custom actions              │ 2026-09-14 13:53:04 │ 00:01:03 │
│ Deploy to GitHub Pages              │ 2026-09-14 12:45:39 │ 00:00:59 │
│ Rust course examples                │ 2026-09-13 17:41:56 │ 00:00:53 │
└─────────────────────────────────────┴─────────────────────┴──────────┘
```

- Le cadre de la fenêtre commence à `1 FOLLOWING`, l'exécution qui suit l'échec ; `FILTER` dans un agrégat de fenêtrage ne garde que les succès. `min(createdAt)` est alors la prochaine exécution verte.
- Le filtre sur les échecs doit être dans `QUALIFY` : dans `WHERE`, il retirerait les succès avant que la fenêtre les cherche, et chaque `red_for` vaudrait `NULL`.
- `NULLS FIRST` met en tête les échecs jamais corrigés ; DuckDB trie `NULL` en dernier par défaut, dans les deux sens.

</details>

3. Réécris la requête `QUALIFY` de cette leçon, les workflows dont la dernière exécution n'est pas verte, sans aucune fonction de fenêtrage.

<details>
<summary>Solution</summary>

```sql
SELECT workflowName, arg_max(conclusion, createdAt) AS last_conclusion
FROM runs
GROUP BY ALL
HAVING last_conclusion <> 'success'
ORDER BY workflowName;
```

```text
┌─────────────────────────────────────┬─────────────────┐
│            workflowName             │ last_conclusion │
│               varchar               │     varchar     │
├─────────────────────────────────────┼─────────────────┤
│ GHA 04: data between steps and jobs │ failure         │
│ GHA 04: exercise checks             │ failure         │
│ GHA 05: exercise checks             │ failure         │
│ GHA 06: exercise checks             │ failure         │
│ GHA 06: undeclared input            │ startup_failure │
│ GHA 09: debugging                   │ cancelled       │
│ GHA 10: exercise checks             │ failure         │
└─────────────────────────────────────┴─────────────────┘
```

[`arg_max(value, key)`](https://duckdb.org/docs/current/sql/functions/aggregates) renvoie `value` depuis la ligne où `key` est la plus grande : la conclusion de l'exécution la plus récente. Les mêmes sept workflows. `QUALIFY` est l'outil général, puisqu'il peut renvoyer des lignes entières ou le top 3 ; `arg_max` est plus court quand une valeur par groupe suffit.

</details>

## Sources

- [Fonctions d'intervalle](https://duckdb.org/docs/current/sql/functions/interval), [fonctions de timestamp](https://duckdb.org/docs/current/sql/functions/timestamp) et [parties de date](https://duckdb.org/docs/current/sql/functions/datepart)
- [Types timestamp](https://duckdb.org/docs/current/sql/data_types/timestamp) et [fuseaux horaires](https://duckdb.org/docs/current/sql/data_types/timezones)
- [Fonctions de fenêtrage](https://duckdb.org/docs/current/sql/functions/window_functions), [`WINDOW`](https://duckdb.org/docs/current/sql/query_syntax/window) et [`QUALIFY`](https://duckdb.org/docs/current/sql/query_syntax/qualify)
- [`PIVOT`](https://duckdb.org/docs/current/sql/statements/pivot)
- [Expressions étoile : `COLUMNS`, `EXCLUDE`, `REPLACE`](https://duckdb.org/docs/current/sql/expressions/star)
- [`ORDER BY`](https://duckdb.org/docs/current/sql/query_syntax/orderby) et [fonctions d'agrégat](https://duckdb.org/docs/current/sql/functions/aggregates)
