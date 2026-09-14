---
title: 2. Charger des fichiers
description: Regarder des fichiers CSV avec LOAD FROM, charger nœuds et relations avec COPY, garder les lignes qui ne rentrent pas comme avertissements, remplir des tables à partir d'une sous-requête, et charger du JSON avec l'extension json.
sidebar:
  order: 2
---

Le site comme graphe : un nœud `Page` par page, une relation `LINKS_TO` par lien entre deux pages. Les données sont les six fichiers CSV décrits sur la [page Mission](../#les-données) ; toutes les requêtes de cette leçon sont dans [`cypher/02-loading.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/02-loading.cypher).

## Regarder un fichier avant de le charger

[`LOAD FROM`](https://docs.ladybugdb.com/cypher/query-clauses/load-from/) lit un fichier comme des lignes, sans rien créer, comme `OPENROWSET(BULK …)` dans SQL Server ou `FROM 'file.csv'` dans DuckDB ([lignes 5-6](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L5-L6)) :

```cypher
LOAD FROM 'data/pages.csv' (HEADER = true) RETURN * ORDER BY url LIMIT 3;
LOAD FROM 'data/pages.csv' (HEADER = true) RETURN locale, count(*) AS pages ORDER BY locale;
```

```text
┌─────────────┬────────┬───────────┬──────────────────┬───────┐
│ url         │ locale │ course    │ title            │ lines │
│ STRING      │ STRING │ STRING    │ STRING           │ INT64 │
├─────────────┼────────┼───────────┼──────────────────┼───────┤
│ /           │ en     │           │ learn            │ 90    │
│ /artifacts/ │ en     │ artifacts │ Artifacts        │ 32    │
│ /duckdb/    │ en     │ duckdb    │ DuckDB — Mission │ 70    │
└─────────────┴────────┴───────────┴──────────────────┴───────┘
┌────────┬───────┐
│ locale │ pages │
│ STRING │ INT64 │
├────────┼───────┤
│ en     │ 117   │
│ es     │ 101   │
│ fr     │ 101   │
└────────┴───────┘
```

`HEADER = true` indique que la première ligne contient les noms des colonnes ; sur ce fichier, la détection automatique l'aurait trouvé aussi. Les types sont devinés à partir du contenu : `lines` est un `INT64`. La page d'accueil `/` n'a pas de cours : son `course` est vide.

## Charger des nœuds : `COPY FROM`

Les tables, puis [`COPY`](https://docs.ladybugdb.com/import/csv/), le chargement en masse ([lignes 8-10](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L8-L10)) :

```cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/pages.csv' (HEADER = true);
```

```text
┌────────────────────────────────────────────────┬────────────────────────────┬───────────────────────┐
│ result                                         │ skipped_duplicate_pk_count │ skipped_duplicate_pks │
│ STRING                                         │ INT64                      │ STRING[]              │
├────────────────────────────────────────────────┼────────────────────────────┼───────────────────────┤
│ 319 tuples have been copied to the Page table. │ 0                          │ []                    │
└────────────────────────────────────────────────┴────────────────────────────┴───────────────────────┘
```

Les colonnes du fichier vont dans les colonnes de la table dans l'ordre ; les noms de l'en-tête n'ont pas besoin de correspondre. Les deux dernières colonnes du résultat comptent et listent les lignes sautées parce que leur clé était déjà dans la table, avec l'option `SKIP_DUPLICATE_PK = true` ([`constants.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L111), absente de la documentation). Lancé deux fois sur `pages.csv` avec cette option, `COPY` copie 0 ligne et liste les 319 URL ; sans elle, la deuxième exécution échoue, et la dernière section de cette leçon montre ce que cet échec fait à la table.

## Une relation a besoin de ses deux nœuds

Dans `links.csv`, chaque ligne est un lien : la page où il se trouve, la page vers laquelle il pointe, et l'ancre après `#`, s'il y en a une. Pour une table de relations, les deux premières colonnes sont les clés primaires des nœuds `FROM` et `TO` ; le reste remplit les colonnes propres à la relation ([lignes 14-16](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L14-L16)) :

```cypher
CALL threads = 1;
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true);
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
```

```text
Error: Copy exception: Unable to find primary key value /es/streeling/computer-science/cs-001-governing-agentic-loops/.
┌───────┐
│ links │
│ INT64 │
├───────┤
│ 0     │
└───────┘
```

Un lien pointe vers une page qui n'est pas dans `pages.csv`, et tout le `COPY` échoue : zéro lien chargé, pas même les lignes avant la mauvaise. `COPY` est tout ou rien, comme un `BULK INSERT` dans une transaction.

Pourquoi `CALL threads = 1` ? `COPY` lit le fichier avec plusieurs threads (24 sur ma machine, la [valeur par défaut](https://docs.ladybugdb.com/cypher/configuration/) étant tous les cœurs), et s'arrête à la première page manquante qu'*un thread* trouve. Deux exécutions ont donné deux pages différentes dans le message. Avec un seul thread, c'est toujours la première mauvaise ligne du fichier, la ligne 127, et la sortie peut être comparée en CI.

## Garder les lignes qui ne rentrent pas : `IGNORE_ERRORS`

Avec `IGNORE_ERRORS = true`, `COPY` saute les mauvaises lignes et garde un avertissement pour chacune ([lignes 19-21](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L19-L21)) :

```cypher
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL show_warnings() RETURN count(*) AS warnings;
CALL show_warnings() RETURN message, file_path, line_number ORDER BY line_number LIMIT 2;
```

```text
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ result                                                                                                            │
│ STRING                                                                                                            │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 648 tuples have been copied to the LINKS_TO table.                                                                │
│ 64 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 8 │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
┌──────────┐
│ warnings │
│ INT64    │
├──────────┤
│ 64       │
└──────────┘
┌──────────────────────────────────────────────────────────────────────────────────────────────────┬────────────────┬─────────────┐
│ message                                                                                          │ file_path      │ line_number │
│ STRING                                                                                           │ STRING         │ UINT64      │
├──────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┼─────────────┤
│ Unable to find primary key value /es/streeling/computer-science/cs-001-governing-agentic-loops/. │ data/links.csv │ 127         │
│ Unable to find primary key value /es/streeling/cybernetics/cyb-001-vsm-ai-governance-mapping/.   │ data/links.csv │ 129         │
└──────────────────────────────────────────────────────────────────────────────────────────────────┴────────────────┴─────────────┘
```

648 + 64 = 712, toutes les lignes du fichier. `show_warnings()` renvoie aussi l'identifiant de la requête et la ligne sautée elle-même. Les avertissements restent dans la connexion jusqu'à `CALL clear_warnings()`, dans la limite de `warning_limit`, 8 192 par défaut.

Les 64 messages contiennent l'URL manquante après `value `. Pour les regrouper par locale, découpe l'URL sur `/` ([lignes 24-28](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L24-L28)) :

```cypher
RETURN split_part('/es/streeling/', '/', 1) AS part_1, split_part('/es/streeling/', '/', 2) AS part_2;
CALL show_warnings()
WITH split_part(message, 'value ', 2) AS missing
RETURN split_part(missing, '/', 1) AS locale, split_part(missing, '/', 2) AS course, count(*) AS links
ORDER BY locale, course;
```

```text
┌────────┬───────────┐
│ part_1 │ part_2    │
│ STRING │ STRING    │
├────────┼───────────┤
│ es     │ streeling │
└────────┴───────────┘
┌────────┬───────────┬───────┐
│ locale │ course    │ links │
│ STRING │ STRING    │ INT64 │
├────────┼───────────┼───────┤
│ es     │ streeling │ 32    │
│ fr     │ streeling │ 32    │
└────────┴───────────┴───────┘
```

**La partie 1 de `/es/streeling/` est `es`** : le [`split_part`](https://docs.ladybugdb.com/cypher/expressions/text-functions/) de LadybugDB ignore la chaîne vide avant le `/` initial. DuckDB et PostgreSQL renvoient cette chaîne vide comme partie 1, et `es` comme partie 2. Ma première version de cette requête utilisait 2 et 3, et regroupait par cours sous une colonne nommée `locale` ; la première requête ci-dessus est là pour le détecter.

`WITH` passe les lignes d'une partie de la requête à la suivante, comme une CTE : ici, l'URL `missing` calculée une seule fois pour les deux appels à `split_part`.

Les 64 pages manquantes sont toutes des modules de l'Université Streeling en français et en espagnol. [Starlight](https://starlight.astro.build/guides/i18n/#fallback-content) sert la page anglaise à une URL traduite qui n'a pas de page propre, donc ces liens fonctionnent sur le site, mais il n'y a pas de fichier français ou espagnol pour ces modules, et pas de nœud.

## Fichiers et graphe dans la même requête

Vers quelles pages anglaises pointent ces liens français ? La requête relit `links.csv`, et confronte chaque ligne au graphe ([lignes 31-36](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L31-L36)) :

```cypher
LOAD FROM 'data/links.csv' (HEADER = true)
WITH `from`, `to`
WHERE `to` STARTS WITH '/fr/' AND NOT EXISTS { MATCH (p:Page) WHERE p.url = `to` }
MATCH (en:Page) WHERE en.url = substring(`to`, 4, size(`to`))
RETURN DISTINCT en.url AS english_page
ORDER BY english_page;
```

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ english_page                                                            │
│ STRING                                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│ /streeling/computer-science/cs-001-governing-agentic-loops/             │
│ /streeling/cybernetics/cyb-001-vsm-ai-governance-mapping/               │
│ /streeling/cybernetics/cyb-002-active-dampening-cross-repo-oscillation/ │
│ /streeling/cybernetics/cyb-003-measuring-variety-ratio-quantitatively/  │
│ /streeling/guitar-alchemist-academy/gaa-002-training-your-ear/          │
│ /streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/  │
│ /streeling/information-theory/inf-001-entropy-of-governance/            │
│ /streeling/music/mus-002-beyond-tonality/                               │
│ /streeling/music/mus-003-functional-harmony/                            │
│ /streeling/music/mus-004-rhythm-and-groove/                             │
│ /streeling/music/mus-005-jazz-harmony/                                  │
│ /streeling/music/mus-006-the-scale-universe/                            │
│ /streeling/musicology/mcl-002-musical-form/                             │
│ /streeling/network-science/net-001-scale-free-tool-networks/            │
│ /streeling/psychohistory/psy-002-governance-phase-transitions/          │
│ /streeling/semiotics/sem-001-signs-in-governance/                       │
└─────────────────────────────────────────────────────────────────────────┘
```

Trois choses dans cette requête :

- Les accents graves délimitent un nom, comme les crochets en T-SQL. `from` et `to` fonctionneraient sans eux dans cette requête, mais ce sont des mots-clés de `CREATE REL TABLE … (FROM Page TO Page)`, et les délimiter évite de se poser la question.
- `substring` compte à partir de 1, comme SQL : `substring('/fr/streeling/…', 4, …)` commence au `/` après `fr`.
- Une requête peut partir d'un fichier et continuer dans le graphe : `LOAD FROM`, puis `WITH … WHERE`, puis `MATCH`. Pour chaque ligne du fichier restante après le filtre, `MATCH` trouve la page anglaise.

## Des tables de nœuds à partir d'une sous-requête

Les liens externes, les 3 712 lignes de `external_links.csv` (`from`, `url`, `domain`), deviennent un nœud `Domain` par site et une relation `CITES` par page et site, avec le nombre de liens comme propriété. [`COPY` peut lire une sous-requête](https://docs.ladybugdb.com/import/copy-from-subquery/) au lieu d'un fichier ([lignes 39-41](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L39-L41)) :

```cypher
CREATE NODE TABLE Domain(name STRING PRIMARY KEY);
CREATE REL TABLE CITES(FROM Page TO Domain, links INT64);
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true) RETURN DISTINCT domain);
```

```text
Error: Copy exception: Error in file data/external_links.csv on line 591: expected 3 values per row, but got more. Line/record containing the error: '/es/java-for-csharp/02-types-and-operators/,"https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#addExact(int,int)",docs.oracle.com'
```

La ligne 591 est la première ligne du fichier avec des guillemets : le module `csv` de Python ne met entre guillemets que les champs qui en ont besoin, comme cette URL avec une virgule dans `addExact(int,int)`. Par défaut, LadybugDB détecte le délimiteur, le caractère de guillemet et le caractère d'échappement à partir des 256 premières lignes du fichier ([`auto_detect` et `sample_size`](https://docs.ladybugdb.com/import/csv/), [`constants.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L138-L144)). Il n'a vu aucun guillemet dans ces lignes, a lu le fichier sans, et a trouvé quatre champs à la ligne 591. Indique-le explicitement ([lignes 44-46](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L44-L46)) :

```cypher
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN DISTINCT domain);
COPY CITES FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN `from`, domain, count(*));
MATCH (d:Domain) RETURN count(*) AS domains;
```

```text
┌─────────────────────────────────────────────────┬────────────────────────────┬───────────────────────┐
│ result                                          │ skipped_duplicate_pk_count │ skipped_duplicate_pks │
│ STRING                                          │ INT64                      │ STRING[]              │
├─────────────────────────────────────────────────┼────────────────────────────┼───────────────────────┤
│ 85 tuples have been copied to the Domain table. │ 0                          │ []                    │
└─────────────────────────────────────────────────┴────────────────────────────┴───────────────────────┘
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 1054 tuples have been copied to the CITES table. │
└──────────────────────────────────────────────────┘
┌─────────┐
│ domains │
│ INT64   │
├─────────┤
│ 85      │
└─────────┘
```

Les colonnes de la sous-requête jouent le rôle de celles du fichier : `from` et `domain` sont les clés des deux nœuds, `count(*)` remplit `links`. 1 054 paires d'une page et d'un site.

## Quels sites citent les pages des cours

[Lignes 47-51](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L47-L51) :

```cypher
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en'
RETURN d.name AS domain, count(*) AS pages, sum(c.links) AS links
ORDER BY links DESC, domain
LIMIT 8;
```

```text
┌─────────────────────┬───────┬────────┐
│ domain              │ pages │ links  │
│ STRING              │ INT64 │ INT128 │
├─────────────────────┼───────┼────────┤
│ learn.microsoft.com │ 44    │ 198    │
│ doc.rust-lang.org   │ 16    │ 192    │
│ github.com          │ 88    │ 189    │
│ docs.oracle.com     │ 28    │ 171    │
│ duckdb.org          │ 9     │ 140    │
│ docs.github.com     │ 12    │ 51     │
│ openjdk.org         │ 15    │ 49     │
│ docs.rs             │ 5     │ 30     │
└─────────────────────┴───────┴────────┘
```

Une variable de relation, `c`, donne accès aux propriétés de la relation comme une variable de nœud. `sum` d'un `INT64` renvoie un `INT128`, un type plus large. GitHub est cité par le plus de pages, Microsoft Learn par le plus de liens.

## Un bug de la 0.20.4 : `count(DISTINCT …)` avant `sum(…)`

Les mêmes agrégats, avec `count(DISTINCT p)` au lieu de `count(*)`, pour deux domaines ([lignes 54-61](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L54-L61)) :

```cypher
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en' AND d.name IN ['duckdb.org', 'openjdk.org']
RETURN d.name AS domain, count(DISTINCT p) AS pages, sum(c.links) AS links
ORDER BY domain;
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en' AND d.name IN ['duckdb.org', 'openjdk.org']
RETURN d.name AS domain, sum(c.links) AS links, count(DISTINCT p) AS pages
ORDER BY domain;
```

```text
┌─────────────┬───────┬────────┐
│ domain      │ pages │ links  │
│ STRING      │ INT64 │ INT128 │
├─────────────┼───────┼────────┤
│ duckdb.org  │ 9     │        │
│ openjdk.org │ 15    │        │
└─────────────┴───────┴────────┘
┌─────────────┬────────┬───────┐
│ domain      │ links  │ pages │
│ STRING      │ INT128 │ INT64 │
├─────────────┼────────┼───────┤
│ duckdb.org  │ 140    │ 9     │
│ openjdk.org │ 49     │ 15    │
└─────────────┴────────┴───────┘
```

Les deux requêtes ne diffèrent que par l'ordre des colonnes. Dans la première, `links` est `NULL` (une cellule vide) pour les deux domaines ; dans la seconde, il vaut 140 et 49, les nombres de la requête précédente. Il n'y a ni erreur ni avertissement : un résultat faux ressemble à un résultat juste. Le [journal](../journal/) garde les détails. En attendant un correctif, place `count(DISTINCT …)` en dernier, ou compare un agrégat avec une deuxième requête quand le résultat compte.

## JSON : l'extension json

Les exécutions de CI du cours DuckDB sont dans un fichier JSON ([lignes 64-66](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L64-L66)) :

```cypher
LOAD FROM '../duckdb/data/runs.json' RETURN count(*);
LOAD json;
LOAD FROM '../duckdb/data/runs.json' RETURN conclusion, count(*) AS runs ORDER BY runs DESC, conclusion;
```

```text
Error: Binder exception: Cannot load from file type json. If this file type is part of a lbug extension please load the extension then try again.
┌──────────────────────────────────┐
│ result                           │
│ STRING                           │
├──────────────────────────────────┤
│ Extension: json has been loaded. │
└──────────────────────────────────┘
┌─────────────────┬───────┐
│ conclusion      │ runs  │
│ STRING          │ INT64 │
├─────────────────┼───────┤
│ success         │ 104   │
│ failure         │ 16    │
│ cancelled       │ 4     │
│ startup_failure │ 1     │
└─────────────────┴───────┘
```

La prise en charge de JSON est une [extension](https://docs.ladybugdb.com/extensions/json/), en deux étapes :

- `INSTALL json;` la télécharge une fois par machine, depuis `https://extension.ladybugdb.com/`. Sur ma machine, elle a atterri dans `~/.lbdb/extension/0.20.0/win_amd64/json/libjson.lbug_extension`. `check.sh` la lance avant les scripts, parce que son message diffère la première fois (`Extension: json installed from the repo: https://extension.ladybugdb.com/.`) et les suivantes (`Extension: json is already installed.`).
- `LOAD json;` la charge dans la base de données courante, à chaque démarrage de la CLI.

125 exécutions, les mêmes nombres que dans le cours DuckDB. Les objets du tableau JSON deviennent des lignes, leurs champs des colonnes.

## Un bug de la 0.20.4 : un `COPY` échoué vide l'index de clé primaire

Un dernier `COPY` d'une page qui est déjà là, [lignes 69-72](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L69-L72) :

```cypher
COPY Page FROM (LOAD FROM 'data/pages.csv' (HEADER = true) WHERE url = '/duckdb/' RETURN *);
MATCH (p:Page) RETURN count(*) AS pages;
MATCH (p:Page {url: '/duckdb/'}) RETURN count(*) AS found_by_key;
MATCH (p:Page) WHERE lower(p.url) = '/duckdb/' RETURN count(*) AS found_by_scan;
```

```text
Error: Copy exception: Found duplicated primary key value /duckdb/, which violates the uniqueness constraint of the primary key column.
┌───────┐
│ pages │
│ INT64 │
├───────┤
│ 319   │
└───────┘
┌──────────────┐
│ found_by_key │
│ INT64        │
├──────────────┤
│ 0            │
└──────────────┘
┌───────────────┐
│ found_by_scan │
│ INT64         │
├───────────────┤
│ 1             │
└───────────────┘
```

L'erreur est attendue, et les 319 pages sont toujours là. Mais la page ne peut plus être trouvée par sa clé : `{url: '/duckdb/'}` et `WHERE p.url = '/duckdb/'` passent tous deux par l'index de clé primaire, et ne trouvent rien. `lower(p.url)` ne peut pas utiliser l'index, lit tous les nœuds, et trouve la page. Ce n'est pas seulement `/duckdb/` : après le `COPY` échoué, aucune des 319 clés n'est trouvée, et un `CREATE` avec une clé existante réussit, en créant un doublon.

Dans un fichier de base de données, la même séquence fonctionne : l'index trouve toujours la page après le `COPY` échoué, et le `CREATE` est rejeté. Les scripts de ce cours utilisent une base de données en mémoire, où cela casse. Le [journal](../journal/) contient la reproduction minimale, avec trois lignes, et une variante pire qui casse aussi les fichiers de base de données, quand les nœuds ont été créés avec `CREATE` plutôt que chargés avec `COPY`. En attendant un correctif, considère un `COPY` échoué dans une table de nœuds comme la fin de cette table : recrée-la.

## À retenir

- `LOAD FROM` lit un fichier comme des lignes ; `COPY FROM` charge en masse un fichier ou une sous-requête dans une table de nœuds ou de relations.
- Pour une table de relations, les deux premières colonnes sont les clés des nœuds ; un nœud manquant fait échouer tout le `COPY`.
- `IGNORE_ERRORS = true` garde les mauvaises lignes comme avertissements, que `CALL show_warnings()` renvoie comme des lignes.
- Le dialecte CSV est détecté à partir des 256 premières lignes : passe `QUOTE`, `DELIM` et `ESCAPE` quand tu les connais.
- `split_part` compte les parties différemment de SQL, `count(DISTINCT …)` avant `sum(…)` renvoie `NULL`, et un `COPY` échoué vide l'index de clé d'une table en mémoire dans la 0.20.4 : vérifie autrement les résultats qui comptent.
- JSON a besoin de `INSTALL json` une fois et de `LOAD json` à chaque session.

## Exercices

Les solutions sont dans [`cypher/02-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/02-exercises.cypher), vérifié par la CI. Elles partent des tables `Page`, `LINKS_TO`, `Domain` et `CITES`, chargées comme dans cette leçon.

1. Quelles pages anglaises n'ont pas de version française, par cours ?

<details>
<summary>Solution</summary>

Tiré de [`02-exercises.cypher`, lignes 13-16](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L13-L16) :

```cypher
MATCH (en:Page)
WHERE en.locale = 'en' AND NOT EXISTS { MATCH (fr:Page) WHERE fr.url = '/fr' + en.url }
RETURN en.course, count(*) AS pages
ORDER BY pages DESC, en.course;
```

```text
┌───────────┬───────┐
│ en.course │ pages │
│ STRING    │ INT64 │
├───────────┼───────┤
│ streeling │ 16    │
└───────────┴───────┘
```

Les 16 modules Streeling de la leçon, et rien d'autre : chaque page de cours a son miroir français. `+` concatène des chaînes.

</details>

2. Combien de liens ont une ancre (une partie `#`) ? Compare `anchor IS NULL` et `anchor = ''`.

<details>
<summary>Solution</summary>

Tiré de [`02-exercises.cypher`, lignes 19-21](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L19-L21) :

```cypher
MATCH ()-[l:LINKS_TO]->()
RETURN l.anchor IS NULL AS no_anchor, l.anchor = '' AS empty_anchor, count(*) AS links
ORDER BY no_anchor;
```

```text
┌───────────┬──────────────┬───────┐
│ no_anchor │ empty_anchor │ links │
│ BOOL      │ BOOL         │ INT64 │
├───────────┼──────────────┼───────┤
│ False     │ False        │ 3     │
│ True      │              │ 645   │
└───────────┴──────────────┴───────┘
```

Trois liens ont une ancre. Pour les 645 autres, le champ vide du fichier CSV est devenu `NULL`, pas `''` : l'option `NULL_STRINGS` de `COPY` vaut par défaut la chaîne vide. Donc `l.anchor = ''` est `NULL` (la cellule vide), et un filtre `WHERE l.anchor = ''` ne trouverait rien. Passe `NULL_STRINGS = ['NA']`, ou toute valeur que le fichier n'utilise pas, pour garder les chaînes vides.

</details>

3. Quels sites sont cités par le plus de cours anglais ?

<details>
<summary>Solution</summary>

Tiré de [`02-exercises.cypher`, lignes 24-28](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L24-L28) :

```cypher
MATCH (p:Page)-[:CITES]->(d:Domain)
WHERE p.locale = 'en'
RETURN d.name AS domain, count(DISTINCT p.course) AS courses
ORDER BY courses DESC, domain
LIMIT 5;
```

```text
┌──────────────────────┬─────────┐
│ domain               │ courses │
│ STRING               │ INT64   │
├──────────────────────┼─────────┤
│ github.com           │ 6       │
│ learn.microsoft.com  │ 5       │
│ www.nuget.org        │ 4       │
│ central.sonatype.com │ 3       │
│ docs.oracle.com      │ 3       │
└──────────────────────┴─────────┘
```

`count(DISTINCT p.course)` compte des cours, pas des pages. Seul dans le `RETURN`, il ne déclenche pas le bug de cette leçon, qui a besoin d'un `sum` après lui. La page d'accueil, la méthode et la page des artifacts comptent ici comme des cours (`''`, `method` et `artifacts`), c'est pourquoi GitHub atteint 6.

</details>

## Sources

- [`LOAD FROM`](https://docs.ladybugdb.com/cypher/query-clauses/load-from/)
- [Import CSV](https://docs.ladybugdb.com/import/csv/) : options, `IGNORE_ERRORS`, détection du dialecte
- [`COPY FROM` une sous-requête](https://docs.ladybugdb.com/import/copy-from-subquery/)
- [Configuration](https://docs.ladybugdb.com/cypher/configuration/) : `threads`, `warning_limit`
- [Fonctions de texte](https://docs.ladybugdb.com/cypher/expressions/text-functions/) et [fonctions d'agrégation](https://docs.ladybugdb.com/cypher/expressions/aggregate-functions/)
- [Extension JSON](https://docs.ladybugdb.com/extensions/json/)
- Code source de LadybugDB 0.20.4 : [constantes CSV](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L138-L144), [erreurs du lecteur CSV](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/processor/operator/persistent/reader/csv/driver.cpp#L38)
