---
title: 4. L'historique Git et les exécutions de CI en graphe
description: Charger les commits, les fichiers et les exécutions de CI de ce dépôt dans un graphe, parcourir l'historique avec de longs chemins, trouver les fichiers modifiés ensemble et relier les échecs aux fichiers qu'ils ont touchés — avec deux autres bugs de LadybugDB 0.20.4 et leurs contournements.
sidebar:
  order: 4
---

Un second graphe, tiré du même dépôt : son historique Git jusqu'au commit `cbcbb42`, et les exécutions de CI de l'instantané du cours DuckDB. Toutes les requêtes sont dans [`cypher/04-git-history.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/04-git-history.cypher).

## Le modèle

| Table | Type | Source |
|---|---|---|
| `Commit(sha, committed_at, subject)` | nœud | `commits.csv` |
| `File(path)` | nœud | les fichiers distincts de `changes.csv` |
| `PARENT` | relation, de `Commit` vers `Commit` | `parents.csv` : chaque commit pointe vers son parent |
| `CHANGED` | relation, de `Commit` vers `File` | `changes.csv` |
| `Run(databaseId, workflowName, conclusion, headBranch)` | nœud | `code/duckdb/data/runs.json` |
| `RAN_ON` | relation, de `Run` vers `Commit` | `runs.json` : le commit extrait par chaque exécution |

En SQL, `PARENT` et `CHANGED` seraient des tables de jointure, et `RAN_ON` une colonne de clé étrangère dans la table des exécutions. Dans le graphe, les trois sont des relations, et une requête peut les suivre dans un seul motif.

Les premières lignes du script créent et chargent la partie Git ([lignes 3-10](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L3-L10)) :

```cypher
CREATE NODE TABLE Commit(sha STRING PRIMARY KEY, committed_at TIMESTAMP, subject STRING);
CREATE NODE TABLE File(path STRING PRIMARY KEY);
CREATE REL TABLE PARENT(FROM Commit TO Commit);
CREATE REL TABLE CHANGED(FROM Commit TO File);
COPY Commit FROM 'data/commits.csv' (HEADER = true, QUOTE = '"');
COPY File FROM (LOAD FROM 'data/changes.csv' (HEADER = true) RETURN DISTINCT file);
COPY PARENT FROM 'data/parents.csv' (HEADER = true);
COPY CHANGED FROM 'data/changes.csv' (HEADER = true);
```

74 commits, 710 fichiers, 73 relations `PARENT` et 1 019 relations `CHANGED`. Le fichier a 74 lignes, donc le sniffer CSV de la leçon 2 les lit toutes et trouve seul les sujets entre guillemets ; `QUOTE = '"'` ne fait que le rendre explicite, pour un historique plus long.

## Horodatages

[Ligne 13](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L13) :

```cypher
MATCH (c:Commit) RETURN count(*) AS commits, min(c.committed_at) AS first_commit, max(c.committed_at) AS last_commit;
```

```text
┌─────────┬─────────────────────┬─────────────────────┐
│ commits │ first_commit        │ last_commit         │
│ INT64   │ TIMESTAMP           │ TIMESTAMP           │
├─────────┼─────────────────────┼─────────────────────┤
│ 74      │ 2026-09-13 15:52:51 │ 2026-09-14 16:03:28 │
└─────────┴─────────────────────┴─────────────────────┘
```

Le fichier contient `2026-09-13T11:52:51-04:00`, l'heure locale du commit avec son décalage. [`TIMESTAMP`](https://docs.ladybugdb.com/cypher/data-types/) n'a pas de fuseau horaire : LadybugDB a converti la valeur en UTC et abandonné le décalage. Tout l'historique du site, jusqu'à ce commit, tient en un peu plus d'une journée.

## Un long chemin qui ne renvoie rien

Du dernier commit jusqu'au premier : un chemin de relations `PARENT` vers un commit sans parent ([lignes 16-22](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L16-L22)) :

```cypher
MATCH (last:Commit)-[p:PARENT*1..30]->(first:Commit)
WHERE last.sha STARTS WITH 'cbcbb42' AND NOT EXISTS { MATCH (first)-[:PARENT]->(:Commit) }
RETURN first.subject, length(p) AS commits_between;
CALL var_length_extend_max_depth = 100;
MATCH (last:Commit)-[p:PARENT*1..100]->(first:Commit)
WHERE last.sha STARTS WITH 'cbcbb42' AND NOT EXISTS { MATCH (first)-[:PARENT]->(:Commit) }
RETURN first.subject, length(p) AS commits_between;
```

```text
┌───────────────┬─────────────────┐
│ first.subject │ commits_between │
│ STRING        │ INT64           │
├───────────────┼─────────────────┤
└───────────────┴─────────────────┘
┌───────────────────────────────────────────────────────────────────────┬─────────────────┐
│ first.subject                                                         │ commits_between │
│ STRING                                                                │ INT64           │
├───────────────────────────────────────────────────────────────────────┼─────────────────┤
│ Initial learn site: Starlight, bilingual en/fr, WSL containers course │ 73              │
└───────────────────────────────────────────────────────────────────────┴─────────────────┘
```

**La première requête ne renvoie aucune ligne, et aucune erreur.** Le premier commit est à 73 relations, au-delà des 30 de `*1..30` : aucun chemin ne correspond au motif. Avec la limite relevée à 100 ([leçon 3](../03-paths/#la-limite-de-profondeur)), le même motif le trouve. Quand un motif de longueur variable ne trouve rien, vérifie sa borne supérieure avant les données. Cet historique n'a pas de branches, donc il n'y a qu'un chemin : aucun risque de l'explosion des marches de la leçon 3.

`STARTS WITH 'cbcbb42'` correspond au hash abrégé, comme `git show cbcbb42`.

## Parents par commit, et un bug des sous-requêtes `COUNT`

Un commit de fusion a deux parents. Y en a-t-il ? [Lignes 26-27](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L26-L27) :

```cypher
MATCH (c:Commit) RETURN COUNT { MATCH (c)-[:PARENT]->(:Commit) } AS parents, count(*) AS commits ORDER BY parents;
MATCH (c:Commit) OPTIONAL MATCH (c)-[:PARENT]->(p:Commit) WITH c, count(p) AS parents RETURN parents, count(*) AS commits ORDER BY parents;
```

```text
┌─────────┬─────────┐
│ parents │ commits │
│ INT64   │ INT64   │
├─────────┼─────────┤
│ 1       │ 73      │
└─────────┴─────────┘
┌─────────┬─────────┐
│ parents │ commits │
│ INT64   │ INT64   │
├─────────┼─────────┤
│ 0       │ 1       │
│ 1       │ 73      │
└─────────┴─────────┘
```

Aucun commit de fusion : l'historique est linéaire. Mais la première requête compte 73 commits sur 74. Le commit racine, dont le `COUNT` vaut 0, manque au résultat groupé, alors que la même sous-requête renvoie 0 pour ce commit quand la requête ne groupe pas par elle. La seconde requête compte la même chose avec `OPTIONAL MATCH` et `count(p)`, et obtient les deux groupes. Encore un bug de la 0.20.4, silencieux comme ceux des leçons 2 et 3 : quand une requête groupe par une sous-requête `COUNT`, vérifie que la somme des groupes donne le nombre de nœuds.

## Fichiers modifiés ensemble

Les fichiers modifiés dans les mêmes commits que `astro.config.mjs`, où les cours sont enregistrés ([lignes 30-33](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L30-L33)) :

```cypher
MATCH (a:File {path: 'astro.config.mjs'})<-[:CHANGED]-(c:Commit)-[:CHANGED]->(b:File)
RETURN b.path, count(*) AS commits
ORDER BY commits DESC, b.path
LIMIT 5;
```

```text
┌───────────────────────────────┬─────────┐
│ b.path                        │ commits │
│ STRING                        │ INT64   │
├───────────────────────────────┼─────────┤
│ astro.config.mjs              │ 11      │
│ src/content/docs/fr/index.mdx │ 9       │
│ src/content/docs/index.mdx    │ 9       │
│ AGENTS.md                     │ 7       │
│ README.md                     │ 7       │
└───────────────────────────────┴─────────┘
```

La première ligne est le fichier lui-même. Le motif a deux relations `CHANGED`, et rien ne les empêche d'être la même : avec la [sémantique de marche](https://docs.ladybugdb.com/cypher/difference/) de la leçon 3, `b` peut être `a`. `WHERE b <> a` supprime cette ligne ; les suivantes sont les pages d'accueil, qui listent aussi les cours, et `AGENTS.md`, où vivent les conventions des cours. La version SQL, une auto-jointure de la table des modifications sur le commit, a le même piège et la même correction (`b.file <> a.file`).

## Les fichiers les plus souvent modifiés

[Lignes 36-39](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L36-L39) :

```cypher
MATCH (c:Commit)-[:CHANGED]->(f:File)
RETURN f.path, count(*) AS commits
ORDER BY commits DESC, f.path
LIMIT 5;
```

```text
┌───────────────────────────────────────────────┬─────────┐
│ f.path                                        │ commits │
│ STRING                                        │ INT64   │
├───────────────────────────────────────────────┼─────────┤
│ src/content/docs/fr/wsl-containers/journal.md │ 16      │
│ src/content/docs/wsl-containers/journal.md    │ 15      │
│ README.md                                     │ 13      │
│ astro.config.mjs                              │ 11      │
│ src/content/docs/fr/index.mdx                 │ 9       │
└───────────────────────────────────────────────┴─────────┘
```

Le journal du cours WSL containers arrive en tête : 16 commits ont modifié le journal français, 15 le journal anglais.

## Exécutions de CI : une relation vers un commit absent

Les exécutions viennent de JSON, donc d'abord l'extension json ([lignes 42-45](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L42-L45)) :

```cypher
LOAD json;
CREATE NODE TABLE Run(databaseId INT64 PRIMARY KEY, workflowName STRING, conclusion STRING, headBranch STRING);
CREATE REL TABLE RAN_ON(FROM Run TO Commit);
COPY Run FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, workflowName, conclusion, headBranch);
```

125 exécutions. Puis les relations, de l'id de l'exécution vers le commit sur lequel elle a tourné ([lignes 48-52](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L48-L52)) :

```cypher
COPY RAN_ON FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, headSha);
LOAD FROM '../duckdb/data/runs.json'
WITH headBranch, headSha
WHERE NOT EXISTS { MATCH (c:Commit) WHERE c.sha = headSha }
RETURN headBranch, count(*) AS runs;
```

```text
Error: Copy exception: Unable to find primary key value bd17932fe35899909b8d983ab289e1ea4ff344a8.
┌────────────────┬───────┐
│ headBranch     │ runs  │
│ STRING         │ INT64 │
├────────────────┼───────┤
│ gha-06-invalid │ 2     │
└────────────────┴───────┘
```

Deux exécutions ont tourné sur un commit de la branche `gha-06-invalid`, une branche temporaire du [cours GitHub Actions](../../github-actions/journal/), utilisée pour tester un workflow invalide sans le mettre sur `main` : ses commits ne sont pas dans cet historique. La réponse de la leçon 2 serait `IGNORE_ERRORS`, mais il n'est pas pris en charge sur un `COPY` depuis une sous-requête : la tentative échoue avec `bad variant access`. L'alternative évidente est de ne garder que les exécutions dont le commit existe.

## Un bug de la 0.20.4 : un `MATCH` dans une sous-requête de `COPY`

Cette alternative, avec un `MATCH` dans la sous-requête ([lignes 55-61](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L55-L61)) :

```cypher
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha
  MATCH (c:Commit) WHERE c.sha = headSha
  RETURN databaseId, headSha
);
MATCH (r:Run)-[:RAN_ON]->(c:Commit) RETURN count(*) AS links, count(DISTINCT r) AS runs, count(DISTINCT c) AS commits;
```

```text
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 123 tuples have been copied to the RAN_ON table. │
└──────────────────────────────────────────────────┘
┌───────┬───────┬─────────┐
│ links │ runs  │ commits │
│ INT64 │ INT64 │ INT64   │
├───────┼───────┼─────────┤
│ 123   │ 1     │ 64      │
└───────┴───────┴─────────┘
```

123 relations, le bon nombre, vers les 64 bons commits, mais **toutes depuis la même exécution**. La sous-requête seule, exécutée comme requête, renvoie 123 ids d'exécution distincts ; dans `COPY`, la colonne `FROM` de chaque relation reçoit l'un d'eux. Le même `COPY` fonctionne avec un fichier CSV au lieu de JSON, et avec JSON quand le filtre n'utilise pas `MATCH`. Le contournement garde JSON et filtre sur une colonne : les deux commits manquants sont ceux de l'autre branche ([lignes 64-71](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L64-L71)) :

```cypher
MATCH ()-[x:RAN_ON]->() DELETE x;
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha, headBranch
  WHERE headBranch = 'main'
  RETURN databaseId, headSha
);
MATCH (r:Run)-[:RAN_ON]->(c:Commit) RETURN count(*) AS links, count(DISTINCT r) AS runs, count(DISTINCT c) AS commits;
```

```text
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 123 tuples have been copied to the RAN_ON table. │
└──────────────────────────────────────────────────┘
┌───────┬───────┬─────────┐
│ links │ runs  │ commits │
│ INT64 │ INT64 │ INT64   │
├───────┼───────┼─────────┤
│ 123   │ 123   │ 64      │
└───────┴───────┴─────────┘
```

123 liens depuis 123 exécutions. `MATCH ()-[x:RAN_ON]->() DELETE x` a d'abord supprimé les mauvaises relations : une relation se supprime sans `DETACH`. La requête de vérification est tout l'intérêt de cette section : `count(*)` seul était juste dans les deux cas ; `count(DISTINCT r)` a montré le bug.

## Les échecs et les fichiers qu'ils ont touchés

Tout le graphe dans un seul motif : exécutions, commits, fichiers ([lignes 74-78](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L74-L78)) :

```cypher
MATCH (r:Run)-[:RAN_ON]->(c:Commit)-[:CHANGED]->(f:File)
WHERE r.conclusion = 'failure'
RETURN f.path, count(DISTINCT c) AS failed_commits
ORDER BY failed_commits DESC, f.path
LIMIT 5;
```

```text
┌────────────────────────────────────────┬────────────────┐
│ f.path                                 │ failed_commits │
│ STRING                                 │ INT64          │
├────────────────────────────────────────┼────────────────┤
│ .github/workflows/gha-03-triggers.yml  │ 2              │
│ .github/workflows/gha-05-exercises.yml │ 2              │
│ astro.config.mjs                       │ 2              │
│ code/github-actions/.gitignore         │ 2              │
│ src/content/docs/fr/index.mdx          │ 2              │
└────────────────────────────────────────┴────────────────┘
```

`count(DISTINCT c)`, pas `count(*)` : un commit avec trois exécutions en échec compte une fois. Les fichiers de workflow des leçons GitHub Actions arrivent en tête ; les fichiers du site à côté d'eux ont été modifiés dans les mêmes commits. Un graphe des modifications montre ce qui a échoué ensemble, pas ce qui a causé l'échec : pour ça, il faut les logs des exécutions.

## Exécutions par workflow sur les commits qui ont modifié le code du cours

[Lignes 81-84](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L81-L84) :

```cypher
MATCH (r:Run)-[:RAN_ON]->(c:Commit)-[:CHANGED]->(f:File)
WHERE f.path STARTS WITH 'code/github-actions/'
RETURN r.workflowName, count(DISTINCT r) AS runs
ORDER BY runs DESC, r.workflowName;
```

```text
┌─────────────────────────────────────┬───────┐
│ r.workflowName                      │ runs  │
│ STRING                              │ INT64 │
├─────────────────────────────────────┼───────┤
│ Deploy to GitHub Pages              │ 2     │
│ GHA 02: build and test              │ 2     │
│ Rust course examples                │ 2     │
│ GHA 01: hello                       │ 1     │
│ GHA 03: triggers                    │ 1     │
│ GHA 04: data between steps and jobs │ 1     │
│ GHA 05: caches and artifacts        │ 1     │
│ GHA 05: exercise checks             │ 1     │
└─────────────────────────────────────┴───────┘
```

Les workflows qu'une modification de `code/github-actions/` a déclenchés : les workflows GitHub Actions, mais aussi le déploiement et les exemples du cours Rust, qui ont tourné sur les mêmes commits parce que d'autres fichiers ont changé avec eux. `count(DISTINCT r)` encore : une exécution est atteinte une fois par fichier de son commit.

## À retenir

- Un historique Git est un graphe : les commits, les fichiers et les exécutions sont des nœuds ; les parents, les modifications et « a tourné sur » sont des relations.
- Un motif de longueur variable dont la borne supérieure est trop petite ne renvoie rien, sans erreur.
- `TIMESTAMP` stocke de l'UTC : un décalage dans le fichier est appliqué, puis abandonné.
- Dans un motif avec deux relations de la même table, les deux peuvent être la même relation : exclus-la avec `WHERE b <> a`.
- Deux autres bugs silencieux de la 0.20.4 : grouper par une sous-requête `COUNT` fait disparaître le groupe zéro, et un `MATCH` dans une sous-requête de `COPY` depuis JSON rattache chaque relation à un seul nœud. `IGNORE_ERRORS` n'est pas disponible non plus sur les sous-requêtes. `count(DISTINCT …)` sur chaque extrémité est une vérification peu coûteuse après un chargement.

## Exercices

Les solutions sont dans [`cypher/04-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/04-exercises.cypher), vérifiées par la CI. Elles chargent le même graphe, avec le contournement `main` pour `RAN_ON`.

1. Quels sont les trois commits qui ont modifié le plus de fichiers ?

<details>
<summary>Solution</summary>

Extrait de [`04-exercises.cypher`, lignes 23-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L23-L26) :

```cypher
MATCH (c:Commit)-[:CHANGED]->(f:File)
RETURN substring(c.sha, 1, 7) AS sha, c.subject, count(*) AS files
ORDER BY files DESC, sha
LIMIT 3;
```

```text
┌─────────┬──────────────────────────────────────────────────────────────┬───────┐
│ sha     │ c.subject                                                    │ files │
│ STRING  │ STRING                                                       │ INT64 │
├─────────┼──────────────────────────────────────────────────────────────┼───────┤
│ d32b186 │ Java lessons 5-8 and a Spanish locale for the whole site     │ 160   │
│ f43ba7e │ Import Streeling University modules from Demerzel            │ 103   │
│ 529c946 │ Java for C# developers: lessons 1-4, tested code and journal │ 80    │
└─────────┴──────────────────────────────────────────────────────────────┴───────┘
```

Le commit qui a ajouté la locale espagnole a ajouté 75 pages espagnoles d'un coup. `substring(c.sha, 1, 7)` est le hash abrégé.

</details>

2. Combien de commits avant `cbcbb42` `AGENTS.md` a-t-il été modifié pour la dernière fois, et par quel commit ?

<details>
<summary>Solution</summary>

Extrait de [`04-exercises.cypher`, lignes 29-34](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L29-L34) :

```cypher
CALL var_length_extend_max_depth = 100;
MATCH (last:Commit)-[p:PARENT* SHORTEST 1..100]->(c:Commit)-[:CHANGED]->(:File {path: 'AGENTS.md'})
WHERE last.sha STARTS WITH 'cbcbb42'
RETURN length(p) AS commits_before, substring(c.sha, 1, 7) AS sha, c.subject
ORDER BY commits_before
LIMIT 1;
```

```text
┌────────────────┬─────────┬──────────────────────────────────────────────────────────┐
│ commits_before │ sha     │ c.subject                                                │
│ INT64          │ STRING  │ STRING                                                   │
├────────────────┼─────────┼──────────────────────────────────────────────────────────┤
│ 42             │ d32b186 │ Java lessons 5-8 and a Spanish locale for the whole site │
└────────────────┴─────────┴──────────────────────────────────────────────────────────┘
```

42 commits : `git log --oneline cbcbb42` liste `d32b186` en position 43. `SHORTEST` trouve un chemin par commit qui a modifié `AGENTS.md`, et `ORDER BY … LIMIT 1` garde le plus proche. La limite de 100 est de nouveau nécessaire : l'historique est plus long que 30. La borne inférieure 1 exclut `cbcbb42` lui-même, qui n'a de toute façon pas modifié le fichier.

</details>

3. Quels commits n'ont aucune exécution de CI ? Pour chacun, combien de temps avant le commit suivant, et celui-ci a-t-il eu des exécutions ?

<details>
<summary>Solution</summary>

Extrait de [`04-exercises.cypher`, lignes 37-45](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L37-L45) :

```cypher
MATCH (c:Commit)
WHERE NOT EXISTS { MATCH (:Run)-[:RAN_ON]->(c) }
RETURN c.committed_at, substring(c.sha, 1, 7) AS sha, c.subject
ORDER BY c.committed_at;
MATCH (c:Commit)-[:PARENT]->(p:Commit)
WHERE NOT EXISTS { MATCH (:Run)-[:RAN_ON]->(p) }
RETURN substring(p.sha, 1, 7) AS without_runs, substring(c.sha, 1, 7) AS next_commit, c.committed_at - p.committed_at AS gap,
       COUNT { MATCH (:Run)-[:RAN_ON]->(c) } AS next_commit_runs
ORDER BY without_runs;
```

```text
┌─────────────────────┬─────────┬──────────────────────────────────────────────────────────────────────────────────────┐
│ c.committed_at      │ sha     │ c.subject                                                                            │
│ TIMESTAMP           │ STRING  │ STRING                                                                               │
├─────────────────────┼─────────┼──────────────────────────────────────────────────────────────────────────────────────┤
│ 2026-09-13 17:13:23 │ 00f2ca4 │ Rust course: lessons 9-12 (lifetimes, modules, smart pointers, threads)              │
│ 2026-09-14 14:08:24 │ 3f3b219 │ DuckDB course: data snapshot of this repository's runs, lesson 1 SQL, CI on 3 OSes   │
│ 2026-09-14 14:24:14 │ 742c967 │ DuckDB course: SQL and expected output for lessons 1-4 and their exercises           │
│ 2026-09-14 14:25:34 │ 36207da │ DuckDB course: don't compare Parquet compressed sizes, they differ on macOS arm64    │
│ 2026-09-14 14:43:42 │ 3e9530f │ DuckDB course: mission, lessons 1-4 and journal (en/fr/es)                           │
│ 2026-09-14 15:13:02 │ a96fd27 │ DuckDB course: lesson 5 C# program (DuckDB.NET, Dapper) and CI on 3 OSes             │
│ 2026-09-14 15:16:11 │ 5a26d1a │ DuckDB course: lesson 6 Java program (JDBC) and CI on 3 OSes                         │
│ 2026-09-14 15:33:19 │ bdf2692 │ DuckDB course: lesson 7 scripts (plans, pushdown, row groups) and CI timings         │
│ 2026-09-14 15:48:40 │ 86e34d9 │ DuckDB course: lesson 7 exercises, lesson 8 persistence script and Java transactions │
│ 2026-09-14 16:03:28 │ cbcbb42 │ DuckDB course: lessons 5-8 (C#, Java, performance, persistence) in en/fr/es          │
└─────────────────────┴─────────┴──────────────────────────────────────────────────────────────────────────────────────┘
┌──────────────┬─────────────┬──────────┬──────────────────┐
│ without_runs │ next_commit │ gap      │ next_commit_runs │
│ STRING       │ STRING      │ INTERVAL │ INT64            │
├──────────────┼─────────────┼──────────┼──────────────────┤
│ 00f2ca4      │ 95a42da     │ 00:00:00 │ 2                │
│ 36207da      │ 3e9530f     │ 00:18:08 │ 0                │
│ 3e9530f      │ a96fd27     │ 00:29:20 │ 0                │
│ 3f3b219      │ 742c967     │ 00:15:50 │ 0                │
│ 5a26d1a      │ bdf2692     │ 00:17:08 │ 0                │
│ 742c967      │ 36207da     │ 00:01:20 │ 0                │
│ 86e34d9      │ cbcbb42     │ 00:14:48 │ 0                │
│ a96fd27      │ 5a26d1a     │ 00:03:09 │ 0                │
│ bdf2692      │ 86e34d9     │ 00:15:21 │ 0                │
└──────────────┴─────────────┴──────────┴──────────────────┘
```

Deux raisons. Neuf commits sont postérieurs à l'instantané des exécutions, dont la dernière exécution a été créée à 14:01 UTC : ils ont eu des exécutions, après la prise de l'instantané. `00f2ca4` est l'autre cas : `95a42da` l'a suivi dans la même seconde, ils ont été poussés ensemble, et GitHub Actions n'exécute les workflows d'un push que sur son dernier commit. Soustraire deux valeurs `TIMESTAMP` donne un `INTERVAL`. `cbcbb42` n'a pas d'enfant dans cet historique, donc il n'est pas dans le second résultat.

</details>

## Sources

- [Types de données](https://docs.ladybugdb.com/cypher/data-types/) : `TIMESTAMP`, `INTERVAL`
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/) : relations de longueur variable et plus courts chemins
- [`COPY FROM` depuis une sous-requête](https://docs.ladybugdb.com/import/copy-from-subquery/) et [extension JSON](https://docs.ladybugdb.com/extensions/json/)
- [Sous-requêtes](https://docs.ladybugdb.com/cypher/subquery/) et [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/)
- [Différences entre LadybugDB et Neo4j](https://docs.ladybugdb.com/cypher/difference/)
- [Événements qui déclenchent des workflows : `push`](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows#push)
