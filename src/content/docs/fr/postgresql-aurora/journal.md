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
- [ ] Leçons 9 à 13
- [ ] Tout ce qui touche AWS : chaque section Aurora est encore *à vérifier*

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

## À vérifier

- Les commandes Linux et macOS des leçons 1 et 4, sur ces systèmes.
- Chaque section « Sur Aurora » : `pg_read_file` et l'exigence `CONNECT` pour `rds_superuser`, `btree_gist` 1.6, l'erreur de lecture seule sur un réplica, TLS par défaut, les jetons IAM avec le fournisseur de mot de passe périodique de Npgsql, l'épinglage de RDS Proxy avec le `DISCARD ALL` de Npgsql et avec les instructions préparées au niveau du protocole, et `pg_is_in_recovery()` sur une Aurora Replica.
- Les leçons 5 à 8 sur Aurora : la valeur par défaut de `shared_buffers` pour Aurora PostgreSQL 18 et la raison pour laquelle elle est plus grande, la gestion des plans de requête sur 18.4, `hot_standby_feedback` qui retient `VACUUM` sur le writer, la valeur par défaut de `max_standby_streaming_delay`, les extensions de confiance sous `rds.allowed_extensions`, et les parcours itératifs de pgvector 0.8.2.
