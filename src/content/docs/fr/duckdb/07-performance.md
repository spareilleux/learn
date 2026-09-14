---
title: 7. Performance
description: Lire un plan de requête DuckDB, projection pushdown et filter pushdown, les row groups Parquet et pourquoi le tri compte, l'élagage des partitions, les threads, les octets que télécharge une requête sur un Parquet distant, les limites de mémoire et le débordement sur disque, et quand DuckDB n'est pas le bon outil.
sidebar:
  order: 7
---

Dans SQL Server, tu lis un [plan d'exécution](https://learn.microsoft.com/sql/relational-databases/performance/execution-plans) pour voir pourquoi une requête est lente, et c'est un [index columnstore](https://learn.microsoft.com/sql/relational-databases/indexes/columnstore-indexes-overview) qui rend les parcours analytiques rapides. DuckDB stocke tout en colonnes, et a aussi des plans. Cette leçon les lit, puis mesure ce qu'ils prédisent.

Deux scripts :

- [`sql/07-performance.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/07-performance.sql) montre des plans et des métadonnées Parquet. Sa sortie ne dépend pas de la machine, donc la CI la compare comme pour les autres leçons.
- [`timings/07-performance.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/timings/07-performance.sql) applique les mêmes idées à une table plus grande avec `.timer on`. La CI l'exécute sur les trois systèmes d'exploitation sans rien comparer ; les temps ci-dessous viennent de ses logs et de ma machine, un PC Windows 11 à 24 threads.

```bash
duckdb < timings/07-performance.sql
```

Il écrit environ 1,5 Go dans `out/` : un fichier CSV de 1 Go et plusieurs fichiers Parquet. Supprime-les ensuite.

## Une table plus grande

315 jobs ne suffisent pas pour mesurer quoi que ce soit. Le script répète chaque step de chaque job, en décalant les horodatages d'un jour par copie :

```sql
CREATE TABLE steps AS
SELECT j.id AS job_id, j.labels[1] AS os, s.number, s.name, s.conclusion,
       s.started_at + to_days(d.i) AS started_at, s.completed_at + to_days(d.i) AS completed_at
FROM jobs j, unnest(j.steps) AS t(s), range(500) AS d(i);
SELECT count(*) AS steps, min(started_at) AS first_step, max(started_at) AS last_step FROM steps;
```

```text
┌─────────┬─────────────────────┬─────────────────────┐
│  steps  │     first_step      │      last_step      │
│  int64  │      timestamp      │      timestamp      │
├─────────┼─────────────────────┼─────────────────────┤
│ 1102000 │ 2026-09-13 15:53:20 │ 2028-01-26 14:03:35 │
└─────────┴─────────────────────┴─────────────────────┘
```

`range(500)` est une fonction table qui renvoie les nombres de 0 à 499 ; la virgule la joint à chaque step. Le script de mesure utilise `range(5000)` : 11 020 000 steps, créés en 1,1 s sur ma machine et entre 2,0 s (runner Ubuntu) et 4,0 s (runner Windows) dans la CI.

## Lire un plan

[`EXPLAIN`](https://duckdb.org/docs/current/guides/meta/explain) montre le plan physique sans exécuter la requête. Ici, une requête sur le fichier JSON :

```sql
EXPLAIN SELECT conclusion, count(*) FROM 'data/jobs.json' GROUP BY ALL;
```

```text
┌─────────────────────────────┐
│┌───────────────────────────┐│
││       Physical Plan       ││
│└───────────────────────────┘│
└─────────────────────────────┘
┌───────────────────────────┐
│       HASH_GROUP_BY       │
│    ────────────────────   │
│         Groups: #0        │
│                           │
│        Aggregates:        │
│        count_star()       │
│                           │
│         ~199 rows         │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         PROJECTION        │
│    ────────────────────   │
│         conclusion        │
│                           │
│         ~315 rows         │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│       READ_JSON_AUTO      │
│    ────────────────────   │
│         Function:         │
│       READ_JSON_AUTO      │
│                           │
│        Projections:       │
│         conclusion        │
│                           │
│         ~315 rows         │
└───────────────────────────┘
```

Lis-le de bas en haut, comme un plan SQL Server se lit de droite à gauche : le parcours produit des lignes pour l'opérateur au-dessus de lui. Les nombres précédés de `~` sont les estimations de l'optimiseur ; `#0` est la première colonne de l'opérateur du dessous. L'estimation pour les groupes, 199, est loin des quatre conclusions réelles : ça ne compte pas beaucoup ici, mais quand une jointure est lente, une mauvaise estimation est la première chose à chercher.

La ligne à remarquer est `Projections: conclusion`. Les jobs ont 11 champs, dont le tableau `steps` ; le lecteur ne construit que la seule colonne que la requête utilise. C'est la **projection pushdown** : la sélection des colonnes est poussée jusque dans la lecture. Avec JSON, le lecteur doit quand même analyser tout le texte pour trouver ce champ. Avec Parquet, il ne lit même pas les autres colonnes.

`EXPLAIN ANALYZE` exécute la requête et ajoute le nombre réel de lignes et le temps passé dans chaque opérateur. La [documentation sur le profilage](https://duckdb.org/docs/current/dev/profiling) liste les autres sorties, comme JSON.

## Filter pushdown et row groups

Le script écrit les steps deux fois : `out/steps.parquet` dans l'ordre d'insertion, `out/steps-sorted.parquet` trié par heure de début.

```sql
COPY steps TO 'out/steps.parquet';
COPY (FROM steps ORDER BY started_at) TO 'out/steps-sorted.parquet';

EXPLAIN
SELECT name, avg(completed_at - started_at) AS took
FROM 'out/steps.parquet'
WHERE started_at < '2026-09-20'
GROUP BY ALL;
```

```text
┌─────────────┴─────────────┐
│        PARQUET_SCAN       │
│    ────────────────────   │
│         Function:         │
│        PARQUET_SCAN       │
│                           │
│        Projections:       │
│         started_at        │
│            name           │
│        completed_at       │
│                           │
│          Filters:         │
│ started_at<'2026-09-20 00 │
│     :00:00'::TIMESTAMP    │
│                           │
│       ~220,400 rows       │
└───────────────────────────┘
```

Trois colonnes sur sept, et une section `Filters:` : la clause `WHERE` est passée dans le parcours. C'est le **filter pushdown**, le filtre poussé jusque dans la lecture, et sur Parquet il fait plus qu'économiser un opérateur de filtre.

Un [fichier Parquet](https://parquet.apache.org/docs/file-format/) est découpé en **row groups** ; DuckDB en écrit un toutes les 122 880 lignes. Pour chaque colonne de chaque row group, le pied du fichier stocke la valeur minimale et la valeur maximale. Avant de lire un row group, le parcours compare le filtre à ces statistiques, et saute le row group si aucune ligne ne peut correspondre. [`parquet_metadata`](https://duckdb.org/docs/current/data/parquet/metadata) les montre :

```sql
SELECT replace(file_name, '\', '/') AS file, count(*) AS row_groups, sum(row_group_num_rows) AS rows,
       count(*) FILTER (stats_min::TIMESTAMP < '2026-09-20') AS row_groups_to_read
FROM parquet_metadata(['out/steps.parquet', 'out/steps-sorted.parquet'])
WHERE path_in_schema = 'started_at'
GROUP BY ALL
ORDER BY file;
```

```text
┌──────────────────────────┬────────────┬─────────┬────────────────────┐
│           file           │ row_groups │  rows   │ row_groups_to_read │
│         varchar          │   int64    │ int128  │       int64        │
├──────────────────────────┼────────────┼─────────┼────────────────────┤
│ out/steps-sorted.parquet │          9 │ 1102000 │                  1 │
│ out/steps.parquet        │          9 │ 1102000 │                  9 │
└──────────────────────────┴────────────┴─────────┴────────────────────┘
```

Mêmes lignes, même réponse (13 895 steps pour les deux fichiers), mais pas le même travail. Dans l'ordre d'insertion, chaque row group mélange des steps de toute la période, donc chaque minimum tombe dans la première semaine et aucun row group ne peut être sauté. Trié, seul le premier row group commence avant le 2026-09-20.

Le plan est le même pour les deux fichiers : `EXPLAIN` montre que le filtre atteint le parcours, pas combien de row groups il sautera. Les temps le montrent. Un thread, un jour de 2030, sur les fichiers de 11 millions de lignes :

| Un jour, un thread | Ma machine | Runner Ubuntu | Runner Windows | Runner macOS |
|---|---|---|---|---|
| Parquet non trié | 0,052 s | 0,061 s | 0,098 s | 0,059 s |
| Parquet trié | 0,003 s | 0,003 s | 0,007 s | 0,007 s |

`EXPLAIN ANALYZE` sur le fichier trié confirme que le parcours n'a produit que les lignes correspondantes, à partir d'un seul fichier :

```text
┌─────────────┴─────────────┐
│         TABLE_SCAN        │
│    ────────────────────   │
│         Function:         │
│        PARQUET_SCAN       │
│                           │
│     Projections: name     │
│                           │
│          Filters:         │
│ started_at>='2030-01-01 00│
│   :00:00'::TIMESTAMP AND  │
│   started_at<='2030-01-02 │
│    00:00:00'::TIMESTAMP   │
│                           │
│    Total Files Read: 1    │
│                           │
│        Filename(s):       │
│    out/steps-big-sorted   │
│          .parquet         │
│                           │
│                           │
│                           │
│         2,204 rows        │
│           0.01s           │
└───────────────────────────┘
```

Les tables de DuckDB lui-même fonctionnent de la même façon : le [guide sur l'indexation](https://duckdb.org/docs/current/guides/performance/indexing) appelle ces statistiques par row group des *zonemaps*, et dit que « plus les données d'une colonne sont ordonnées, plus les index zonemap ont de la valeur ». Si une colonne est souvent filtrée, trie par elle quand tu écris le fichier. Le tri compresse aussi mieux : le fichier trié de 11 millions de lignes faisait 106 Mo contre 119 Mo sur ma machine.

:::note[Les tailles de fichiers changent d'une exécution à l'autre]
Le writer Parquet utilise plusieurs threads, et les tailles ont varié de quelques centaines de kilo-octets entre deux exécutions sur la même machine, et de quelques mégaoctets entre machines : le fichier trié faisait 102 Mo sur les trois runners. C'est pourquoi le script comparé montre des nombres de lignes et des statistiques, jamais des tailles compressées.
:::

## Élagage des partitions

La leçon 4 disait qu'un filtre sur une colonne de partition saute des fichiers entiers. `EXPLAIN` le montre sans rien exécuter :

```sql
EXPLAIN SELECT count(*) FROM read_parquet('out/jobs-by-os/*/*.parquet') WHERE os = 'windows-latest';
```

```text
┌─────────────┴─────────────┐
│        READ_PARQUET       │
│    ────────────────────   │
│         Function:         │
│        READ_PARQUET       │
│                           │
│       File Filters:       │
│  (os = 'windows-latest')  │
│                           │
│    Scanning Files: 1/3    │
│                           │
│          ~34 rows         │
└───────────────────────────┘
```

Les `File Filters` sont décidés à partir des seuls noms de dossiers : les deux autres fichiers ne sont pas ouverts. Le [partitionnement Hive](https://duckdb.org/docs/current/data/partitioning/hive_partitioning) est aux fichiers ce que les statistiques des row groups sont aux lignes.

## Table, Parquet ou CSV

Le même agrégat, le step le plus lent en moyenne, sur les 11 millions de steps stockés de trois façons, avec tous les threads :

```sql
SELECT os, name, avg(completed_at - started_at) AS took FROM steps GROUP BY ALL ORDER BY took DESC LIMIT 1;
```

| Source | Ma machine (24 threads) | Ubuntu (4) | Windows (4) | macOS (3) |
|---|---|---|---|---|
| table `steps` en mémoire | 0,042 s | 0,263 s | 0,420 s | 0,289 s |
| `out/steps-big.parquet`, 119 Mo | 0,048 s | 0,237 s | 0,553 s | 0,415 s |
| `out/steps-big.csv`, 1,09 Go | 0,416 s | 1,676 s | 2,709 s | 2,403 s |
| filtre sur une semaine, Parquet | 0,009 s | 0,025 s | 0,034 s | 0,026 s |
| filtre sur une semaine, CSV | 0,383 s | 1,064 s | 1,698 s | 1,117 s |

Chaque requête a renvoyé la même ligne : `Lesson 10 builds` sur `windows-latest`, 2 min 24,75 s. Parquet est aussi rapide qu'une table en mémoire, parce que DuckDB ne lit que trois colonnes et les décode en bloc. CSV est 5 à 9 fois plus lent que Parquet sur l'agrégat : chaque valeur est du texte à analyser, et il n'y a pas de statistiques, donc le filtre sur la semaine lit tout le gigaoctet. L'écriture a pris 0,41 s pour Parquet et 0,50 s pour CSV sur ma machine. Si un fichier CSV est interrogé plus d'une fois, convertis-le d'abord.

## Threads

DuckDB exécute une requête sur autant de threads que la machine a de cœurs : le [réglage `threads`](https://duckdb.org/docs/current/configuration/overview) vaut par défaut le nombre de cœurs du CPU. Les runners en ont montré 4, 4 et 3. L'agrégat sur la table, avec `SET threads = 1` :

| Agrégat sur la table | Ma machine | Ubuntu | Windows | macOS |
|---|---|---|---|---|
| tous les threads | 0,042 s | 0,263 s | 0,420 s | 0,289 s |
| `SET threads = 1` | 0,530 s | 0,632 s | 1,089 s | 1,120 s |

12,6 fois plus rapide avec 24 threads, 2,4 à 3,9 fois avec 3 ou 4. Les parcours et les agrégats par hachage se répartissent bien entre threads. Le revers : une requête DuckDB dans un serveur web prend tous les cœurs par défaut, et plusieurs requêtes simultanées se les disputent. Règle `threads` quand DuckDB partage la machine.

## Un fichier Parquet distant

La leçon 4 lisait du Parquet via HTTPS et affirmait que DuckDB ne télécharge que ce dont il a besoin. Le [log HTTP](https://duckdb.org/docs/current/operations_manual/logging/overview) le prouve, sur janvier 2024 des [courses de taxi de New York](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), un fichier de 49 961 641 octets :

```sql
CALL enable_logging('HTTP', storage = 'memory');
SELECT count(*) FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet';
SELECT count(*) AS requests, sum(response.headers['Content-Length']::BIGINT) AS bytes FROM duckdb_logs_parsed('HTTP') WHERE request.type = 'GET';
CALL truncate_duckdb_logs();
```

Activer le log affiche un avertissement dans la CLI, parce que le log collecte désormais aussi les avertissements :

```text
WARNING:
The logging settings have been changed so you may lose warnings printed in the CLI.
To continue printing warnings to the console, set storage='shell_log_storage'.
```

Le script répète le comptage pour deux autres requêtes. Les téléchargements étaient les mêmes sur ma machine et sur les trois runners :

| Requête | Résultat | Requêtes `GET` | Octets téléchargés | Temps, ma machine |
|---|---|---|---|---|
| `count(*)` | 2 964 624 | 1 | 65 536 | 0,25 s |
| `avg(trip_distance)` | 3.6521691789583146 | 3 | 4 082 947 | 0,63 s |
| `SELECT * … LIMIT 1` | une course | 1 | 17 612 330 | 1,64 s |

Chaque requête commence par une requête `HEAD` pour obtenir la taille du fichier. La première télécharge ensuite la fin du fichier, où se trouve le pied, et n'a besoin de rien d'autre : les nombres de lignes sont dans le pied. La moyenne lit une colonne, le `LIMIT 1` lit toutes les colonnes d'un row group. L'exercice 3 fait correspondre ces nombres avec les métadonnées.

Sur un réseau, la disposition des colonnes compte plus que sur un disque : `SELECT *` sur un fichier distant est la requête coûteuse, même avec `LIMIT 1`.

## Mémoire et débordement sur disque

Par défaut, DuckDB peut utiliser 80 % de la RAM (`memory_limit`). Quand un tri, une jointure, un `GROUP BY` ou une fonction de fenêtrage a besoin de plus, le [guide de réglage](https://duckdb.org/docs/current/guides/performance/how_to_tune_workloads) dit qu'il déborde dans des fichiers temporaires, dans `temp_directory` : `.tmp` à côté du processus pour une base de données en mémoire, `<file>.tmp` à côté d'un fichier de base de données. Le script de mesure trie les 11 millions de steps du fichier Parquet sous deux limites :

```sql
SET temp_directory = 'out/tmp';
SET memory_limit = '500MB';
COPY (FROM 'out/steps-big.parquet' ORDER BY started_at) TO 'out/steps-big-sorted-500mb.parquet';
SET memory_limit = '100MB';
SET threads = 1;
COPY (FROM 'out/steps-big.parquet' ORDER BY started_at) TO 'out/steps-big-sorted-100mb.parquet';
```

| Tri de 11 millions de lignes | Ma machine | Ubuntu | Windows | macOS |
|---|---|---|---|---|
| 500 Mo, tous les threads | 2,21 s | 2,91 s | 4,62 s | 4,92 s |
| 100 Mo, un thread | 6,34 s | 6,96 s | 9,89 s | 7,94 s |

Sur ma machine, le même tri a pris 1,37 s avec 1 Go. Avec 100 Mo et quatre threads, il a échoué :

```text
Out of Memory Error: failed to pin block of size 256.0 KiB (95.4 MiB/95.3 MiB used)

Possible solutions:
* Reducing the number of threads (SET threads=X)
* Disabling insertion-order preservation (SET preserve_insertion_order=false)
* Increasing the memory limit (SET memory_limit='...GB')
```

Les threads travaillent en parallèle, chacun sur sa propre partie des données, donc moins de threads ont besoin de moins de mémoire en même temps : c'est la première suggestion, et c'est pourquoi le script règle un seul thread. Le `COPY` en échec a aussi laissé un fichier derrière lui : 1,1 Mo lors d'une exécution ; vide lors d'une autre, où la requête suivante a échoué avec `File 'out/steps-big-sorted-100mb.parquet' too small to be a Parquet file`. Vérifie qu'un `COPY` a réussi avant d'utiliser son fichier.

Deux pièges rencontrés en chemin. Abaisser la limite en dessous de ce qui est déjà utilisé échoue : dans une session qui contenait la table de 11 millions de lignes, `SET memory_limit = '10MB'` a répondu `Failed to change memory limit to 10000000: could not free up enough memory for the new limit`. Et une table dans une base de données en mémoire compte aussi dans la limite : après `SET memory_limit = '100MB'` dans cette session, les requêtes échouaient avec `failed to pin block`. C'est pourquoi le script supprime d'abord la table.

## Quand DuckDB n'est pas le bon outil

DuckDB est [conçu pour les requêtes analytiques](https://duckdb.org/why_duckdb) : quelques gros parcours, agrégats et jointures. Ce que ce cours a mesuré, et ce que dit la documentation, oriente vers d'autres outils pour :

- **De nombreuses petites transactions.** Un `INSERT` par ligne a pris de 0,07 à 0,4 ms dans la CI des leçons 5 et 6, là où l'appender chargeait un million de lignes en 0,2 à 0,5 s. Un système de saisie de commandes a sa place dans SQL Server ou PostgreSQL.
- **Plusieurs processus qui écrivent dans la même base de données.** Un processus peut lire et écrire un fichier de base de données ; [plusieurs processus ne peuvent que le lire](https://duckdb.org/docs/current/connect/concurrency). La leçon 8 l'essaie.
- **Un serveur partagé par de nombreux utilisateurs.** DuckDB vit dans ton processus ; il n'y a ni serveur, ni utilisateurs, ni permissions à gérer.
- **Un fichier de base de données sur un partage réseau.** La [FAQ](https://duckdb.org/faq) déconseille fortement les charges en lecture-écriture sur un stockage réseau.

Pour lire des fichiers, un historique de CI, un export de données ou un notebook, il a la bonne taille.

## À retenir

- `EXPLAIN` montre le plan ; lis-le de bas en haut. `EXPLAIN ANALYZE` exécute la requête et ajoute les lignes et les temps réels.
- `Projections:` dans un parcours est la liste des colonnes réellement lues ; `Filters:` est la partie de la clause `WHERE` poussée dans le parcours.
- Les row groups Parquet portent des statistiques min/max par colonne. Un filtre ne saute des row groups que si les données sont ordonnées sur cette colonne : trie les fichiers par la colonne sur laquelle tu filtres.
- Les dossiers de partition sont sautés avant l'ouverture de tout fichier (`Scanning Files: 1/3`).
- Parquet est à peu près aussi rapide qu'une table en mémoire, et 5 à 9 fois plus rapide que CSV pour ces requêtes.
- DuckDB utilise tous les cœurs par défaut ; règle `threads` quand il partage une machine.
- Une requête sur un Parquet distant télécharge le pied et les blocs de colonnes dont elle a besoin ; `SELECT *` télécharge des row groups entiers.
- Avec une limite de mémoire, les tris, les jointures et les agrégats débordent dans `temp_directory` ; chaque thread a besoin de mémoire, donc réduis `threads` pour les petites limites.

## Exercices

Les solutions sont dans [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/07-exercises.sql) ; leurs temps sont dans le script de mesure.

1. Quatre façons de garder les steps du 2030-01-01, sur le fichier trié. Lesquelles peuvent sauter des row groups ? `EXPLAIN` te le dit-il ?

```sql
WHERE started_at >= '2030-01-01' AND started_at < '2030-01-02'
WHERE started_at::DATE = '2030-01-01'
WHERE date_trunc('day', started_at) = '2030-01-01'
WHERE strftime(started_at, '%Y-%m-%d') = '2030-01-01'
```

<details>
<summary>Solution</summary>

`EXPLAIN` montre une section `Filters:` dans le parcours pour les quatre, donc il ne répond pas. Mais ce qu'il montre diffère. Sur le petit fichier, avec le 2026-09-14, le cast et `date_trunc` ont été réécrits en intervalle :

```text
│          Filters:         │
│ started_at>='2026-09-14 00│
│   :00:00'::TIMESTAMP AND  │
│  started_at<'2026-09-15 00│
│     :00:00'::TIMESTAMP    │
```

Le filtre `strftime` reste une expression, à laquelle aucune statistique min/max ne peut répondre :

```text
│          Filters:         │
│ (strftime(started_at, '%Y-│
│  %m-%d') = '2026-09-14')  │
```

Les temps concordent. Les quatre renvoient 2 204 steps ; avec un thread, l'intervalle, le cast et `date_trunc` ont pris de 0,002 à 0,005 s sur ma machine et sur les runners, alors que `strftime` a pris 0,467 s sur ma machine, et 0,60 s (Ubuntu), 0,96 s (macOS) et 1,12 s (Windows) dans la CI, parce qu'il formate 11 millions d'horodatages en texte. Dans SQL Server, envelopper une colonne dans une fonction rend le prédicat non sargable ; l'optimiseur de DuckDB défait certaines de ces enveloppes, pas toutes. Compare les colonnes à des valeurs de leur propre type.

</details>

2. Les steps sont filtrés par `os = 'windows-latest'`. Combien des 9 row groups faut-il lire dans `out/steps.parquet`, dans `out/steps-sorted.parquet`, et dans un fichier trié par `os, started_at` ?

<details>
<summary>Solution</summary>

Écris le troisième fichier, puis compare le filtre aux statistiques de `os` :

```sql
COPY (FROM steps ORDER BY os, started_at) TO 'out/steps-by-os.parquet';
SELECT replace(file_name, '\', '/') AS file, count(*) AS row_groups,
       count(*) FILTER (stats_min <= 'windows-latest' AND stats_max >= 'windows-latest') AS row_groups_to_read
FROM parquet_metadata(['out/steps.parquet', 'out/steps-sorted.parquet', 'out/steps-by-os.parquet'])
WHERE path_in_schema = 'os'
GROUP BY ALL
ORDER BY file;
```

```text
┌──────────────────────────┬────────────┬────────────────────┐
│           file           │ row_groups │ row_groups_to_read │
│         varchar          │   int64    │       int64        │
├──────────────────────────┼────────────┼────────────────────┤
│ out/steps-by-os.parquet  │          9 │                  2 │
│ out/steps-sorted.parquet │          9 │                  9 │
│ out/steps.parquet        │          9 │                  9 │
└──────────────────────────┴────────────┴────────────────────┘
```

Trier par heure aide les filtres sur l'heure et rien d'autre. Un fichier ne peut être bien trié que pour une seule colonne, ou pour une colonne de tête et, à l'intérieur de chaque valeur, la suivante. Pour une colonne avec peu de valeurs comme `os`, le partitionnement (un dossier par valeur) est une autre réponse.

</details>

3. Explique les octets téléchargés par les trois requêtes distantes (65 536, puis 4 082 947, puis 17 612 330) avec `parquet_metadata` sur la même URL.

<details>
<summary>Solution</summary>

```sql
SELECT row_group_id, max(row_group_num_rows) AS rows, sum(total_compressed_size) AS all_columns,
       sum(total_compressed_size) FILTER (path_in_schema = 'trip_distance') AS trip_distance
FROM parquet_metadata('https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet')
GROUP BY ALL
ORDER BY row_group_id;
```

```text
┌──────────────┬─────────┬─────────────┬───────────────┐
│ row_group_id │  rows   │ all_columns │ trip_distance │
│    int64     │  int64  │   int128    │    int128     │
├──────────────┼─────────┼─────────────┼───────────────┤
│            0 │ 1048576 │    17611010 │       1441439 │
│            1 │ 1048576 │    17522229 │       1451920 │
│            2 │  867472 │    14817869 │       1189588 │
└──────────────┴─────────┴─────────────┴───────────────┘
```

- `count(*)` : 65 536 octets, c'est une requête de plage de 64 Kio à la fin du fichier. Le pied y tient, et les nombres de lignes (1 048 576 + 1 048 576 + 867 472 = 2 964 624) sont dans le pied.
- `avg(trip_distance)` : 1 441 439 + 1 451 920 + 1 189 588 = 4 082 947, exactement les trois blocs de `trip_distance`, une requête par row group. Il n'y a pas eu de requête pour le pied : il était déjà dans le cache de fichiers distants de DuckDB (`enable_external_file_cache`, `true` par défaut), depuis la première requête de la session.
- `SELECT * … LIMIT 1` : toutes les colonnes du row group 0, 17 611 010 octets, plus 1 320 octets. Une requête de plage couvre des octets contigus : de l'octet 4, où le premier bloc commence après le nombre magique `PAR1`, jusqu'à la fin du dernier bloc. Dans les métadonnées, `dictionary_page_offset` et `total_compressed_size` donnent cette étendue, 17 612 330 octets ; les 1 320 octets sont les trous entre les blocs des 19 colonnes.

</details>

## Sources

- [`EXPLAIN`](https://duckdb.org/docs/current/guides/meta/explain), [`EXPLAIN ANALYZE`](https://duckdb.org/docs/current/guides/meta/explain_analyze) et [profilage](https://duckdb.org/docs/current/dev/profiling)
- [Guide des performances](https://duckdb.org/docs/current/guides/performance/overview) : [formats de fichiers](https://duckdb.org/docs/current/guides/performance/file_formats), [indexation](https://duckdb.org/docs/current/guides/performance/indexing), [réglage des charges de travail](https://duckdb.org/docs/current/guides/performance/how_to_tune_workloads)
- [Métadonnées Parquet](https://duckdb.org/docs/current/data/parquet/metadata) et [conseils Parquet](https://duckdb.org/docs/current/data/parquet/tips)
- [Format de fichier Apache Parquet](https://parquet.apache.org/docs/file-format/)
- [Réglages de configuration](https://duckdb.org/docs/current/configuration/overview) : `threads`, `memory_limit`, `temp_directory`
- [Journalisation](https://duckdb.org/docs/current/operations_manual/logging/overview)
- [Partitionnement Hive](https://duckdb.org/docs/current/data/partitioning/hive_partitioning)
- [Concurrence](https://duckdb.org/docs/current/connect/concurrency), [Pourquoi DuckDB](https://duckdb.org/why_duckdb) et la [FAQ](https://duckdb.org/faq)
- [TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), New York City Taxi and Limousine Commission
