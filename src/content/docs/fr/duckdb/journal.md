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
- [ ] Leçon 5 : DuckDB depuis C#
- [ ] Leçon 6 : DuckDB depuis Java
- [ ] Leçon 7 : performances
- [ ] Leçon 8 : persistance, transactions et concurrence

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

## À vérifier

- Pourquoi le step numéro 4 manque dans les jobs de `Deploy to GitHub Pages` (step `withastro/action`) : un step interne de l'action composite ?
- Le chemin d'installation des extensions sous Linux et macOS (`~/.duckdb/extensions/v1.5.5/<platform>/`), déduit de celui de Windows.
- Les requêtes de plage (range requests) lors de la lecture de Parquet en HTTPS (leçon 7).
- L'élagage des partitions (partition pruning) sur `WHERE os = 'windows-latest'` (leçon 7).
