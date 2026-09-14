---
title: Journal
description: Notes de progression datées — données, exécutions de CI, bugs trouvés dans LadybugDB 0.20.4 et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Données : les pages, les liens et l'historique Git de ce dépôt au commit `cbcbb42`, et les exécutions de CI du cours DuckDB
- [x] CI : le Cypher de chaque leçon comparé à sa sortie attendue sur trois OS, et une vérification croisée en SQL avec DuckDB
- [x] Leçon 1 : un premier graphe
- [x] Leçon 2 : charger des fichiers
- [x] Leçon 3 : chemins
- [x] Leçon 4 : l'historique Git et les exécutions de CI en graphe
- [ ] Leçon 5 : LadybugDB depuis C#
- [ ] Leçon 6 : LadybugDB depuis Java
- [ ] Leçon 7 : algorithmes de graphe et recherche plein texte
- [ ] Leçon 8 : persistance, transactions et concurrence

## 2026-09-14 — Les données

- [`extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/extract.py), lancé avec le commit `cbcbb42` en argument, lit les fichiers Markdown et l'historique Git à ce commit, avec `git ls-tree`, `git show` et `git log`, et non la copie de travail : les fichiers CSV ne changent pas quand le site change.
- 319 pages, 712 liens internes, 3 712 liens externes, 74 commits, 73 liens de parenté et 1 019 fichiers modifiés.
- Les exécutions sont le `runs.json` du [cours DuckDB](../../duckdb/journal/), 125 exécutions exportées vers 14:04 UTC, réutilisées telles quelles.
- Les dates des commits gardent leur décalage `-04:00` dans `commits.csv` ; LadybugDB les stocke en UTC.

## 2026-09-14 — Installer LadybugDB

- Windows : `lbug_cli-windows-x86_64.zip` de la release v0.20.4 ne contient que `lbug.exe`, 14 772 736 octets. `lbug --version` affiche `Lbug 0.20.4`.
- CI : le workflow télécharge l'asset de release de chaque OS (`linux-x86_64`, `windows-x86_64`, `osx-arm64`) et ajoute le dossier à `GITHUB_PATH`. Il installe DuckDB 1.5.5 de la même façon, pour la vérification croisée en SQL de la leçon 3.
- `INSTALL json` a mis l'extension dans `~/.lbdb/extension/0.20.0/win_amd64/json/` : le dossier porte le nom de 0.20.0, pas de 0.20.4. L'historique du shell se trouve dans `~/.lbdb/history.txt`.
- Dans une fenêtre Git Bash, `lbug.exe` ne trouve pas les chemins `/c/Users/…`, et les barres obliques inverses dans une chaîne Cypher sont des caractères d'échappement : les scripts utilisent des chemins relatifs à `code/ladybugdb`, et `C:/…` fonctionne quand il faut un chemin complet.

## 2026-09-14 — La CI

- La CLI se termine avec 0 même quand une requête échoue, et affiche les erreurs sur la sortie standard ([`embedded_shell.cpp`, lignes 608-611](https://github.com/LadybugDB/ladybug/blob/v0.20.4/tools/shell/embedded_shell.cpp#L608-L611)) : `check.sh` compare toute la sortie, erreurs comprises, donc une erreur inattendue fait quand même échouer le job.
- La barre de progression écrit des codes d'échappement même quand la sortie va vers un pipe : `check.sh` passe `--no_progress_bar` et `--no_stats`.
- Premier push : échec sous Linux, succès sous Windows et macOS. Supprimer une leçon qui avait encore des relations donnait un message nommant `HAS_LESSON` sous Windows et macOS, et `LINKS_TO` sous Linux : l'exécuteur nomme la première table de relations qu'il vérifie ([`delete_executor.cpp`, lignes 33-42](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/processor/operator/persistent/delete_executor.cpp#L33-L42)), et leur ordre diffère. La leçon 1 supprime désormais une leçon dont toutes les relations sont dans une seule table.
- Même push : `ACYCLIC` a donné 14 chemins sous Windows et 29 sous Linux et macOS (voir plus bas). La leçon 3 utilise `is_acyclic(p)`, identique sur les trois.
- Deux sorties pouvaient varier d'une exécution à l'autre : un `LOAD FROM … LIMIT 3` sans `ORDER BY`, et la première clé manquante signalée par un `COPY` en échec, qui dépend du thread qui la trouve. Les scripts trient, et exécutent `CALL threads = 1` avant ce `COPY`.
- Une marche `LINKS_TO*` sans borne sur le graphe du site a tourné plus de cinq minutes avant que je l'arrête ; `* SHORTEST` sur le même motif répond immédiatement.

## 2026-09-14 — Surprises en écrivant les leçons 1-4

- `MERGE` fait correspondre le motif entier : sans la clé primaire, il échoue à la liaison, et avec la clé et une autre propriété qui diffère, il tente de créer le nœud et échoue sur la clé en double.
- `:schema` affiche des instructions `CREATE`, avec `MANY_MANY` sur chaque table de relations.
- L'en-tête CSV est détecté sans `HEADER = true`, et ses noms n'ont pas besoin de correspondre aux colonnes de la table.
- `SKIP_DUPLICATE_PK = true` fonctionne sur un `COPY` depuis un fichier ([`constants.h`, ligne 111](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L111)) mais ne figure pas dans la documentation, et n'est pas pris en charge sur un `COPY` depuis une sous-requête ([`bind_copy_from.cpp`, ligne 149](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/binder/bind/copy/bind_copy_from.cpp#L149)).
- Le détecteur de format CSV lit les 256 premières lignes ([`constants.h`, ligne 144](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L144)) ; un champ entre guillemets plus bas fait échouer le `COPY`, sauf si `QUOTE` est précisé.
- Les champs CSV vides deviennent `NULL` par défaut ; `NULL_STRINGS = ['NA']` les garde en `''`.
- `split_part('/es/streeling/', '/', 1)` renvoie `es` : la partie vide avant le séparateur initial est ignorée. DuckDB renvoie `''`.
- `nodes(e)` sur une liste de relations ne renvoie que les nœuds intermédiaires ; les listes sont indexées à partir de 1 ; `ORDER BY` sur un `STRING[]` échoue, un cast en `STRING` fonctionne.
- Les motifs de longueur variable sont des marches par défaut, donc deux relations `CHANGED` d'un même motif peuvent être la même.
- La borne supérieure d'un motif de longueur variable est limitée à 30 ([`client_config.h`, ligne 32](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/main/client_config.h#L32)) jusqu'à un `CALL var_length_extend_max_depth = …` ; un motif qui a besoin de plus ne renvoie rien, sans erreur.
- Les nombres de chemins à 4 liens de la leçon 3 ont été vérifiés deux fois hors de LadybugDB : un script Python sur `links.csv` (marches 1, 5, 12, 29 ; pistes 26 ; acycliques 1, 5, 9, 10), et une CTE récursive dans DuckDB (marches 1, 5, 12, 29), que la CI exécute.

## 2026-09-14 — Bugs trouvés dans la 0.20.4

Cinq bugs silencieux : aucune erreur, un résultat faux. Aucun n'avait d'issue sur le [tracker de LadybugDB](https://github.com/LadybugDB/ladybug/issues) quand j'ai cherché le 2026-09-14 ; je ne les ai pas signalés. Chaque reproduction ci-dessous s'exécute dans une base de données en mémoire vide (`lbug -m csv < repro.cypher`) et n'a été exécutée que sous Windows, sauf mention contraire.

### 1. `COPY` depuis une sous-requête JSON avec `MATCH` relie les mauvais nœuds

Avec `r.json` contenant `[{"id":1,"k":"a"},{"id":2,"k":"b"},{"id":3,"k":"c"}]` :

```cypher
LOAD json;
CREATE NODE TABLE K(k STRING PRIMARY KEY);
CREATE NODE TABLE R(id INT64 PRIMARY KEY);
CREATE REL TABLE ON_K(FROM R TO K);
CREATE (:K {k: 'a'}), (:K {k: 'b'}), (:K {k: 'c'}), (:R {id: 1}), (:R {id: 2}), (:R {id: 3});
COPY ON_K FROM (LOAD FROM 'r.json' WITH id, k MATCH (x:K) WHERE x.k = k RETURN id, k);
MATCH (r:R)-[:ON_K]->(x:K) RETURN r.id, x.k ORDER BY x.k;
```

```text
3 tuples have been copied to the ON_K table.
r.id,x.k
1,a
1,b
1,c
```

J'attendais `1,a`, `2,b`, `3,c`, ce que donne le même `COPY` depuis un fichier CSV avec les mêmes lignes. Avec `(IGNORE_ERRORS = true)` en plus, les trois relations vont plutôt vers `a` : `1,a`, `2,a`, `3,a`. La leçon 4 l'a rencontré avec 123 exécutions : les 123 relations partaient toutes de la même exécution ; filtrer avec `WHERE` sans `MATCH` fonctionne.

`IGNORE_ERRORS = true` sur un `COPY` depuis une sous-requête, quand une clé manque, échoue avec `Error: bad variant access` au lieu d'ignorer la ligne.

### 2. `count(DISTINCT …)` avant `sum(…)` rend la somme `NULL`

```cypher
CREATE NODE TABLE P(id INT64 PRIMARY KEY, g STRING, n INT64);
CREATE (:P {id: 1, g: 'x', n: 10}), (:P {id: 2, g: 'x', n: 20}), (:P {id: 3, g: 'y', n: 5});
MATCH (p:P) RETURN p.g, count(DISTINCT p) AS ps, sum(p.n) AS total ORDER BY p.g;
MATCH (p:P) RETURN p.g, sum(p.n) AS total, count(DISTINCT p) AS ps ORDER BY p.g;
```

```text
p.g,ps,total
x,2,""
y,1,""
p.g,total,ps
x,30,2
y,5,1
```

Les mêmes agrégats, dans l'autre ordre, donnent les bons totaux.

### 3. `ACYCLIC` garde des chemins qui répètent un nœud

Trois nœuds, `a` et `b` reliés dans les deux sens, `b` relié à `c` :

```cypher
CREATE NODE TABLE V(id STRING PRIMARY KEY);
CREATE REL TABLE E(FROM V TO V);
CREATE (:V {id: 'a'}), (:V {id: 'b'}), (:V {id: 'c'});
MATCH (x:V {id: 'a'}), (y:V {id: 'b'}) CREATE (x)-[:E]->(y), (y)-[:E]->(x);
MATCH (x:V {id: 'b'}), (y:V {id: 'c'}) CREATE (x)-[:E]->(y);
MATCH p = (x:V {id: 'a'})-[e:E* ACYCLIC 1..4]->(y:V {id: 'c'}) RETURN properties(nodes(p), 'id') AS path;
MATCH p = (x:V {id: 'a'})-[e:E*1..4]->(y:V {id: 'c'}) WHERE is_acyclic(p) RETURN properties(nodes(p), 'id') AS path;
```

```text
path
"[a,b,a,b,c]"
"[a,b,c]"
path
"[a,b,c]"
```

`[a,b,a,b,c]` passe deux fois par `b`. La vérification `ACYCLIC` se trouve dans [`output_writer.cpp`, ligne 280](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/function/gds/output_writer.cpp#L280) ; je n'ai pas trouvé la cause. Sur le graphe du site de la leçon 3, `LINKS_TO* ACYCLIC 1..4` depuis l'index de GitHub Actions jusqu'à sa leçon 7 a renvoyé 14 chemins sous Windows, dont un qui passe deux fois par la même leçon, et 29, toutes les marches, sur les runners Linux et macOS. Une énumération en Python donne 25 chemins dont les nœuds intermédiaires sont distincts, et 10 avec la définition de `is_acyclic`, les deux extrémités comprises.

### 4. Un `COPY` en échec dans une table de nœuds la corrompt

Chargée avec `COPY`, puis un `COPY` qui échoue sur une clé en double, avec `n.csv` contenant l'en-tête `k` et les lignes `a`, `b`, `c` :

```cypher
CREATE NODE TABLE N(k STRING PRIMARY KEY);
COPY N FROM 'n.csv' (HEADER = true);
COPY N FROM (RETURN 'a' AS k);
MATCH (n:N {k: 'b'}) RETURN count(*) AS b_by_key;
CREATE (:N {k: 'b'});
MATCH (n:N) RETURN n.k ORDER BY n.k;
```

En mémoire :

```text
Error: Copy exception: Found duplicated primary key value a, which violates the uniqueness constraint of the primary key column.
b_by_key
0
n.k
a
a
b
c
```

`b` est là, mais sa clé ne trouve rien ; le `CREATE` d'une clé existante réussit, et le nouveau nœud contient `a`, la clé que le `COPY` en échec a rejetée, au lieu de `b`. Dans un fichier de base de données (`lbug -m csv d/x.lbdb`), cette séquence fonctionne : `b_by_key` vaut 1 et le `CREATE` échoue avec `Runtime exception: Found duplicated primary key value b`.

Quand les trois nœuds sont créés avec `CREATE` au lieu de `COPY`, le `COPY` en échec casse aussi un fichier de base de données : après lui, `CREATE (:N {k: 'z', v: 26})` sur une table `N(k STRING PRIMARY KEY, v INT64)` ajoute un nœud qui se relit comme `a,9`, la ligne rejetée, en mémoire comme sur disque.

### 5. Grouper par une sous-requête `COUNT` fait disparaître le groupe de 0

```cypher
CREATE NODE TABLE C(id INT64 PRIMARY KEY);
CREATE REL TABLE PARENT(FROM C TO C);
CREATE (:C {id: 1}), (:C {id: 2}), (:C {id: 3});
MATCH (a:C {id: 2}), (b:C {id: 1}) CREATE (a)-[:PARENT]->(b);
MATCH (a:C {id: 3}), (b:C {id: 2}) CREATE (a)-[:PARENT]->(b);
MATCH (c:C) RETURN c.id, COUNT { MATCH (c)-[:PARENT]->(:C) } AS parents ORDER BY c.id;
MATCH (c:C) RETURN COUNT { MATCH (c)-[:PARENT]->(:C) } AS parents, count(*) AS cs ORDER BY parents;
```

```text
c.id,parents
1,0
2,1
3,1
parents,cs
1,2
```

La sous-requête renvoie 0 pour le nœud 1, mais la requête groupée n'a pas de ligne `0,1`. `OPTIONAL MATCH` avec `count(…)` donne les deux groupes (leçon 4).

## À vérifier

- Le script d'installation (`curl -s https://install.ladybugdb.com | bash`) et `brew install ladybug` : pas exécutés pour ce cours.
- Les reproductions minimales n'ont été exécutées que sous Windows. Les scripts du cours qui montrent les bugs 1, 2, 4 et 5 sur les données du site donnent la même sortie sur les trois runners de la CI.
- Si ces bugs sont déjà corrigés sur la branche principale de LadybugDB, après la 0.20.4.
