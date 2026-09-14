---
title: LadybugDB — Mission
description: Apprendre LadybugDB, la base de données orientée graphe embarquée qui prend la suite de Kuzu, en interrogeant avec Cypher les liens entre les pages de ce site, son historique Git, ses exécutions de CI et les projets d'une solution .NET — en ligne de commande, puis depuis C# et Java.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque requête de ce cours se trouve dans [`code/ladybugdb/cypher`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/cypher), à côté de sa sortie attendue. [`.github/workflows/ladybugdb-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ladybugdb-examples.yml) les exécute toutes avec la CLI de LadybugDB sous Linux, Windows et macOS et compare les résultats ; il fait de même avec le programme C# de la leçon 5, les programmes Java des leçons 6 et 8, et le script de la leçon 8 qui lance et tue des processus de la CLI sur un fichier de base de données. Les sorties des leçons ont été capturées avec LadybugDB 0.20.4 en septembre 2026, avec la CLI 0.19.1 pour les extensions de la leçon 7, avec le paquet NuGet `LadybugDB` 0.19.1 pour C#, et avec le paquet Maven `com.ladybugdb:lbug` 0.20.4 pour Java.
:::

## Pourquoi j'apprends ça

Le [cours DuckDB](../duckdb/) répond à des questions sur des lignes : combien d'exécutions, combien de temps, quel step. D'autres questions sur ce site portent sur des connexions. Combien de clics entre la page d'accueil et une leçon ? Quels fichiers changent ensemble ? Sur quels commits un workflow en échec a-t-il tourné ? En SQL, chacune d'elles devient une chaîne d'auto-jointures, ou une CTE récursive dont je dois deviner la profondeur.

Une base de données orientée graphe stocke les connexions elles-mêmes, et son langage de requête décrit directement les chemins. [LadybugDB](https://ladybugdb.com/) en est une qui s'exécute dans ton processus, comme DuckDB et SQLite : aucun serveur à installer.

## À qui s'adresse ce cours

Tu connais le SQL : `SELECT`, `JOIN`, `GROUP BY`, peut-être une CTE récursive. Tu écris du C# ou du Java. Tu n'as besoin de rien savoir des bases de données orientées graphe ni de [Cypher](https://opencypher.org/).

## LadybugDB en un tableau

| | Tables de graphe de SQL Server | Neo4j | LadybugDB |
|---|---|---|---|
| S'exécute | comme un serveur | comme un serveur | dans ton processus |
| Schéma | tables créées `AS NODE` et `AS EDGE` | facultatif : les étiquettes et les propriétés apparaissent quand tu les écris | obligatoire : tables de nœuds et tables de relations, avec des colonnes typées |
| Langage de requête | T-SQL avec `MATCH` | Cypher | Cypher |
| Chemins de longueur quelconque | `SHORTEST_PATH` | motifs de longueur variable | motifs de longueur variable, plus courts chemins |
| Depuis .NET | `Microsoft.Data.SqlClient` | pilote .NET de Neo4j | paquet NuGet `LadybugDB` |
| Depuis Java | pilote JDBC | pilote Java de Neo4j | paquet Maven `com.ladybugdb:lbug` |

Sources : [architecture de SQL Graph](https://learn.microsoft.com/sql/relational-databases/graphs/sql-graph-architecture), [manuel Cypher de Neo4j](https://neo4j.com/docs/cypher-manual/current/introduction/), [différences entre LadybugDB et Neo4j](https://docs.ladybugdb.com/cypher/difference/).

LadybugDB s'appelait [auparavant Kuzu](https://github.com/LadybugDB/ladybug#readme). Les auteurs de Kuzu [ont archivé son dépôt](https://github.com/kuzudb/kuzu) ; LadybugDB poursuit la base de code sous licence MIT, avec de nouveaux noms : la CLI s'appelle `lbug`, et la documentation nomme les fichiers de base de données `.lbdb`.

## Les données

[`code/ladybugdb/data/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/extract.py) lit ce dépôt au commit [`cbcbb42`](https://github.com/spareilleux/learn/commit/cbcbb42) (2026-09-14) et écrit six fichiers CSV dans [`code/ladybugdb/data`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/data) :

- `pages.csv` : les 319 pages du site (117 en anglais, 101 en français, 101 en espagnol), avec leur locale, leur cours, leur titre et leur nombre de lignes ;
- `links.csv` : les 712 liens d'une page du site vers une autre, trouvés dans les liens Markdown et les attributs `href` hors des blocs de code ;
- `external_links.csv` : les 3 712 liens vers 85 autres sites ;
- `commits.csv`, `parents.csv` et `changes.csv` : les 74 commits jusqu'à `cbcbb42`, le parent de chacun, et les 1 019 modifications qu'ils ont apportées à 710 fichiers.

La leçon 4 ajoute les 125 exécutions de CI de [`code/duckdb/data/runs.json`](https://github.com/spareilleux/learn/blob/main/code/duckdb/data/runs.json), l'instantané qu'interroge le cours DuckDB.

Les leçons 5 et 6 interrogent un autre dépôt : les projets .NET de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893), extraits par [`code/ladybugdb/data/ga/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/ga/extract.py) : 111 projets, 266 références de projet et 478 références de paquet.

## À la fin de ce cours, je saurai

- modéliser des données en tables de nœuds et tables de relations, et les interroger avec des motifs Cypher ;
- charger des fichiers CSV et JSON, et trouver les lignes qui ne respectent pas le schéma ;
- écrire des chemins de longueur variable et des plus courts chemins, et connaître la sémantique de chemin qu'ils utilisent ;
- reconnaître les bugs et les limites de LadybugDB, et vérifier un résultat autrement ;
- utiliser LadybugDB depuis C# et depuis Java.

## Plan

| # | Leçon | Si tu connais SQL |
|---|---|---|
| 1 | [Un premier graphe : tables, `CREATE`, `MATCH`, `MERGE`](01-first-graph/) | `CREATE TABLE`, `INSERT`, `MERGE`, `JOIN` |
| 2 | [Charger des fichiers : `LOAD FROM`, `COPY`, avertissements](02-loading/) | `OPENROWSET`, `BULK INSERT` |
| 3 | [Chemins : longueur variable et plus courts chemins](03-paths/) | CTE récursives |
| 4 | [L'historique Git et les exécutions de CI en graphe](04-git-history/) | auto-jointures, tables de jointure |
| 5 | [LadybugDB depuis C#](05-csharp/) | ADO.NET |
| 6 | [LadybugDB depuis Java](06-java/) | JDBC |
| 7 | [Algorithmes de graphe et recherche plein texte](07-algorithms/) | index plein texte, `CONTAINSTABLE` |
| 8 | [Persistance, transactions et concurrence](08-persistence/) | isolation, verrous, journal des transactions |
| — | [Journal](journal/) | |

## Ressources

- [Documentation de LadybugDB](https://docs.ladybugdb.com/)
- [Cypher dans LadybugDB](https://docs.ladybugdb.com/get-started/cypher-intro/)
- [CLI de LadybugDB](https://docs.ladybugdb.com/client-apis/cli/)
- [Code source de LadybugDB](https://github.com/LadybugDB/ladybug), et la [version 0.20.4](https://github.com/LadybugDB/ladybug/releases/tag/v0.20.4) qu'utilise ce cours
- [openCypher](https://opencypher.org/) : la spécification ouverte de Cypher
