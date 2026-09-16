---
title: "5. Index et plans"
description: Lire EXPLAIN (ANALYZE, BUFFERS) dans PostgreSQL 18 et choisir un index sur une table de 440 800 lignes — index B-tree, multicolonnes, partiels, sur expression et couvrants, parcours d'index seul et carte de visibilité, GIN sur des tableaux, BRIN et ordre physique, et statistiques étendues pour des colonnes corrélées ; comparés aux plans d'exécution, index filtrés et colonnes incluses de SQL Server.
sidebar:
  order: 5
---

Le script de la leçon est [`sql/05-indexes.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql), les exercices sont dans [`sql/05-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql), et `check.sh` compare leur sortie à [`expected/05-indexes.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/05-indexes.txt) et [`expected/05-exercises.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/05-exercises.txt).

L'instantané de CI est trop petit pour que les index comptent : 2 204 étapes tiennent en quelques dizaines de pages, et les lire toutes est le plan le plus rapide. La leçon construit une table plus grande, `ci.step_history`, à partir de [`sql/history.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/history.sql) : chaque étape de l'instantané, rejouée sur chacun des 200 jours jusqu'au 2026-09-14, dans l'ordre chronologique.

| SQL Server | PostgreSQL |
|---|---|
| plan d'exécution réel, `SET STATISTICS IO ON` | `EXPLAIN (ANALYZE, BUFFERS)` |
| index cluster : la table elle-même, ordonnée par sa clé | un heap sans ordre ; `CLUSTER` le trie une fois |
| index non cluster avec `INCLUDE` | B-tree avec `INCLUDE` |
| index filtré, `WHERE …` | index partiel, `WHERE …` |
| index sur une colonne calculée persistante | index sur une expression |
| index de texte intégral et XML, index JSON (en préversion dans SQL Server 2025) | GIN, GiST, SP-GiST |
| élimination de segments columnstore | BRIN |
| statistiques multicolonnes, `CREATE STATISTICS` | `CREATE STATISTICS (dependencies, ndistinct, mcv)` |

## Des plans stables pour une leçon

Un plan contient des durées, des coûts et des nombres de buffers qui changent d'une exécution à l'autre, et `check.sh` compare les sorties ligne par ligne. [`sql/explain.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/explain.sql) les rend reproductibles ([lignes 3-30](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/explain.sql#L3-L30)) :

```sql
-- Des plans et des nombres de lignes identiques à chaque exécution :
-- pas de workers parallèles, dont la part des lignes varie, et des statistiques calculées sur toutes les lignes, pas sur un échantillon
SET max_parallel_workers_per_gather = 0;
SET default_statistics_target = 1500;

-- EXPLAIN ANALYZE sans ce qui change d'une exécution à l'autre : coûts, durées, buffers utilisés par le planificateur lui-même, et la répartition des
-- pages entre shared buffers (hit) et disque (read), qui dépend de ce que les requêtes précédentes ont laissé en mémoire
CREATE FUNCTION pg_temp.plan(query text) RETURNS TABLE ("QUERY PLAN" text) LANGUAGE plpgsql AS $$
DECLARE
    line text;
    planning boolean := false;
    pages bigint;
BEGIN
    FOR line IN EXECUTE 'EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF) ' || query LOOP
        IF line = 'Planning:' THEN
            planning := true;
        ELSIF NOT (planning AND line LIKE ' %') THEN
            planning := false;
            IF line ~ 'Buffers: shared ' THEN
                pages := coalesce(substring(line FROM 'hit=(\d+)')::bigint, 0) + coalesce(substring(line FROM 'read=(\d+)')::bigint, 0);
                line := substring(line FROM '^\s*') || 'Buffers: shared hit+read=' || pages;
            END IF;
            "QUERY PLAN" := line;
            RETURN NEXT;
        END IF;
    END LOOP;
END
$$;
```

- [`max_parallel_workers_per_gather`](https://www.postgresql.org/docs/18/runtime-config-resource.html#GUC-MAX-PARALLEL-WORKERS-PER-GATHER) `= 0` désactive les requêtes parallèles : avec des workers, la part des lignes de chaque processus changeait à chaque exécution.
- [`default_statistics_target`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-DEFAULT-STATISTICS-TARGET) `= 1500` fait échantillonner à `ANALYZE` 300 lignes par unité de cible, soit 450 000 lignes, plus que la table n'en a : les statistiques viennent de toutes les lignes, et les estimations sont les mêmes à chaque exécution. Avec la valeur par défaut de 100, `ANALYZE` lit un échantillon aléatoire de 30 000 lignes.
- `pg_temp.plan` exécute [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html) `(ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF)` et additionne les pages trouvées en mémoire (`hit`) et lues sur le disque (`read`) en un seul nombre : leur répartition dépend de ce que les requêtes précédentes ont laissé dans le cache, pas le total.

`EXPLAIN ANALYZE` exécute la requête. Depuis PostgreSQL 18, il affiche aussi `BUFFERS` sans qu'on le demande, montre les nombres de lignes avec deux décimales, qui comptent quand un nœud s'exécute en de nombreuses boucles, et compte les `Index Searches` de chaque parcours d'index ([notes de version de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html)). Dans ton propre `psql`, `EXPLAIN (ANALYZE, BUFFERS)` montre les mêmes plans avec leurs coûts et leurs durées.

## La table

[Lignes 8-11](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L8-L11) :

```sql
-- La table : 2 204 étapes rejouées sur 200 jours
SELECT count(*) AS rows, pg_size_pretty(pg_relation_size('ci.step_history')) AS size,
       min(started_at)::date AS first_day, max(started_at)::date AS last_day
FROM ci.step_history;
```

```text
  rows  | size  | first_day  |  last_day
--------+-------+------------+------------
 440800 | 76 MB | 2026-02-26 | 2026-09-14
(1 row)
```

## Un parcours séquentiel

Les étapes en échec du jour, sans index ([lignes 13-17](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L13-L17)) :

```sql
-- Une requête, sans index : chaque page de la table est lue
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=9667
   ->  Seq Scan on step_history (actual rows=15.00 loops=1)
         Filter: ((started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone) AND ((conclusion)::text = 'failure'::text))
         Rows Removed by Filter: 440785
         Buffers: shared hit+read=9667
(6 rows)
```

Un plan se lit depuis le nœud le plus indenté vers le haut : chaque nœud alimente celui du dessus. `Seq Scan` a lu les 9 667 pages de la table, de 8 ko chacune, gardé 15 lignes et écarté 440 785. `Buffers` est le nombre à surveiller dans cette leçon : sur un vrai serveur, les pages absentes de la mémoire sont des lectures disque.

## B-tree

Un [B-tree](https://www.postgresql.org/docs/18/indexes-types.html#INDEXES-TYPES-BTREE) sur `started_at`, et la même requête ([lignes 19-24](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L19-L24)) :

```sql
-- Un B-tree sur started_at
CREATE INDEX step_history_started_at ON ci.step_history (started_at);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
CREATE INDEX
                                         QUERY PLAN
--------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=47
   ->  Index Scan using step_history_started_at on step_history (actual rows=15.00 loops=1)
         Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 1518
         Index Searches: 1
         Buffers: shared hit+read=47
(8 rows)
```

47 pages au lieu de 9 667. `Index Cond` est ce que l'index trouve : les 1 533 étapes du 14 septembre. `Filter` est vérifié sur chaque ligne renvoyée par l'index, dans la table : 1 518 d'entre elles n'étaient pas des échecs.

Le même index, à partir du 1er juillet : un tiers de la table ([lignes 26-30](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L26-L30)) :

```sql
-- Le même index, un intervalle qui couvre un tiers de la table
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-07-01' AND conclusion = 'failure'
$$);
```

```text
                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=4396
   ->  Index Scan using step_history_started_at on step_history (actual rows=1665.00 loops=1)
         Index Cond: (started_at >= '2026-07-01 00:00:00+00'::timestamp with time zone)
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 165168
         Index Searches: 1
         Buffers: shared hit+read=4396
(8 rows)
```

Le planificateur a quand même choisi l'index, et a lu 4 396 pages, moins de la moitié de la table. Il sait que les lignes aux valeurs de `started_at` proches sont dans des pages proches, parce que la table a été remplie dans l'ordre chronologique : le parcours d'index lit les pages de la table presque dans l'ordre. Sur une table dont les lignes ne suivent aucun ordre particulier, un tiers des lignes serait réparti sur la plupart des pages, et un parcours séquentiel gagnerait. La [section BRIN](#brin) montre la statistique qu'utilise le planificateur.

SQL Server stocke une table qui a un index cluster dans l'ordre de cet index. Une table PostgreSQL est un heap : les lignes vont là où il y a de la place, et [`CLUSTER`](https://www.postgresql.org/docs/18/sql-cluster.html) la trie une fois, sans la garder triée ensuite.

## Index multicolonnes

Les cinq derniers échecs, tous jours confondus ([lignes 32-39](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L32-L39)) :

```sql
-- Les derniers échecs, tous jours confondus : la colonne d'égalité d'abord, puis la colonne de tri
CREATE INDEX step_history_conclusion_started_at ON ci.step_history (conclusion, started_at);
SELECT * FROM pg_temp.plan($$
    SELECT started_at, workflow_name, step_name FROM ci.step_history
    WHERE conclusion = 'failure'
    ORDER BY started_at DESC
    LIMIT 5
$$);
```

```text
CREATE INDEX
                                                  QUERY PLAN
---------------------------------------------------------------------------------------------------------------
 Limit (actual rows=5.00 loops=1)
   Buffers: shared hit+read=6
   ->  Index Scan Backward using step_history_conclusion_started_at on step_history (actual rows=5.00 loops=1)
         Index Cond: ((conclusion)::text = 'failure'::text)
         Index Searches: 1
         Buffers: shared hit+read=6
(6 rows)
```

L'index sur `(conclusion, started_at)` garde les échecs ensemble, triés par date : `Index Scan Backward` les lit depuis le plus récent, et `Limit` s'arrête après cinq. Six pages, et aucun nœud `Sort`. La règle est la même que dans SQL Server : d'abord les colonnes comparées avec `=`, puis la colonne de l'intervalle ou du tri ([index multicolonnes](https://www.postgresql.org/docs/18/indexes-multicolumn.html)).

## Index partiels

Un [index partiel](https://www.postgresql.org/docs/18/indexes-partial.html) ne contient que les lignes acceptées par son `WHERE`, comme un index filtré dans SQL Server ([lignes 41-50](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L41-L50)) :

```sql
-- Un index partiel ne contient que les lignes acceptées par son WHERE
CREATE INDEX step_history_not_success ON ci.step_history (started_at) WHERE conclusion <> 'success';
SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index WHERE indrelid = 'ci.step_history'::regclass
ORDER BY pg_relation_size(indexrelid) DESC, 1;

SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE conclusion <> 'success' AND started_at >= '2026-09-01'
$$);
```

```text
CREATE INDEX
                 index                 |  size
---------------------------------------+---------
 ci.step_history_conclusion_started_at | 9792 kB
 ci.step_history_pkey                  | 9688 kB
 ci.step_history_started_at            | 7504 kB
 ci.step_history_not_success           | 368 kB
(4 rows)

                                             QUERY PLAN
----------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=6
   ->  Index Only Scan using step_history_not_success on step_history (actual rows=1527.00 loops=1)
         Index Cond: (started_at >= '2026-09-01 00:00:00+00'::timestamp with time zone)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=6
(7 rows)
```

- 368 ko, contre 7,5 Mo pour l'index sur toutes les lignes : 95 % des étapes ont réussi, et l'index ne contient que les 5 % qui ont été sautées, en échec ou annulées.
- La requête répète le prédicat de l'index, `conclusion <> 'success'`, donc le planificateur sait que chaque ligne qu'il cherche est dans l'index. Une requête sans condition sur `conclusion` ne peut pas l'utiliser.
- `Index Only Scan` : le comptage n'a besoin d'aucune colonne de la table, et `Heap Fetches: 0` dit qu'il n'a pas du tout visité la table. La [section sur les index couvrants](#index-couvrants-et-parcours-dindex-seul) explique quand il le doit.

## Index sur des expressions

Un index sur le jour de `started_at` ([lignes 52-58](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L52-L58)) :

```sql
-- Un index sur une expression : l'expression doit être immuable
CREATE INDEX step_history_day ON ci.step_history ((started_at::date));
CREATE INDEX step_history_day ON ci.step_history (((started_at AT TIME ZONE 'UTC')::date));
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE (started_at AT TIME ZONE 'UTC')::date = '2026-09-14'
$$);
```

```text
ERROR:  functions in index expression must be marked IMMUTABLE
CREATE INDEX
                                           QUERY PLAN
------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=41
   ->  Bitmap Heap Scan on step_history (actual rows=1533.00 loops=1)
         Recheck Cond: (((started_at AT TIME ZONE 'UTC'::text))::date = '2026-09-14'::date)
         Heap Blocks: exact=37
         Buffers: shared hit+read=41
         ->  Bitmap Index Scan on step_history_day (actual rows=1533.00 loops=1)
               Index Cond: (((started_at AT TIME ZONE 'UTC'::text))::date = '2026-09-14'::date)
               Index Searches: 1
               Buffers: shared hit+read=4
(10 rows)
```

Le premier `CREATE INDEX` échoue : la date d'un `timestamptz` dépend du `TimeZone` de la session, donc la conversion est `STABLE`, pas `IMMUTABLE`, et un index ne peut stocker que ce qui ne change jamais ([volatilité des fonctions](https://www.postgresql.org/docs/18/xfunc-volatility.html)). `AT TIME ZONE 'UTC'` fixe le fuseau, et le second index fonctionne. SQL Server a la même règle pour un index sur une colonne calculée, qui doit être déterministe.

La requête doit répéter l'expression telle que l'index l'écrit. Le planificateur a choisi un `Bitmap Heap Scan` : l'index donne les positions des 1 533 lignes, triées par page dans un bitmap, et la table est lue page par page, 37 pages.

## Index couvrants et parcours d'index seul

`INCLUDE` ajoute des colonnes aux entrées feuilles d'un B-tree, comme dans SQL Server ([lignes 60-72](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L60-L72)) :

```sql
-- Un index couvrant et les parcours d'index seul
CREATE INDEX step_history_step_name ON ci.step_history (step_name) INCLUDE (duration);
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
UPDATE ci.step_history SET duration = duration WHERE step_name = 'Compile-fail doctests' AND started_at >= '2026-09-01';
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
VACUUM ci.step_history;
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
```

```text
CREATE INDEX
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=70
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=70
(7 rows)

UPDATE 622
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=426
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 1244
         Index Searches: 1
         Buffers: shared hit+read=426
(7 rows)

VACUUM
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=71
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=71
(7 rows)
```

L'index a toutes les colonnes dont la somme a besoin, mais un index PostgreSQL ne sait pas si la transaction peut voir une ligne : cette information est dans la version de la ligne, dans la table ([leçon 6](../06-transactions/)). Un [parcours d'index seul](https://www.postgresql.org/docs/18/indexes-index-only-scans.html) évite la table pour les pages que la [carte de visibilité](https://www.postgresql.org/docs/18/storage-vm.html) marque comme entièrement visibles, marque que pose `VACUUM`.

1. Après `VACUUM ANALYZE`, toutes les pages sont entièrement visibles : 70 pages d'index, `Heap Fetches: 0`.
2. L'`UPDATE` ne change rien, mais écrit une nouvelle version de 622 lignes. Leurs pages ne sont plus entièrement visibles, et l'index a maintenant 1 244 entrées qui pointent vers elles, une pour l'ancienne version et une pour la nouvelle : 1 244 lectures dans la table, 426 pages.
3. `VACUUM` supprime les anciennes versions et leurs entrées d'index, et marque de nouveau les pages comme entièrement visibles : retour à 71 pages.

Sur une table mise à jour sans arrêt, avec un autovacuum en retard, un parcours « d'index seul » lit quand même la table. Un index non cluster couvrant de SQL Server ne retourne jamais à la table pour cela ; dans PostgreSQL, l'index ne contient pas ce qu'une transaction doit savoir pour voir une ligne.

## GIN

[GIN](https://www.postgresql.org/docs/18/gin.html) indexe les éléments d'une valeur, ici les labels du runner, un tableau ([lignes 74-81](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L74-L81)) :

```sql
-- GIN sur un tableau : quels éléments une ligne contient-elle ?
CREATE INDEX step_history_labels ON ci.step_history USING gin (labels);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE labels @> '{macos-latest}' AND step_name = 'Toolchain'
$$);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE 'macos-latest' = ANY (labels) AND step_name = 'Toolchain'
$$);
```

```text
CREATE INDEX
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=3631
   ->  Bitmap Heap Scan on step_history (actual rows=4200.00 loops=1)
         Recheck Cond: ((step_name = 'Toolchain'::text) AND (labels @> '{macos-latest}'::text[]))
         Heap Blocks: exact=3532
         Buffers: shared hit+read=3631
         ->  BitmapAnd (actual rows=0.00 loops=1)
               Buffers: shared hit+read=99
               ->  Bitmap Index Scan on step_history_step_name (actual rows=13400.00 loops=1)
                     Index Cond: (step_name = 'Toolchain'::text)
                     Index Searches: 1
                     Buffers: shared hit+read=84
               ->  Bitmap Index Scan on step_history_labels (actual rows=80400.00 loops=1)
                     Index Cond: (labels @> '{macos-latest}'::text[])
                     Index Searches: 1
                     Buffers: shared hit+read=15
(16 rows)

                                       QUERY PLAN
----------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=5548
   ->  Bitmap Heap Scan on step_history (actual rows=4200.00 loops=1)
         Recheck Cond: (step_name = 'Toolchain'::text)
         Filter: ('macos-latest'::text = ANY (labels))
         Rows Removed by Filter: 9200
         Heap Blocks: exact=5464
         Buffers: shared hit+read=5548
         ->  Bitmap Index Scan on step_history_step_name (actual rows=13400.00 loops=1)
               Index Cond: (step_name = 'Toolchain'::text)
               Index Searches: 1
               Buffers: shared hit+read=84
(12 rows)
```

- `labels @> '{macos-latest}'`, « contient », utilise l'index GIN. Le planificateur a combiné deux index dans un `BitmapAnd` : 13 400 étapes `Toolchain` et 80 400 étapes sous macOS, 4 200 dans les deux.
- `'macos-latest' = ANY (labels)` veut dire la même chose, mais aucun opérateur d'index ne lui correspond : le plan lit toutes les étapes `Toolchain` et en écarte 9 200.

Un index sert les opérateurs de sa [classe d'opérateurs](https://www.postgresql.org/docs/18/indexes-opclass.html), pas le sens d'une condition. La leçon 7 utilise GIN pour `jsonb` et la recherche plein texte. [GiST](https://www.postgresql.org/docs/18/gist.html), l'autre type d'index généraliste, stocke des intervalles, des formes géométriques et d'autres valeurs qui se chevauchent ou se contiennent : c'est l'index derrière la contrainte d'exclusion sur `ci.steps` de la [leçon 2](../02-types/).

## BRIN

Un index [BRIN](https://www.postgresql.org/docs/18/brin.html) stocke, pour chaque plage de 128 pages, la plus petite et la plus grande valeur de la colonne ([lignes 83-93](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L83-L93)) :

```sql
-- BRIN : un résumé par plage de pages, utile quand la colonne suit l'ordre physique
DROP INDEX ci.step_history_started_at, ci.step_history_conclusion_started_at, ci.step_history_not_success;
CREATE INDEX step_history_started_at_brin ON ci.step_history USING brin (started_at);
SELECT pg_size_pretty(pg_relation_size('ci.step_history_started_at_brin')) AS brin_size;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
SELECT attname, round(correlation::numeric, 2) AS correlation
FROM pg_stats WHERE schemaname = 'ci' AND tablename = 'step_history' AND attname IN ('id', 'started_at', 'step_name')
ORDER BY attname;
```

```text
DROP INDEX
CREATE INDEX
 brin_size
-----------
 24 kB
(1 row)

                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=87
   ->  Bitmap Heap Scan on step_history (actual rows=15.00 loops=1)
         Recheck Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Rows Removed by Index Recheck: 2094
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 1518
         Heap Blocks: lossy=82
         Buffers: shared hit+read=87
         ->  Bitmap Index Scan on step_history_started_at_brin (actual rows=820.00 loops=1)
               Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
               Index Searches: 1
               Buffers: shared hit+read=5
(13 rows)

  attname   | correlation
------------+-------------
 id         |        1.00
 started_at |        1.00
 step_name  |        0.06
(3 rows)
```

- 24 ko, là où le B-tree sur la même colonne prenait 7,5 Mo.
- L'index donne des plages de pages, pas des lignes : `Heap Blocks: lossy=82`, et chaque ligne de ces pages est vérifiée de nouveau, `Rows Removed by Index Recheck: 2094`. 87 pages, contre 47 avec le B-tree.
- Cela ne marche que parce que la table a été remplie dans l'ordre chronologique. [`pg_stats`](https://www.postgresql.org/docs/18/view-pg-stats.html)`.correlation` mesure à quel point une colonne suit l'ordre physique des lignes : 1,00 pour `id` et `started_at`, 0,06 pour `step_name`. L'exercice 3 construit la même table dans un autre ordre.

BRIN est fait pour les grandes tables qui grandissent dans l'ordre d'une colonne : journaux, événements, mesures. L'idée la plus proche dans SQL Server est un index columnstore qui saute des groupes de lignes d'après leur minimum et leur maximum.

## Statistiques sur des colonnes corrélées

Le planificateur multiplie la sélectivité de chaque condition, comme si les colonnes étaient indépendantes ([lignes 95-106](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L95-L106)) :

```sql
-- Statistiques : deux colonnes qui dépendent l'une de l'autre
SELECT * FROM pg_temp.estimate($$
    SELECT * FROM ci.step_history
    WHERE workflow_name = 'Java course examples' AND job_name = 'java-for-csharp (ubuntu-latest)'
$$);
CREATE STATISTICS step_history_workflow_job (dependencies) ON workflow_name, job_name FROM ci.step_history;
ANALYZE ci.step_history;
SELECT * FROM pg_temp.estimate($$
    SELECT * FROM ci.step_history
    WHERE workflow_name = 'Java course examples' AND job_name = 'java-for-csharp (ubuntu-latest)'
$$);
SELECT dependencies FROM pg_stats_ext WHERE statistics_name = 'step_history_workflow_job';
```

```text
 estimated | actual
-----------+--------
      2254 |  18200
(1 row)

CREATE STATISTICS
ANALYZE
 estimated | actual
-----------+--------
     17896 |  18200
(1 row)

               dependencies
------------------------------------------
 {"2 => 3": 0.010889, "3 => 2": 0.980944}
(1 row)
```

`pg_temp.estimate` met l'estimation de lignes du planificateur à côté du compte réel. Un job nommé `java-for-csharp (ubuntu-latest)` ne s'exécute que dans le workflow `Java course examples`, donc la seconde condition n'écarte rien. Le planificateur a estimé 2 254 lignes, huit fois trop peu ; une mauvaise estimation choisit une boucle imbriquée là où il fallait une jointure par hachage, ou le mauvais index.

[`CREATE STATISTICS … (dependencies)`](https://www.postgresql.org/docs/18/planner-stats.html#PLANNER-STATS-EXTENDED) mesure à quel point une colonne en détermine une autre. Les colonnes 2 et 3 sont `workflow_name` et `job_name` : le nom du job détermine le workflow pour 98 % des lignes, et l'estimation passe à 17 896. `ndistinct` aide les `GROUP BY` sur plusieurs colonnes, `mcv` liste leurs combinaisons les plus fréquentes.

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* Aurora PostgreSQL utilise le planificateur et les types d'index de PostgreSQL, donc les plans de cette leçon s'y lisent de la même façon, et `EXPLAIN (ANALYZE, BUFFERS)` fonctionne comme sur n'importe quel PostgreSQL. Trois choses changent autour d'eux.

- **Stabilité des plans.** La [gestion des plans de requête](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.overview.html), l'extension `apg_plan_mgmt` (version 3.0 sur Aurora PostgreSQL 18.4), capture les plans des instructions qu'exécute une application. Avec [`apg_plan_mgmt.capture_plan_baselines`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Parameters.html) réglé sur `manual` ou `automatic`, « the optimizer sets the status of a managed statement's first captured plan to `approved` », et les suivants sur `unapproved` ([capture des plans](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.CapturePlans.html)). Avec `apg_plan_mgmt.use_plan_baselines` activé, l'optimiseur choisit parmi les plans approuvés, et [`evolve_plan_baselines`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Maintenance.html) compare les autres avant qu'ils soient approuvés. Le Query Store de SQL Server force des plans dans le même esprit ; PostgreSQL communautaire n'a rien d'intégré. Une mauvaise estimation comme celle de la section sur les statistiques ci-dessus est le genre de régression contre laquelle elle protège.
- **Supervision.** Performance Insights a été remplacé par [CloudWatch Database Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html) : « AWS announced that the end-of-life date for Performance Insights was July 31, 2026, and has migrated Performance Insights users to Database Insights ». L'[historique du document du guide de l'utilisateur d'Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/WhatsNew.html) donne encore le 30 novembre 2025. Database Insights montre la charge par événement d'attente et par instruction SQL ; les plans d'exécution et l'analyse des verrous ne sont que dans son mode Advanced. L'événement d'attente [`IO:DataFileRead`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.iodatafileread.html) est la partie `read` de `Buffers` : « a connection waits on a backend process to read a required page from storage because the page isn't available in shared memory ».
- **Mémoire.** [AWS écrit](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.Tuning-memory-parameters.html) que « the value for `shared_buffers` in the default parameter group is usually set to around 75% of the available memory ». PostgreSQL communautaire est livré avec 128 Mo, et sa documentation suggère 25 % de la mémoire comme point de départ sur un serveur dédié ([`shared_buffers`](https://www.postgresql.org/docs/18/runtime-config-resource.html#GUC-SHARED-BUFFERS)). La [référence des paramètres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html) donne la formule `SUM(DBInstanceClassMemory/12038,-50003)`, dans un tableau pour Aurora PostgreSQL 14 ; la valeur pour 18 est *à vérifier*. Ma lecture, que je n'ai pas trouvée écrite par AWS, est que le stockage d'Aurora n'est pas lu à travers le cache de fichiers du système d'exploitation, sur lequel PostgreSQL communautaire compte pour le reste de la mémoire.

## À retenir

- `EXPLAIN (ANALYZE, BUFFERS)` exécute la requête ; lis-le depuis le nœud le plus interne, et compare les pages, pas seulement les durées.
- Un B-tree sert `=`, les intervalles et les tris ; les colonnes d'égalité d'abord dans un index multicolonne.
- Les index partiels sont petits ; les index sur expression exigent des expressions `IMMUTABLE` et la même expression dans la requête.
- Les parcours d'index seul dépendent de la carte de visibilité, c'est-à-dire de `VACUUM`.
- GIN indexe les éléments des tableaux, de `jsonb` et du texte ; un index sert des opérateurs, pas des significations.
- BRIN est minuscule et n'est utile que quand la colonne suit l'ordre physique.
- Des colonnes corrélées trompent le planificateur ; `CREATE STATISTICS` corrige l'estimation.

## Exercices

Les solutions sont dans [`sql/05-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql), après la même préparation que la leçon.

1. Affiche les 20 dernières étapes en échec du workflow `Rust course examples`, avec un plan sans nœud `Sort`, et un index de moins d'un mégaoctet.

<details>
<summary>Solution</summary>

Tiré des [lignes 8-16](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L8-L16) :

```sql
-- Exercice 1 : les 20 dernières étapes en échec du workflow du cours Rust, sans tri
CREATE INDEX step_history_failures ON ci.step_history (workflow_name, started_at) WHERE conclusion = 'failure';
SELECT * FROM pg_temp.plan($$
    SELECT started_at, job_name, step_name FROM ci.step_history
    WHERE conclusion = 'failure' AND workflow_name = 'Rust course examples'
    ORDER BY started_at DESC
    LIMIT 20
$$);
SELECT pg_size_pretty(pg_relation_size('ci.step_history_failures')) AS size;
```

```text
CREATE INDEX
                                            QUERY PLAN
---------------------------------------------------------------------------------------------------
 Limit (actual rows=20.00 loops=1)
   Buffers: shared hit+read=15
   ->  Index Scan Backward using step_history_failures on step_history (actual rows=20.00 loops=1)
         Index Cond: (workflow_name = 'Rust course examples'::text)
         Index Searches: 1
         Buffers: shared hit+read=15
(6 rows)

  size
--------
 232 kB
(1 row)
```

Un index partiel sur `(workflow_name, started_at)`, pour les échecs seulement : 232 ko. Le `conclusion = 'failure'` de la requête correspond au prédicat, donc le plan ne le montre même pas comme condition ; `workflow_name` est la colonne d'égalité, et `started_at` donne l'ordre, lu à l'envers.

</details>

2. Compte les étapes du 10 septembre 2026, d'abord avec `date_trunc('day', started_at) = '2026-09-10'`, puis avec un intervalle, les deux avec un B-tree sur `started_at`. Compare les plans.

<details>
<summary>Solution</summary>

Tiré des [lignes 18-25](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L18-L25) :

```sql
-- Exercice 2 : un jour d'étapes, écrit de deux façons
CREATE INDEX step_history_started_at ON ci.step_history (started_at);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE date_trunc('day', started_at) = '2026-09-10'
$$);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE started_at >= '2026-09-10' AND started_at < '2026-09-11'
$$);
```

```text
CREATE INDEX
                                                 QUERY PLAN
------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=935
   ->  Index Only Scan using step_history_started_at on step_history (actual rows=2204.00 loops=1)
         Filter: (date_trunc('day'::text, started_at) = '2026-09-10 00:00:00+00'::timestamp with time zone)
         Rows Removed by Filter: 438596
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=935
(8 rows)

                                                                           QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=8
   ->  Index Only Scan using step_history_started_at on step_history (actual rows=2204.00 loops=1)
         Index Cond: ((started_at >= '2026-09-10 00:00:00+00'::timestamp with time zone) AND (started_at < '2026-09-11 00:00:00+00'::timestamp with time zone))
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=8
(7 rows)
```

Avec `date_trunc`, l'index n'est qu'une copie plus petite de la colonne : le plan le lit en entier, 935 pages, et filtre 438 596 entrées. `date_trunc` sur un `timestamptz` dépend du fuseau horaire de la session, donc il ne pourrait pas non plus être indexé sans `AT TIME ZONE`. L'intervalle sur la colonne elle-même est un `Index Cond` : 8 pages. SQL Server appelle la seconde forme *sargable* ; la règle est la même.

</details>

3. Copie `ci.step_history` dans une table triée par `step_name`, puis par `started_at`. Construis un index BRIN sur `started_at` et compte les étapes du 14 septembre. Que s'est-il passé ?

<details>
<summary>Solution</summary>

Tiré des [lignes 27-35](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L27-L35) :

```sql
-- Exercice 3 : les mêmes lignes dans un autre ordre physique, et un index BRIN sur started_at
CREATE TABLE ci.step_history_by_name AS SELECT * FROM ci.step_history ORDER BY step_name, started_at;
CREATE INDEX step_history_by_name_brin ON ci.step_history_by_name USING brin (started_at);
VACUUM ANALYZE ci.step_history_by_name;
SELECT attname, round(correlation::numeric, 2) AS correlation
FROM pg_stats WHERE schemaname = 'ci' AND tablename = 'step_history_by_name' AND attname = 'started_at';
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history_by_name WHERE started_at >= '2026-09-14'
$$);
```

```text
SELECT 440800
CREATE INDEX
VACUUM
  attname   | correlation
------------+-------------
 started_at |        0.06
(1 row)

                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=4869
   ->  Bitmap Heap Scan on step_history_by_name (actual rows=1533.00 loops=1)
         Recheck Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Rows Removed by Index Recheck: 212661
         Heap Blocks: lossy=4864
         Buffers: shared hit+read=4869
         ->  Bitmap Index Scan on step_history_by_name_brin (actual rows=48640.00 loops=1)
               Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
               Index Searches: 1
               Buffers: shared hit+read=5
(11 rows)
```

La corrélation de `started_at` tombe à 0,06. Une plage de pages contient maintenant les étapes d'un nom ou de quelques-uns, sur de nombreux jours : la moitié des plages peut contenir le 14 septembre, donc l'index garde 4 864 des 9 667 pages de la table, et la revérification écarte 212 661 lignes. Un parcours séquentiel n'aurait pas fait beaucoup plus de travail. Un index BRIN a besoin de données qui arrivent dans l'ordre de sa colonne et y restent.

</details>

## Sources

- Documentation de PostgreSQL 18 : [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html), [utiliser `EXPLAIN`](https://www.postgresql.org/docs/18/using-explain.html), [types d'index](https://www.postgresql.org/docs/18/indexes-types.html), [index multicolonnes](https://www.postgresql.org/docs/18/indexes-multicolumn.html), [index partiels](https://www.postgresql.org/docs/18/indexes-partial.html), [index sur des expressions](https://www.postgresql.org/docs/18/indexes-expressional.html), [parcours d'index seul et index couvrants](https://www.postgresql.org/docs/18/indexes-index-only-scans.html), [classes d'opérateurs](https://www.postgresql.org/docs/18/indexes-opclass.html), [GIN](https://www.postgresql.org/docs/18/gin.html), [GiST](https://www.postgresql.org/docs/18/gist.html), [BRIN](https://www.postgresql.org/docs/18/brin.html), [la carte de visibilité](https://www.postgresql.org/docs/18/storage-vm.html), [statistiques utilisées par le planificateur](https://www.postgresql.org/docs/18/planner-stats.html), [`pg_stats`](https://www.postgresql.org/docs/18/view-pg-stats.html), [volatilité des fonctions](https://www.postgresql.org/docs/18/xfunc-volatility.html), [`CLUSTER`](https://www.postgresql.org/docs/18/sql-cluster.html), [notes de version](https://www.postgresql.org/docs/18/release-18.html)
- SQL Server : [index filtrés](https://learn.microsoft.com/sql/relational-databases/indexes/create-filtered-indexes), [index avec colonnes incluses](https://learn.microsoft.com/sql/relational-databases/indexes/create-indexes-with-included-columns), [index columnstore et élimination de rowgroups](https://learn.microsoft.com/sql/relational-databases/indexes/columnstore-indexes-query-performance)
- Amazon Aurora : [gestion des plans de requête](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.overview.html), [capture des plans](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.CapturePlans.html), [ses paramètres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Parameters.html), [maintenance des plans](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Maintenance.html), [CloudWatch Database Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html), [historique du document](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/WhatsNew.html), [`IO:DataFileRead`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.iodatafileread.html), [paramètres de mémoire](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.Tuning-memory-parameters.html), [référence des paramètres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html), toutes lues le 2026-09-16
