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

## QA

DuckDB 1.5.5, son pilote .NET et son pilote JDBC sont le logiciel de quelqu'un d'autre. Deux lignes ci-dessous perdent des données sans le dire : c'est pourquoi la colonne État les sépare de celles qui décrivent un comportement documenté sur lequel une habitude C# ou Java vient buter. Rien n'a été signalé en amont.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| DuckDB.NET remplit une classe depuis un `STRUCT` par nom de propriété | Il ignore la casse mais pas les soulignés : `StartedAt` garde donc sa valeur par défaut sans rien dire, tandis que `Started_At` est rempli | DuckDB.NET 1.5.5 | Silencieux, aucune exception. Un record positionnel lève en revanche `MissingMethodException` | Reproduit, non signalé [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-5-6) |
| Un `TIMESTAMPTZ` survit à un aller-retour par le pilote | Il revient en `DateTime` portant la valeur UTC avec un `Kind` `Unspecified` : `ToUniversalTime` la décale donc une seconde fois. En Java, c'est un `OffsetDateTime` dans le fuseau de la JVM, quoi qu'ait dit `SET TimeZone` | DuckDB.NET 1.5.5, duckdb_jdbc 1.5.5.1 | Valeurs fausses, en silence, sur les deux pilotes | Reproduit, non signalé [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-5-6) |
| Une chaîne multi-instructions est atomique, comme la page sur les transactions de DuckDB décrit une transaction implicite | Elle ne l'est pas : les deux premières lignes sont restées quand la troisième instruction a échoué, en CLI comme en JDBC | CLI DuckDB 1.5.5 et duckdb_jdbc | 2 lignes sur 3 conservées, par `-c "a; b; c"` comme par `statement.execute("a; b; c")`. Un `COMMIT` après une erreur n'affiche rien et annule | Reproduit ; la documentation et le comportement se contredisent [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |
| Une requête échouée laisse le `Statement` utilisable | Le statement est fermé : une boucle qui rattrape l'erreur et continue échoue sur toutes les instructions suivantes | duckdb_jdbc 1.5.5.1 | `Statement was closed` | Reproduit, non signalé [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-5-6) |
| Le renifleur CSV signale une colonne qu'il n'a pas su analyser | Il lit en silence `13/09/2026 15:53` comme du `VARCHAR`, et un `timestampformat` faux aussi ; seul un type explicite le fait échouer | DuckDB 1.5.5 | Toute comparaison de dates ultérieure devient une comparaison de chaînes | Reproduit ; les mots du journal : « This isn't an error » [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-1-4) |
| Un glob sur des fichiers de formes différentes avertit ou échoue | `FROM 'data/*.json'` fusionne les runs et les jobs en une table sans un mot | DuckDB 1.5.5 | 20 colonnes tirées de deux formes sans rapport | Reproduit, non signalé [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-1-4) |
| L'`approx_unique` de `SUMMARIZE` compte les valeurs distinctes | Il surcompte et sous-compte | CLI DuckDB 1.5.5 | 131 pour 125 identifiants d'exécution, 17 pour 21 noms de workflow | Par conception : HyperLogLog échange l'exactitude contre une mémoire constante [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-1-4) |
| `labels[0]` est une erreur | Il rend `NULL`, comme tout indice au-delà de la fin | DuckDB 1.5.5 | Aucune erreur | Par conception : les listes commencent à 1. Une habitude C# ou Java qui échoue en silence [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-1-4) |
| L'écrivain Parquet produit les mêmes octets pour les mêmes données | Non — il écrit avec plusieurs fils | écriture Parquet de DuckDB 1.5.5 | 119 021 205 puis 119 392 814 octets en local pour un fichier de 11 millions de lignes ; 118 714 412 à 119 120 557 sur les exécuteurs. Au premier push, le script de la leçon 4 a échoué sur macOS seulement : 8 fragments de colonnes différaient de 1 à 6 octets sur `total_compressed_size` | Reproduit ; un vrai échec de CI, contourné en comparant `num_values` [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |
| Des prédicats de dates équivalents donnent des plans équivalents | `started_at::DATE = …` et `date_trunc('day', started_at) = …` sont réécrits en un intervalle qui saute des groupes de lignes ; `strftime(started_at, …) = …` reste une expression et lit toutes les lignes | optimiseur DuckDB 1.5.5 | 0,47 s contre 0,003 s sur le fichier trié | Reproduit ; une réécriture réellement manquée [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |
| Un tri qui ne tient pas dans `memory_limit` déborde sur le disque | Il échoue avec 4 fils et réussit avec 1, et le `COPY` échoué laisse un fichier partiel derrière lui | DuckDB 1.5.5 | 11 M de lignes à `memory_limit = '100MB'` ; 6,3 à 9,9 s dans le cas à un fil | Reproduit, dépendant du nombre de fils [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |
| Un processus en lecture seule peut ouvrir un fichier tenu par un autre | Un processus qui tient le fichier bloque tous les autres, lecture seule comprise, avec un message différent par OS | DuckDB 1.5.5 | Trois OS, trois messages ; Linux et macOS ajoutent une indication sur `-readonly` que Windows ne donne pas | Reproduit ; par conception [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |
| Le jar JDBC et le paquet .NET embarquent ce qu'il faut à la plateforme | Le jar pèse 85 Mo, avec quatre bibliothèques natives et aucune build Windows sur Arm | duckdb_jdbc 1.5.5.1, DuckDB.NET 1.5.5 | `DuckDB.NET.Data.Full` pèse 420 Mo dans le cache NuGet, 316 Mo dans `bin/Debug`, 69 Mo publié pour `linux-x64` seul | Mesuré ; l'absence de build win-arm64 est un vrai manque [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-5-6) |
| Le script d'installation en une ligne couvre les trois systèmes | `curl -fsSL https://install.duckdb.org | sh` ne prend pas Windows en charge | install.duckdb.org | Le workflow télécharge `duckdb_cli-windows-amd64.zip` à la place | Reproduit [2026-09-14](#2026-09-14--installer-duckdb) |
| Un lot JDBC est plus rapide que des instructions une à une | Il ne l'était pas | duckdb_jdbc 1.5.5.1, en CI | 690 ms à 2,4 s pour 10 000 lignes, contre 226 à 331 ms pour 1 000 000 de lignes avec l'appender C# | Mesuré, cause non cherchée [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-5-6) |

## Expériences

Quatre questions que le cours a posées avant de mesurer. Aucune n'est une hypothèse que l'auteur aurait inventée puis éprouvée — deux reposent sur de la documentation lue au préalable, une sur une valeur lue dans le fichier lui-même — et le tableau le dit plutôt que de les déguiser. La troisième est celle qui est revenue réfutée.

| Question | Hypothèse | Résultat | Verdict | Où |
|---|---|---|---|---|
| La CI peut-elle comparer des plans `EXPLAIN` entre trois exécuteurs ? | Le journal pose la question et tire sa conclusion de la réponse ; aucune prédiction écrite | La sortie ne dépend pas du nombre de fils, et les estimations étaient les mêmes sur les trois exécuteurs | Confirmée : les plans sont comparables | [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |
| Un DuckDB plus ancien peut-il lire un fichier écrit par la 1.5.5 ? | L'étiquette `storage_version=v1.0.0+` du fichier lui-même, lue avant l'essai | La CLI 1.0.0 a lu les fichiers écrits par défaut. Avec `STORAGE_VERSION 'v1.5.0'`, elle les a refusés : `version number 68, can only read 64` | Confirmée, avec son témoin négatif | [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |
| Une chaîne multi-instructions est-elle atomique ? | Oui — la page sur les transactions de DuckDB décrit une transaction implicite. Un a priori documenté et cité avant l'essai | `-c "a; b; c"` et `statement.execute("a; b; c")` ont tous deux gardé les deux premières lignes quand la troisième a échoué | Réfutée | [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |
| La prédiction du plan tient-elle en temps réel ? | Le plan annonce que `::DATE` et `date_trunc` sautent des groupes de lignes et que `strftime` non ; la leçon 7 lit les plans, puis mesure ce qu'ils prédisent | 0,47 s contre 0,003 s sur le fichier trié | Confirmée | [2026-09-14](#2026-09-14--surprises-en-écrivant-les-leçons-7-8) |

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
