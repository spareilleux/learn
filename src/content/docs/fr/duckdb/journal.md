---
title: Journal
description: Notes de progression datées — données, exécutions de CI, surprises et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Instantané des données : 125 exécutions et 315 jobs de ce dépôt
- [x] CI : le SQL de chaque leçon comparé à sa sortie attendue sur trois OS
- [x] Leçon 1 : premières requêtes
- [x] Leçon 2 : Friendly SQL
- [x] Leçon 3 : données imbriquées
- [x] Leçon 4 : fichiers
- [x] Leçon 5 : DuckDB depuis C#
- [x] Leçon 6 : DuckDB depuis Java
- [x] Leçon 7 : performances
- [x] Leçon 8 : persistance, transactions et concurrence

## 2026-09-14 — Les données

- `runs.json` : `gh run list --limit 1000 --json databaseId,workflowName,event,status,conclusion,createdAt,updatedAt,startedAt,headBranch,headSha,attempt`, exporté vers 14:04 UTC. 125 exécutions, la plus ancienne du 2026-09-13 à 15:53.
- `jobs.json` : un appel par exécution à `repos/spareilleux/learn/actions/runs/{id}/jobs?per_page=100`, en gardant 11 champs de chaque job et 5 de chaque step. 315 jobs pour 121 exécutions : 4 exécutions n'ont jamais eu de job.
- L'endpoint des jobs ne renvoie que la dernière tentative : 4 jobs pour l'exécution tentée trois fois, 12 avec `?filter=all`. Remarqué en écrivant la leçon 3 ; l'instantané reste tel quel.

## 2026-09-14 — Installer DuckDB

- En local, `winget` avait installé DuckDB 1.5.3 (`DuckDB.cli`), avec la 1.5.5 disponible. Le cours utilise la 1.5.5, décompressée depuis la release GitHub.
- CI sous Linux et macOS : `curl -fsSL https://install.duckdb.org | sh` → `Successfully installed DuckDB 1.5.5 to /home/runner/.duckdb/cli/1.5.5/duckdb`. Le script lit `DUCKDB_VERSION` dans l'environnement, que le workflow définit, donc la version est épinglée.
- CI sous Windows : le script ne le prend pas en charge ; le workflow télécharge `duckdb_cli-windows-amd64.zip` et ajoute le dossier à `GITHUB_PATH`.
- `check.sh` exécute chaque script avec `duckdb -csv <` et fait un diff avec `sql/expected/`. Chaque OS met une à deux secondes pour tous les scripts des leçons 1-4, requête HTTPS comprise.

## 2026-09-14 — Surprises en écrivant les leçons 1-4

- L'`approx_unique` de `SUMMARIZE` valait 131 pour 125 identifiants d'exécution uniques, et 17 pour 21 noms de workflow.
- La CLI utilise le fuseau horaire de l'OS pour afficher les `TIMESTAMPTZ` (`America/…` en local, UTC sur les runners) : le script de la leçon 2 définit `TimeZone` explicitement.
- `sum(INTERVAL)` n'existe pas, `avg(INTERVAL)` si.
- `labels[0]` renvoie `NULL` sans erreur.
- La flèche de lambda `x -> …` affiche un avertissement de dépréciation en 1.5.5 ; les leçons utilisent `lambda x: …`.
- Un job ignoré a `runner_name` à `NULL` ; le job de déploiement rejeté par la politique de branches de l'environnement a `''`.
- Le détecteur de format CSV (sniffer) lit silencieusement `13/09/2026 15:53` comme du `VARCHAR`, et un mauvais `timestampformat` aussi. Seul un type explicite le fait échouer.
- `FROM 'data/*.json'` fusionne les exécutions et les jobs en une seule table de 20 colonnes, sans avertissement.
- Premier push du script de la leçon 4 : échec sur `macos-latest` uniquement. Le `total_compressed_size` Parquet de 8 blocs de colonnes (column chunks) différait de 1 à 6 octets de celui de Linux et de Windows. Le script compare désormais `num_values` à la place.
- `COPY` vers un fichier existant l'écrase ; `COPY … PARTITION_BY` vers un dossier non vide échoue sans `OVERWRITE`.

## 2026-09-14 — Surprises en écrivant les leçons 5-6

- `DuckDB.NET.Data.Full` 1.5.5 pèse 420 Mo dans le cache NuGet, 316 Mo dans `bin/Debug`, 69 Mo une fois publié pour `linux-x64` seulement. Le jar JDBC pèse 85 Mo, avec quatre bibliothèques natives et aucune build Windows on Arm.
- DuckDB.NET associe un `STRUCT` à une classe par nom de propriété, sans tenir compte de la casse mais en tenant compte des underscores : `StartedAt` reste silencieusement à sa valeur par défaut, `Started_At` est rempli. Un record positionnel lève `MissingMethodException`.
- `TIMESTAMPTZ` revient sous forme de `DateTime` contenant la valeur UTC avec `Kind` `Unspecified`, donc `ToUniversalTime` la décale une seconde fois. En Java, c'est un `OffsetDateTime` dans le fuseau par défaut de la JVM, quoi que dise `SET TimeZone`.
- `(long)` et `Convert.ToInt64` lèvent tous deux une exception sur le `BigInteger` d'un `HUGEINT` ; `(long)(BigInteger)value` fonctionne.
- Avec JDBC, un `Statement` est fermé après une requête en échec : une boucle qui attrape l'erreur et continue fait échouer toutes les instructions suivantes avec `Statement was closed`.
- Le JDK 25 affiche quatre avertissements d'accès natif au chargement du driver, sauf avec `--enable-native-access=ALL-UNNAMED` ; le lanceur de Maven le passe déjà.
- Temps dans la CI, non comparés : l'appender C# a chargé 1 000 000 de lignes en 226 à 331 ms et 10 000 instructions `INSERT` isolées ont pris 1,3 à 3,9 s ; en Java, un batch JDBC n'était pas plus rapide que des instructions isolées (690 ms à 2,4 s pour 10 000 lignes).
- Les chemins relatifs dans le SQL sont relatifs au répertoire de travail du processus, pas au projet : les deux programmes s'exécutent depuis `code/duckdb`.

## 2026-09-14 — Surprises en écrivant les leçons 7-8

- La sortie de `EXPLAIN` ne dépend pas du nombre de threads, et les estimations étaient les mêmes sur les trois runners : la CI peut donc comparer les plans.
- Le writer Parquet utilise plusieurs threads, et la taille du même fichier de 11 millions de lignes a changé d'une exécution à l'autre : 119 021 205 puis 119 392 814 octets en local, de 118 714 412 à 119 120 557 octets sur les runners.
- L'optimiseur réécrit `started_at::DATE = …` et `date_trunc('day', started_at) = …` en un intervalle qui saute des row groups ; `strftime(started_at, …) = …` reste une expression et lit toutes les lignes : 0,47 s contre 0,003 s sur le fichier trié.
- Les téléchargements du Parquet distant étaient identiques à l'octet près sur les quatre machines, et correspondent exactement aux métadonnées : les trois blocs `trip_distance` pour la moyenne, le row group 0 à partir de l'octet 4 pour `SELECT * … LIMIT 1`.
- Un tri de 11 millions de lignes avec `memory_limit = '100MB'` échoue avec 4 threads et réussit avec 1 (6,3 à 9,9 s). Le `COPY` en échec a laissé un fichier partiel derrière lui.
- `COMMIT` après une erreur dans une transaction n'affiche aucune erreur et annule tout, dans le CLI comme en JDBC. Les chaînes de plusieurs instructions ne sont pas atomiques non plus : `-c "a; b; c"` et `statement.execute("a; b; c")` ont gardé les deux premières lignes quand la troisième a échoué, alors que la page sur les transactions décrit une transaction implicite.
- Un conflit d'écriture échoue au second `UPDATE`, une clé en double entre deux transactions seulement au second commit.
- Un processus qui tient un fichier de base de données bloque tous les autres processus, y compris ceux en lecture seule, avec un message différent sur chaque OS. Les fichiers écrits par DuckDB 1.5.5 portent l'étiquette `storage_version=v1.0.0+` et ont été lus par le CLI de DuckDB 1.0.0 ; avec `STORAGE_VERSION 'v1.5.0'`, la 1.0.0 les a refusés (numéro de version 68, ne sait lire que 64).
- La CI exécute aussi `timings/07-performance.sql` (non comparé : 17 s sous Ubuntu, 32 s sous Windows, avec un fichier CSV de 1 Go) et `shell/08-*.sh`.

## À vérifier

- Pourquoi le step numéro 4 manque dans les jobs de `Deploy to GitHub Pages` (step `withastro/action`) : un step interne de l'action composite ?
- Le chemin d'installation des extensions sous Linux et macOS (`~/.duckdb/extensions/v1.5.5/<platform>/`), déduit de celui de Windows.
- Les commandes Linux et macOS pour lancer le programme Java sans Maven (leçon 6).
- Les conflits d'écriture et les connexions en lecture seule avec DuckDB.NET (leçon 8) : testés avec JDBC seulement.
- Ouvrir, écrire et fermer un fichier de base de données depuis plusieurs processus sous charge (leçon 8, exercice 3).
- Le protocole distant Quack et DuckLake, pour plusieurs processus qui écrivent : mentionnés, pas essayés.
