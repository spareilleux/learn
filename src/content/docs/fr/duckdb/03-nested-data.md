---
title: 3. Données imbriquées
description: Listes et structs issues du JSON, unnest pour transformer une liste en lignes, lambdas pour filtrer des listes sur place, ANTI JOIN, et construction de valeurs imbriquées — sur les jobs et les steps de la CI de ce site.
sidebar:
  order: 3
---

Les exécutions des leçons 1 et 2 sont plates : une valeur par champ. Leurs jobs, non. Les requêtes sont dans [`sql/03-nested-data.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/03-nested-data.sql).

## Le fichier des jobs

`data/jobs.json` contient les 315 jobs des exécutions, tels que les renvoie le point de terminaison de l'API REST de GitHub [List jobs for a workflow run](https://docs.github.com/rest/actions/workflow-jobs), avec une partie des champs. Pour une exécution relancée, l'API ne renvoie que les jobs de la dernière tentative : 4 jobs pour l'exécution `GHA 09: debugging`, tentée trois fois, là où `?filter=all` en renvoie 12. Un job, abrégé :

```json
{
  "id": 104004920113,
  "run_id": 34852867099,
  "name": "build",
  "conclusion": "success",
  "started_at": "2026-09-14T14:01:14Z",
  "labels": ["ubuntu-latest"],
  "steps": [
    {"number": 1, "name": "Set up job", "conclusion": "success", "started_at": "2026-09-14T14:01:15Z", "completed_at": "2026-09-14T14:01:19Z"},
    …
  ]
}
```

```sql
CREATE TABLE runs AS FROM 'data/runs.json';
CREATE TABLE jobs AS FROM 'data/jobs.json';
DESCRIBE jobs;
```

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                          jobs                                                          │
│                                                                                                                        │
│ id           bigint                                                                                                    │
│ run_id       bigint                                                                                                    │
│ name         varchar                                                                                                   │
│ status       varchar                                                                                                   │
│ conclusion   varchar                                                                                                   │
│ created_at   timestamp                                                                                                 │
│ started_at   timestamp                                                                                                 │
│ completed_at timestamp                                                                                                 │
│ runner_name  varchar                                                                                                   │
│ labels       varchar[]                                                                                                 │
│ steps        struct(number bigint, "name" varchar, conclusion varchar, started_at timestamp, completed_at timestamp)[] │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

Le lecteur JSON a transformé les tableaux en types [`LIST`](https://duckdb.org/docs/current/sql/data_types/list), notés `type[]`, et les objets en types [`STRUCT`](https://duckdb.org/docs/current/sql/data_types/struct), avec des champs nommés et typés. `steps` est une liste de structs. En C#, c'est une propriété `List<Step>` sur un record `Job` ; dans SQL Server, le JSON resterait une chaîne `nvarchar(max)`, et chaque requête repasserait par `OPENJSON`.

## Lire dans les listes et les structs

Extrait de [`sql/03-nested-data.sql`, lignes 6-9](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L6-L9) :

```sql
SELECT name, labels, labels[1] AS os, labels[0] AS index_zero, len(steps) AS steps, steps[1].name AS first_step
FROM jobs
ORDER BY id
LIMIT 3;
```

```text
┌─────────┬─────────────────┬───────────────┬────────────┬───────┬────────────┐
│  name   │     labels      │      os       │ index_zero │ steps │ first_step │
│ varchar │    varchar[]    │    varchar    │  varchar   │ int64 │  varchar   │
├─────────┼─────────────────┼───────────────┼────────────┼───────┼────────────┤
│ build   │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     6 │ Set up job │
│ deploy  │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     3 │ Set up job │
│ build   │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     6 │ Set up job │
└─────────┴─────────────────┴───────────────┴────────────┴───────┴────────────┘
```

- **Les listes commencent à 1**, comme partout en SQL. `labels[0]` n'est pas une erreur, juste `NULL`, tout comme un indice au-delà de la fin : une habitude de C# ou de Java qui échoue en silence.
- `steps[1].name` lit un champ d'une struct avec un point, comme une propriété.
- `len` compte les éléments d'une liste.

## `unnest` : une ligne par élément

[`unnest`](https://duckdb.org/docs/current/sql/query_syntax/unnest) transforme une liste en lignes. Placé dans la clause `FROM` après la table, il s'exécute une fois par job, avec accès aux colonnes de ce job : le `CROSS APPLY OPENJSON(...)` de SQL Server, ou `SelectMany` en LINQ.

Extrait de [`sql/03-nested-data.sql`, lignes 12-15](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L12-L15) :

```sql
SELECT j.name AS job, s.number, s.name AS step, s.completed_at - s.started_at AS took
FROM jobs j, unnest(j.steps) AS t(s)
WHERE j.id = 104004920113
ORDER BY s.number;
```

```text
┌─────────┬────────┬──────────────────────────────────────┬──────────┐
│   job   │ number │                 step                 │   took   │
│ varchar │ int64  │               varchar                │ interval │
├─────────┼────────┼──────────────────────────────────────┼──────────┤
│ build   │      1 │ Set up job                           │ 00:00:04 │
│ build   │      2 │ Checkout                             │ 00:00:02 │
│ build   │      3 │ Install, build, and upload site      │ 00:00:48 │
│ build   │      5 │ Post Install, build, and upload site │ 00:00:00 │
│ build   │      6 │ Post Checkout                        │ 00:00:01 │
│ build   │      7 │ Complete job                         │ 00:00:00 │
└─────────┴────────┴──────────────────────────────────────┴──────────┘
```

`AS t(s)` nomme la table `t` et son unique colonne `s`, une struct. C'est le job de build du déploiement de ce site : 48 de ses 58 secondes sont passées dans le step `withastro/action`. Le step 4 manque dans la réponse de l'API elle-même (`gh run view 34852867099 --json jobs` montre les mêmes numéros) ; probablement un step interne de cette action composite, *à vérifier*.

## Agréger des données imbriquées

Le même schéma que pour des données plates, une fois la liste dépliée. Les horodatages des jobs donnent une meilleure durée que les champs des exécutions de la leçon 2, et une de plus : le temps passé **à attendre** un runner, de `created_at` à `started_at`.

Extrait de [`sql/03-nested-data.sql`, lignes 18-22](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L18-L22) :

```sql
SELECT labels[1] AS os, count(*) AS jobs,
       avg(started_at - created_at) AS avg_wait, avg(completed_at - started_at) AS avg_run
FROM jobs
GROUP BY ALL
ORDER BY os;
```

```text
┌────────────────┬───────┬─────────────────┬────────────────┐
│       os       │ jobs  │    avg_wait     │    avg_run     │
│    varchar     │ int64 │    interval     │    interval    │
├────────────────┼───────┼─────────────────┼────────────────┤
│ macos-latest   │    34 │ 00:00:08.470596 │ 00:00:55.67649 │
│ ubuntu-latest  │   246 │ 00:00:03.5      │ 00:00:21.43097 │
│ windows-latest │    35 │ 00:00:03.4      │ 00:01:36.71431 │
└────────────────┴───────┴─────────────────┴────────────────┘
```

Les runners macOS mettent plus de deux fois plus de temps à démarrer ; les jobs Windows durent plus de quatre fois plus longtemps que les jobs Ubuntu. La comparaison n'est pas équitable, car la plupart des jobs Ubuntu sont de petits jobs comme le déploiement du site ; l'exercice 3 compare le même job sur les trois systèmes.

## Lambdas : travailler sur une liste sans la déplier

Quels steps échouent le plus ? Chaque job garde ses steps en échec dans sa propre liste ; [`list_filter`](https://duckdb.org/docs/current/sql/functions/list) garde les éléments pour lesquels une [lambda](https://duckdb.org/docs/current/sql/functions/lambda) est vraie, avant que `unnest` transforme ce qui reste en lignes ([lignes 25-31](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L25-L31)) :

```sql
SELECT f.name AS failed_step, count(*) AS failures, list(DISTINCT r.workflowName ORDER BY r.workflowName) AS workflows
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id,
     unnest(list_filter(j.steps, lambda s: s.conclusion = 'failure')) AS t(f)
GROUP BY ALL
ORDER BY failures DESC, failed_step
LIMIT 5;
```

```text
┌───────────────────────────────────────┬──────────┬───────────────────────────────────────────────────────┐
│              failed_step              │ failures │                       workflows                       │
│                varchar                │  int64   │                       varchar[]                       │
├───────────────────────────────────────┼──────────┼───────────────────────────────────────────────────────┤
│ Formatting                            │        6 │ [Rust course examples]                                │
│ Run actions/setup-dotnet@v6           │        3 │ ['GHA 05: exercise checks']                           │
│ Run exit 3                            │        3 │ ['GHA 09: debugging', 'GHA 09: exercise checks']      │
│ Run ./.github/actions/hello-container │        2 │ ['GHA 10: custom actions', 'GHA 10: exercise checks'] │
│ Compile-fail doctests                 │        1 │ [Rust course examples]                                │
└───────────────────────────────────────┴──────────┴───────────────────────────────────────────────────────┘
```

- Deux des trois échecs Rust de la leçon 2 venaient du formatage, `cargo fmt --check`, sur chacun des trois systèmes d'exploitation ; le troisième était un doctest compile-fail. `Run actions/setup-dotnet@v6` est le fichier de verrouillage manquant du cours GitHub Actions, leçon 5.
- `lambda s: s.conclusion = 'failure'` est la lambda C# `s => s.Conclusion == "failure"`. `list_transform` est `Select`, `list_filter` est `Where`, `list_reduce` est `Aggregate`.
- `list(… ORDER BY …)` est un agrégat qui construit une liste : `STRING_AGG` sans la chaîne. Certaines valeurs sont entre guillemets simples à l'affichage (`'GHA 05: exercise checks'`) et d'autres non (`Rust course examples`) : les guillemets appartiennent à l'affichage, pas aux valeurs.

La syntaxe fléchée qu'on trouve dans des exemples plus anciens fonctionne encore en 1.5.5, avec un avertissement :

```text
WARNING:
Deprecated lambda arrow (->) detected. Please transition to the new lambda syntax, i.e.., lambda x, i: x + i, before DuckDB's next release.
Use SET lambda_syntax='ENABLE_SINGLE_ARROW' to revert to the deprecated behavior.
For more information, see https://duckdb.org/docs/stable/sql/functions/lambda.html.
```

## `ANTI JOIN` : les lignes sans correspondance

125 exécutions dans `runs.json`, mais `count(DISTINCT run_id)` dans `jobs` vaut 121. Quelles exécutions n'ont aucun job ? `NOT EXISTS` fonctionne, et le [`ANTI JOIN`](https://duckdb.org/docs/current/sql/query_syntax/from) de DuckDB aussi, qui se lit comme ce qu'il fait ([lignes 34-37](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L34-L37)) :

```sql
SELECT r.workflowName, r.event, r.conclusion, r.createdAt
FROM runs r
ANTI JOIN jobs j ON j.run_id = r.databaseId
ORDER BY r.createdAt;
```

```text
┌──────────────────────────┬───────────────────┬─────────────────┬─────────────────────┐
│       workflowName       │       event       │   conclusion    │      createdAt      │
│         varchar          │      varchar      │     varchar     │      timestamp      │
├──────────────────────────┼───────────────────┼─────────────────┼─────────────────────┤
│ GHA 03: triggers         │ push              │ failure         │ 2026-09-14 12:45:24 │
│ GHA 03: triggers         │ push              │ failure         │ 2026-09-14 12:45:38 │
│ GHA 03: triggers         │ workflow_dispatch │ cancelled       │ 2026-09-14 12:47:19 │
│ GHA 06: undeclared input │ push              │ startup_failure │ 2026-09-14 13:24:30 │
└──────────────────────────┴───────────────────┴─────────────────┴─────────────────────┘
```

Les quatre figurent dans le [journal du cours GitHub Actions](../../github-actions/journal/) : les deux pushs d'un fichier de workflow au YAML invalide, une exécution manuelle annulée par une plus récente avant le démarrage de son job, et le workflow qui en appelait un autre avec un input non déclaré. Une exécution peut échouer sans rien exécuter. `SEMI JOIN` est l'inverse : les lignes qui **ont** une correspondance, chacune une seule fois, comme `EXISTS`.

## Construire des valeurs imbriquées

Dans l'autre sens : regrouper des lignes en une liste de structs, avec un littéral de struct `{'key': value}` ([lignes 40-43](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L40-L43)) :

```sql
SELECT run_id, list({'job': name, 'conclusion': conclusion} ORDER BY name) AS jobs
FROM jobs
WHERE run_id = (SELECT databaseId FROM runs WHERE workflowName = 'GHA 10: exercise checks')
GROUP BY ALL;
```

```text
┌─────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│   run_id    │                                                                   jobs                                                                   │
│    int64    │                                                struct(job varchar, conclusion varchar)[]                                                 │
├─────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 34852035176 │ [{'job': commonjs, 'conclusion': failure}, {'job': container-on-windows, 'conclusion': failure}, {'job': inputs, 'conclusion': success}] │
└─────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

`to_json` transforme n'importe quelle valeur en texte JSON, pour une réponse d'API ou un fichier : `to_json({'job': 'commonjs', 'steps': [1, 2]})` donne `{"job":"commonjs","steps":[1,2]}`.

## À retenir

- Les tableaux JSON deviennent des `LIST`, les objets des `STRUCT`, avec des types ; les données imbriquées restent interrogeables sans analyser de chaînes.
- Les listes sont indexées à partir de 1, et un indice hors limites donne `NULL`, pas une erreur.
- `unnest` dans la clause `FROM` transforme une liste en lignes, comme `CROSS APPLY` ou `SelectMany`.
- `list_filter` et `list_transform` avec `lambda x: …` travaillent sur une liste sur place.
- `ANTI JOIN` et `SEMI JOIN` disent directement « sans correspondance » et « avec correspondance ».
- `list(…)` et `{'key': value}` reconstruisent des valeurs imbriquées.

## Exercices

Les solutions sont dans [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/03-exercises.sql), vérifiées par la CI.

1. Certains jobs n'ont aucun step. Lesquels, et que contient leur `runner_name` ?

<details>
<summary>Solution</summary>

Extrait de [`sql/03-exercises.sql`, lignes 6-10](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-exercises.sql#L6-L10) :

```sql
SELECT r.workflowName, j.name AS job, j.conclusion, j.runner_name, j.runner_name IS NULL AS runner_is_null
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id
WHERE len(j.steps) = 0
ORDER BY j.id;
```

```text
┌─────────────────────────────────────┬──────────────┬────────────┬─────────────┬────────────────┐
│            workflowName             │     job      │ conclusion │ runner_name │ runner_is_null │
│               varchar               │   varchar    │  varchar   │   varchar   │    boolean     │
├─────────────────────────────────────┼──────────────┼────────────┼─────────────┼────────────────┤
│ GHA 04: data between steps and jobs │ consume      │ skipped    │ NULL        │ true           │
│ Deploy to GitHub Pages              │ deploy       │ failure    │             │ false          │
│ GHA 09: exercise checks             │ job-timeout  │ skipped    │ NULL        │ true           │
│ GHA 09: exercise checks             │ step-timeout │ skipped    │ NULL        │ true           │
└─────────────────────────────────────┴──────────────┴────────────┴─────────────┴────────────────┘
```

Trois jobs ignorés (skipped), qui n'ont jamais reçu de runner : `NULL`. Et un job `deploy` en échec sans aucun step : le déploiement depuis une branche autre que `main`, rejeté par la règle de branche de l'environnement dans le cours GitHub Actions. Il a reçu une **chaîne vide** comme nom de runner, pas `NULL`. `WHERE runner_name IS NULL` le manquerait : teste les deux, ou `coalesce(runner_name, '') = ''`, chaque fois que la source est le JSON de quelqu'un d'autre.

</details>

2. `SELECT name, unnest(steps, recursive := true) FROM jobs` déplie chaque struct de step en colonnes. Le job a un `name`, et chaque step aussi. Comment s'appellent les colonnes ?

<details>
<summary>Solution</summary>

Dans l'affichage de la CLI, deux colonnes s'appellent toutes les deux `name`. Les référencer depuis une requête externe montre les vrais noms ([`sql/03-exercises.sql`, lignes 13-16](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-exercises.sql#L13-L16)) :

```sql
SELECT name, name_1, conclusion
FROM (SELECT name, unnest(steps, recursive := true) FROM jobs WHERE id = 104004920113)
ORDER BY number
LIMIT 3;
```

```text
┌─────────┬─────────────────────────────────┬────────────┐
│  name   │             name_1              │ conclusion │
│ varchar │             varchar             │  varchar   │
├─────────┼─────────────────────────────────┼────────────┤
│ build   │ Set up job                      │ success    │
│ build   │ Checkout                        │ success    │
│ build   │ Install, build, and upload site │ success    │
└─────────┴─────────────────────────────────┴────────────┘
```

La [règle de déduplication](https://duckdb.org/docs/current/sql/dialect/keywords_and_identifiers) garde le premier `name` et renomme le suivant `name_1`. Et `conclusion` est celle **du step** : le job n'a pas de `conclusion` dans cette sous-requête, puisque seul `name` a été sélectionné. Quand les deux côtés ont des champs en commun, donne-leur explicitement des alias, comme le fait la leçon avec `j.name AS job, s.name AS step`.

</details>

3. `GHA 02: build and test` compile les mêmes projets .NET et Java sur trois systèmes d'exploitation. Quel est le step le plus lent sur chacun ?

<details>
<summary>Solution</summary>

Extrait de [`sql/03-exercises.sql`, lignes 19-25](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-exercises.sql#L19-L25) :

```sql
SELECT j.labels[1] AS os, j.name AS job, s.name AS step, s.completed_at - s.started_at AS took
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id,
     unnest(j.steps) AS t(s)
WHERE r.workflowName = 'GHA 02: build and test'
QUALIFY row_number() OVER (PARTITION BY os ORDER BY took DESC, j.id, s.number) = 1
ORDER BY os;
```

```text
┌────────────────┬─────────────────────────┬─────────────────────────────┬──────────┐
│       os       │           job           │            step             │   took   │
│    varchar     │         varchar         │           varchar           │ interval │
├────────────────┼─────────────────────────┼─────────────────────────────┼──────────┤
│ macos-latest   │ dotnet (macos-latest)   │ Run actions/setup-dotnet@v6 │ 00:00:11 │
│ ubuntu-latest  │ java (ubuntu-latest)    │ Run mvn -B verify           │ 00:00:11 │
│ windows-latest │ dotnet (windows-latest) │ Run actions/setup-dotnet@v6 │ 00:00:31 │
└────────────────┴─────────────────────────┴─────────────────────────────┴──────────┘
```

Sous Windows et macOS, installer le SDK .NET coûte plus que n'importe quelle compilation ou n'importe quel test. Sous Ubuntu, où c'est plus rapide, la compilation et les tests de Maven passent en tête. `j.id, s.number` dans le `ORDER BY` de la fenêtre départagent les ex æquo : plusieurs steps peuvent durer le même nombre entier de secondes, et sans critère de départage `row_number()` en choisirait un arbitrairement, peut-être un autre à l'exécution suivante.

</details>

## Sources

- Types [liste](https://duckdb.org/docs/current/sql/data_types/list) et [struct](https://duckdb.org/docs/current/sql/data_types/struct)
- [`unnest`](https://duckdb.org/docs/current/sql/query_syntax/unnest)
- [Fonctions de liste](https://duckdb.org/docs/current/sql/functions/list) et [fonctions lambda](https://duckdb.org/docs/current/sql/functions/lambda)
- [`FROM` et jointures, dont `SEMI` et `ANTI`](https://duckdb.org/docs/current/sql/query_syntax/from)
- [Charger du JSON](https://duckdb.org/docs/current/data/json/overview)
- [API REST de GitHub : jobs de workflow](https://docs.github.com/rest/actions/workflow-jobs)
