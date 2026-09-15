---
title: "3. Requêtes : CTE, fenêtres, LATERAL, upserts et MERGE"
description: Le SQL que PostgreSQL écrit autrement que T-SQL, sur le modèle du cours — CTE et WITH RECURSIVE avec un cycle et la clause CYCLE, fonctions de fenêtrage et FILTER, LATERAL pour CROSS APPLY, DISTINCT ON, RETURNING avec old et new, INSERT … ON CONFLICT et MERGE avec merge_action() ; et ce qu'ils trouvent dans l'historique de CI de ce site et dans les dépendances de Guitar Alchemist.
sidebar:
  order: 3
---

Le script de la leçon est [`sql/03-queries.sql`](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql), les exercices sont dans [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql), et `check.sh` compare leur sortie à [`expected/03-queries.txt`](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/expected/03-queries.txt) et [`expected/03-exercises.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/03-exercises.txt). Les deux scripts commencent par charger le modèle de la [leçon 2](../02-types/).

Jointures, `GROUP BY` et sous-requêtes s'écrivent de la même façon dans les deux dialectes, donc cette leçon les laisse de côté. Elle couvre ce qu'un développeur SQL Server écrit autrement, ou ne peut pas écrire du tout.

| T-SQL | PostgreSQL |
|---|---|
| `SELECT TOP (1) …` dans une sous-requête, ou `ROW_NUMBER()` et un filtre | `DISTINCT ON (…)` |
| `CROSS APPLY`, `OUTER APPLY` | `CROSS JOIN LATERAL`, `LEFT JOIN LATERAL … ON true` |
| `OPTION (MAXRECURSION n)` | `statement_timeout`, `UNION`, la clause `CYCLE` |
| `SUM(CASE WHEN … THEN 1 END)` | `count(*) FILTER (WHERE …)` |
| `OUTPUT inserted.*, deleted.*` | `RETURNING new.*, old.*` |
| `MERGE … WITH (HOLDLOCK)` pour insérer ou mettre à jour | `INSERT … ON CONFLICT DO UPDATE` |
| `MERGE … OUTPUT $action` | `MERGE … RETURNING merge_action()` |

## CTE

Une expression de table commune nomme une requête pour l'instruction qui suit, comme en T-SQL ([lignes 7-16](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L7-L16)) :

```sql
WITH failed_runs AS (
    SELECT run_id, workflow_name FROM ci.runs WHERE conclusion = 'failure'
)
SELECT f.workflow_name, count(DISTINCT f.run_id) AS failed_runs,
       count(j.job_id) FILTER (WHERE j.conclusion = 'failure') AS failed_jobs
FROM failed_runs AS f
LEFT JOIN ci.jobs AS j USING (run_id)
GROUP BY f.workflow_name
ORDER BY failed_runs DESC, f.workflow_name
LIMIT 5;
```

```text
            workflow_name            | failed_runs | failed_jobs
-------------------------------------+-------------+-------------
 GHA 05: exercise checks             |           3 |           3
 Rust course examples                |           3 |           7
 Deploy to GitHub Pages              |           2 |           2
 GHA 03: triggers                    |           2 |           0
 GHA 04: data between steps and jobs |           1 |           1
(5 rows)
```

- `USING (run_id)` joint sur la colonne de ce nom dans les deux tables, et ne garde qu'une colonne `run_id` dans le résultat.
- [`FILTER (WHERE …)`](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES) restreint un agrégat à certaines lignes. T-SQL écrit `COUNT(CASE WHEN j.conclusion = 'failure' THEN 1 END)`.
- `GHA 03: triggers` a deux exécutions en échec et aucun job en échec : ces deux exécutions n'ont aucun job dans l'instantané.

Depuis PostgreSQL 12, une CTE référencée une seule fois et sans effet de bord est intégrée à la requête, comme une vue ; `WITH … AS MATERIALIZED` impose l'ancien comportement, qui la calcule une fois ([requêtes `WITH`](https://www.postgresql.org/docs/18/queries-with.html)).

## CTE récursives

Les références de projets de Guitar Alchemist forment un graphe. `WITH RECURSIVE` le parcourt depuis `GaApi` : le premier `SELECT` donne les références directes, et le second joint les lignes trouvées jusque-là aux références de ces projets, jusqu'à ce qu'un tour ne trouve rien de nouveau ([lignes 19-29](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L19-L29)) :

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth
    FROM ga.project_refs
    WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.depth + 1
    FROM deps AS d
    JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) AS paths, count(DISTINCT to_path) AS projects, max(depth) AS longest_path
FROM deps;
```

```text
 paths | projects | longest_path
-------+----------+--------------
   435 |       20 |            7
(1 row)
```

`GaApi` dépend de 20 projets, atteints par 435 chemins différents : un losange de dépendances compte une fois par chemin. Le plus long chemin fait 7 références.

Le chemin lui-même peut être transporté dans un tableau. `DISTINCT ON` garde la plus courte chaîne vers chaque projet ; il est expliqué plus bas ([lignes 32-49](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L32-L49)) :

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, ARRAY[split_part(to_path, '/', -1)] AS chain
    FROM ga.project_refs
    WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.chain || split_part(r.to_path, '/', -1)
    FROM deps AS d
    JOIN ga.project_refs AS r ON r.from_path = d.to_path
),
shortest AS (
    SELECT DISTINCT ON (to_path) to_path, chain
    FROM deps
    ORDER BY to_path, cardinality(chain), chain
)
SELECT cardinality(chain) AS depth, array_to_string(chain, ' > ') AS chain
FROM shortest
WHERE cardinality(chain) >= 3
ORDER BY chain;
```

```text
 depth |                                   chain
-------+----------------------------------------------------------------------------
     3 | GA.Business.AI.csproj > GA.Data.MongoDB.csproj > GA.Business.Assets.csproj
(1 row)
```

[`split_part`](https://www.postgresql.org/docs/18/functions-string.html) avec un indice négatif compte depuis la fin, depuis PostgreSQL 14 : `-1` est le nom du fichier. Un seul projet est à trois références, même par le plus court chemin : les 19 autres sont à une ou deux références de `GaApi`.

### Un cycle

Les références de projets .NET ne peuvent pas former de cycle : MSBuild refuse d'en construire un. Les données, si. Le script ajoute la référence `GA.Core → GaApi`, et relance la première requête ([lignes 52-60](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L52-L60)) :

```sql
INSERT INTO ga.project_refs VALUES ('Common/GA.Core/GA.Core.csproj', 'Apps/ga-server/GaApi/GaApi.csproj');
SET statement_timeout = '3s';
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION
    SELECT r.to_path, d.depth + 1 FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) FROM deps;
RESET statement_timeout;
```

```text
INSERT 0 1
SET
ERROR:  canceling statement due to statement timeout
RESET
```

La requête ne se termine jamais : chaque tour retrouve les mêmes projets, un niveau plus bas, et `depth` rend chaque ligne nouvelle, donc `UNION`, qui supprime les lignes en double, ne supprime rien. [`statement_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-STATEMENT-TIMEOUT) l'arrête au bout de 3 secondes. SQL Server arrête une CTE récursive après 100 niveaux par défaut, avec une erreur qui dit que la récursion maximale de 100 est épuisée, et [`MAXRECURSION`](https://learn.microsoft.com/sql/t-sql/queries/with-common-table-expression-transact-sql) change la limite. PostgreSQL n'a pas de telle limite : sans délai maximal, cette requête tourne jusqu'à ce que quelqu'un l'annule ou que le serveur manque de mémoire ou de disque.

Deux façons d'en sortir ([lignes 62-76](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L62-L76)) :

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.depth + 1 FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
) CYCLE to_path SET is_cycle USING path
SELECT count(*) AS paths, count(*) FILTER (WHERE is_cycle) AS cycles, max(depth) AS longest_path
FROM deps;

WITH RECURSIVE deps AS (
    SELECT to_path FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION
    SELECT r.to_path FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) AS projects FROM deps;
DELETE FROM ga.project_refs WHERE from_path = 'Common/GA.Core/GA.Core.csproj';
```

```text
 paths | cycles | longest_path
-------+--------+--------------
 15655 |   6982 |           13
(1 row)

 projects
----------
       21
(1 row)

DELETE 1
```

- La [clause `CYCLE`](https://www.postgresql.org/docs/18/queries-with.html#QUERIES-WITH-CYCLE), issue du standard SQL et présente dans PostgreSQL depuis la version 14, garde la liste des valeurs `to_path` visitées dans une colonne nommée `path`, et met `is_cycle` à vrai sur une ligne qui atteint un projet déjà présent sur son chemin. Cette ligne est gardée, et la récursion s'arrête là. Avec le cycle, il y a 15 655 chemins au lieu de 435 : chaque chemin qui passe par `GA.Core` fait maintenant un tour de plus.
- Sans `depth`, un projet retrouvé est une ligne en double, `UNION` l'écarte, et la récursion s'arrête quand un tour n'ajoute rien. 21 projets : les 20 dépendances, et `GaApi` lui-même, atteint par le cycle. T-SQL n'autorise pas `UNION` dans une CTE récursive, seulement `UNION ALL`.

La dernière instruction supprime le cycle.

## Fonctions de fenêtrage

Les fonctions de fenêtrage existent dans les deux dialectes, avec le même `OVER (PARTITION BY … ORDER BY …)`. Les exécutions du workflow du cours Rust, dans l'ordre ([lignes 79-88](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L79-L88)) :

```sql
SELECT run_id, started_at,
       updated_at - started_at AS took,
       lag(updated_at - started_at) OVER w AS previous_took,
       row_number() OVER w AS nth,
       count(*) FILTER (WHERE conclusion = 'failure') OVER w AS failures_so_far
FROM ci.runs
WHERE workflow_name = 'Rust course examples'
WINDOW w AS (PARTITION BY workflow_name ORDER BY started_at, run_id)
ORDER BY started_at, run_id
LIMIT 6;
```

```text
   run_id    |       started_at       |   took   | previous_took | nth | failures_so_far
-------------+------------------------+----------+---------------+-----+-----------------
 34768259924 | 2026-09-13 16:20:06+00 | 00:00:32 |               |   1 |               0
 34768314558 | 2026-09-13 16:21:09+00 | 00:00:20 | 00:00:32      |   2 |               0
 34769559799 | 2026-09-13 16:45:55+00 | 00:00:20 | 00:00:20      |   3 |               0
 34770934509 | 2026-09-13 17:13:25+00 | 00:00:33 | 00:00:20      |   4 |               0
 34772306529 | 2026-09-13 17:40:34+00 | 00:00:40 | 00:00:33      |   5 |               1
 34772373891 | 2026-09-13 17:41:56+00 | 00:00:31 | 00:00:40      |   6 |               2
(6 rows)
```

- La clause `WINDOW` nomme une fenêtre une fois pour plusieurs fonctions. SQL Server l'a depuis SQL Server 2022.
- `FILTER` fonctionne aussi sur un agrégat utilisé comme fonction de fenêtrage : `failures_so_far` est un compte cumulé des échecs.
- Une fenêtre avec `ORDER BY` et sans cadre va du début de la partition jusqu'à la ligne courante, et ses pairs : les lignes qui ont les mêmes valeurs d'`ORDER BY`. C'est pourquoi `run_id` est dans l'`ORDER BY` : deux exécutions commencées dans la même seconde seraient sinon comptées ensemble.

Une fonction de fenêtrage peut aussi s'appliquer au résultat d'un `GROUP BY` ([lignes 91-95](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L91-L95)) :

```sql
SELECT labels[1] AS os, count(*) AS jobs, sum(duration) AS total,
       round(100 * extract(epoch FROM sum(duration)) / sum(extract(epoch FROM sum(duration))) OVER (), 1) AS percent
FROM ci.jobs
GROUP BY labels[1]
ORDER BY total DESC;
```

```text
       os       | jobs |  total   | percent
----------------+------+----------+---------
 ubuntu-latest  |  246 | 01:27:52 |    50.0
 windows-latest |   35 | 00:56:25 |    32.1
 macos-latest   |   34 | 00:31:33 |    17.9
(3 rows)
```

`sum(duration)` est l'agrégat de chaque groupe ; `sum(…) OVER ()` additionne ces agrégats sur tout le résultat. [`extract(epoch FROM …)`](https://www.postgresql.org/docs/18/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT) transforme un intervalle en secondes. Les jobs Windows sont 11 % des jobs et 32 % du temps de CI. Le [tutoriel des fonctions de fenêtrage](https://www.postgresql.org/docs/18/tutorial-window.html) les présente, et la [syntaxe d'appel des fonctions de fenêtrage](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS) liste les options de cadre.

## LATERAL

Une sous-requête dans `FROM` ne voit normalement pas les autres tables du même `FROM`. Avec [`LATERAL`](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-LATERAL), elle les voit, et elle s'exécute une fois par ligne à sa gauche : le `CROSS APPLY` de SQL Server. La première étape en échec de chaque exécution en échec ([lignes 98-117](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L98-L117)) :

```sql
SELECT r.workflow_name, r.run_id, first_failure.job, first_failure.step
FROM ci.runs AS r
CROSS JOIN LATERAL (
    SELECT j.name AS job, s.name AS step
    FROM ci.jobs AS j
    JOIN ci.steps AS s USING (job_id)
    WHERE j.run_id = r.run_id AND s.conclusion = 'failure'
    ORDER BY s.started_at, j.job_id, s.number
    LIMIT 1
) AS first_failure
WHERE r.conclusion = 'failure'
ORDER BY r.workflow_name, r.run_id
LIMIT 6;

SELECT count(*) AS failed_runs,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT FROM ci.jobs AS j JOIN ci.steps AS s USING (job_id)
           WHERE j.run_id = r.run_id AND s.conclusion = 'failure')) AS without_failed_step
FROM ci.runs AS r
WHERE r.conclusion = 'failure';
```

```text
            workflow_name            |   run_id    |     job      |            step
-------------------------------------+-------------+--------------+-----------------------------
 Deploy to GitHub Pages              | 34845198191 | deploy       | Deploy to GitHub Pages
 GHA 04: data between steps and jobs | 34845384597 | produce      | Tests (fail on demand)
 GHA 04: exercise checks             | 34847078287 | produce      | Fail
 GHA 05: exercise checks             | 34847802892 | no-lock-file | Run actions/setup-dotnet@v6
 GHA 05: exercise checks             | 34848189352 | no-lock-file | Run actions/setup-dotnet@v6
 GHA 05: exercise checks             | 34848421802 | no-lock-file | Run actions/setup-dotnet@v6
(6 rows)

 failed_runs | without_failed_step
-------------+---------------------
          16 |                   3
(1 row)
```

`CROSS JOIN LATERAL` écarte les lignes de gauche pour lesquelles la sous-requête ne renvoie rien, comme `CROSS APPLY` ; `LEFT JOIN LATERAL (…) ON true` les garde, comme `OUTER APPLY`, et l'exercice 3 s'en sert. Ici, 3 des 16 exécutions en échec n'ont pas d'étape en échec, donc elles manquent au premier résultat : les deux exécutions sans jobs vues plus haut, et une exécution de `Deploy to GitHub Pages` dont le job en échec n'a que des étapes réussies dans l'instantané.

Le `LIMIT 1` dans la sous-requête est la raison d'utiliser `LATERAL` : « le premier … de chaque … » est difficile à écrire avec une simple jointure.

## DISTINCT ON

Les versions de paquets sont du texte dans `ga.package_refs`, comme dans un `.csproj`. La plus haute version d'un paquet, avec `max` ([lignes 120-124](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L120-L124)) :

```sql
SELECT package, max(version) AS text_max, count(DISTINCT version) AS versions
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.Hosting%'
GROUP BY package
ORDER BY package;
```

```text
                  package                  | text_max | versions
-------------------------------------------+----------+----------
 Microsoft.Extensions.Hosting              | 9.0.4    |        5
 Microsoft.Extensions.Hosting.Abstractions | 9.0.10   |        1
(2 rows)
```

`max` compare le texte caractère par caractère, et `'9'` est plus grand que `'1'` : le maximum textuel de `Microsoft.Extensions.Hosting` est 9.0.4, alors que Guitar Alchemist référence aussi 10.0.5. Le même paquet est référencé dans cinq versions différentes dans la solution.

Une version se compare correctement comme un tableau d'entiers, et [`DISTINCT ON`](https://www.postgresql.org/docs/18/sql-select.html#SQL-DISTINCT) garde la première ligne de chaque groupe dans l'ordre de l'`ORDER BY` ([lignes 127-141](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L127-L141)) :

```sql
SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.%'
ORDER BY package, string_to_array(version, '.')::int[] DESC;

SELECT version, count(*) AS refs
FROM ga.package_refs
WHERE version !~ '^\d+(\.\d+)*$'
GROUP BY version
ORDER BY version;

SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.H%' AND version ~ '^\d+(\.\d+)*$'
ORDER BY package, string_to_array(version, '.')::int[] DESC;
```

```text
ERROR:  invalid input syntax for type integer: "0-preview"
         version         | refs
-------------------------+------
 0.*                     |    1
 0.1.0-preview.10        |    1
 0.22.0-preview.24378.1  |    1
 1.0.0-alpha0031         |    1
 1.0.0-beta.24164.1      |   12
 1.0.0-preview.251028.1  |    1
 1.27.0-alpha            |    2
 13.0.0-preview.24       |    2
 2.0.0-beta5.25277.114   |    2
 2.2.0-beta.1            |    5
 4.0.0-preview.24478.1   |    2
 8.*-*                   |    1
 9.4.0-preview.1.25207.5 |    4
(13 rows)

                  package                  | version
-------------------------------------------+---------
 Microsoft.Extensions.Hosting              | 10.0.5
 Microsoft.Extensions.Hosting.Abstractions | 9.0.10
 Microsoft.Extensions.Http                 | 10.0.0
 Microsoft.Extensions.Http.Polly           | 9.0.10
 Microsoft.Extensions.Http.Resilience      | 9.1.0
(5 rows)
```

1. La conversion échoue : une version comme `9.4.0-preview.1.25207.5` se découpe en `9`, `4`, `0-preview`, … et `0-preview` n'est pas un entier. Une seule mauvaise ligne fait échouer toute l'instruction.
2. `!~` signifie « ne correspond pas à l'expression régulière ». 13 versions distinctes ne sont pas de simples nombres : des previews et des bêtas, et deux versions flottantes, `0.*` et `8.*-*`, qui laissent NuGet choisir un paquet différent à chaque restauration.
3. Filtré sur les versions numériques, `DISTINCT ON (package)` donne une ligne par paquet, la première dans l'ordre `package, version DESC`. Ses expressions doivent commencer l'`ORDER BY`.

T-SQL n'a pas de `DISTINCT ON` ; l'équivalent habituel est `ROW_NUMBER() OVER (PARTITION BY package ORDER BY …)` dans une sous-requête, filtré sur `= 1`. Le tri à deux niveaux, texte pour les paquets et tableaux pour les versions, est aussi quelque chose que T-SQL ne sait pas écrire sans découper la chaîne en colonnes.

## RETURNING

`INSERT`, `UPDATE`, `DELETE` et `MERGE` peuvent renvoyer les lignes qu'ils ont modifiées, comme le fait l'`OUTPUT` de T-SQL ([lignes 144-154](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L144-L154)) :

```sql
CREATE TABLE ga.pinned_versions (
    package    text PRIMARY KEY,
    version    text NOT NULL CHECK (version ~ '^\d+(\.\d+)*$'),
    pinned_at  timestamptz NOT NULL DEFAULT '2026-09-14 00:00:00+00'
);
INSERT INTO ga.pinned_versions (package, version)
SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package IN ('Microsoft.Extensions.Hosting', 'MongoDB.Driver')
ORDER BY package, string_to_array(version, '.')::int[] DESC
RETURNING package, version, pinned_at;
```

```text
CREATE TABLE
           package            | version |       pinned_at
------------------------------+---------+------------------------
 Microsoft.Extensions.Hosting | 10.0.5  | 2026-09-14 00:00:00+00
 MongoDB.Driver               | 3.5.0   | 2026-09-14 00:00:00+00
(2 rows)

INSERT 0 2
```

L'instruction renvoie les lignes comme une requête, et `psql` affiche `INSERT 0 2` après elles. `pinned_at` a une valeur par défaut fixe pour que la sortie ne change pas d'un jour à l'autre ; une vraie table utiliserait `DEFAULT now()`. [`RETURNING`](https://www.postgresql.org/docs/18/dml-returning.html) est la façon dont un programme récupère une identité ou un `uuidv7()` généré par le serveur, en un seul aller-retour : la leçon 4 s'en sert depuis C# et Java.

## INSERT … ON CONFLICT

« Insérer, ou mettre à jour si ça existe » tient en une instruction ([lignes 157-171](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L157-L171)) :

```sql
INSERT INTO ga.pinned_versions (package, version, pinned_at)
VALUES ('MongoDB.Driver', '3.2.0', '2026-09-15 00:00:00+00'),
       ('Npgsql', '10.0.3', '2026-09-15 00:00:00+00')
ON CONFLICT (package) DO UPDATE
SET version = EXCLUDED.version, pinned_at = EXCLUDED.pinned_at
RETURNING package, old.version AS old_version, new.version AS new_version, old IS NULL AS inserted;

INSERT INTO ga.pinned_versions (package, version)
VALUES ('Dapper', '2.1.86'), ('Dapper', '2.1.72')
ON CONFLICT (package) DO UPDATE SET version = EXCLUDED.version;

INSERT INTO ga.pinned_versions (package, version)
VALUES ('Npgsql', '9.0.5')
ON CONFLICT (package) DO NOTHING
RETURNING package;
```

```text
    package     | old_version | new_version | inserted
----------------+-------------+-------------+----------
 MongoDB.Driver | 3.5.0       | 3.2.0       | f
 Npgsql         |             | 10.0.3      | t
(2 rows)

INSERT 0 2
ERROR:  ON CONFLICT DO UPDATE command cannot affect row a second time
HINT:  Ensure that no rows proposed for insertion within the same command have duplicate constrained values.
 package
---------
(0 rows)

INSERT 0 0
```

- [`ON CONFLICT (package) DO UPDATE`](https://www.postgresql.org/docs/18/sql-insert.html#SQL-ON-CONFLICT) exige un index ou une contrainte unique sur `package`, ici la clé primaire. `EXCLUDED` est la ligne qui était proposée à l'insertion.
- Depuis PostgreSQL 18, `RETURNING` peut nommer `old` et `new`, comme `deleted` et `inserted` dans l'`OUTPUT` de T-SQL. Pour une ligne insérée, `old` vaut `NULL`, donc `old IS NULL` distingue une insertion d'une mise à jour.
- La deuxième instruction propose `Dapper` deux fois, et échoue : une ligne ne peut pas être mise à jour deux fois par la même commande, car le résultat dépendrait de l'ordre des `VALUES`. Dédoublonne d'abord l'entrée.
- `DO NOTHING` saute la ligne en conflit, et `RETURNING` ne renvoie que les lignes vraiment insérées : aucune ici.

La documentation garantit un résultat atomique pour `ON CONFLICT DO UPDATE`, une insertion ou une mise à jour, même avec une forte concurrence : si une autre transaction insère le même `package` au même moment, l'instruction l'attend puis met à jour, au lieu d'échouer sur une clé en double. Pour le même upsert, la [documentation de `MERGE` de SQL Server](https://learn.microsoft.com/sql/t-sql/statements/merge-transact-sql) recommande l'indicateur `HOLDLOCK`, synonyme du niveau d'isolation sérialisable.

## MERGE

[`MERGE`](https://www.postgresql.org/docs/18/sql-merge.html) est arrivé dans PostgreSQL 15 ; `WHEN NOT MATCHED BY SOURCE`, `RETURNING` et `merge_action()` dans PostgreSQL 17. Le script épingle la plus haute version numérique de chaque paquet référencé par huit projets ou plus, met à jour ce qui a changé, et supprime les épinglages des paquets qui ne sont plus dans la liste ([lignes 174-195](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L174-L195)) :

```sql
WITH changes AS (
    MERGE INTO ga.pinned_versions AS t
    USING (
        SELECT package, (array_agg(version ORDER BY string_to_array(version, '.')::int[] DESC))[1] AS version
        FROM ga.package_refs
        WHERE version ~ '^\d+(\.\d+)*$'
        GROUP BY package
        HAVING count(*) >= 8
    ) AS s
    ON t.package = s.package
    WHEN MATCHED AND t.version <> s.version THEN
        UPDATE SET version = s.version, pinned_at = '2026-09-16 00:00:00+00'
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (package, version) VALUES (s.package, s.version)
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE
    RETURNING merge_action() AS action, coalesce(new.package, old.package) AS package,
              old.version AS old_version, new.version AS new_version
)
SELECT * FROM changes ORDER BY action, package;

SELECT package, version, pinned_at FROM ga.pinned_versions ORDER BY package;
```

```text
 action |                  package                  | old_version | new_version
--------+-------------------------------------------+-------------+-------------
 DELETE | Npgsql                                    | 10.0.3      |
 INSERT | coverlet.collector                        |             | 6.0.4
 INSERT | JetBrains.Annotations                     |             | 2024.3.0
 INSERT | Microsoft.Extensions.DependencyInjection  |             | 10.0.2
 INSERT | Microsoft.Extensions.Logging              |             | 10.0.0
 INSERT | Microsoft.Extensions.Logging.Abstractions |             | 10.0.2
 INSERT | Microsoft.Extensions.Logging.Console      |             | 10.0.0
 INSERT | Microsoft.NET.Test.Sdk                    |             | 17.14.0
 INSERT | NUnit                                     |             | 4.3.2
 INSERT | NUnit3TestAdapter                         |             | 5.0.0
 INSERT | NUnit.Analyzers                           |             | 4.7.0
 INSERT | Spectre.Console                           |             | 0.51.1
 INSERT | Swashbuckle.AspNetCore                    |             | 7.0.0
 INSERT | System.Numerics.Tensors                   |             | 10.0.2
 UPDATE | MongoDB.Driver                            | 3.2.0       | 3.5.0
(15 rows)

                  package                  | version  |       pinned_at
-------------------------------------------+----------+------------------------
 coverlet.collector                        | 6.0.4    | 2026-09-14 00:00:00+00
 JetBrains.Annotations                     | 2024.3.0 | 2026-09-14 00:00:00+00
 Microsoft.Extensions.DependencyInjection  | 10.0.2   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Hosting              | 10.0.5   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging              | 10.0.0   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging.Abstractions | 10.0.2   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging.Console      | 10.0.0   | 2026-09-14 00:00:00+00
 Microsoft.NET.Test.Sdk                    | 17.14.0  | 2026-09-14 00:00:00+00
 MongoDB.Driver                            | 3.5.0    | 2026-09-16 00:00:00+00
 NUnit                                     | 4.3.2    | 2026-09-14 00:00:00+00
 NUnit3TestAdapter                         | 5.0.0    | 2026-09-14 00:00:00+00
 NUnit.Analyzers                           | 4.7.0    | 2026-09-14 00:00:00+00
 Spectre.Console                           | 0.51.1   | 2026-09-14 00:00:00+00
 Swashbuckle.AspNetCore                    | 7.0.0    | 2026-09-14 00:00:00+00
 System.Numerics.Tensors                   | 10.0.2   | 2026-09-14 00:00:00+00
(15 rows)
```

- `(array_agg(version ORDER BY …))[1]` est « la première valeur dans cet ordre » sous forme d'agrégat, une autre façon d'écrire `DISTINCT ON`.
- `merge_action()` renvoie `INSERT`, `UPDATE` ou `DELETE`, comme `$action` en T-SQL. `coalesce(new.package, old.package)` est nécessaire parce que `new` vaut `NULL` pour une ligne supprimée.
- Un `MERGE` avec `RETURNING` peut s'utiliser dans `WITH`, et la requête externe trie ses lignes : l'ordre du `RETURNING` d'une instruction n'est pas garanti.
- `Npgsql` est supprimé : aucun projet de Guitar Alchemist ne le référence. `MongoDB.Driver`, 14 références, repasse de 3.2.0 à 3.5.0 avec une nouvelle date. `Microsoft.Extensions.Hosting`, 12 références, correspond avec la même version 10.0.5 : aucune clause `WHEN` ne s'applique, donc sa ligne reste telle quelle et n'est pas renvoyée.

La documentation de PostgreSQL recommande `INSERT … ON CONFLICT` plutôt que `MERGE` quand des insertions concurrentes sont possibles : `MERGE` peut échouer sur une violation d'unicité là où `ON CONFLICT` mettrait à jour.

La liste finale est triée par `package`, et `coverlet.collector` vient avant `JetBrains.Annotations`, `NUnit3TestAdapter` avant `NUnit.Analyzers`. La base `learn` utilise la [collation](https://www.postgresql.org/docs/18/collation.html) `en_US.utf8` de la bibliothèque C de l'image, qui compare les lettres avant la casse et la ponctuation. Avec la collation `C`, les majuscules se trient avant les minuscules et `.` avant les chiffres. Un résultat trié sur du texte dépend de la collation de la base : c'est une partie de ce que « toujours un `ORDER BY` » ne règle pas à lui seul.

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* Aurora PostgreSQL exécute le moteur de requêtes de PostgreSQL, donc chaque instruction de cette leçon y est la même, de `WITH RECURSIVE` à `MERGE … RETURNING` (PostgreSQL 17) et `old` et `new` dans `RETURNING` (PostgreSQL 18, donc Aurora PostgreSQL 18 seulement). Ce qui change, c'est **où s'exécute une requête**.

- Un cluster Aurora a une instance writer et jusqu'à 15 Aurora Replicas, et plusieurs [endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html). Le **cluster endpoint** se connecte au writer, pour `INSERT`, `MERGE` et le DDL. Le **reader endpoint** sert aux requêtes, et AWS écrit qu'Aurora « automatically performs connection-balancing among all the Aurora Replicas » : la répartition se fait par connexion, pas par requête. Un pool de connexions ouvertes sur le reader endpoint reste sur les réplicas qu'il a atteints.
- Les réplicas partagent le volume de stockage du writer, et AWS donne leur retard comme « usually much less than 100 milliseconds » dans la [page sur la réplication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html), croissant avec le rythme des écritures. Un programme qui écrit par le cluster endpoint et lit aussitôt par le reader endpoint peut manquer sa propre écriture : relis tes propres écritures sur le writer.
- Des rapports comme les requêtes de fenêtrage et `LATERAL` ci-dessus sont le genre de travail à envoyer au reader endpoint, ou à un custom endpoint pour un groupe de réplicas plus gros.

Les réplicas sont en lecture seule, et une écriture envoyée à l'un d'eux échoue. Dans PostgreSQL, un serveur en récupération, comme l'est un standby, démarre chaque transaction en lecture seule ([`xact.c`, lignes 2122-2130](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/access/transam/xact.c#L2122-L2130)) ; une transaction en lecture seule sur le serveur local donne la même erreur ([lignes 197-201](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L197-L201)) :

```sql
-- Une transaction en lecture seule refuse les écritures, comme toute transaction sur un standby
BEGIN TRANSACTION READ ONLY;
SELECT count(*) AS pinned FROM ga.pinned_versions;
DELETE FROM ga.pinned_versions WHERE package = 'Npgsql';
ROLLBACK;
```

```text
BEGIN
 pinned
--------
     15
(1 row)

ERROR:  cannot execute DELETE in a read-only transaction
ROLLBACK
```

Qu'une Aurora Replica renvoie exactement ce message, SQLSTATE `25006`, est *à vérifier*.

La leçon 4 choisit entre le writer et les readers depuis une chaîne de connexion, et la leçon 12 revient sur les endpoints et le basculement.

## À retenir

- `WITH RECURSIVE` n'a pas de limite de récursion dans PostgreSQL : protège-le avec `UNION` sans colonne de profondeur, la clause `CYCLE`, ou `statement_timeout`.
- `FILTER (WHERE …)` restreint un agrégat, dans un `GROUP BY` comme dans une fenêtre.
- `LATERAL` est `CROSS APPLY` ; `LEFT JOIN LATERAL … ON true` est `OUTER APPLY`.
- `DISTINCT ON` garde la première ligne de chaque groupe dans l'ordre de l'`ORDER BY`.
- Des versions stockées en texte se comparent comme du texte : `'9.0.4' > '10.0.5'`.
- `RETURNING old.*, new.*` remplace `OUTPUT deleted.*, inserted.*` ; `INSERT … ON CONFLICT` est l'upsert sûr en concurrence, et `MERGE … RETURNING merge_action()` l'upsert général.
- Trier du texte dépend de la collation ; sur Aurora, les écritures vont au cluster endpoint, et les lectures sur les réplicas peuvent être en retard.

## Exercices

Les solutions sont dans [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql).

1. Guitar Alchemist donne à chaque accord iconique ses classes de hauteur et un doigté de guitare : une case par corde, du mi grave au mi aigu, `-1` pour une corde non jouée. En accordage standard, les cordes à vide sont les classes de hauteur `4 9 2 7 11 4`. Calcule les classes de hauteur que joue vraiment chaque doigté, et compare-les à celles déclarées.

<details>
<summary>Solution</summary>

Tiré de [`sql/03-exercises.sql`, lignes 8-23](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L8-L23) :

```sql
WITH played AS (
    SELECT c.name, array_agg(DISTINCT (t.open_string + f.fret) % 12 ORDER BY (t.open_string + f.fret) % 12) AS voicing_pcs
    FROM ga.iconic_chords AS c
    CROSS JOIN LATERAL unnest(c.guitar_voicing) WITH ORDINALITY AS f(fret, string)
    JOIN unnest('{4,9,2,7,11,4}'::int[]) WITH ORDINALITY AS t(open_string, string) USING (string)
    WHERE f.fret >= 0
    GROUP BY c.name
)
SELECT p.name,
       ARRAY(SELECT unnest(c.pitch_classes) ORDER BY 1) AS declared,
       p.voicing_pcs AS played,
       ARRAY(SELECT unnest(c.pitch_classes) EXCEPT SELECT unnest(p.voicing_pcs) ORDER BY 1) AS missing,
       ARRAY(SELECT unnest(p.voicing_pcs) EXCEPT SELECT unnest(c.pitch_classes) ORDER BY 1) AS extra
FROM played AS p
JOIN ga.iconic_chords AS c USING (name)
ORDER BY p.name;
```

```text
       name       |   declared   |   played    | missing |  extra
------------------+--------------+-------------+---------+---------
 Blackbird Chord  | {2,7,11}     | {1,2,4,7,9} | {11}    | {1,4,9}
 Cowboy Chord     | {2,7,11}     | {2,7,11}    | {}      | {}
 Hendrix Chord    | {2,4,7,8,11} | {2,4,7,8}   | {11}    | {}
 James Bond Chord | {3,4,7,11}   | {3,4,7,11}  | {}      | {}
 Mu Major Chord   | {0,2,7}      | {0,2,4,7}   | {}      | {4}
 Power Chord      | {2,7}        | {2,7}       | {}      | {}
(6 rows)
```

`unnest(…) WITH ORDINALITY` numérote les éléments d'un tableau, ce qui joint chaque case à sa corde. La case plus la corde à vide, modulo 12, est la classe de hauteur jouée. `ARRAY(SELECT … EXCEPT SELECT …)` calcule une différence d'ensembles entre deux tableaux.

Seuls six des 17 accords ont un doigté. Trois sont cohérents. Les trois autres sont des constats sur les données de Guitar Alchemist, dans [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml) au commit `32f143c` :

- Le doigté de Blackbird `{0,0,0,0,2,0}`, déclaré comme G/B, joue les cordes à vide et un do♯ sur la corde de si : mi, la, ré, sol, do♯, mi. Il lui manque si, et il ajoute do♯, mi et la.
- L'accord Hendrix, E7♯9, déclare si, sa quinte, et le doigté `{0,7,6,7,8,0}` ne la joue pas. Les guitaristes omettent souvent la quinte de cet accord ; l'ensemble déclaré et le doigté ne sont simplement pas d'accord.
- Le doigté du Mu Major `{0,3,0,0,3,0}`, déclaré comme `Cadd9(no3)`, joue les cordes de mi à vide : mi, la tierce que `no3` dit omise.

</details>

2. Liste chaque projet qui dépend de `GA.Data.MongoDB`, directement ou non, avec sa plus petite distance. Le chemin du projet est `GA.Data.MongoDB/GA.Data.MongoDB.csproj`.

<details>
<summary>Solution</summary>

Tiré de [`sql/03-exercises.sql`, lignes 26-38](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L26-L38) :

```sql
WITH RECURSIVE dependents AS (
    SELECT from_path, 1 AS depth
    FROM ga.project_refs
    WHERE to_path = 'GA.Data.MongoDB/GA.Data.MongoDB.csproj'
    UNION
    SELECT r.from_path, d.depth + 1
    FROM dependents AS d
    JOIN ga.project_refs AS r ON r.to_path = d.from_path
)
SELECT min(depth) AS depth, from_path AS project
FROM dependents
GROUP BY from_path
ORDER BY depth, project;
```

```text
 depth |                                      project
-------+-----------------------------------------------------------------------------------
     1 | Apps/GaChatbotCli/GaChatbotCli.csproj
     1 | Apps/GaChatbot/GaChatbot.csproj
     1 | Apps/ga-server/GA.BSP.Service/GA.BSP.Service.csproj
     1 | Apps/ga-server/GA.DocumentProcessing.Service/GA.DocumentProcessing.Service.csproj
     1 | Common/GA.Business.AI/GA.Business.AI.csproj
     1 | Common/GA.Business.ML/GA.Business.ML.csproj
     1 | GaCLI/GaCLI.csproj
     2 | Apps/GaChatbot.Api/GaChatbot.Api.csproj
     2 | Apps/GaMemoryCli/GaMemoryCli.csproj
     2 | Apps/GaQaMcp/GaQaMcp.csproj
     2 | Apps/ga-server/GaApi/GaApi.csproj
     2 | Common/GA.Business.Core.Orchestration/GA.Business.Core.Orchestration.csproj
     2 | Common/GA.Business.Intelligence/GA.Business.Intelligence.csproj
     2 | Common/GA.Testing.Semantic/GA.Testing.Semantic.csproj
     2 | Demos/IntelligentAnalysis/IntelligentAnalysisDemo.csproj
     2 | Demos/Music Theory/FretboardVoicingsCLI/FretboardVoicingsCLI.csproj
     2 | GaMcpServer/GaMcpServer.csproj
     2 | GenerateNatData/GenerateNatData.csproj
     2 | Tests/Apps/GaChatbot.Tests/GaChatbot.Tests.csproj
     2 | Tests/Common/GA.Business.Core.Tests/GA.Business.Core.Tests.csproj
     2 | Tests/Common/GA.Business.ML.Tests/GA.Business.ML.Tests.csproj
     2 | Tools/GaStructureInvariance/GaStructureInvariance.csproj
     3 | AllProjects.AppHost/AllProjects.AppHost.csproj
     3 | Apps/ga-server/GA.Analytics.Service/GA.Analytics.Service.csproj
     3 | Apps/InteractiveTutorial/InteractiveTutorial.csproj
     3 | Demos/Performance/VectorSearchBenchmark/VectorSearchBenchmark.csproj
     3 | Tests/Apps/GaApi.Tests/GaApi.Tests.csproj
     3 | Tests/Apps/GaChatbot.Api.Tests/GaChatbot.Api.Tests.csproj
     3 | Tests/Apps/GaMcpServer.Tests/GaMcpServer.Tests.csproj
     3 | Tests/GaApi.Tests/GaApi.Tests.csproj
(30 rows)
```

La récursion va dans l'autre sens : de `to_path` vers `from_path`. `UNION` l'arrête sur les lignes déjà trouvées, et `min(depth)` garde la plus courte distance d'un projet atteint par plusieurs chemins. 30 projets dépendent de la couche MongoDB, un quart de la solution. Deux d'entre eux s'appellent `GaApi.Tests.csproj`, l'un dans `Tests/Apps/GaApi.Tests` et l'autre dans `Tests/GaApi.Tests` : regrouper sur le nom du fichier au lieu du chemin les aurait fusionnés.

</details>

3. Pour chaque exécution en échec, combien de temps le même workflow a-t-il mis à réussir de nouveau ? Garde en premier les échecs qui n'ont jamais été suivis d'une réussite dans l'instantané.

<details>
<summary>Solution</summary>

Tiré de [`sql/03-exercises.sql`, lignes 41-51](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L41-L51) :

```sql
SELECT f.workflow_name, f.started_at AS failed_at, next_success.started_at - f.started_at AS time_to_green
FROM ci.runs AS f
LEFT JOIN LATERAL (
    SELECT s.started_at
    FROM ci.runs AS s
    WHERE s.workflow_name = f.workflow_name AND s.conclusion = 'success' AND s.started_at > f.started_at
    ORDER BY s.started_at
    LIMIT 1
) AS next_success ON true
WHERE f.conclusion = 'failure'
ORDER BY time_to_green DESC NULLS FIRST, f.workflow_name, f.started_at;
```

```text
            workflow_name            |       failed_at        | time_to_green
-------------------------------------+------------------------+---------------
 GHA 04: data between steps and jobs | 2026-09-14 12:47:40+00 |
 GHA 04: exercise checks             | 2026-09-14 13:05:23+00 |
 GHA 05: exercise checks             | 2026-09-14 13:12:27+00 |
 GHA 05: exercise checks             | 2026-09-14 13:16:06+00 |
 GHA 05: exercise checks             | 2026-09-14 13:18:20+00 |
 GHA 06: exercise checks             | 2026-09-14 13:24:13+00 |
 GHA 10: exercise checks             | 2026-09-14 13:53:12+00 |
 Rust course examples                | 2026-09-13 19:09:08+00 | 00:03:48
 Deploy to GitHub Pages              | 2026-09-14 13:36:16+00 | 00:03:46
 Rust course examples                | 2026-09-13 17:40:34+00 | 00:02:15
 GHA 09: exercise checks             | 2026-09-14 13:46:43+00 | 00:02:13
 GHA 03: triggers                    | 2026-09-14 12:45:24+00 | 00:02:05
 GHA 03: triggers                    | 2026-09-14 12:45:38+00 | 00:01:51
 GHA 10: custom actions              | 2026-09-14 13:53:04+00 | 00:01:03
 Deploy to GitHub Pages              | 2026-09-14 12:45:39+00 | 00:00:59
 Rust course examples                | 2026-09-13 17:41:56+00 | 00:00:53
(16 rows)
```

`LEFT JOIN LATERAL (…) ON true` garde les exécutions en échec pour lesquelles la sous-requête ne trouve pas de réussite ultérieure, avec des colonnes `NULL` : `OUTER APPLY`. `NULLS FIRST` les place en tête d'un tri décroissant, là où PostgreSQL les mettrait de toute façon : `NULL` se trie comme plus grand que toute valeur, l'inverse de SQL Server. Sept échecs n'ont été suivis d'aucune réussite dans l'instantané, dont six dans des workflows de vérification d'exercices.

</details>

## Sources

- Documentation de PostgreSQL 18 : [requêtes `WITH`](https://www.postgresql.org/docs/18/queries-with.html), [expressions d'agrégat et `FILTER`](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES), [fonctions de fenêtrage](https://www.postgresql.org/docs/18/tutorial-window.html) et [leur référence](https://www.postgresql.org/docs/18/functions-window.html), [`LATERAL`](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-LATERAL), [`SELECT`](https://www.postgresql.org/docs/18/sql-select.html), [renvoyer les données des lignes modifiées](https://www.postgresql.org/docs/18/dml-returning.html), [`INSERT`](https://www.postgresql.org/docs/18/sql-insert.html), [`MERGE`](https://www.postgresql.org/docs/18/sql-merge.html), [support des collations](https://www.postgresql.org/docs/18/collation.html), [`statement_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-STATEMENT-TIMEOUT)
- Sources de PostgreSQL au tag `REL_18_6` : [`xact.c`, lignes 2122-2130](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/access/transam/xact.c#L2122-L2130)
- SQL Server : [expression de table commune `WITH`](https://learn.microsoft.com/sql/t-sql/queries/with-common-table-expression-transact-sql), [`FROM` et `APPLY`](https://learn.microsoft.com/sql/t-sql/queries/from-transact-sql), [`OUTPUT`](https://learn.microsoft.com/sql/t-sql/queries/output-clause-transact-sql), [`MERGE`](https://learn.microsoft.com/sql/t-sql/statements/merge-transact-sql)
- Amazon Aurora : [endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html), [réplication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html)
- Guitar Alchemist au commit `32f143c` : [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml)
