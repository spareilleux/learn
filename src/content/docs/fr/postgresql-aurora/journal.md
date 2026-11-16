---
title: Journal
description: Notes de progression datées — versions, ce que j'ai essayé, surprises, constats sur les données de Guitar Alchemist et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Mission et un plan en 13 leçons
- [x] Code : scripts SQL exécutés par `psql`, programmes C# et Java, tous comparés à leur sortie attendue par `check.sh`
- [x] CI : [`postgresql-aurora-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/postgresql-aurora-examples.yml) exécute tout contre PostgreSQL sous Linux et construit les programmes sous Windows et macOS ; premier passage vert le 2026-09-16
- [x] Leçon 1 : un conteneur, `psql`, bases, schémas et rôles
- [x] Leçon 2 : types et modélisation
- [x] Leçon 3 : CTE, fenêtres, `LATERAL`, upserts et `MERGE`
- [x] Leçon 4 : PostgreSQL depuis C# et Java
- [x] Leçon 5 : index et plans
- [x] Leçon 6 : transactions et MVCC
- [x] Leçon 7 : JSON et recherche
- [x] Leçon 8 : fonctions, extensions et pgvector
- [x] Leçon 9 : partitionnement
- [x] Leçon 10 : réplication, sur trois clusters dans le conteneur du cours
- [x] Leçon 11 : sauvegardes, restauration à un instant donné et `pg_upgrade`
- [x] Leçon 12 : Aurora, d'après la documentation, et un basculement depuis C# et Java
- [x] Leçon 13 : migrer depuis SQL Server, à la main, par programme et avec pgloader ; DMS, Babelfish et les coûts d'après la documentation
- [x] Le cours est terminé
- [ ] Tout ce qui touche AWS : chaque section Aurora est encore *à vérifier*

## QA

PostgreSQL 18.6 en conteneur, Npgsql 10.0.3, pgjdbc 42.7.13, pgvector 0.8.6, pgloader compilé depuis les sources, et SQL Server 2025 pour la migration. La plupart des lignes sont un pilote, un outil ou un réglage par défaut qui fait autre chose que ce que disent la documentation ou l'autre pilote ; deux portent sur GuitarAlchemist/ga et sur la documentation d'AWS elle-même. Rien n'a été signalé en amont.

Il n'y a pas de tableau d'expériences. Le journal ne consigne aucune hypothèse avant ses mesures : les cinq reconstructions de l'index HNSW, le seuil de la cible de statistiques et les temps des pilotes sont des mesures dont l'explication a été écrite après le nombre, et en faire des expériences maintenant reviendrait à inventer l'a priori à rebours.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| `CREATE FUNCTION … BEGIN ATOMIC …; END` est une seule commande, puisque ses points-virgules sont dans le corps | Npgsql coupe le texte de la commande au point-virgule du corps, comme entre deux instructions, et le serveur refuse la commande tronquée | Npgsql 10.0.3, `NpgsqlCommand` sans paramètres | `42601: syntax error at end of input`. Ça marche dans un `NpgsqlBatch`, avec `Npgsql.EnableSqlRewriting` désactivé, ou avec des paramètres positionnels. pgjdbc 42.7.13 reconnaît `BEGIN ATOMIC` et ne coupe pas | Reproduit, non signalé [2026-09-16](#2026-09-16--fonctions-et-pgvector) |
| pgloader migre une colonne `money` de SQL Server sans perdre de chiffres, ou prévient | Il garde deux décimales, en silence : il lit `money` via `convert(varchar(40), [col], 0)`, et le style 0 tronque | pgloader construit depuis `231ab86`, [`mssql-schema.lisp`, lignes 212-217](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp#L212-L217) | `0.0125` est devenu `0.01`, sans erreur ni avertissement. La même exécution a perdu la contrainte `CHECK` et fait d'`INCLUDE (Conclusion)` une colonne de clé | Reproduit, non signalé [2026-09-16](#2026-09-16--migrer-depuis-sql-server) |
| `Target Session Attributes=standby` est accepté avec un seul hôte, comme pgjdbc accepte `targetServerType=secondary` | Npgsql refuse la chaîne de connexion d'emblée ; pgjdbc l'accepte et échoue plus tard, à la connexion | Npgsql 10.0.3, pgjdbc 42.7.13 | `NotSupportedException: Target Session Attributes other then Any is only supported with multiple hosts` | Par conception chez les deux, différemment [2026-09-15](#2026-09-15--les-pilotes) |
| PowerShell passe `-Duser.timezone=Asia/Tokyo` à `java` en un seul argument | PowerShell 7.6 le coupe encore au point | PowerShell 7.6 | `Could not find or load main class .timezone=Asia.Tokyo` | Reproduit ; entre guillemets, ça marche [2026-09-15](#2026-09-15--les-pilotes) |
| Un `DateTime` de genre non spécifié donne les mêmes lignes quel que soit le fuseau de la session | Il ne lève pas d'exception, comme attendu, mais il part en `timestamp` et est converti dans le fuseau de la session | Npgsql 10.0.3 | 82 exécutions ou 59, selon `Timezone`. Un `DateTimeOffset` décalé de −4 heures, lui, lève une `ArgumentException` | Par conception [2026-09-15](#2026-09-15--les-pilotes) |
| `SET statement_timeout = '2s'` met fin à un `INSERT` qui attend un standby synchrone arrêté | L'attente n'est pas interrompue ; l'instruction reste bloquée jusqu'à ce qu'on l'annule de l'extérieur | PostgreSQL 18.6, réplication synchrone entre les clusters du conteneur du cours | Dix minutes, jusqu'à `pg_cancel_backend` ; l'avertissement dit que la transaction « has already committed locally » | Par conception : la validation est déjà locale et seule l'attente reste. Le script annule désormais l'attente depuis une autre session [2026-09-16](#2026-09-16--plusieurs-serveurs-dans-un-conteneur) |
| `pg_rewind` rembobine l'ancien primaire rétrogradé sur le nouveau | L'ancien primaire avait déjà recyclé le segment de WAL dont `pg_rewind` a besoin | `pg_rewind` 18, le `node1` du conteneur du cours | `could not open file "node1/pg_wal/000000010000000000000002"` | Reproduit ; `wal_keep_size = 128MB` garde le segment [2026-09-16](#2026-09-16--plusieurs-serveurs-dans-un-conteneur) |
| `pg_upgrade --check` d'un cluster 17 par défaut vers un cluster 18 par défaut passe | `initdb` 18 active les sommes de contrôle par défaut : les deux défauts ne concordent plus | `pg_upgrade` 18, `initdb` 18 | Arrêt sur « old cluster does not use data checksums but the new one does » | Par conception, défaut modifié ; `--no-data-checksums` sur le nouveau cluster [2026-09-16](#2026-09-16--sauvegardes-et-pg_upgrade) |
| Un index GIN `jsonb_path_ops` est plus petit qu'un `jsonb_ops`, comme la documentation dit que c'est l'usage | Sur ces documents il est un peu plus gros | PostgreSQL 18.6, les documents de CI copiés | 1 752 ko pour `jsonb_path_ops` contre 1 688 ko pour `jsonb_ops` | Reproduit ; « l'usage » n'est pas « toujours » [2026-09-16](#2026-09-16--json-et-recherche) |
| Une recherche des plus proches voisins filtrée rend les dix lignes demandées | Le parcours HNSW réunit ses candidats avant le filtre, aucun ne le passe, et la requête ne rend rien | pgvector 0.8.6, `enable_seqscan = off` | Aucune ligne là où dix étaient demandées : 40 candidats, aucun n'est une triade. Reconstruire l'index cinq fois a donné les mêmes 40 distances chaque fois | Par conception ; `hnsw.iterative_scan = strict_order` rend les dix, et la leçon le pose [2026-09-16](#2026-09-16--fonctions-et-pgvector) |
| Un script lancé par `sqlcmd -i` affiche ce que les mêmes instructions affichent avec `-Q` | Avec `-i`, tout résultat qui suit une erreur non rattrapée disparaît, quand l'erreur est la première instruction d'un lot qui suit un lot à résultats | `sqlcmd` 18.6 contre SQL Server 2025 CU9 | `-Q` affichait les résultats ; `-i` les perdait | Reproduit, non signalé ; les scripts rattrapent leurs erreurs par `TRY … CATCH` [2026-09-16](#2026-09-16--migrer-depuis-sql-server) |
| `Microsoft.Data.SqlClient` ouvre une connexion depuis le projet C# du cours | Il refuse, parce que le projet active `InvariantGlobalization` | `Microsoft.Data.SqlClient` 7.0.3, `OpenAsync` | `Globalization Invariant Mode is not supported.` | Par conception ; le programme de migration a son propre projet [2026-09-16](#2026-09-16--migrer-depuis-sql-server) |
| Un convertisseur qui joint une liste en une chaîne relit tous les éléments enregistrés | `StringSplitOptions.RemoveEmptyEntries` à la relecture fait disparaître un nom alternatif vide | GuitarAlchemist/ga, les convertisseurs de valeurs de `MusicalKnowledgeDbContext.cs`, en trois exemplaires | Trois noms enregistrés, deux relus | Corrigé en amont par [#734](https://github.com/GuitarAlchemist/ga/pull/734), fusionnée le 2026-09-24, dans les trois copies [2026-09-15](#2026-09-15--constats-sur-guitar-alchemist), [2026-09-24](#2026-09-24--correctifs-amont) |
| Les pages d'AWS s'accordent sur une date de fin de vie | Deux guides donnent deux dates, et se contredisent aussi sur un mode par défaut | le guide CloudWatch et l'historique du guide utilisateur d'Aurora | Performance Insights finit le 31 juillet 2026 dans l'un et le 30 novembre 2025 dans l'autre ; Database Insights est en mode Standard par défaut dans l'un, Advanced dans l'autre | Reproduit dans la documentation ; non signalé [2026-09-16](#2026-09-16--aurora-daprès-la-documentation) |

## 2026-09-15 — Versions

- La [page des versions de PostgreSQL](https://www.postgresql.org/support/versioning/) liste 18.6 comme version mineure courante de PostgreSQL 18, supportée jusqu'au 14 novembre 2030. PostgreSQL 19 est en bêta. Le cours épingle le tag d'image `postgres:18.6-trixie` et note son digest dans la page de mission.
- La version d'Aurora PostgreSQL la plus récente dans les notes de version d'AWS est 18.4.1, du 21 août 2026. Son tableau des extensions donne `btree_gist` 1.6 ; PostgreSQL 18.6 dans l'image propose 1.8.
- Clients : Npgsql 10.0.3 et son fournisseur EF Core 10.0.3, qui exige EF Core 10.0.4 ou plus ; pgjdbc 42.7.13, HikariCP 7.1.0. `pgvector` n'est pas dans l'image officielle : la leçon 8 aura besoin d'une autre image ou d'une compilation.

## 2026-09-15 — Démarrer le serveur

- Le premier démarrage de l'image exécute un serveur temporaire pour créer le cluster, qui n'écoute que sur le socket Unix. `pg_isready` par le socket répondait « accepting connections » pendant ce laps de temps, et la commande suivante tombait sur un serveur en cours d'arrêt. `pg_isready -h 127.0.0.1` passe par TCP. `server.sh` et le health check du service de CI l'utilisent.
- Les erreurs de `psql` sortaient avant les résultats des instructions précédentes dans les sorties enregistrées : `psql` met la sortie standard en tampon, pas la sortie d'erreur. `server.sh` exécute `psql` sous `stdbuf -o0`, dans le conteneur, avec les deux flux fusionnés là-bas.
- Chaque script s'exécute avec `TimeZone=UTC`, `DateStyle=ISO, MDY` et `lc_messages=C`, réglés dans `PGOPTIONS`, et chaque requête a un `ORDER BY`. `\conninfo` affiche l'identifiant du processus serveur, qui change à chaque exécution : les scripts ne l'utilisent pas.

## 2026-09-15 — Modéliser l'historique de CI

- Un intervalle fermé `[started_at, completed_at]` pour les étapes faisait se chevaucher 2 798 paires d'étapes d'un même job : les heures de GitHub sont à la seconde, et une étape commence à la seconde où la précédente se termine. Des intervalles semi-ouverts `[)` règlent ça, mais 857 des 2 204 étapes deviennent des intervalles vides, qui perdent leurs bornes. La table garde les deux horodatages et dérive l'intervalle comme colonne générée stockée.
- Un `CHECK` dont le message d'erreur incluait `now()` donnait une sortie différente à chaque exécution ; les lignes de test utilisent des dates fixes.
- `WITH TIES` renvoyait les lignes à égalité dans un ordre différent d'une exécution à l'autre : un `ORDER BY` externe fixe l'ordre.

## 2026-09-15 — Constats sur Guitar Alchemist

Rien de tout cela n'a été signalé au projet ; ce sont des notes, avec les requêtes qui les reproduisent dans les leçons.

- `GA.Knowledge.Service.csproj` référence `GA.Business.Config.fsproj` deux fois, aux lignes 26 et 31, au commit `32f143c`. La clé primaire de `ga.project_refs` rejette la seconde (leçon 2).
- `MusicalKnowledgeDbContext.cs` existe en trois copies qui ne diffèrent que par leur namespace, dans `Common/GA.Data.EntityFramework/`, `Common/GA.Data.EntityFramework/Data/` et `Common/GA.Infrastructure/Persistence/EntityFramework/`. Je n'ai trouvé aucun appel à `AddDbContext` ou `UseSqlite` pour lui à ce commit, alors que des services l'injectent.
- Ses convertisseurs de valeurs stockent les listes comme des chaînes jointes et les relisent avec `StringSplitOptions.RemoveEmptyEntries` : un nom alternatif vide est perdu. Trois noms enregistrés, deux relus (leçon 4).
- Dans `IconicChords.yaml`, trois doigtés ne jouent pas leurs classes de hauteur déclarées : Blackbird ne joue pas de si et ajoute do♯, mi et la ; le doigté Hendrix n'a pas de si ; le doigté du Mu Major, `Cadd9(no3)`, joue mi (leçon 3, exercice 1).
- Versions de paquets : `Microsoft.Extensions.Hosting` est référencé dans 5 versions et `MongoDB.Driver` dans 5 ; 16 paquets ont un maximum textuel qui n'est pas leur plus haute version ; 13 versions distinctes ne sont pas de simples nombres, dont les flottantes `0.*` et `8.*-*` (leçon 3).
- Deux projets s'appellent `GaApi.Tests.csproj`, dans `Tests/Apps/GaApi.Tests` et `Tests/GaApi.Tests`.

## 2026-09-15 — Les pilotes

- Npgsql : un `DateTime` avec `Kind=Unspecified` n'a pas levé d'exception, comme je m'y attendais, mais a été envoyé comme `timestamp` et converti dans le fuseau horaire de la session : 82 exécutions ou 59 selon `Timezone`. Un `DateTimeOffset` avec un décalage de −4 heures lève `ArgumentException`.
- `pg_prepared_statements` comptait la requête de comptage elle-même une fois qu'elle était préparée ; une expression régulière qui ne correspond pas à son propre texte a corrigé le compte.
- EF Core construit un modèle une fois par type de contexte : deux configurations de la même entité dans une seule classe de contexte, choisies par un argument du constructeur, donnaient deux fois le premier modèle. Une sous-classe par configuration.
- pgjdbc envoie le fuseau horaire de la JVM comme `TimeZone` de la session, donc `getString` sur un `timestamptz` dépendait de la machine. `check.sh` exécute Java avec `-Duser.timezone=America/Toronto`.
- PowerShell 7.6 coupe toujours `-Duser.timezone=Asia/Tokyo` au point : Java répondait « Could not find or load main class .timezone=Asia.Tokyo ». Entre guillemets, ça marche.
- Npgsql refuse `Target Session Attributes=standby` avec un seul hôte : `NotSupportedException: Target Session Attributes other then Any is only supported with multiple hosts`. pgjdbc accepte `targetServerType=secondary` avec un hôte et échoue à la connexion.
- Une exécution de `l04-timings` : 478 commandes `INSERT` en une seconde environ, un `NpgsqlBatch` en 5 à 7 ms, un `COPY` binaire en 50 ms environ. Des exécutions plus tôt le même jour ont pris jusqu'à 2,2 secondes pour la boucle d'`INSERT`.

## 2026-09-16 — Des plans qui donnent la même sortie à chaque exécution

- `EXPLAIN ANALYZE` sur l'historique de 440 800 étapes donnait des nombres de lignes par nœud différents d'une exécution à l'autre : les workers parallèles répartissaient les lignes différemment à chaque fois. `max_parallel_workers_per_gather = 0` pour les leçons qui montrent des plans.
- Les estimations du planificateur changeaient après chaque `ANALYZE`, qui lit un échantillon aléatoire de 30 000 lignes avec la cible de statistiques par défaut. À 1 500, l'échantillon est de 450 000 lignes, plus que la table, et les estimations sont exactes et stables.
- La ligne `Buffers` répartissait les pages entre `hit` et `read` selon ce que les instructions précédentes avaient laissé en mémoire. L'outil de plan les additionne en un seul nombre ; le total n'a pas changé après un redémarrage du conteneur.
- PostgreSQL 18 affiche `Buffers` sans `BUFFERS`, les nombres de lignes avec deux décimales, et `Index Searches`.
- `xmin` affichait `-1` pour la première version de ligne : l'identifiant de transaction enregistré avec `\gset` était pris après l'`INSERT`. Il est maintenant pris juste avant.
- `pg_stat_user_tables` montrait zéro mise à jour HOT juste après les mises à jour : les statistiques sont envoyées au plus une fois par seconde. `pg_stat_force_next_flush()` corrige le compte.

## 2026-09-16 — Deux sessions dans un seul programme

- Un programme ne peut pas attendre que l'instruction bloquée de B revienne. Les programmes C# et Java la lancent, et une troisième connexion interroge `pg_stat_activity` jusqu'à ce que B attende un verrou, avec `pg_blocking_pids` qui nomme A.
- Dans l'exemple de deadlock, l'une ou l'autre session pouvait être annulée, selon celle qui avait attendu `deadlock_timeout` la première. A a 10 secondes et B 100 ms : B détecte toujours le cycle, et est annulée.

## 2026-09-16 — JSON et recherche

- Un `tsvector` en colonne générée stockée dont la configuration venait d'une autre colonne générée a été refusé : une colonne générée ne peut pas faire référence à une autre. La configuration est une colonne ordinaire, remplie par l'`INSERT`.
- Un index de trigrammes sur les 478 lignes de `ga.package_refs` n'était jamais utilisé, même avec `enable_seqscan = off` : l'index de la clé primaire coûtait moins cher. L'exemple utilise les 88 160 noms d'étapes des documents copiés.
- Sur ces documents, `jsonb_path_ops` est sorti un peu plus grand que `jsonb_ops`, 1 752 ko contre 1 688 ko, l'inverse de ce que la documentation dit être habituel.
- La phrase `"prepared statements"` a trouvé `pg_prepared_statements` dans ce journal : l'analyseur de la recherche de texte coupe aux underscores.

## 2026-09-16 — Fonctions et pgvector

- **Constat, Npgsql 10.0.3.** Un seul `CREATE FUNCTION … BEGIN ATOMIC SELECT …; END` dans une `NpgsqlCommand` sans paramètres échoue avec `42601: syntax error at end of input`. Npgsql découpe le texte de la commande au point-virgule à l'intérieur du corps, comme il le fait pour plusieurs instructions. Le même texte fonctionne dans un `NpgsqlBatch`, avec le commutateur `Npgsql.EnableSqlRewriting` à `false`, ou dans une commande qui a des paramètres positionnels. pgjdbc 42.7.13 détecte `BEGIN ATOMIC` et ne découpe pas ; une fonction `BEGIN ATOMIC` suivie d'une autre instruction dans un seul `execute` échoue alors comme plusieurs commandes dans une instruction préparée. Signalé à aucun des deux projets.
- L'image officielle n'a pas pgvector. Les scripts pgvector s'exécutent sur `pgvector/pgvector:0.8.6-pg18-trixie`, un serveur à la fois sur le port 5432 ; la CI l'exécute comme second service, sans port.
- Avec `enable_seqscan = off`, une recherche des plus proches voisins filtrée sur les triades ne renvoyait aucune ligne, là où dix étaient demandées : le parcours HNSW renvoie 40 candidats, dont aucune triade. `hnsw.iterative_scan = strict_order` renvoie les dix. J'ai reconstruit l'index cinq fois : les distances des 40 candidats étaient les mêmes à chaque fois.
- Les vecteurs de classes d'intervalles des accords iconiques montrent que l'accord Elektra est l'accord Petrushka transposé d'une tierce majeure vers le haut, et que l'accord Foxy Lady est le renversement de l'accord Joni Mitchell, dont la transposition est l'accord Debussy.

## 2026-09-16 — Aurora, d'après la documentation

- Aurora PostgreSQL 18.4 livre pgvector 0.8.2, là où le cours utilise 0.8.6. `pageinspect` n'est pas dans le tableau des extensions d'Aurora PostgreSQL 18.
- Les pages d'AWS se contredisent sur la fin de vie de Performance Insights : le 31 juillet 2026 dans le guide de CloudWatch, le 30 novembre 2025 dans l'historique du guide de l'utilisateur d'Aurora. Elles se contredisent aussi sur le mode par défaut de Database Insights, Standard ou Advanced.
- `max_standby_streaming_delay` : 30 secondes sur la page `Lock:Relation`, 14 000 ms dans le tableau des paramètres d'Aurora PostgreSQL 14.

## 2026-09-16 — Partitionnement

- Une clé primaire sur `id` seul est refusée sur une table partitionnée par `started_at` ; avec `(id, started_at)`, elle est acceptée, et vérifiée partition par partition.
- `DETACH PARTITION … CONCURRENTLY` n'est pas permis tant que la table a une partition par défaut, et une partition par défaut qui contient une ligne d'octobre bloque la création de la partition d'octobre.
- Le partitionnement par hachage sur 64 noms de jobs a donné à une partition 2,1 fois les lignes d'une autre.
- Une procédure qui affichait un `regclass` après `DROP TABLE` affichait l'OID nu : la notice doit venir avant la suppression.

## 2026-09-16 — Plusieurs serveurs dans un conteneur

- Le cours exécute un conteneur à la fois. Les leçons 10 et 11 démarrent de petits clusters à l'intérieur avec `initdb` et `pg_ctl`, sur les ports 5433 à 5436, avec `shared_buffers = 32MB` ; la CI exécute les mêmes scripts dans son conteneur de service.
- Un script réécrit sous Windows par le mode texte de Python a reçu des fins de ligne CRLF, et `bash -s` dans le conteneur échouait dès ses premières lignes. Les fichiers écrits avec `newline=''` gardent LF.
- Les clusters de l'image mettent leur socket Unix dans `/var/run/postgresql`, pas dans `/tmp` : avec `PGHOST=/tmp`, chaque `psql` échouait, et chaque boucle d'attente expirait au bout de 30 secondes.
- `SET statement_timeout = '2s'` n'a pas terminé un `INSERT` qui attendait un standby synchrone arrêté : il a attendu dix minutes, jusqu'à ce que je l'annule avec `pg_cancel_backend`. Le script annule maintenant l'attente depuis une autre session ; l'avertissement dit que la transaction « has already committed locally ».
- `pg_rewind` a d'abord échoué avec `could not open file "node1/pg_wal/000000010000000000000002"` : l'ancien primaire avait recyclé le segment dont il avait besoin. `wal_keep_size = 128MB` le garde.
- Les statistiques de conflits de PostgreSQL 18 comptent le conflit `insert_exists` d'un abonné qui avait sa propre ligne ; l'apply worker réessaie jusqu'à ce que la ligne soit supprimée.

## 2026-09-16 — Sauvegardes et pg_upgrade

- `pg_upgrade --check` d'un cluster 17 vers un nouveau cluster 18 s'est arrêté sur « old cluster does not use data checksums but the new one does » : `initdb` 18 active les sommes de contrôle par défaut. `--no-data-checksums` sur le nouveau cluster règle ça.
- `pg_upgrade` 18 a gardé les six statistiques de colonnes de `ci.runs`, pas ses statistiques étendues ; `vacuumdb --analyze-only --missing-stats-only` les a reconstruites.
- La mise à niveau a besoin des binaires de PostgreSQL 17 : `check.sh` installe `postgresql-17` depuis le dépôt apt que l'image utilise déjà, donc la version mineure de l'ancien côté n'est pas épinglée. Les sorties n'affichent que la version majeure.

## 2026-09-16 — Un basculement vu des pilotes

- `ops/12-cluster.sh` démarre un primaire et un standby dans le conteneur du cours, publiés sur les ports 5433 et 5434. Les programmes arrêtent le primaire par `COPY … TO PROGRAM 'pg_ctl … -W stop'` et promeuvent le standby avec `pg_promote()`.
- Sur la connexion ouverte avant la panne, pgjdbc signale `57P01`, « terminating connection due to administrator command », et Npgsql « Exception while reading from stream » sous Windows à travers Docker Desktop, mais une `PostgresException` avec `57P01` en CI sous Linux : le premier passage de la CI a échoué sur cette ligne. Le programme C# affiche maintenant le `FullState` de la connexion, `Broken` dans les deux cas.
- Les deux pilotes mettent en cache l'état des hôtes pendant 10 secondes par défaut, et pourtant une écriture juste après la promotion a trouvé le nouveau primaire dans les deux. Je n'ai pas cherché pourquoi dans leur code source.

## 2026-09-16 — Aurora, leçons 9 à 12

- Le volume de cluster maximal : 256 Tio pour Aurora PostgreSQL 15.13, 16.9, 17.5 et plus dans le tableau par version de la page des quotas, 128 Tio dans le tableau des quotas de la même page, 256 Tio sans condition dans la présentation.
- Le calendrier des versions donne à PostgreSQL 18 une « community release date » du 26 février 2026, la date de 18.3 ; PostgreSQL 18.0 est sorti le 25 septembre 2025.
- La page des mises à niveau de version majeure dit que les statistiques de l'optimiseur ne sont pas transférées, alors que `pg_upgrade` 18 en transfère la plupart.
- Les déploiements blue/green et zero-ETL n'ont pas encore de colonne Aurora PostgreSQL 18 dans leurs tableaux de versions ; RDS Proxy en a une, à partir de 18.3.
- L'AWS Advanced .NET Data Provider Wrapper existe, en 2.2.0 sur GitHub, avec un dialecte Npgsql, mais la liste des pilotes AWS du guide de l'utilisateur d'Aurora ne le mentionne pas.

## 2026-09-16 — Migrer depuis SQL Server

- Le cours est terminé : 13 leçons. SQL Server 2025 CU9 a démarré en quelques secondes dans son conteneur et utilisait environ 450 Mo au repos ; la CI l'exécute comme conteneur de service à côté de PostgreSQL.
- `sqlcmd` 18.6 (`mssql-tools18` dans l'image) abandonnait tous les résultats qui suivaient une erreur non attrapée dans un script exécuté avec `-i`, quand l'erreur était la première instruction d'un lot venant après un lot qui avait des résultats ; `-Q` avec les mêmes instructions les affichait. Les scripts attrapent leurs erreurs avec `TRY … CATCH`.
- `Microsoft.Data.SqlClient` 7.0.3 levait `Globalization Invariant Mode is not supported.` sur `OpenAsync` dans le projet C# du cours, qui active `InvariantGlobalization`. Le programme de migration a son propre projet.
- Npgsql a tronqué les ticks de `datetimeoffset(7)` aux microsecondes (`.9999999` en `.999999`) ; pgloader les a arrondis (`10:06:00.9999999 -04:00` en `14:06:01`).
- pgloader, image construite depuis `231ab86`, a changé une valeur `money` de `0.0125` en `0.01`, sans erreur ni avertissement : il lit `money` avec `convert(varchar(40), [col], 0)`, et le style 0 garde deux décimales ([`mssql-schema.lisp`, lignes 212-217](https://github.com/dimitri/pgloader/blob/231ab86778ca5ffd7de40878714760c8b4860cdf/src/sources/mssql/mssql-schema.lisp#L212-L217)). Il a aussi laissé de côté la contrainte `CHECK` et changé `INCLUDE (Conclusion)` en colonne de clé.
- L'`IDENT_CURRENT` de SQL Server valait 6 avec trois lignes : deux insertions en échec et une ligne supprimée avaient utilisé des valeurs.
- Documentation d'AWS lue le même jour : DMS ne liste pas SQL Server 2025 comme source ; le tableau des paramètres et la page des collations de Babelfish donnent deux collations serveur par défaut différentes, et la page des collations dit encore que PostgreSQL ne prend pas en charge `LIKE` sur les collations non déterministes ; le Babelfish open source s'arrête à PostgreSQL 17.7 et n'a pas d'image de conteneur.
- La page web des prix de SQL Server 2025 de Microsoft refusait les requêtes scriptées ; les prix viennent de sa grille tarifaire en PDF.

## 2026-09-24 — Correctifs amont

- [#734](https://github.com/GuitarAlchemist/ga/pull/734), fusionnée le 2026-09-24, corrige les convertisseurs de listes : les 11 convertisseurs de listes de chaînes des trois copies de `MusicalKnowledgeDbContext` découpent sans `RemoveEmptyEntries`, et une colonne vide se relit comme une liste vide. Son test échoue sur les 11 avec l'ancien code. Une limite demeure, et la PR le dit : une liste qui ne contient qu'une chaîne vide se relit encore comme une liste vide, parce que les deux stockent la même valeur de colonne.

## À vérifier

- Les commandes Linux et macOS des leçons 1 et 4, sur ces systèmes.
- Chaque section « Sur Aurora » : `pg_read_file` et l'exigence `CONNECT` pour `rds_superuser`, `btree_gist` 1.6, l'erreur de lecture seule sur un réplica, TLS par défaut, les jetons IAM avec le fournisseur de mot de passe périodique de Npgsql, l'épinglage de RDS Proxy avec le `DISCARD ALL` de Npgsql et avec les instructions préparées au niveau du protocole, et `pg_is_in_recovery()` sur une Aurora Replica.
- Les leçons 5 à 8 sur Aurora : la valeur par défaut de `shared_buffers` pour Aurora PostgreSQL 18 et la raison pour laquelle elle est plus grande, la gestion des plans de requête sur 18.4, `hot_standby_feedback` qui retient `VACUUM` sur le writer, la valeur par défaut de `max_standby_streaming_delay`, les extensions de confiance sous `rds.allowed_extensions`, et les parcours itératifs de pgvector 0.8.2.
- Les leçons 9 à 12 sur Aurora : pg_partman 5.4.3 sur 18.4, la réplication logique après `rds.logical_replication`, les statistiques après une mise à niveau majeure vers 18, les déploiements blue/green et zero-ETL sur 18, les plages d'Aurora Serverless et la mise en pause automatique sur 18, si les connexions inactives d'un pool empêchent la mise en pause automatique, RDS Proxy avec les demandes d'annulation, et la durée d'un basculement vue depuis Npgsql et pgjdbc.
- Pourquoi Npgsql et pgjdbc ont trouvé le standby promu tout de suite malgré leurs caches d'état des hôtes de 10 secondes.
- La leçon 13 sur AWS : DMS avec une source SQL Server 2025, si la validation de DMS signale les valeurs `datetimeoffset(7)` tronquées aux microsecondes, la collation serveur par défaut de Babelfish et sa façon de traiter les sept comportements de cette leçon, les prix de l'AWS Price List publiée le 2026-09-11, et si RDS facture une instance SQL Server à 2 vCPU pour 4 vCPU de licence.
