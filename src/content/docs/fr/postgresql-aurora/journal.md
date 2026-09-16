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
- [ ] Leçons 5 à 13
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

## À vérifier

- Les commandes Linux et macOS des leçons 1 et 4, sur ces systèmes.
- Chaque section « Sur Aurora » : `pg_read_file` et l'exigence `CONNECT` pour `rds_superuser`, `btree_gist` 1.6, l'erreur de lecture seule sur un réplica, TLS par défaut, les jetons IAM avec le fournisseur de mot de passe périodique de Npgsql, l'épinglage de RDS Proxy avec le `DISCARD ALL` de Npgsql et avec les instructions préparées au niveau du protocole, et `pg_is_in_recovery()` sur une Aurora Replica.
