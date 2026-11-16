---
title: 9. Un laboratoire de graphe — traductions, cycles de prérequis, atteignabilité bornée
description: Un laboratoire sur quelques pages inventées, chaque prédiction écrite avant l'exécution — un COPY échoué et l'état qu'il laisse, les traductions manquantes trouvées par identité de contenu plutôt que par titre, des cycles de prérequis tenus à l'écart de la navigation, ce qu'une borne de profondeur prouve et ne prouve pas, et un témoin de cycle que la 0.20.4 affiche à l'envers.
sidebar:
  order: 9
---

Les leçons [2](../02-loading/) et [3](../03-paths/) interrogeaient les vraies pages du site. Ce laboratoire utilise une douzaine de pages inventées sous `/lab/`, assez peu pour que chaque réponse attendue puisse être écrite **avant** l'exécution de la requête. Les prédictions sont dans [`data/lab/preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/lab/preregistration.md), haché avant la première exécution, avec un addendum daté pour les deux endroits où cette exécution a contredit le fichier. Les requêtes sont dans [`cypher/09-graph-lab.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/09-graph-lab.cypher).

Les sorties ci-dessous sont ce qu'affiche `lbug --no_progress_bar --no_stats --mode csv`, la commande exacte que `check.sh` lance avant de comparer à [`cypher/expected/09-graph-lab.csv`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/expected/09-graph-lab.csv). Sans les deux premières options, `--mode csv` affiche aussi une bannière d'ouverture, des barres de progression, le nombre de tuples et les temps, et la sortie ne correspondrait plus. Chaque script tourne dans une nouvelle base en mémoire : chaque exécution part de zéro.

Le schéma est celui du cours. `Page` a son URL pour clé primaire, et `LINKS_TO` contient les liens de navigation. Le laboratoire ajoute une table de relations, `REQUIRES`, pour les prérequis. **Les trois relations restent séparées :**
- la navigation, c'est `LINKS_TO` ;
- les prérequis, c'est `REQUIRES` ;
- la traduction n'est pas du tout une relation.

Une remarque sur la portabilité : les motifs `MATCH` sont du [Cypher](https://opencypher.org/), mais `CREATE NODE TABLE`, `CREATE REL TABLE` et `COPY` sont les instructions de schéma et d'import de LadybugDB, pas de l'openCypher. `CALL` lui-même est la clause d'[appel de procédure](https://s3.amazonaws.com/artifacts.opencypher.org/openCypher9.pdf) d'openCypher ; ce qui est propre à LadybugDB, c'est ce que cette leçon appelle avec : `CALL threads = 1` règle une [option de configuration](https://docs.ladybugdb.com/cypher/configuration/), et `show_warnings()` est l'une des [fonctions intégrées](https://docs.ladybugdb.com/cypher/query-clauses/call/) de LadybugDB. La [page des différences](https://docs.ladybugdb.com/cypher/difference/) liste ce qui change par rapport à Neo4j.

## Le traceur : trois pages, deux liens

La première exécution vérifie toute la boucle : deux fichiers, puis une question dont la réponse est connue.

```cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/lab/tracer-pages.csv' (HEADER = true);
COPY LINKS_TO FROM 'data/lab/tracer-links.csv' (HEADER = true);
MATCH (a:Page {url: '/fr/lab/intro/'})-[e:LINKS_TO*1..3]->(b:Page)
WHERE b.locale = 'en'
RETURN length(e) AS links, properties(nodes(e), 'url') AS between, b.url AS reached;
```

```text
result,skipped_duplicate_pk_count,skipped_duplicate_pks
3 tuples have been copied to the Page table.,0,[]
result
2 tuples have been copied to the LINKS_TO table.
links,between,reached
2,[/fr/lab/paths/],/lab/paths/
```

Il y a une marche de l'introduction française vers une page anglaise : deux liens, en passant par `/fr/lab/paths/`. Comme dans la [leçon 2](../02-loading/), `HEADER = true` est explicite, et dans un fichier de relations les deux premières colonnes sont les clés des pages `FROM` et `TO` ([Import CSV](https://docs.ladybugdb.com/import/csv/)).

## Une extrémité absente, et ce qui reste après

La leçon 2 a montré qu'une seule page absente fait échouer tout un `COPY`. Ici la question est plus étroite : **après l'échec, que contient la table ?** Une garantie transactionnelle y répondrait pour toutes les versions ; une mesure n'y répond que pour la 0.20.4. `links-missing.csv` contient une bonne ligne et une ligne qui pointe vers `/es/lab/paths/`, qui n'est pas une page.

```cypher
CALL threads = 1;
COPY LINKS_TO FROM 'data/lab/links-missing.csv' (HEADER = true);
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
MATCH (p:Page {url: '/lab/paths/'}) RETURN count(*) AS found_by_key;
COPY LINKS_TO FROM 'data/lab/links-missing.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL show_warnings() RETURN message, line_number;
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
```

```text
Error: Copy exception: Unable to find primary key value /es/lab/paths/.
links
2
found_by_key
1
result
1 tuples have been copied to the LINKS_TO table.
1 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 9
message,line_number
Unable to find primary key value /es/lab/paths/.,3
links
3
```

**Après l'échec :**
- Il reste les 2 liens du traceur : la bonne ligne du fichier échoué n'a pas été ajoutée.
- La page est toujours trouvée par sa clé.

Le [bug d'index de la leçon 2](../02-loading/#un-bug-de-la-0204--un-copy-échoué-vide-lindex-de-clé-primaire) suivait un `COPY` échoué dans une table de *nœuds*. Celui-ci visait une table de relations, et n'a pas cassé l'index des nœuds.

Avec `IGNORE_ERRORS = true`, la bonne ligne entre et la mauvaise devient un avertissement, à la ligne 3, l'en-tête étant la ligne 1. C'est un chargement tolérant, voulu : l'avertissement dit ce qui a été écarté, et ne rend pas le fichier correct.

## Traductions manquantes : l'identité, c'est l'URL, pas le titre

`translations-pages.csv` contient trois pages anglaises. `/lab/intro/` et `/lab/cycles/` ont leurs pages française et espagnole, tandis que `/lab/paths/` n'a que la française. Une page française ou espagnole porte son URL anglaise après `/fr` ou `/es`, ce qui donne à chaque groupe de traductions une **identité de contenu**. La requête construit l'URL sœur pour chaque langue et la cherche :

```cypher
MATCH (en:Page) WHERE en.locale = 'en'
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.url = '/' + locale + en.url }
RETURN en.url AS english_page, locale AS missing ORDER BY english_page, missing;
```

```text
english_page,missing
/lab/paths/,es
```

Le contrôle négatif applique le même test aux deux groupes complets seulement, et ne trouve rien :

```text
missing_in_complete_groups
0
```

Voici maintenant la version tentante : « une page a une traduction si une page de l'autre langue a le même titre ».

```cypher
MATCH (en:Page) WHERE en.locale = 'en'
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.locale = locale AND t.title = en.title }
RETURN en.url AS english_page, locale AS missing ORDER BY english_page, missing;
```

```text
english_page,missing
/lab/cycles/,es
/lab/intro/,es
/lab/paths/,es
/lab/paths/,fr
```

Quatre lignes, dont trois fausses : ces traductions existent, sous des titres traduits (« Ciclos », « Introducción », « Chemins »). « Introduction » et « Cycles » s'écrivent pareil en français, si bien que l'égalité des titres semble même juste pour une partie des données. [Le premier exercice de la leçon 2](../02-loading/#exercices) utilise la même identité par URL sur le vrai site.

## Cycles de prérequis, à l'écart de la navigation

Deux fichiers de prérequis :
- `requires-dag.csv` : `/lab/paths/` requiert `/lab/intro/`, et `/lab/cycles/` requiert `/lab/paths/` ;
- `requires-cycle.csv` : les deux mêmes, plus `/lab/intro/` requiert `/lab/cycles/`, qui ferme une boucle.

Les liens de navigation vont dans les deux sens entre `/lab/intro/` et `/lab/paths/`, comme le feraient un lien « suivant » et un lien « précédent ».

Un cycle est un chemin qui revient à son point de départ : `(a)-[…]->(a)`. `TRAIL` interdit de répéter une relation, comme dans la [leçon 3](../03-paths/#pistes-trails-et-chemins-acycliques). D'abord sur les prérequis acycliques, puis sur la navigation :

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a) RETURN count(*) AS prerequisite_cycles;
MATCH (a:Page)-[e:LINKS_TO* TRAIL 1..3]->(a) RETURN a.url AS page, length(e) AS links ORDER BY page;
```

```text
prerequisite_cycles
0
page,links
/lab/intro/,2
/lab/paths/,2
```

**Ici, 0 ligne est une preuve, grâce à la borne.** Trois pages portent des relations `REQUIRES`. Tout cycle contient un cycle simple, qui passe par des pages distinctes : un cycle entre trois pages a donc un cycle simple de longueur au plus 3. Une borne de 3 est donc complète : aucune piste fermée jusqu'à 3 signifie aucun cycle du tout. La même requête sur `LINKS_TO` trouve la boucle de navigation, qui est normale et ne doit pas être lue comme un cycle de prérequis. C'est pourquoi les prérequis ont leur propre table.

Avec le fichier du cycle, chaque piste fermée est un **témoin** : les pages qu'on montrerait à quelqu'un pour prouver que le cycle existe.

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a)
RETURN a.url AS page, length(e) AS length, properties(nodes(e), 'url') AS through ORDER BY page;
```

```text
page,length,through
/lab/cycles/,3,"[/lab/intro/,/lab/paths/]"
/lab/intro/,3,"[/lab/paths/,/lab/cycles/]"
/lab/paths/,3,"[/lab/cycles/,/lab/intro/]"
```

**Les trois pages et la longueur sont justes, mais l'ordre est inversé.** Depuis `/lab/cycles/`, les flèches vont vers `/lab/paths/`, puis `/lab/intro/`, puis reviennent ; pourtant la liste met `/lab/intro/` en premier. J'avais prédit l'ordre des flèches, et l'addendum de la pré-inscription consigne l'erreur. Un chemin ouvert, depuis la même page, liste ses pages dans le bon sens ; la piste fermée les liste à l'envers :

```cypher
MATCH p = (a:Page {url: '/lab/cycles/'})-[e:REQUIRES*2..2]->(b:Page) RETURN properties(nodes(p), 'url') AS open_path;
MATCH p = (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* TRAIL 3..3]->(a) RETURN properties(nodes(p), 'url') AS closed_path;
```

```text
open_path
"[/lab/cycles/,/lab/paths/,/lab/intro/]"
closed_path
"[/lab/cycles/,/lab/intro/,/lab/paths/,/lab/cycles/]"
```

La [documentation des fonctions de chemin](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) ne montre `nodes(p)` que sur des motifs ouverts, dans l'ordre des flèches. En 0.20.4, faites donc confiance aux pages d'un témoin fermé, pas à leur ordre : vérifiez chaque étape dans la table de relations avant de l'afficher comme une chaîne.

## Ce qu'une borne de profondeur prouve, et ce qu'elle ne prouve pas

La borne de 3 ci-dessus était complète parce qu'elle valait au moins le nombre de pages concernées. `requires-long.csv` forme un cycle de six pages, `/lab/s1/` → … → `/lab/s6/` → `/lab/s1/` :

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..5]->(a) WHERE a.url STARTS WITH '/lab/s' RETURN count(*) AS closed_trails;
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..6]->(a) WHERE a.url STARTS WITH '/lab/s'
RETURN count(*) AS closed_trails, min(length(e)) AS min_length, max(length(e)) AS max_length;
```

```text
closed_trails
0
closed_trails,min_length,max_length
6,6,6
```

Avec une borne de 5, rien n'est trouvé. Cela ne prouve rien, car le seul cycle est plus long que 5. Avec une borne de 6, le cycle apparaît, une fois depuis chacune de ses six pages. Pour prouver ainsi qu'un graphe est acyclique, la borne doit valoir au moins le nombre de pages qui portent la relation. Sous la limite par défaut de 30 ([leçon 3](../03-paths/#la-limite-de-profondeur)), cela ne marche que pour de petits graphes. Ma première version de cette requête nommait une colonne `shortest`, qui est un mot-clé en 0.20.4 : l'analyseur l'a refusée, et les alias sont devenus `min_length` et `max_length`.

Il en va de même pour l'atteignabilité. Voici les prérequis de `/lab/cycles/` dans le fichier acyclique, avec `SHORTEST`, qui donne un plus court chemin par page, d'abord avec une borne de 2, puis de 1 :

```cypher
MATCH (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* SHORTEST 1..2]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
MATCH (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* SHORTEST 1..1]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
MATCH (a:Page {url: '/lab/intro/'})-[e:LINKS_TO* SHORTEST 1..2]->(b:Page) RETURN b.url AS reached, length(e) AS clicks ORDER BY reached;
```

```text
prerequisite,depth
/lab/intro/,2
/lab/paths/,1
prerequisite,depth
/lab/paths/,1
reached,clicks
/lab/cycles/,2
/lab/paths/,1
```

- **Avec une borne de 1,** `/lab/intro/` disparaît. C'est toujours un prérequis, seulement plus loin que la borne ne le permet.
- **Sur le cycle de six pages,** `SHORTEST 1..3` depuis `/lab/s1/` liste `/lab/s2/`, `/lab/s3/` et `/lab/s4/`, et laisse de côté `/lab/s5/` et `/lab/s6/`, à 4 et 5 étapes.
- **Absent d'une réponse bornée veut dire « pas dans la borne », pas « inaccessible ».** La dernière requête suit la navigation depuis `/lab/intro/` et atteint `/lab/cycles/`, qui n'est pas un de ses prérequis. C'est le type de relation qui décide de ce que la question veut dire.

## À retenir

- **Écrivez les réponses attendues avant l'exécution.** Un jeu de données assez petit pour raisonner dessus le permet, et les erreurs sont des résultats : ici, un témoin affiché à l'envers.
- **Un `COPY` échoué dans une table de relations** a laissé la table et l'index de clé tels quels, en 0.20.4. C'est observé, pas une garantie documentée. `IGNORE_ERRORS` est une tolérance voulue, avec des avertissements à lire.
- **Trouvez les traductions par une identité de contenu,** ici l'URL anglaise, pas par le titre.
- **Gardez les prérequis dans leur propre table de relations.** Les boucles de navigation sont normales ; les boucles de prérequis sont des erreurs.
- **Une piste fermée jusqu'à n trouve tous les cycles entre n pages.** Sous cette borne, 0 ligne ne prouve rien, et une réponse d'atteignabilité bornée ne dit rien au-delà de sa borne.
- **En 0.20.4, `nodes()` sur un motif fermé `(a)-[…]->(a)` liste les pages à contresens des flèches.**

## Exercices

La solution est dans [`cypher/09-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/09-exercises.cypher), vérifiée par la CI.

1. Avec `translations-pages.csv` et `requires-cycle.csv` chargés, quelles pages d'un cycle de prérequis n'ont pas de page sœur en espagnol ?

<details>
<summary>Solution</summary>

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a)
WHERE a.locale = 'en' AND NOT EXISTS { MATCH (t:Page) WHERE t.url = '/es' + a.url }
RETURN DISTINCT a.url AS page;
```

```text
page
/lab/paths/
```

Les trois pages du cycle commencent chacune une piste fermée. `DISTINCT` garde une ligne par page, et l'identité de contenu, `'/es' + a.url`, trouve celle qui n'a pas de page espagnole. La borne de 3 est complète ici, car trois pages portent des relations `REQUIRES`.

</details>

## Sources

- [Import CSV](https://docs.ladybugdb.com/import/csv/) : `HEADER`, `IGNORE_ERRORS`, fichiers de relations dont les deux premières colonnes sont les clés des nœuds (lu le 2026-09-27)
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/) : motifs de longueur variable, `TRAIL`, `SHORTEST` (lu le 2026-09-27)
- [Fonctions de chemin](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) : `nodes`, `length`, `properties` (lu le 2026-09-27)
- [Différences entre LadybugDB et Neo4j](https://docs.ladybugdb.com/cypher/difference/) et [openCypher](https://opencypher.org/)
