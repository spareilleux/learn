---
title: "11. Sauvegarde, restauration et mises à niveau"
description: Les sauvegardes de PostgreSQL 18 pour les développeurs SQL Server — le format custom de pg_dump et un pg_restore en parallèle, les rôles avec pg_dumpall, des sauvegardes de base avec manifestes, des sauvegardes incrémentales et pg_combinebackup, l'archivage du WAL et une restauration à un instant donné jusqu'à un point de restauration nommé, puis une mise à niveau majeure de 17 à 18 avec pg_upgrade --swap et les statistiques qu'elle garde — et ce qu'Aurora fait à la place.
sidebar:
  order: 11
---

Les scripts de la leçon sont [`ops/11-backup.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh) et [`ops/11-upgrade.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh), et les exercices sont dans [`ops/11-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh). Comme dans la [leçon 10](../10-replication/), ils démarrent de petits clusters dans le conteneur du cours, et `check.sh ops` compare leur sortie aux fichiers de mêmes noms dans [`expected`](https://github.com/spareilleux/learn/tree/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected) :

```bash
bash server.sh sh < ops/11-backup.sh
```

| SQL Server | PostgreSQL |
|---|---|
| `BACKUP DATABASE`, un fichier `.bak` | `pg_dump`, un dump logique d'une base ; `pg_basebackup`, une copie physique du cluster |
| logins dans `master` | rôles, exportés par `pg_dumpall --globals-only` |
| sauvegarde différentielle | sauvegarde incrémentale (`pg_basebackup --incremental`), combinée avec `pg_combinebackup` |
| sauvegardes du journal | archivage du WAL (`archive_command`) |
| `RESTORE … WITH STOPAT`, `STOPATMARK` | `recovery_target_time`, `recovery_target_name`, `recovery_target_xid` |
| `RESTORE VERIFYONLY` | `pg_verifybackup` |
| mise à niveau sur place par le programme d'installation | un nouveau cluster, et `pg_upgrade` depuis l'ancien |

## Dumps logiques

Un cluster avec le schéma du cours, dont les segments de WAL terminés sont archivés ; les réglages sont expliqués plus bas ([lignes 21-33](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L21-L33)) :

```bash
say "node1: every finished WAL segment is copied to /tmp/archive, and the WAL summarizer runs for incremental backups"
initdb -D node1 --auth=trust > /dev/null
mkdir archive
cat >> node1/postgresql.conf <<'EOF'
shared_buffers = 32MB
archive_mode = on
archive_command = 'test ! -f /tmp/archive/%f && cp %p /tmp/archive/%f'
summarize_wal = on
EOF
pg_ctl -D node1 -l node1.log -o "-p 5433" -w start > /dev/null || exit 1
psql -X -q -p 5433 -c 'CREATE DATABASE learn' -c 'CREATE ROLE reader NOLOGIN'
psql -X -q -p 5433 -d learn -c '\o /dev/null' -c '\i /course/sql/schema.sql' -c 'GRANT USAGE ON SCHEMA ci TO reader'
sql 5433 -c "$counts"
```

```text

-- node1: every finished WAL segment is copied to /tmp/archive, and the WAL summarizer runs for incremental backups
 runs | jobs | steps
------+------+-------
  125 |  315 |  2204
(1 row)
```

[`pg_dump`](https://www.postgresql.org/docs/18/app-pgdump.html) écrit une base sous la forme du SQL qui la recrée, depuis un seul snapshot, pendant que les autres sessions continuent de travailler. Son format *custom*, `--format=custom`, est compressé et permet à [`pg_restore`](https://www.postgresql.org/docs/18/app-pgrestore.html) de choisir quoi restaurer et de travailler en parallèle ([lignes 35-43](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L35-L43)) :

```bash
say "A logical dump in the custom format, its table of contents, and a restore with two parallel jobs"
pg_dump -p 5433 -d learn --format=custom --file=learn.dump
# Chaque ligne de la liste commence par un identifiant de dump et deux identifiants d'objet, retirés ici
pg_restore --list learn.dump | grep ' TABLE DATA ' | sed -E 's/^[0-9]+; [0-9]+ [0-9]+ //'
psql -X -q -p 5433 -c 'CREATE DATABASE learn_copy'
pg_restore -p 5433 -d learn_copy --jobs=2 learn.dump
psql -X -p 5433 -d learn_copy -c "$counts"
# Les rôles appartiennent au cluster, pas à une base : pg_dump les laisse de côté, pg_dumpall --globals-only les écrit
pg_dumpall -p 5433 --globals-only | grep -E '^(CREATE|ALTER) ROLE reader'
```

```text
-- A logical dump in the custom format, its table of contents, and a restore with two parallel jobs
TABLE DATA ci jobs postgres
TABLE DATA ci runs postgres
TABLE DATA ci steps postgres
TABLE DATA ga iconic_chords postgres
TABLE DATA ga package_refs postgres
TABLE DATA ga project_refs postgres
TABLE DATA ga projects postgres
 runs | jobs | steps
------+------+-------
  125 |  315 |  2204
(1 row)

CREATE ROLE reader;
ALTER ROLE reader WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
```

- `pg_restore --list` affiche la table des matières du dump, une ligne par objet. Enregistrée dans un fichier et modifiée, elle peut être repassée avec `--use-list` pour ne restaurer que certains objets, dans un ordre choisi.
- `--jobs=2` restaure avec deux connexions : les données de plusieurs tables, puis leurs index, en même temps. Il faut le format custom ou le format répertoire.
- Un dump ne contient pas les rôles, qui appartiennent au cluster : le `GRANT` à `reader` y est, le rôle non. [`pg_dumpall --globals-only`](https://www.postgresql.org/docs/18/app-pg-dumpall.html) écrit les rôles et les tablespaces.

Un dump est une copie à un instant. Ce qui s'est passé après est perdu, et restaurer une grande base veut dire recharger toutes ses données et reconstruire chaque index.

## Sauvegardes de base et sauvegardes incrémentales

Une sauvegarde physique copie les fichiers du cluster, comme un standby de la leçon 10 sans la réplication. [`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html) écrit un `backup_manifest` à côté d'eux, avec une somme de contrôle par fichier. Depuis PostgreSQL 17, une sauvegarde ultérieure peut ne copier que ce qui a changé depuis ce manifeste ([lignes 45-54](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L45-L54)) :

```bash
say "A full base backup, with its manifest, then new work on node1"
pg_basebackup -p 5433 -D base -c fast
ls base/backup_manifest
psql -X -q -p 5433 -d learn -c "UPDATE ci.runs SET conclusion = 'failure' WHERE run_id = (SELECT min(run_id) FROM ci.runs)"

say "An incremental backup holds only the blocks changed since the manifest it is given"
pg_basebackup -p 5433 -D incremental -c fast --incremental=base/backup_manifest
du -sk --exclude=pg_wal base incremental | awk '{ size[$2] = $1 } END { print "without WAL, the incremental backup is", (size["incremental"] * 3 < size["base"] ? "less" : "more"), "than a third of the full one" }'
pg_combinebackup base incremental -o combined
pg_verifybackup combined
```

```text
-- A full base backup, with its manifest, then new work on node1
base/backup_manifest

-- An incremental backup holds only the blocks changed since the manifest it is given
without WAL, the incremental backup is less than a third of the full one
backup successfully verified
```

- `--incremental` a besoin de [`summarize_wal = on`](https://www.postgresql.org/docs/18/runtime-config-wal.html#GUC-SUMMARIZE-WAL) sur le serveur : le WAL summarizer enregistre les blocs que chaque portion de WAL a modifiés.
- Sans leur WAL, la sauvegarde incrémentale fait moins du tiers de la complète : un seul `UPDATE` a tourné entre les deux.
- Une sauvegarde incrémentale ne peut pas être démarrée directement. [`pg_combinebackup`](https://www.postgresql.org/docs/18/app-pgcombinebackup.html) « is used to reconstruct a synthetic full backup from an incremental backup and the earlier backups upon which it depends ».
- [`pg_verifybackup`](https://www.postgresql.org/docs/18/app-pgverifybackup.html) vérifie le résultat par rapport à son manifeste, et que le WAL dont il a besoin peut être analysé.

La documentation ajoute un avertissement : « PostgreSQL has no built-in mechanism to figure out which backups are still needed as a basis for restoring later incremental backups » ([archivage continu](https://www.postgresql.org/docs/18/continuous-archiving.html#BACKUP-INCREMENTAL-BACKUP)). Supprimer une sauvegarde complète casse toutes les incrémentales construites dessus.

## Archivage du WAL et restauration à un instant donné

Une sauvegarde de base plus chaque segment de WAL écrit depuis suffit pour rejouer le cluster jusqu'à n'importe quel moment : la [restauration à un instant donné](https://www.postgresql.org/docs/18/continuous-archiving.html). Sur `node1`, `archive_mode = on` et `archive_command` copient chaque segment terminé dans `/tmp/archive`. `%p` est le chemin du segment et `%f` son nom ; `test ! -f` refuse d'écraser un fichier archivé, l'exemple même de la documentation. En production, l'archive vit sur une autre machine.

Un point de restauration nommé, puis une erreur ([lignes 56-61](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L56-L61)) :

```bash
say "Later: a named restore point, then a mistake"
sql 5433 -c "SELECT pg_create_restore_point('before_truncate') IS NOT NULL AS restore_point"
sql 5433 -c "TRUNCATE ci.runs CASCADE"
wal=$(psql -X -Atq -p 5433 -c 'SELECT pg_walfile_name(pg_switch_wal())')
until_true 5433 postgres "SELECT last_archived_wal >= '$wal' FROM pg_stat_archiver"
sql 5433 -c "$counts"
```

```text
-- Later: a named restore point, then a mistake
 restore_point
---------------
 t
(1 row)

NOTICE:  truncate cascades to table "jobs"
NOTICE:  truncate cascades to table "steps"
TRUNCATE TABLE
 runs | jobs | steps
------+------+-------
    0 |    0 |     0
(1 row)
```

- [`pg_create_restore_point`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-BACKUP) écrit un nom dans le WAL, comme une transaction marquée pour le `STOPATMARK` de SQL Server.
- `TRUNCATE … CASCADE` vide les trois tables de CI.
- `pg_switch_wal()` termine le segment courant, pour qu'il soit archivé maintenant plutôt que lorsqu'il sera plein ; [`pg_stat_archiver`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ARCHIVER-VIEW) dit quand.

La restauration, sur `node2`, depuis la sauvegarde combinée ([lignes 63-78](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L63-L78)) :

```bash
say "Point-in-time recovery on node2: the combined backup, the archived WAL, and a target"
cp -r combined node2
chmod 700 node2
cat >> node2/postgresql.conf <<'EOF'
archive_mode = off
restore_command = 'cp /tmp/archive/%f %p'
recovery_target_name = 'before_truncate'
recovery_target_action = 'promote'
EOF
touch node2/recovery.signal
pg_ctl -D node2 -l node2.log -o "-p 5434" -w start > /dev/null || exit 1
until_true 5434 postgres "SELECT NOT pg_is_in_recovery()"
grep -o 'recovery stopping at restore point "[a-z_]*"' node2.log
sql 5434 -c "$counts"
sql 5434 -c "SELECT conclusion FROM ci.runs ORDER BY run_id LIMIT 1"
sql 5434 -c "SELECT substr(pg_walfile_name(pg_current_wal_lsn()), 1, 8) AS timeline"
```

```text
-- Point-in-time recovery on node2: the combined backup, the archived WAL, and a target
recovery stopping at restore point "before_truncate"
 runs | jobs | steps
------+------+-------
  125 |  315 |  2204
(1 row)

 conclusion
------------
 failure
(1 row)

 timeline
----------
 00000002
(1 row)
```

- `recovery.signal` démarre le serveur en récupération. `restore_command` va chercher les segments archivés, l'inverse d'`archive_command`.
- [`recovery_target_name`](https://www.postgresql.org/docs/18/runtime-config-wal.html#RUNTIME-CONFIG-WAL-RECOVERY-TARGET) arrête le rejeu au point de restauration ; `recovery_target_time`, `recovery_target_xid` et `recovery_target_lsn` sont les autres cibles. `recovery_target_action = 'promote'` ouvre le serveur aux écritures quand il y arrive.
- Les trois tables sont de retour, avec l'`UPDATE` fait entre les deux sauvegardes : `failure`. Le serveur restauré continue sur la timeline 2, comme après une promotion dans la leçon 10.
- `archive_mode = off` sur `node2` : la copie ne doit pas écrire ses segments dans l'archive de `node1`.

## Une mise à niveau majeure avec pg_upgrade

Le programme d'installation de SQL Server met une instance à niveau sur place. Les versions majeures de PostgreSQL changent le format des catalogues système, donc une mise à niveau crée un nouveau cluster avec l'`initdb` de la nouvelle version, et [`pg_upgrade`](https://www.postgresql.org/docs/18/pgupgrade.html) y déplace les bases : il exporte et restaure le schéma, et réutilise les fichiers de données, dont les versions majeures changent rarement le format. Les versions mineures, de 18.5 à 18.6, n'ont besoin que des nouveaux binaires.

[`ops/11-upgrade.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh) a besoin des binaires de PostgreSQL 17 à côté de ceux de 18. L'image utilise déjà le [dépôt apt](https://wiki.postgresql.org/wiki/Apt) du projet PostgreSQL, donc `check.sh` les installe en root avant d'exécuter le script :

```bash
# Il faut les binaires de PostgreSQL 17 dans le conteneur du cours, installés d'abord en root (check.sh le fait) :
# docker exec pg sh -c 'apt-get update -qq && apt-get install -qq -y --no-install-recommends postgresql-17'
```

Un cluster PostgreSQL 17 avec les exécutions, leurs statistiques, et des statistiques étendues de la [leçon 5](../05-indexes/) ([lignes 14-36](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L14-L36)) :

```bash
say "A PostgreSQL 17 cluster, with a table, its statistics, and extended statistics"
$old/initdb -D pg17 --auth=trust > /dev/null
$old/pg_ctl -D pg17 -l pg17.log -o "-p 5436" -w start > /dev/null || exit 1
psql -X -q -p 5436 -c 'CREATE DATABASE learn'
sql 5436 -q <<'EOF'
CREATE SCHEMA ci;
CREATE TABLE ci.runs (
    run_id bigint PRIMARY KEY, workflow_name text NOT NULL, event text NOT NULL, conclusion text,
    head_branch text NOT NULL, created_at timestamptz NOT NULL
);
INSERT INTO ci.runs
SELECT r."databaseId", r."workflowName", r.event, r.conclusion, r."headBranch", r."createdAt"
FROM jsonb_to_recordset(pg_read_file('/course/data/runs.json')::jsonb) AS r(
    "databaseId" bigint, "workflowName" text, event text, conclusion text, "headBranch" text, "createdAt" timestamptz);
CREATE STATISTICS ci.runs_workflow_event (dependencies) ON workflow_name, event FROM ci.runs;
ANALYZE ci.runs;
EOF
# La version majeure seulement : la mineure change avec les paquets Debian
sql 5436 -c "SELECT current_setting('server_version_num')::int / 10000 AS version, current_setting('data_checksums') AS checksums"
statistics="SELECT (SELECT count(*) FROM pg_stats WHERE schemaname = 'ci') AS column_stats,
                   (SELECT count(*) FROM pg_stats_ext WHERE statistics_schemaname = 'ci') AS extended_stats"
sql 5436 -c "$statistics"
$old/pg_ctl -D pg17 -m fast -w stop > /dev/null
```

```text

-- A PostgreSQL 17 cluster, with a table, its statistics, and extended statistics
 version | checksums
---------+-----------
      17 | off
(1 row)

 column_stats | extended_stats
--------------+----------------
            6 |              1
(1 row)
```

La table est plus simple que celle de `schema.sql`, qui utilise une colonne générée virtuelle, nouvelle dans 18. Le script n'affiche que la version majeure : la mineure suit les paquets Debian.

Un premier essai, avec `--check`, qui n'exécute que les vérifications ([lignes 38-42](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L38-L42)) :

```bash
say "A new 18 cluster: initdb 18 turns data checksums on, 17 left them off"
$new/initdb -D pg18 --auth=trust > /dev/null
$new/pg_upgrade --old-bindir=$old --new-bindir=$new --old-datadir=pg17 --new-datadir=pg18 --check 2>&1 | grep -v '^$'
rm -rf pg18
$new/initdb -D pg18 --auth=trust --no-data-checksums > /dev/null
```

```text
-- A new 18 cluster: initdb 18 turns data checksums on, 17 left them off
Performing Consistency Checks
-----------------------------
Checking cluster versions                                     ok
old cluster does not use data checksums but the new one does
Failure, exiting
```

`initdb` 18 active les sommes de contrôle des données par défaut, et 17 ne le faisait pas. Les notes de version indiquent la sortie : « Checksums can be disabled with the new initdb option `--no-data-checksums`. pg_upgrade requires matching cluster checksum settings ». Le nouveau cluster est recréé sans elles.

La mise à niveau ([lignes 44-51](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L44-L51)) :

```bash
say "The upgrade: --swap moves the old data directory into the new cluster, so the 17 cluster can't be started again"
$new/pg_upgrade --old-bindir=$old --new-bindir=$new --old-datadir=pg17 --new-datadir=pg18 --swap 2>&1 | grep -v '^$'
$new/pg_ctl -D pg18 -l pg18.log -o "-p 5436" -w start > /dev/null || exit 1
sql 5436 -c "SELECT current_setting('server_version_num')::int / 10000 AS version, count(*) AS runs FROM ci.runs"
# Les statistiques de colonnes ont été transférées ; les statistiques étendues, non
sql 5436 -c "$statistics"
$new/vacuumdb -p 5436 --all --analyze-only --missing-stats-only 2>&1
sql 5436 -c "$statistics"
```

```text
Performing Consistency Checks
-----------------------------
Checking cluster versions                                     ok
Checking database connection settings                         ok
Checking database user is the install user                    ok
Checking for prepared transactions                            ok
Checking for contrib/isn with bigint-passing mismatch         ok
Checking for valid logical replication slots                  ok
Checking for subscription state                               ok
Checking data type usage                                      ok
Checking for objects affected by Unicode update               ok
Checking for not-null constraint inconsistencies              ok
Creating dump of global objects                               ok
Creating dump of database schemas                             ok
Checking for presence of required libraries                   ok
Checking database user is the install user                    ok
Checking for prepared transactions                            ok
Checking for new cluster tablespace directories               ok
If pg_upgrade fails after this point, you must re-initdb the
new cluster before continuing.
Performing Upgrade
------------------
Setting locale and encoding for new cluster                   ok
Analyzing all rows in the new cluster                         ok
Freezing all rows in the new cluster                          ok
Deleting files from new pg_xact                               ok
Copying old pg_xact to new server                             ok
Setting oldest XID for new cluster                            ok
Setting next transaction ID and epoch for new cluster         ok
Deleting files from new pg_multixact/offsets                  ok
Copying old pg_multixact/offsets to new server                ok
Deleting files from new pg_multixact/members                  ok
Copying old pg_multixact/members to new server                ok
Setting next multixact ID and offset for new cluster          ok
Resetting WAL archives                                        ok
Setting frozenxid and minmxid counters in new cluster         ok
Restoring global objects in the new cluster                   ok
Restoring database schemas in the new cluster                 ok
Adding ".old" suffix to old "global/pg_control"               ok
Because "swap" mode was used, the old cluster can no longer be
safely started.
Swapping data directories                                     ok
Setting next OID for new cluster                              ok
Sync data directory to disk                                   ok
Creating script to delete old cluster                         ok
Checking for extension updates                                ok
Upgrade Complete
----------------
Some statistics are not transferred by pg_upgrade.
Once you start the new server, consider running these two commands:
    /usr/lib/postgresql/18/bin/vacuumdb --all --analyze-in-stages --missing-stats-only
    /usr/lib/postgresql/18/bin/vacuumdb --all --analyze-only
Running this script will delete the old cluster's data files:
    ./delete_old_cluster.sh
 version | runs
---------+------
      18 |  125
(1 row)

 column_stats | extended_stats
--------------+----------------
            6 |              0
(1 row)

vacuumdb: vacuuming database "learn"
vacuumdb: vacuuming database "postgres"
vacuumdb: vacuuming database "template1"
 column_stats | extended_stats
--------------+----------------
            6 |              1
(1 row)
```

- `pg_upgrade` vérifie, exporte l'ancien schéma, le restaure dans le nouveau cluster, puis reprend les identifiants de transaction et les fichiers de données.
- `--swap`, nouveau dans PostgreSQL 18, déplace les répertoires de données de l'ancien cluster dans le nouveau au lieu de copier ou de lier les fichiers ; la documentation dit qu'il « can outperform `--link`, `--clone`, `--copy`, and `--copy-file-range`, especially on clusters with many relations ». Le prix est dans la sortie : « the old cluster can no longer be safely started ». Sans sauvegarde, pas de retour en arrière.
- Nouveau aussi dans 18, `pg_upgrade` « will transfer most optimizer statistics from the old cluster to the new cluster » : les six statistiques de colonnes sont là, et le serveur peut bien planifier dès sa première requête. Les statistiques étendues, non.
- [`vacuumdb --analyze-only --missing-stats-only`](https://www.postgresql.org/docs/18/app-vacuumdb.html), une autre option de PostgreSQL 18, n'analyse que ce qui n'a pas de statistiques, et ramène les statistiques étendues. Le conseil de `pg_upgrade` lui-même est de l'exécuter d'abord avec `--analyze-in-stages`.

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* Aurora gère lui-même les sauvegardes, et ses restaurations créent de nouveaux clusters.

- **Sauvegardes continues.** « Aurora automated backups are continuous and incremental, so you can quickly restore to any point within the backup retention period », période qui va « from 1–35 days », un jour par défaut ; « you can't disable automated backups on Aurora » ([sauvegardes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Backups.html)). Il n'y a pas d'`archive_command` à régler : « Amazon Aurora uploads log records for DB clusters to Amazon S3 continuously » ([restauration à un instant donné](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-pitr.html)).
- **La restauration à un instant donné** crée un nouveau cluster, comme `node2` était un nouveau cluster ici. Le dernier instant restaurable « is typically within 5 minutes of the current time ». Les snapshots manuels gardent les données au-delà de la période de rétention : « Aurora DB cluster snapshots don't expire ».
- **Pas de retour arrière pour PostgreSQL.** Backtrack, qui ramène un cluster en arrière sur place, est réservé à Aurora MySQL ([Backtrack](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html)).
- **Clones.** « Aurora uses a copy-on-write protocol to create a clone », qui partage le stockage avec sa source jusqu'à ce que l'un des deux le modifie ; « you can create up to 15 clones with copy-on-write protocol », dans la même région ([clonage](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Clone.html)). Un clone est le moyen peu coûteux de tester une restauration ou une mise à niveau sur des données réelles.
- **Dumps et exports.** `pg_dump` et `pg_restore` marchent depuis une machine cliente ; je n'ai trouvé la procédure d'AWS que dans le [guide de RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Procedural.Importing.EC2.html), pas dans celui d'Aurora. L'extension [`aws_s3`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/postgresql-s3-export.html) exporte le résultat d'une requête directement vers S3 avec `aws_s3.query_export_to_s3`.
- **Les mises à niveau majeures utilisent pg_upgrade.** « To safely upgrade the DB instances that make up your cluster, Aurora PostgreSQL uses the pg_upgrade utility » ([mises à niveau de version majeure](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html)). Avant : « Drop logical replication slots. The upgrade process can't proceed if the Aurora PostgreSQL DB cluster is using any logical replication slots ». Aurora prend un snapshot nommé avec un préfixe `preupgrade`.
- **Statistiques : une contradiction à vérifier.** La même page dit « Optimizer statistics aren't transferred during a major version upgrade, so you need to regenerate all statistics », alors que `pg_upgrade` 18 les transfère, comme l'a montré cette leçon. Qu'une mise à niveau vers Aurora PostgreSQL 18 les garde n'est pas documenté : exécute `ANALYZE` de toute façon.
- **Les déploiements blue/green** copient un cluster dans un environnement green tenu synchronisé par réplication logique, où la mise à niveau s'exécute, puis basculent ; « the switchover typically takes under a minute with no data loss » ([présentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-overview.html)). Les limites sont celles de la réplication logique : « Data definition language (DDL) statements, such as CREATE TABLE and CREATE SCHEMA, aren't replicated from the blue environment to the green environment » ([considérations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html)). Le [tableau des versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.BlueGreenDeployments.html) s'arrête à Aurora PostgreSQL 17.
- **Les versions mineures** peuvent être appliquées avec le zero-downtime patching (ZDP), où « application sessions are maintained except for those with dropped connections », avec une baisse de débit qui « typically lasts only for a few seconds or at most, approximately one minute » ([mises à niveau mineures](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MinorUpgrade.html)).

## À retenir

- `pg_dump` copie une base à un instant ; les rôles viennent de `pg_dumpall --globals-only`.
- Le format custom permet à `pg_restore` de choisir des objets et de restaurer en parallèle.
- Les sauvegardes de base ont des manifestes ; les sauvegardes incrémentales ont besoin de `summarize_wal`, des sauvegardes dont elles dépendent, et de `pg_combinebackup`.
- L'archivage du WAL plus une sauvegarde de base donne la restauration à un instant donné, jusqu'à une heure, un point nommé, une transaction ou un LSN.
- Une mise à niveau majeure est un nouveau cluster : les sommes de contrôle doivent correspondre, `--swap` est rapide et sans retour, et 18 garde la plupart des statistiques.
- Sur Aurora, les sauvegardes sont continues, les restaurations et les clones créent de nouveaux clusters, et les mises à niveau exécutent toujours `pg_upgrade`.

## Exercices

Les solutions sont dans [`ops/11-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh), sur un cluster comme `node1` ([lignes 19-28](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L19-L28)).

1. Quelqu'un supprime toutes les lignes de `ga.iconic_chords`. Ramène les lignes de cette table depuis un dump au format custom, sans toucher aux autres tables.

<details>
<summary>Solution</summary>

[Lignes 30-34](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L30-L34) :

```bash
say "Exercise 1: the iconic chords are deleted by mistake; only that table's data comes back from the dump"
pg_dump -p 5433 -d learn --format=custom --file=learn.dump
sql 5433 -c "DELETE FROM ga.iconic_chords"
pg_restore -p 5433 -d learn --data-only --table=iconic_chords learn.dump
sql 5433 -c "SELECT count(*) AS chords FROM ga.iconic_chords"
```

```text
-- Exercise 1: the iconic chords are deleted by mistake; only that table's data comes back from the dump
DELETE 17
 chords
--------
     17
(1 row)
```

`--table` choisit la table et `--data-only` restaure ses lignes dans la table existante, sans essayer de la recréer. Les lignes sont celles du dump : ce qui a changé dans cette table après le dump est perdu, ce qu'évite la restauration à un instant donné.

</details>

2. Après une sauvegarde de base, un `UPDATE` marque la dernière exécution `cancelled`, puis une transaction supprime toutes les étapes. Restaure une copie qui a l'`UPDATE` mais pas le `DELETE`, en utilisant l'identifiant de la transaction comme cible.

<details>
<summary>Solution</summary>

[Lignes 36-55](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L36-L55) :

```bash
say "Exercise 2: a recovery that stops before the transaction of a DELETE, found by its ID"
pg_basebackup -p 5433 -D base -c fast
sql 5433 -q -c "UPDATE ci.runs SET conclusion = 'cancelled' WHERE run_id = (SELECT max(run_id) FROM ci.runs)"
xid=$(psql -X -Atq -p 5433 -d learn -c "BEGIN" -c "DELETE FROM ci.steps" -c "SELECT pg_current_xact_id()" -c "COMMIT" | sed -n 1p)
wal=$(psql -X -Atq -p 5433 -c 'SELECT pg_walfile_name(pg_switch_wal())')
until_true 5433 postgres "SELECT last_archived_wal >= '$wal' FROM pg_stat_archiver"
cp -r base node2
chmod 700 node2
cat >> node2/postgresql.conf <<EOF
archive_mode = off
restore_command = 'cp /tmp/archive/%f %p'
recovery_target_xid = '$xid'
recovery_target_inclusive = off
recovery_target_action = 'promote'
EOF
touch node2/recovery.signal
pg_ctl -D node2 -l node2.log -o "-p 5434" -w start > /dev/null || exit 1
until_true 5434 postgres "SELECT NOT pg_is_in_recovery()"
grep -o 'recovery stopping before commit of transaction' node2.log
sql 5434 -c "SELECT (SELECT count(*) FROM ci.steps) AS steps, (SELECT conclusion FROM ci.runs ORDER BY run_id DESC LIMIT 1) AS last_run"
```

```text
-- Exercise 2: a recovery that stops before the transaction of a DELETE, found by its ID
recovery stopping before commit of transaction
 steps | last_run
-------+-----------
  2204 | cancelled
(1 row)
```

[`pg_current_xact_id()`](https://www.postgresql.org/docs/18/functions-info.html#FUNCTIONS-PG-SNAPSHOT) donne l'identifiant de la transaction depuis l'intérieur de celle-ci. `recovery_target_xid` s'arrête au commit de cette transaction, et `recovery_target_inclusive = off` s'arrête juste avant : les étapes sont là, et l'exécution est `cancelled`. En pratique, l'identifiant d'une mauvaise transaction est rarement connu ; une heure tirée des journaux de l'application, avec `recovery_target_time`, est la cible habituelle.

</details>

## Sources

- Documentation de PostgreSQL 18 : [sauvegarde et restauration](https://www.postgresql.org/docs/18/backup.html), [dump SQL](https://www.postgresql.org/docs/18/backup-dump.html), [archivage continu et PITR](https://www.postgresql.org/docs/18/continuous-archiving.html), [`pg_dump`](https://www.postgresql.org/docs/18/app-pgdump.html), [`pg_restore`](https://www.postgresql.org/docs/18/app-pgrestore.html), [`pg_dumpall`](https://www.postgresql.org/docs/18/app-pg-dumpall.html), [`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html), [`pg_combinebackup`](https://www.postgresql.org/docs/18/app-pgcombinebackup.html), [`pg_verifybackup`](https://www.postgresql.org/docs/18/app-pgverifybackup.html), [réglages du WAL et cibles de récupération](https://www.postgresql.org/docs/18/runtime-config-wal.html), [fonctions de contrôle des sauvegardes](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-BACKUP), [`pg_upgrade`](https://www.postgresql.org/docs/18/pgupgrade.html), [mettre à niveau un cluster](https://www.postgresql.org/docs/18/upgrading.html), [`vacuumdb`](https://www.postgresql.org/docs/18/app-vacuumdb.html), [notes de version de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html), [notes de version de PostgreSQL 17](https://www.postgresql.org/docs/17/release-17.html) ; le [dépôt apt](https://wiki.postgresql.org/wiki/Apt)
- SQL Server : [vue d'ensemble des sauvegardes](https://learn.microsoft.com/sql/relational-databases/backup-restore/backup-overview-sql-server), [restaurer à un instant donné](https://learn.microsoft.com/sql/relational-databases/backup-restore/restore-a-sql-server-database-to-a-point-in-time-full-recovery-model), [choisir une méthode de mise à niveau](https://learn.microsoft.com/sql/database-engine/install-windows/choose-a-database-engine-upgrade-method)
- AWS : [sauvegardes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Backups.html), [restauration à un instant donné](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-pitr.html), [Backtrack](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html), [clonage](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Clone.html), [importer avec pg_dump sur RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Procedural.Importing.EC2.html), [exporter vers S3](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/postgresql-s3-export.html), [mises à niveau de version majeure](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html), [mises à niveau de version mineure](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MinorUpgrade.html), [présentation de blue/green](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-overview.html), [considérations](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html) et [versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.BlueGreenDeployments.html), toutes lues le 2026-09-16
