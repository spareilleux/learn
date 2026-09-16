---
title: "9. Partitionnement et grandes tables"
description: Le partitionnement déclaratif de PostgreSQL 18 pour les développeurs SQL Server — partitions par intervalle, par liste et par hachage de l'historique de 440 800 étapes, clés primaires qui incluent la clé de partitionnement, élagage à la planification et à l'exécution, index partitionnés, rétention avec DETACH et DROP plutôt que DELETE, partitions par défaut, ATTACH avec une contrainte CHECK correspondante, et pg_partman sur Aurora.
sidebar:
  order: 9
---

Le script de la leçon est [`sql/09-partitioning.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql), et les exercices sont dans [`sql/09-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql). `check.sh` compare leur sortie à [`expected/09-partitioning.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/09-partitioning.txt) et [`expected/09-exercises.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/09-exercises.txt). Les deux chargent `ci.step_history`, la table de la leçon 5 avec 440 800 étapes sur 200 jours.

| SQL Server | PostgreSQL |
|---|---|
| fonction de partition et schéma de partition | `PARTITION BY RANGE`, `LIST` ou `HASH` sur la table, une table par partition |
| valeurs limites `RANGE LEFT` ou `RANGE RIGHT` | `FOR VALUES FROM (…) TO (…)` : la borne inférieure incluse, la supérieure exclue |
| groupes de fichiers | tablespaces, rarement nécessaires ; chaque partition a ses propres fichiers |
| index alignés | un index sur la table partitionnée, créé sur chaque partition |
| `ALTER TABLE … SWITCH PARTITION` | `ALTER TABLE … ATTACH PARTITION` et `DETACH PARTITION` |
| `$PARTITION.function(value)` | `tableoid::regclass`, la partition d'où une ligne a été lue |
| jusqu'à 15 000 partitions | pas de limite fixe ; le temps de planification et la mémoire croissent avec les partitions qu'une requête garde |

## Une table partitionnée

SQL Server partitionne une table au moyen de deux objets distincts, une [fonction de partition](https://learn.microsoft.com/sql/t-sql/statements/create-partition-function-transact-sql) et un schéma. Le [partitionnement déclaratif](https://www.postgresql.org/docs/18/ddl-partitioning.html) de PostgreSQL met la méthode et la clé sur la table, et chaque partition est une table à part entière, avec ses bornes. Le premier essai, avec la même clé primaire que `ci.step_history` ([lignes 8-18](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L8-L18)) :

```sql
-- Une table partitionnée n'a pas de lignes à elle : chaque ligne va dans la partition dont les bornes contiennent sa clé
CREATE TABLE ci.step_log (
    id            bigint NOT NULL,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL,
    PRIMARY KEY (id)
) PARTITION BY RANGE (started_at);
```

```text
ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "step_log" lacks column "started_at" which is part of the partition key.
```

Il n'y a pas d'index qui couvre toutes les partitions : chaque partition a le sien, qui ne peut vérifier l'unicité que parmi ses propres lignes. La règle de la documentation est que « the constraint's columns must include all of the partition key columns ». Deux lignes avec le même `id` dans deux mois différents seraient toutes deux acceptées, donc PostgreSQL refuse la clé. Avec `started_at` dedans, la clé est vérifiée partition par partition et reste valable pour toute la table ([lignes 20-46](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L20-L46)) :

```sql
-- Une clé primaire doit inclure la clé de partitionnement : chaque partition vérifie l'unicité sur ses propres lignes
CREATE TABLE ci.step_log (
    id            bigint NOT NULL,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL,
    PRIMARY KEY (id, started_at)
) PARTITION BY RANGE (started_at);

-- Une partition par mois, de février à septembre 2026, écrites par une requête et exécutées par \gexec
SELECT format('CREATE TABLE ci.step_log_%s PARTITION OF ci.step_log FOR VALUES FROM (%L) TO (%L)',
              to_char(m, 'YYYY_MM'), m, m + interval '1 month')
FROM generate_series(timestamptz '2026-02-01', '2026-09-01', interval '1 month') AS m
ORDER BY m
\gexec

INSERT INTO ci.step_log
SELECT id, workflow_name, job_name, step_name, conclusion, started_at, duration FROM ci.step_history;
VACUUM ANALYZE ci.step_log;

SELECT tableoid::regclass AS partition, count(*) AS rows, min(started_at)::date AS first_day, max(started_at)::date AS last_day
FROM ci.step_log
GROUP BY tableoid
ORDER BY first_day;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 440800
VACUUM
      partition      | rows  | first_day  |  last_day
---------------------+-------+------------+------------
 ci.step_log_2026_02 |  5079 | 2026-02-26 | 2026-02-28
 ci.step_log_2026_03 | 68324 | 2026-03-01 | 2026-03-31
 ci.step_log_2026_04 | 66120 | 2026-04-01 | 2026-04-30
 ci.step_log_2026_05 | 68324 | 2026-05-01 | 2026-05-31
 ci.step_log_2026_06 | 66120 | 2026-06-01 | 2026-06-30
 ci.step_log_2026_07 | 68324 | 2026-07-01 | 2026-07-31
 ci.step_log_2026_08 | 68324 | 2026-08-01 | 2026-08-31
 ci.step_log_2026_09 | 30185 | 2026-09-01 | 2026-09-14
(8 rows)
```

- La requête écrit huit instructions [`CREATE TABLE … PARTITION OF`](https://www.postgresql.org/docs/18/sql-createtable.html), une par mois, et le [`\gexec`](https://www.postgresql.org/docs/18/app-psql.html#APP-PSQL-META-COMMAND-GEXEC) de `psql` exécute chaque ligne du résultat comme une instruction : les neuf lignes `CREATE TABLE` sont la table et ses huit partitions.
- `FROM` inclut sa borne et `TO` l'exclut, donc `2026-03-01 00:00` appartient à mars seulement.
- `tableoid::regclass` nomme la partition dans laquelle chaque ligne est stockée.
- Février n'a que trois jours, puisque l'historique commence le 26 février.

Une ligne qui tombe hors de toutes les partitions est refusée ([lignes 48-49](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L48-L49)) :

```sql
-- Une ligne hors des bornes de toutes les partitions n'a nulle part où aller
INSERT INTO ci.step_log VALUES (0, 'Deploy to GitHub Pages', 'deploy', 'Checkout', 'success', '2026-10-01 12:00+00', '2 seconds');
```

```text
ERROR:  no partition of relation "step_log" found for row
DETAIL:  Partition key of the failing row contains (started_at) = (2026-10-01 12:00:00+00).
```

## Élagage des partitions

Avec une condition sur la clé de partitionnement, le planificateur écarte les partitions dont les bornes ne peuvent pas correspondre. `pg_temp.plan` est l'`EXPLAIN (ANALYZE, BUFFERS)` de la leçon 5, sans les coûts ni les temps ([lignes 51-58](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L51-L58)) :

```sql
-- Élagage des partitions : une condition sur la clé de partitionnement écarte les partitions qui ne peuvent pas correspondre
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_log WHERE started_at >= '2026-09-14'
$$);
-- Sans condition sur la clé, chaque partition est lue
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_log WHERE step_name = 'Compile-fail doctests'
$$);
```

```text
                                                  QUERY PLAN
--------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=121
   ->  Index Only Scan using step_log_2026_09_pkey on step_log_2026_09 step_log (actual rows=1533.00 loops=1)
         Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=121
(7 rows)

                                    QUERY PLAN
-----------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=7453
   ->  Append (actual rows=9200.00 loops=1)
         Buffers: shared hit+read=7453
         ->  Seq Scan on step_log_2026_02 step_log_1 (actual rows=114.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 4965
               Buffers: shared hit+read=86
         ->  Seq Scan on step_log_2026_03 step_log_2 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_04 step_log_3 (actual rows=1380.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 64740
               Buffers: shared hit+read=1118
         ->  Seq Scan on step_log_2026_05 step_log_4 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_06 step_log_5 (actual rows=1380.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 64740
               Buffers: shared hit+read=1118
         ->  Seq Scan on step_log_2026_07 step_log_6 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_08 step_log_7 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_09 step_log_8 (actual rows=622.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 29563
               Buffers: shared hit+read=511
(36 rows)
```

- La première requête lit une partition, celle de septembre, par l'index de sa clé primaire, dont la deuxième colonne est `started_at` : 121 pages.
- La seconde n'a pas de condition sur `started_at` : un nœud `Append` lit les huit partitions, 7 453 pages. Le partitionnement n'accélère pas une requête qui ne filtre pas sur la clé ; un index sur `step_name`, si.

Avec un paramètre, la valeur est inconnue quand le plan est construit. Un plan générique garde toutes les partitions, et l'exécuteur retire celles que la valeur exclut quand la requête s'exécute ([lignes 60-65](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L60-L65)) :

```sql
-- Un paramètre n'est connu qu'à l'exécution : le plan générique élague alors, et dit combien de partitions il a sautées
PREPARE failures_since (timestamptz) AS
    SELECT count(*) FROM ci.step_log WHERE started_at >= $1 AND conclusion = 'failure';
SET plan_cache_mode = force_generic_plan;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF, BUFFERS OFF) EXECUTE failures_since('2026-09-01');
RESET plan_cache_mode;
```

```text
PREPARE
SET
                                      QUERY PLAN
---------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   ->  Append (actual rows=301.00 loops=1)
         Subplans Removed: 7
         ->  Seq Scan on step_log_2026_09 step_log_1 (actual rows=301.00 loops=1)
               Filter: ((started_at >= $1) AND ((conclusion)::text = 'failure'::text))
               Rows Removed by Filter: 29884
(6 rows)

RESET
```

`Subplans Removed: 7` est cet élagage à l'exécution. [`plan_cache_mode`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-PLAN-CACHE-MODE) force le plan générique, vers lequel une [instruction préparée](https://www.postgresql.org/docs/18/sql-prepare.html) peut basculer après ses cinq premières exécutions, qu'elle ait été préparée en SQL ou par Npgsql et pgjdbc ([leçon 4](../04-csharp-java/)). [`enable_partition_pruning`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-ENABLE-PARTITION-PRUNING), activé par défaut, contrôle les deux sortes d'élagage.

## Index et lignes déplacées

Un index créé sur la table partitionnée est un *index partitionné* : PostgreSQL crée un index sur chaque partition et l'attache au parent ([lignes 67-72](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L67-L72)) :

```sql
-- Un index créé sur la table partitionnée est créé sur chaque partition, et sur les partitions ajoutées plus tard
CREATE INDEX step_log_step_name ON ci.step_log (step_name);
SELECT c.relname AS index, i.inhparent::regclass AS parent
FROM pg_inherits AS i JOIN pg_class AS c ON c.oid = i.inhrelid
WHERE i.inhparent = 'ci.step_log_step_name'::regclass
ORDER BY c.relname;
```

```text
CREATE INDEX
             index              |        parent
--------------------------------+-----------------------
 step_log_2026_02_step_name_idx | ci.step_log_step_name
 step_log_2026_03_step_name_idx | ci.step_log_step_name
 step_log_2026_04_step_name_idx | ci.step_log_step_name
 step_log_2026_05_step_name_idx | ci.step_log_step_name
 step_log_2026_06_step_name_idx | ci.step_log_step_name
 step_log_2026_07_step_name_idx | ci.step_log_step_name
 step_log_2026_08_step_name_idx | ci.step_log_step_name
 step_log_2026_09_step_name_idx | ci.step_log_step_name
(8 rows)
```

Une partition créée plus tard reçoit sa propre copie de l'index. Le créer sur une grande table verrouille la table ; la documentation décrit comment construire d'abord l'index de chaque partition avec `CONCURRENTLY`, puis créer l'index du parent `ON ONLY` le parent et les attacher.

Un `UPDATE` qui change la clé de partitionnement déplace la ligne : PostgreSQL la supprime d'une partition et l'insère dans l'autre ([lignes 74-77](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L74-L77)) :

```sql
-- Un UPDATE de la clé de partitionnement déplace la ligne vers une autre partition
UPDATE ci.step_log SET started_at = started_at - interval '1 month'
WHERE id = (SELECT min(id) FROM ci.step_log WHERE started_at >= '2026-09-01')
RETURNING tableoid::regclass AS now_in, started_at;
```

```text
       now_in        |       started_at
---------------------+------------------------
 ci.step_log_2026_08 | 2026-08-01 01:37:05+00
(1 row)

UPDATE 1
```

## Rétention : détacher, puis supprimer

La raison habituelle des partitions mensuelles est de retirer un mois d'un coup. Un `DELETE` de février laisse autant de versions de lignes mortes à nettoyer par vacuum qu'il a retiré de lignes, comme dans la [leçon 6](../06-transactions/). Retirer la partition prend un verrou et supprime des fichiers ([lignes 79-87](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L79-L87)) :

```sql
-- Rétention : retirer un mois avec DELETE laisse des lignes mortes à nettoyer ; supprimer sa partition retire un fichier
CREATE EXTENSION pgstattuple;
BEGIN;
DELETE FROM ci.step_log WHERE started_at < '2026-03-01';
SELECT pg_size_pretty(table_len) AS size, dead_tuple_count FROM pgstattuple('ci.step_log_2026_02');
ROLLBACK;
ALTER TABLE ci.step_log DETACH PARTITION ci.step_log_2026_02;
SELECT count(*) AS rows_left FROM ci.step_log;
DROP TABLE ci.step_log_2026_02;
```

```text
CREATE EXTENSION
BEGIN
DELETE 5079
  size  | dead_tuple_count
--------+------------------
 688 kB |             5079
(1 row)

ROLLBACK
ALTER TABLE
 rows_left
-----------
    435721
(1 row)

DROP TABLE
```

- [`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html) compte 5 079 tuples morts dans le fichier de 688 ko de février, annulés ici.
- [`DETACH PARTITION`](https://www.postgresql.org/docs/18/sql-altertable.html) transforme la partition en table ordinaire, qui peut être archivée avec `pg_dump` ([leçon 11](../11-backup/)) avant `DROP TABLE`.
- `DETACH PARTITION … CONCURRENTLY` prend un verrou plus faible sur le parent, mais « cannot be run in a transaction block and is not allowed if the partitioned table contains a default partition ».

## Partitions par défaut, et attacher une table chargée

Une [partition par défaut](https://www.postgresql.org/docs/18/sql-createtable.html) reçoit les lignes qu'aucune autre partition n'accepte : la ligne d'octobre refusée plus haut y entre. Elle empêche ensuite de créer la partition à laquelle cette ligne appartient ([lignes 89-93](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L89-L93)) :

```sql
-- Une partition par défaut prend les lignes qu'aucune autre partition n'accepte
CREATE TABLE ci.step_log_default PARTITION OF ci.step_log DEFAULT;
INSERT INTO ci.step_log VALUES (0, 'Deploy to GitHub Pages', 'deploy', 'Checkout', 'success', '2026-10-01 12:00+00', '2 seconds');
-- ... puis bloque une nouvelle partition à laquelle ses lignes appartiennent
CREATE TABLE ci.step_log_2026_10 PARTITION OF ci.step_log FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
```

```text
CREATE TABLE
INSERT 0 1
ERROR:  updated partition constraint for default partition "step_log_default" would be violated by some row
```

Ajouter une partition parcourt aussi la partition par défaut, pour vérifier qu'aucune de ses lignes n'appartient à la nouvelle. Une partition par défaut est un filet de sécurité, qui devrait rester vide.

L'habitude SQL Server de charger une table de préparation, puis de la faire entrer par `SWITCH`, devient `ATTACH PARTITION` ([lignes 95-107](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L95-L107)) :

```sql
-- Charger un mois à part, puis l'attacher : une contrainte CHECK avec les mêmes bornes évite le parcours qui les valide
DELETE FROM ci.step_log_default;
CREATE TABLE ci.step_log_2026_10 (LIKE ci.step_log INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
INSERT INTO ci.step_log_2026_10
SELECT id + 1000000, workflow_name, job_name, step_name, conclusion, started_at + interval '1 month', duration
FROM ci.step_log_2026_09;
ALTER TABLE ci.step_log_2026_10 ADD CONSTRAINT in_october
    CHECK (started_at >= '2026-10-01' AND started_at < '2026-11-01');
ALTER TABLE ci.step_log ATTACH PARTITION ci.step_log_2026_10 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
SELECT relname AS partition, pg_get_expr(relpartbound, oid) AS bounds
FROM pg_class
WHERE oid IN (SELECT inhrelid FROM pg_inherits WHERE inhparent = 'ci.step_log'::regclass)
ORDER BY relname;
```

```text
DELETE 1
CREATE TABLE
INSERT 0 30184
ALTER TABLE
ALTER TABLE
    partition     |                                  bounds
------------------+--------------------------------------------------------------------------
 step_log_2026_03 | FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00')
 step_log_2026_04 | FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-05-01 00:00:00+00')
 step_log_2026_05 | FOR VALUES FROM ('2026-05-01 00:00:00+00') TO ('2026-06-01 00:00:00+00')
 step_log_2026_06 | FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00')
 step_log_2026_07 | FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00')
 step_log_2026_08 | FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00')
 step_log_2026_09 | FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00')
 step_log_2026_10 | FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00')
 step_log_default | DEFAULT
(9 rows)
```

- Octobre est chargé dans une table hors de la table partitionnée, une copie de septembre un mois plus tard, où il peut être vérifié avant que quiconque le voie.
- `ATTACH PARTITION` parcourt la table pour vérifier ses bornes, en détenant un verrou `ACCESS EXCLUSIVE` sur elle. La documentation recommande de « creating a `CHECK` constraint matching the expected partition constraint on the table prior to attaching it » : PostgreSQL fait alors confiance à la contrainte et saute le parcours. La contrainte peut être supprimée ensuite.
- Sur le parent, `ATTACH PARTITION` prend un verrou `SHARE UPDATE EXCLUSIVE`, plus faible que le verrou `ACCESS EXCLUSIVE` de `CREATE TABLE … PARTITION OF`.
- [`pg_get_expr(relpartbound, oid)`](https://www.postgresql.org/docs/18/functions-info.html) affiche les bornes de chaque partition, en UTC dans cette session.

## Liste et hachage

[`PARTITION BY LIST`](https://www.postgresql.org/docs/18/ddl-partitioning.html) liste les valeurs de chaque partition ; `PARTITION BY HASH` répartit les lignes sur un nombre fixe de partitions selon le hachage de la clé ([lignes 109-125](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L109-L125)) :

```sql
-- Partitionnement par liste et par hachage
CREATE TABLE ci.step_outcomes (LIKE ci.step_log) PARTITION BY LIST (conclusion);
CREATE TABLE ci.step_outcomes_success PARTITION OF ci.step_outcomes FOR VALUES IN ('success');
CREATE TABLE ci.step_outcomes_other PARTITION OF ci.step_outcomes DEFAULT;
CREATE TABLE ci.step_buckets (LIKE ci.step_log) PARTITION BY HASH (job_name);
SELECT format('CREATE TABLE ci.step_buckets_%s PARTITION OF ci.step_buckets FOR VALUES WITH (MODULUS 4, REMAINDER %s)', r, r)
FROM generate_series(0, 3) AS r
ORDER BY r
\gexec
INSERT INTO ci.step_outcomes SELECT * FROM ci.step_log;
INSERT INTO ci.step_buckets SELECT * FROM ci.step_log;
SELECT tableoid::regclass AS partition, count(*) AS rows, count(DISTINCT job_name) AS jobs
FROM ci.step_outcomes GROUP BY tableoid
UNION ALL
SELECT tableoid::regclass, count(*), count(DISTINCT job_name)
FROM ci.step_buckets GROUP BY tableoid
ORDER BY 1;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 465905
INSERT 0 465905
        partition         |  rows  | jobs
--------------------------+--------+------
 ci.step_outcomes_success | 441875 |   64
 ci.step_outcomes_other   |  24030 |   17
 ci.step_buckets_0        |  83288 |   18
 ci.step_buckets_1        | 113779 |   15
 ci.step_buckets_2        | 175176 |   13
 ci.step_buckets_3        |  93662 |   18
(6 rows)
```

- La partition `success` contient 95 % des lignes : le partitionnement par liste suit les données, équilibrées ou non.
- Le partitionnement par hachage de 64 noms de jobs distincts laisse une partition avec deux fois les lignes d'une autre. Un hachage répartit des *clés*, pas des lignes : quelques jobs très actifs pèsent plus que beaucoup de jobs rares. Les partitions par hachage n'aident ni l'élagage par intervalles ni la rétention ; elles découpent une table qui n'a pas d'intervalle naturel, pour la maintenance ou le travail en parallèle.

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* Le partitionnement déclaratif est celui de PostgreSQL, et Aurora ne le change pas. Ce qui change, ce sont les outils autour.

- **pg_partman et pg_cron.** Les partitions du mois prochain doivent exister avant le mois prochain. [pg_partman](https://github.com/pgpartman/pg_partman) les crée à l'avance et supprime les anciennes, et [pg_cron](https://github.com/citusdata/pg_cron) exécute sa maintenance selon un calendrier. Le [tableau des extensions d'Aurora PostgreSQL 18](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) liste pg_partman 5.4.3 sur 18.4 (5.2.4 sur 18.3) et pg_cron 1.6.7 ; la [page pg_partman](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_Partitions.html) d'AWS dit qu'il « is supported on Aurora PostgreSQL versions 12.6 and higher ».
- **Limites.** Je n'ai trouvé aucun quota de partitions ni de nombre de tables dans les [quotas et limites d'Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html). La même page donne une taille maximale de table de 32 Tio pour Aurora PostgreSQL, et recommande des « table design best practices, such as partitioning of large tables » : chaque partition est une table, donc la limite s'applique par partition.
- **Déploiements blue/green.** Ils répliquent par réplication logique ([leçon 11](../11-backup/#sur-aurora)), et les [considérations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html) d'AWS indiquent que « creating new partitions on partitioned tables isn't supported during blue/green deployments for Aurora », et que « the pg_partman extension must be disabled in the blue environment ».
- **Zero-ETL vers Redshift.** Pour les [intégrations zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html), « the table partitions will be replicated to Amazon Redshift. However, the partitioned table itself isn't replicated ».

## À retenir

- Une table partitionnée est un parent sans lignes et une table par partition ; `FROM` est inclusif, `TO` exclusif.
- Les clés primaires et les contraintes d'unicité doivent inclure la clé de partitionnement.
- L'élagage a besoin d'une condition sur la clé ; avec des paramètres, il a lieu à l'exécution (`Subplans Removed`).
- Les index créés sur le parent sont créés sur chaque partition, présente et future.
- La rétention, c'est `DETACH` et `DROP`, pas `DELETE` : pas de lignes mortes, pas de vacuum.
- Une partition par défaut attrape les égarées, et oblige l'ajout de partitions à la parcourir.
- Charger à part, ajouter une contrainte `CHECK` correspondante, puis `ATTACH` : le motif du `SWITCH` de SQL Server.
- Les partitions par hachage répartissent des clés, pas des lignes.

## Exercices

Les solutions sont dans [`sql/09-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql).

1. Partitionne une copie de `ci.runs` par workflow : une partition pour `Deploy to GitHub Pages`, une pour les trois workflows d'exemples des cours, et une partition par défaut. Combien d'exécutions chacune contient-elle, et quelles partitions une requête sur `Rust course examples` lit-elle ?

<details>
<summary>Solution</summary>

[Lignes 8-19](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L8-L19) :

```sql
-- Exercice 1 : les exécutions partitionnées par workflow, avec une partition pour les déploiements et une par défaut pour le reste,
-- et un plan qui ne lit que la partition de 'Rust course examples'
CREATE TABLE ci.runs_by_workflow (LIKE ci.runs) PARTITION BY LIST (workflow_name);
CREATE TABLE ci.runs_deploy PARTITION OF ci.runs_by_workflow FOR VALUES IN ('Deploy to GitHub Pages');
CREATE TABLE ci.runs_examples PARTITION OF ci.runs_by_workflow
    FOR VALUES IN ('Rust course examples', 'Java course examples', 'WSL containers examples');
CREATE TABLE ci.runs_other PARTITION OF ci.runs_by_workflow DEFAULT;
INSERT INTO ci.runs_by_workflow SELECT * FROM ci.runs;
SELECT tableoid::regclass AS partition, count(*) AS runs FROM ci.runs_by_workflow GROUP BY tableoid ORDER BY tableoid::regclass::text;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.runs_by_workflow WHERE workflow_name = 'Rust course examples'
$$);
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 125
    partition     | runs
------------------+------
 ci.runs_deploy   |   65
 ci.runs_examples |   27
 ci.runs_other    |   33
(3 rows)

                                  QUERY PLAN
------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=1
   ->  Seq Scan on runs_examples runs_by_workflow (actual rows=18.00 loops=1)
         Filter: (workflow_name = 'Rust course examples'::text)
         Rows Removed by Filter: 9
         Buffers: shared hit+read=1
(6 rows)
```

`LIKE ci.runs` copie les colonnes et leurs contraintes `NOT NULL`, pas la clé primaire. L'élagage garde `runs_examples`, la partition dont la liste contient la valeur ; la partition par défaut est écartée elle aussi, puisque la valeur est dans la liste d'une autre partition.

</details>

2. Partitionne les étapes de septembre sur deux niveaux : par mois, puis, à l'intérieur du mois, par conclusion. Montre l'arbre avec [`pg_partition_tree`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-INFO-PARTITION), et le plan d'une requête sur les échecs depuis le 14 septembre.

<details>
<summary>Solution</summary>

[Lignes 21-31](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L21-L31) :

```sql
-- Exercice 2 : deux niveaux, les mois puis la conclusion, et l'arbre que renvoie pg_partition_tree
CREATE TABLE ci.step_months (LIKE ci.step_history) PARTITION BY RANGE (started_at);
CREATE TABLE ci.step_months_2026_09 PARTITION OF ci.step_months
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01') PARTITION BY LIST (conclusion);
CREATE TABLE ci.step_months_2026_09_success PARTITION OF ci.step_months_2026_09 FOR VALUES IN ('success');
CREATE TABLE ci.step_months_2026_09_other PARTITION OF ci.step_months_2026_09 DEFAULT;
INSERT INTO ci.step_months SELECT * FROM ci.step_history WHERE started_at >= '2026-09-01';
SELECT relid, parentrelid, isleaf, level FROM pg_partition_tree('ci.step_months') ORDER BY level, relid::text;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_months WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 30185
             relid              |      parentrelid       | isleaf | level
--------------------------------+------------------------+--------+-------
 ci.step_months                 |                        | f      |     0
 ci.step_months_2026_09         | ci.step_months         | f      |     1
 ci.step_months_2026_09_other   | ci.step_months_2026_09 | t      |     2
 ci.step_months_2026_09_success | ci.step_months_2026_09 | t      |     2
(4 rows)

                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=36
   ->  Seq Scan on step_months_2026_09_other step_months (actual rows=15.00 loops=1)
         Filter: ((started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone) AND ((conclusion)::text = 'failure'::text))
         Rows Removed by Filter: 1512
         Buffers: shared hit+read=36
(6 rows)
```

Une partition déclarée avec son propre `PARTITION BY` est elle-même partitionnée : le niveau 1 n'a pas de lignes non plus. Les deux conditions élaguent, une par niveau, et la requête ne lit que la partition `other` de septembre.

</details>

3. Écris une procédure qui détache et supprime les partitions mensuelles d'une table qui se terminent au plus tard à une date donnée, et utilise-la pour garder juin à septembre.

<details>
<summary>Solution</summary>

[Lignes 33-63](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L33-L63) :

```sql
-- Exercice 3 : une procédure qui détache et supprime les partitions mensuelles qui se terminent avant une date
CREATE TABLE ci.step_log (LIKE ci.step_history) PARTITION BY RANGE (started_at);
SELECT format('CREATE TABLE ci.step_log_%s PARTITION OF ci.step_log FOR VALUES FROM (%L) TO (%L)',
              to_char(m, 'YYYY_MM'), m, m + interval '1 month')
FROM generate_series(timestamptz '2026-02-01', '2026-09-01', interval '1 month') AS m
ORDER BY m
\gexec

CREATE PROCEDURE ci.drop_partitions_before(parent regclass, cutoff timestamptz)
LANGUAGE plpgsql AS $$
DECLARE
    part regclass;
BEGIN
    FOR part IN
        SELECT c.oid::regclass
        FROM pg_inherits AS i JOIN pg_class AS c ON c.oid = i.inhrelid
        -- la borne supérieure, relue dans la définition de la partition : FOR VALUES FROM ('…') TO ('…')
        WHERE i.inhparent = parent
          AND substring(pg_get_expr(c.relpartbound, c.oid) FROM $re$TO \('([^']+)'\)$re$)::timestamptz <= cutoff
        ORDER BY c.relname
    LOOP
        -- le nom d'abord : une fois la table supprimée, son regclass s'affiche comme un simple OID
        RAISE NOTICE 'dropping %', part;
        EXECUTE format('ALTER TABLE %s DETACH PARTITION %s', parent, part);
        EXECUTE format('DROP TABLE %s', part);
    END LOOP;
END
$$;

CALL ci.drop_partitions_before('ci.step_log', '2026-06-01');
SELECT relid FROM pg_partition_tree('ci.step_log') WHERE isleaf ORDER BY relid::text;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE PROCEDURE
NOTICE:  dropping ci.step_log_2026_02
NOTICE:  dropping ci.step_log_2026_03
NOTICE:  dropping ci.step_log_2026_04
NOTICE:  dropping ci.step_log_2026_05
CALL
        relid
---------------------
 ci.step_log_2026_06
 ci.step_log_2026_07
 ci.step_log_2026_08
 ci.step_log_2026_09
(4 rows)
```

La borne supérieure revient du catalogue sous forme de texte, lue avec une expression régulière et convertie en `timestamptz`. Un `regclass` s'affiche comme un nom tant que la table existe ; après `DROP TABLE`, la même valeur s'affiche comme un nombre, c'est pourquoi la notice vient d'abord. C'est le travail que les réglages de rétention de pg_partman font selon un calendrier.

</details>

## Sources

- Documentation de PostgreSQL 18 : [partitionnement des tables](https://www.postgresql.org/docs/18/ddl-partitioning.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html), [`ALTER TABLE`](https://www.postgresql.org/docs/18/sql-altertable.html), [réglages de la planification des requêtes](https://www.postgresql.org/docs/18/runtime-config-query.html), [`psql`](https://www.postgresql.org/docs/18/app-psql.html), [`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html), [fonctions d'information système](https://www.postgresql.org/docs/18/functions-info.html), [fonctions d'information sur le partitionnement](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-INFO-PARTITION), [notes de version de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html)
- SQL Server : [tables et index partitionnés](https://learn.microsoft.com/sql/relational-databases/partitions/partitioned-tables-and-indexes), [`CREATE PARTITION FUNCTION`](https://learn.microsoft.com/sql/t-sql/statements/create-partition-function-transact-sql), [`ALTER TABLE … SWITCH`](https://learn.microsoft.com/sql/t-sql/statements/alter-table-transact-sql)
- AWS : [versions des extensions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [pg_partman sur Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_Partitions.html), [quotas et limites](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html), [considérations blue/green](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html), [intégrations zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html), toutes lues le 2026-09-16
- [pg_partman](https://github.com/pgpartman/pg_partman), [pg_cron](https://github.com/citusdata/pg_cron)
