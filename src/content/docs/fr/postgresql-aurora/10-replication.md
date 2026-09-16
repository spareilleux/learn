---
title: "10. Réplication et haute disponibilité"
description: La réplication de PostgreSQL 18 pour les développeurs SQL Server — un standby construit avec pg_basebackup et un slot de réplication, des requêtes en lecture seule dessus, les commits synchrones et ce que fait vraiment l'annulation de l'un d'eux, un basculement qui perd un commit asynchrone, pg_rewind pour ramener l'ancien primaire, la réplication logique avec un filtre de lignes et un conflit — exécutés sur trois petits clusters dans le conteneur du cours, puis comparés aux Aurora Replicas.
sidebar:
  order: 10
---

Le script de la leçon est [`ops/10-replication.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh), et les exercices sont dans [`ops/10-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh). Ce sont des scripts shell, pas des scripts SQL : la réplication a besoin de plusieurs serveurs. `check.sh ops` les exécute dans le conteneur du cours et compare leur sortie à [`expected/10-replication.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/10-replication.txt) et [`expected/10-exercises.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/10-exercises.txt).

| SQL Server | PostgreSQL |
|---|---|
| journal des transactions | journal d'écriture anticipée (WAL), en fichiers de segments de 16 Mo |
| groupe de disponibilité, réplica secondaire | un serveur standby qui rejoue le WAL du primaire (réplication physique) |
| secondaire accessible en lecture | hot standby |
| modes de validation synchrone et asynchrone | `synchronous_standby_names` et `synchronous_commit` |
| basculement automatique avec un gestionnaire de cluster | `pg_promote()` ; la détection et la décision sont laissées à d'autres outils |
| log shipping | archivage du WAL et `restore_command` ([leçon 11](../11-backup/)) |
| réplication transactionnelle, publications et abonnements | réplication logique, publications et abonnements |

## Trois clusters dans un conteneur

Chaque modification des données est d'abord écrite dans le [journal d'écriture anticipée](https://www.postgresql.org/docs/18/wal-intro.html), comme le journal des transactions de SQL Server. Un standby est un serveur qui reçoit ce WAL du primaire et le rejoue, pour que ses fichiers restent une copie de ceux du primaire : la [réplication physique](https://www.postgresql.org/docs/18/warm-standby.html).

La réplication a besoin de plusieurs serveurs. Plutôt que plusieurs conteneurs, le script démarre de petits clusters *dans* le conteneur du cours, à côté du serveur du cours : [`initdb`](https://www.postgresql.org/docs/18/app-initdb.html) crée le répertoire d'un cluster, [`pg_ctl`](https://www.postgresql.org/docs/18/app-pg-ctl.html) le démarre sur son propre port, et `psql` l'atteint par le socket Unix. Pour l'exécuter :

```bash
bash server.sh start
bash server.sh sh < ops/10-replication.sh
```

`server.sh sh` envoie le script à `bash` dans le conteneur, en tant qu'utilisateur `postgres`. Quelques fonctions utilitaires viennent d'abord ([lignes 10-28](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L10-L28)) :

```bash
# say <text> : un titre dans la sortie ; lsn : masque les positions dans le WAL, qui changent d'une exécution à l'autre
say() { printf '\n-- %s\n' "$*"; }
lsn() { sed -E 's#[0-9A-F]+/[0-9A-F]{1,8}#X/XXXXXXXX#g'; }
# start <node> <port> : le port et le nom qu'annoncent les standbys vont sur la ligne de commande, donc les fichiers de configuration copiés ne gardent ni l'un ni l'autre
start() { pg_ctl -D "$1" -l "$1.log" -o "-p $2 -c cluster_name=$1" -w start > /dev/null || exit 1; }
# until_true <port> <database> <query> : interroge jusqu'à ce que la requête renvoie true, pendant 30 secondes au plus
until_true() {
  for _ in $(seq 150); do
    [ "$(psql -X -Atq -p "$1" -d "$2" -c "$3" 2>/dev/null)" = t ] && return 0
    sleep 0.2
  done
  echo "timed out on port $1: $3"
}
sql() { local port=$1; shift; psql -X -p "$port" -d learn "$@" 2>&1; }
# add_run <port> <run id> <workflow name> [psql options] : insère une exécution de la branche main
add_run() {
  sql "$1" "${@:4}" -c "INSERT INTO ci.runs VALUES ($2, '$3', 'push', 'success', 'main', repeat('a', 40), 1,
                        '2026-09-16 12:00+00', '2026-09-16 12:00+00', '2026-09-16 12:00+00')"
}
```

- `until_true` interroge une requête en boucle : la réplication est asynchrone, et le script attend un état avant de l'afficher, pour que la sortie soit la même à chaque exécution.
- `lsn` masque les positions dans le WAL, qui diffèrent d'une exécution à l'autre.
- `start` donne à chaque nœud son port et son `cluster_name` sur la ligne de commande : un standby copie les fichiers de configuration du primaire, et copierait sinon son port aussi.

Le premier nœud, avec le schéma du cours ([lignes 30-41](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L30-L41)) :

```bash
say "node1: a new cluster, with enough WAL for logical decoding, and the course schema"
initdb -D node1 --auth=trust > /dev/null
cat >> node1/postgresql.conf <<'EOF'
shared_buffers = 32MB
wal_level = logical
# pg_rewind relit le WAL jusqu'au dernier checkpoint commun aux deux nœuds : garder quelques segments au lieu de les recycler
wal_keep_size = 128MB
EOF
start node1 5433
psql -X -q -p 5433 -c 'CREATE DATABASE learn'
psql -X -q -p 5433 -d learn -c '\o /dev/null' -c '\i /course/sql/schema.sql'
sql 5433 -Atc 'SHOW data_checksums'
```

```text

-- node1: a new cluster, with enough WAL for logical decoding, and the course schema
on
```

`wal_level = logical` écrit assez de WAL pour la réplication logique, à la fin de la leçon ; la valeur par défaut, `replica`, suffit pour un standby. `data_checksums` vaut `on` : PostgreSQL 18 note « change[d] initdb default to enable data checksums » ([notes de version](https://www.postgresql.org/docs/18/release-18.html)), ce dont `pg_rewind` aura besoin.

## Un standby

[`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html) copie un cluster en marche par une connexion de réplication ([lignes 43-50](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L43-L50)) :

```bash
say "node2: a copy of node1 taken over a replication connection, with a slot and the settings of a standby (-R)"
pg_basebackup -p 5433 -D node2 -R -C -S node2 -X stream -c fast
ls node2/*.signal
grep -o "primary_slot_name = .*\|port=[0-9]*" node2/postgresql.auto.conf
start node2 5434
until_true 5433 learn "SELECT EXISTS (SELECT FROM pg_stat_replication WHERE application_name = 'node2' AND state = 'streaming')"
sql 5433 -c "SELECT application_name, state, sync_state FROM pg_stat_replication"
sql 5433 -c "SELECT slot_name, slot_type, active, wal_status FROM pg_replication_slots"
```

```text
-- node2: a copy of node1 taken over a replication connection, with a slot and the settings of a standby (-R)
node2/standby.signal
port=5433
primary_slot_name = 'node2'
 application_name |   state   | sync_state
------------------+-----------+------------
 node2            | streaming | async
(1 row)

 slot_name | slot_type | active | wal_status
-----------+-----------+--------+------------
 node2     | physical  | t      | reserved
(1 row)
```

- `-R` écrit `standby.signal`, qui démarre la copie comme standby, et `primary_conninfo` dans `postgresql.auto.conf`, qui lui dit où est le primaire.
- `-C -S node2` crée un [slot de réplication](https://www.postgresql.org/docs/18/warm-standby.html#STREAMING-REPLICATION-SLOTS) sur le primaire et l'utilise : le primaire garde le WAL que `node2` n'a pas encore reçu, même pendant que `node2` est arrêté. `wal_status = reserved` indique que le WAL est gardé. Un slot dont le standby ne revient jamais garde le WAL indéfiniment ; [`max_slot_wal_keep_size`](https://www.postgresql.org/docs/18/runtime-config-replication.html#GUC-MAX-SLOT-WAL-KEEP-SIZE) le plafonne.
- `-X stream` transmet en flux le WAL écrit pendant la copie, en même temps qu'elle.
- [`pg_stat_replication`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-REPLICATION-VIEW) sur le primaire liste ses standbys : `node2`, le `cluster_name` qu'il annonce, est en `streaming`, de façon asynchrone.

Un standby est un *hot standby* : il répond aux requêtes, et refuse les écritures ([lignes 52-57](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L52-L57)) :

```bash
say "A write on node1 is replayed on node2, which answers read-only queries"
add_run 5433 1 'Replication test' -q
lsn=$(psql -X -Atq -p 5433 -c 'SELECT pg_current_wal_lsn()')
until_true 5434 learn "SELECT pg_last_wal_replay_lsn() >= '$lsn'"
sql 5434 -c "SELECT pg_is_in_recovery(), workflow_name FROM ci.runs WHERE run_id = 1"
sql 5434 -c "DELETE FROM ci.runs WHERE run_id = 1"
```

```text
-- A write on node1 is replayed on node2, which answers read-only queries
 pg_is_in_recovery |  workflow_name
-------------------+------------------
 t                 | Replication test
(1 row)

ERROR:  cannot execute DELETE in a read-only transaction
```

Le script attend que `node2` ait rejoué la position que `node1` avait atteinte après l'`INSERT`, puis lit. Sans cette attente, une lecture sur un standby peut manquer une écriture tout juste validée sur le primaire : le retard que la leçon 3 décrivait pour les Aurora Replicas.

## Réplication synchrone

Par défaut, un commit revient une fois que le primaire a écrit son WAL. [`synchronous_standby_names`](https://www.postgresql.org/docs/18/runtime-config-replication.html#GUC-SYNCHRONOUS-STANDBY-NAMES) le fait aussi attendre des standbys ([lignes 59-73](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L59-L73)) :

```bash
say "Synchronous replication: node1's commits now wait for node2 to confirm"
sql 5433 -qc "ALTER SYSTEM SET synchronous_standby_names = 'FIRST 1 (node2)'" -c 'SELECT pg_reload_conf()' -o /dev/null
until_true 5433 learn "SELECT EXISTS (SELECT FROM pg_stat_replication WHERE sync_state = 'sync')"
sql 5433 -c "SELECT application_name, sync_state FROM pg_stat_replication"
pg_ctl -D node2 -m fast -w stop > /dev/null
echo "node2 stopped"
# Le commit est écrit localement, puis attend un standby qui n'est pas là. statement_timeout ne couvre pas cette attente :
# une autre session l'annule, ce qui termine l'attente mais pas le commit
add_run 5433 2 'Committed locally' > insert.log &
until_true 5433 learn "SELECT EXISTS (SELECT FROM pg_stat_activity WHERE wait_event = 'SyncRep')"
sql 5433 -c "SELECT wait_event_type, wait_event, pg_cancel_backend(pid) FROM pg_stat_activity WHERE wait_event = 'SyncRep'"
wait
cat insert.log
sql 5433 -c "SELECT run_id, workflow_name FROM ci.runs WHERE run_id < 100 ORDER BY run_id"
sql 5433 -qc "ALTER SYSTEM RESET synchronous_standby_names" -c 'SELECT pg_reload_conf()' -o /dev/null
```

```text
-- Synchronous replication: node1's commits now wait for node2 to confirm
 application_name | sync_state
------------------+------------
 node2            | sync
(1 row)

node2 stopped
 wait_event_type | wait_event | pg_cancel_backend
-----------------+------------+-------------------
 IPC             | SyncRep    | t
(1 row)

WARNING:  canceling wait for synchronous replication due to user request
DETAIL:  The transaction has already committed locally, but might not have been replicated to the standby.
INSERT 0 1
 run_id |   workflow_name
--------+-------------------
      1 | Replication test
      2 | Committed locally
(2 rows)
```

- `FIRST 1 (node2)` attend un standby, le premier de la liste qui est connecté. `sync_state` devient `sync`.
- Avec `node2` arrêté, l'`INSERT` attend : `pg_stat_activity` le montre sur l'événement d'attente `SyncRep`, et il attendrait indéfiniment.
- Le commit est déjà dans le WAL de node1. Annuler l'attente ne le défait pas : l'avertissement le dit, et l'exécution 2 est dans la table. Un client qui perd sa connexion pendant cette attente ne peut pas savoir si sa transaction a été validée.
- Une première version de ce script mettait `SET statement_timeout = '2s'` avant l'`INSERT` : l'`INSERT` a quand même attendu, dix minutes, jusqu'à ce que je l'annule à la main. L'attente vient après l'instruction, au commit : PostgreSQL désactive le délai d'instruction avant de valider ([`postgres.c`, `finish_xact_command`](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/tcop/postgres.c#L2826-L2833), à `REL_18_6`).

[`synchronous_commit`](https://www.postgresql.org/docs/18/runtime-config-wal.html#GUC-SYNCHRONOUS-COMMIT) règle ce qu'attend le primaire : `on`, l'écriture sur disque du standby ; `remote_write`, son écriture ; `remote_apply`, son rejeu, qui « will cause each commit to wait until the current synchronous standbys report that they have replayed the transaction, making it visible to user queries » ([la documentation](https://www.postgresql.org/docs/18/warm-standby.html#SYNCHRONOUS-REPLICATION)). Il peut être réglé par transaction, pour les écritures qui ne doivent pas être perdues.

## Basculement, et le commit perdu

De nouveau en réplication asynchrone et avec `node2` toujours arrêté, `node1` valide l'exécution 3, puis s'arrête. `node2` démarre et est promu avec [`pg_promote()`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-RECOVERY-CONTROL) ([lignes 75-85](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L75-L85)) :

```bash
say "Asynchronous again, node2 still down: node1 commits a run that node2 will never receive"
add_run 5433 3 'Lost in the failover' -q
pg_ctl -D node1 -m fast -w stop > /dev/null
echo "node1 stopped"

say "Failover: node2 starts, is promoted, and becomes a primary on a new timeline"
start node2 5434
sql 5434 -c "SELECT pg_promote()"
sql 5434 -c "SELECT pg_is_in_recovery(), substr(pg_walfile_name(pg_current_wal_lsn()), 1, 8) AS timeline"
sql 5434 -c "SELECT run_id, workflow_name FROM ci.runs WHERE run_id < 100 ORDER BY run_id"
add_run 5434 4 'After the failover' -q
```

```text
-- Asynchronous again, node2 still down: node1 commits a run that node2 will never receive
node1 stopped

-- Failover: node2 starts, is promoted, and becomes a primary on a new timeline
 pg_promote
------------
 t
(1 row)

 pg_is_in_recovery | timeline
-------------------+----------
 f                 | 00000002
(1 row)

 run_id |  workflow_name
--------+------------------
      1 | Replication test
(1 row)
```

- `node2` est maintenant un primaire, sur la **timeline** 2 : les huit premiers chiffres hexadécimaux d'un nom de fichier WAL. Une nouvelle timeline commence à chaque promotion, pour que le WAL écrit après elle ne puisse pas être confondu avec du WAL que l'ancien primaire a pu écrire.
- Les exécutions 2 et 3 manquent. L'exécution 2 a été validée pendant que `node2` était arrêté, la 3 aussi. Un basculement vers un standby asynchrone perd ce que le standby n'avait pas reçu.
- PostgreSQL ne décide pas lui-même de basculer : « PostgreSQL does not provide the system software required to identify a failure on the primary and notify the standby database server » ([basculement](https://www.postgresql.org/docs/18/warm-standby-failover.html)). Des outils extérieurs à PostgreSQL surveillent le primaire, promeuvent un standby et déplacent les clients ; sur Aurora, AWS s'en charge.

## Ramener l'ancien primaire avec pg_rewind

`node1` a les exécutions 2 et 3 dans ses fichiers, sur la timeline 1, après le point où `node2` a divergé. Il ne peut pas suivre `node2` en l'état. [`pg_rewind`](https://www.postgresql.org/docs/18/app-pgrewind.html) recopie depuis `node2` les blocs qui ont changé depuis leur dernier checkpoint commun, au lieu d'une copie entière ([lignes 87-94](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L87-L94)) :

```bash
say "node1 can't simply follow node2: its WAL went further on the old timeline. pg_rewind takes it back."
pg_rewind -D node1 --source-server='port=5434 dbname=postgres' -R 2>&1 | lsn
sql 5434 -Atc "SELECT pg_create_physical_replication_slot('node1') IS NOT NULL" -o /dev/null
pg_ctl -D node1 -l node1.log -o "-p 5433 -c cluster_name=node1 -c primary_slot_name=node1" -w start > /dev/null
until_true 5434 learn "SELECT EXISTS (SELECT FROM pg_stat_replication WHERE application_name = 'node1' AND state = 'streaming')"
lsn=$(psql -X -Atq -p 5434 -c 'SELECT pg_current_wal_lsn()')
until_true 5433 learn "SELECT pg_last_wal_replay_lsn() >= '$lsn'"
sql 5433 -c "SELECT pg_is_in_recovery(), run_id, workflow_name FROM ci.runs WHERE run_id < 100 ORDER BY run_id"
```

```text
-- node1 can't simply follow node2: its WAL went further on the old timeline. pg_rewind takes it back.
pg_rewind: servers diverged at WAL location X/XXXXXXXX on timeline 1
pg_rewind: rewinding from last common checkpoint at X/XXXXXXXX on timeline 1
pg_rewind: Done!
 pg_is_in_recovery | run_id |   workflow_name
-------------------+--------+--------------------
 t                 |      1 | Replication test
 t                 |      4 | After the failover
(2 rows)
```

- `pg_rewind` « requires that the target server either has the `wal_log_hints` option enabled in `postgresql.conf` or data checksums enabled », et a besoin du WAL de la cible jusqu'au checkpoint commun. Une première version du script a échoué avec `could not open file "node1/pg_wal/000000010000000000000002"` : `node1` avait déjà recyclé ce segment. `wal_keep_size = 128MB` le garde.
- `-R` écrit `standby.signal` et un `primary_conninfo` qui pointe vers `node2`.
- `node1` revient comme standby de `node2`, par un slot créé pour lui : les exécutions 2 et 3 ont disparu, l'exécution 4 est là.

## Réplication logique

La réplication physique copie un cluster entier, bloc par bloc, vers des serveurs de la même version majeure. La [réplication logique](https://www.postgresql.org/docs/18/logical-replication.html) envoie des *lignes* : les modifications de tables choisies, décodées depuis le WAL, vers n'importe quel serveur PostgreSQL qui a des tables correspondantes. `node3` est un nouveau cluster, indépendant ([lignes 96-108](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L96-L108)) :

```bash
say "Logical replication: node3, a separate cluster, subscribes to the runs table of node2"
initdb -D node3 --auth=trust > /dev/null
echo "shared_buffers = 32MB" >> node3/postgresql.conf
start node3 5435
psql -X -q -p 5435 -c 'CREATE DATABASE learn'
# La réplication logique transporte des lignes, pas le schéma : la table est créée d'abord
psql -X -q -p 5435 -d learn -c 'CREATE EXTENSION btree_gist'
pg_dump -p 5434 -d learn --schema-only --schema=ci | psql -X -q -p 5435 -d learn > /dev/null
sql 5434 -c "CREATE PUBLICATION runs_on_main FOR TABLE ci.runs WHERE (head_branch = 'main')"
sql 5435 -c "CREATE SUBSCRIPTION runs_from_node2 CONNECTION 'port=5434 dbname=learn' PUBLICATION runs_on_main"
until_true 5435 learn "SELECT count(*) = 0 FROM pg_subscription_rel WHERE srsubstate <> 'r'"
sql 5434 -c "SELECT head_branch = 'main' AS on_main, count(*) FROM ci.runs GROUP BY 1 ORDER BY 1"
sql 5435 -c "SELECT head_branch = 'main' AS on_main, count(*) FROM ci.runs GROUP BY 1 ORDER BY 1"
```

```text
-- Logical replication: node3, a separate cluster, subscribes to the runs table of node2
CREATE PUBLICATION
NOTICE:  created replication slot "runs_from_node2" on publisher
CREATE SUBSCRIPTION
 on_main | count
---------+-------
 f       |     2
 t       |   125
(2 rows)

 on_main | count
---------+-------
 t       |   125
(1 row)
```

- « The database schema and DDL commands are not replicated » ([restrictions](https://www.postgresql.org/docs/18/logical-replication-restrictions.html)) : `pg_dump --schema-only` crée d'abord les tables sur `node3`, ce que suggère aussi la documentation.
- [`CREATE PUBLICATION`](https://www.postgresql.org/docs/18/sql-createpublication.html) sur l'éditeur liste les tables, ici avec un [filtre de lignes](https://www.postgresql.org/docs/18/logical-replication-row-filter.html) : seulement les exécutions de `main`.
- [`CREATE SUBSCRIPTION`](https://www.postgresql.org/docs/18/sql-createsubscription.html) sur l'abonné crée un slot de réplication logique sur l'éditeur, copie les lignes existantes, puis applique les modifications au fil de l'eau. `pg_subscription_rel` montre l'état de chaque table ; `r` signifie prête.
- 125 exécutions de `main` sur `node3`, et pas les deux autres.

L'abonné est un primaire comme un autre, et rien n'y empêche une écriture ([lignes 110-119](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L110-L119)) :

```bash
say "The subscriber is an ordinary primary: it accepts writes, which can conflict with replicated rows"
add_run 5435 5 'Written on node3'
add_run 5434 5 'Written on node2' -q
until_true 5435 learn "SELECT confl_insert_exists > 0 FROM pg_stat_subscription_stats WHERE subname = 'runs_from_node2'"
sql 5435 -c "SELECT subname, apply_error_count > 0 AS apply_errors, confl_insert_exists > 0 AS insert_conflicts FROM pg_stat_subscription_stats"
grep -o 'ERROR:  conflict detected on relation "ci.runs": conflict=insert_exists' node3.log | head -1
# Supprimer la ligne de l'abonné permet à l'apply worker, qui réessaie, de passer le conflit
sql 5435 -qc "DELETE FROM ci.runs WHERE run_id = 5"
until_true 5435 learn "SELECT EXISTS (SELECT FROM ci.runs WHERE run_id = 5)"
sql 5435 -c "SELECT run_id, workflow_name FROM ci.runs WHERE run_id < 100 ORDER BY run_id"
```

```text
-- The subscriber is an ordinary primary: it accepts writes, which can conflict with replicated rows
INSERT 0 1
     subname     | apply_errors | insert_conflicts
-----------------+--------------+------------------
 runs_from_node2 | t            | t
(1 row)

ERROR:  conflict detected on relation "ci.runs": conflict=insert_exists
 run_id |   workflow_name
--------+--------------------
      1 | Replication test
      4 | After the failover
      5 | Written on node2
(3 rows)
```

- L'exécution 5 est insérée sur `node3`, puis sur `node2`. Quand la ligne de `node2` arrive, la clé existe déjà : un [conflit `insert_exists`](https://www.postgresql.org/docs/18/logical-replication-conflicts.html). « In this case, an error will be raised until the conflict is resolved manually. »
- PostgreSQL 18 compte les conflits par sorte dans [`pg_stat_subscription_stats`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-SUBSCRIPTION-STATS).
- L'apply worker s'arrête à l'erreur et redémarre plus tard, en échouant à chaque fois : la réplication de tout l'abonnement reste bloquée derrière cette seule ligne. Supprimer la ligne de `node3` la débloque, et la version de `node2` arrive. La documentation décrit aussi comment sauter la transaction avec `ALTER SUBSCRIPTION … SKIP` et le LSN écrit dans le journal.

Deux ajouts de PostgreSQL 17 complètent le tableau, non exécutés ici :

- [`pg_createsubscriber`](https://www.postgresql.org/docs/18/app-pgcreatesubscriber.html) « creates a new logical replica from a physical standby server », sans recopier les données.
- Les slots logiques peuvent suivre un basculement : un abonnement créé avec `failover = true`, et [`sync_replication_slots`](https://www.postgresql.org/docs/18/runtime-config-replication.html#GUC-SYNC-REPLICATION-SLOTS) sur le standby, permettent aux abonnés de « resume replication from the new primary server after failover » ([basculement des slots logiques](https://www.postgresql.org/docs/18/logical-replication-failover.html)).

## Sur Aurora

*À vérifier : rien dans cette section n'a été exécuté sur AWS.* Aurora ne réplique pas ses instances comme le fait cette leçon.

- **Aurora Replicas.** « The cluster volume is shared among all instances in your Aurora PostgreSQL DB cluster. Thus, no extra work is needed to replicate a copy of the data for each Aurora Replica » ([réplication avec Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html)). Pas de `pg_basebackup` à exécuter, pas de slot à surveiller, et un cluster « can contain up to 15 Aurora Replicas » ([réplication Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html)), avec un retard « usually much less than 100 milliseconds ». La leçon 12 couvre leur basculement.
- **Pas de standby physique externe.** Les options de réplication que cette page liste pour Aurora PostgreSQL sont les Aurora Replicas, Global Database, la réplication logique, et une source RDS for PostgreSQL vers Aurora ; un standby à soi, alimenté par `pg_basebackup` et le streaming, n'en fait pas partie. Je n'ai trouvé aucune page qui le dise en toutes lettres.
- **La réplication logique** marche comme dans cette leçon, une fois activée : règle `rds.logical_replication` à 1 dans un groupe de paramètres de cluster personnalisé, puis « reboot the writer instance of your Aurora PostgreSQL DB cluster so that your changes takes effect » ([configurer la réplication logique](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.Configure.html)). La même page avertit que « leaving a logical replication slot inactive prevents the vacuum from removing obsolete tuples from tables ».
- **Depuis les réplicas.** « PostgreSQL 16 added support for logical decoding from read replicas. This feature isn't supported on Aurora PostgreSQL » ([réplication logique sur Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.html)).
- **pglogical** est disponible aussi : « all currently available Aurora PostgreSQL versions support the pglogical extension » ([pglogical](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.html)).
- **Construits sur la réplication logique.** Les déploiements blue/green ([leçon 11](../11-backup/#sur-aurora)) et les [intégrations zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html) avec Amazon Redshift, qui rendent les « transactional data available in your analytics destination after it is written to an Aurora DB cluster ». Le [tableau des versions zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.Zero-ETL.html) d'AWS ne liste qu'Aurora PostgreSQL 16 et 17.

## À retenir

- Un standby rejoue le WAL du primaire ; `pg_basebackup -R` en crée un, un slot garde le WAL dont il a encore besoin.
- Les standbys répondent aux requêtes en lecture seule, un peu en retard sur le primaire.
- Un commit synchrone est d'abord écrit localement : une attente annulée, ou une connexion perdue, ne te dit pas qu'il a échoué. `statement_timeout` ne couvre pas l'attente.
- Un basculement vers un standby asynchrone perd les commits qu'il n'avait pas reçus, et commence une nouvelle timeline.
- `pg_rewind` transforme l'ancien primaire en standby, en abandonnant ses commits divergents ; il a besoin des checksums ou de `wal_log_hints`, et du WAL jusqu'à la divergence.
- La réplication logique envoie les lignes de tables choisies, pas le schéma, et un conflit bloque tout l'abonnement jusqu'à ce que quelqu'un le règle.
- PostgreSQL promeut, mais ne décide pas quand : c'est le travail d'un outil, ou d'AWS sur Aurora.

## Exercices

Les solutions sont dans [`ops/10-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh), qui démarre `node1` et deux standbys, `node2` et `node3` ([lignes 20-31](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh#L20-L31)).

1. Mets en pause le rejeu sur `node2` avec [`pg_wal_replay_pause()`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-RECOVERY-CONTROL), écris sur `node1`, et montre depuis `node1` quel standby est en retard, en octets de WAL. Puis reprends.

<details>
<summary>Solution</summary>

[Lignes 33-43](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh#L33-L43) :

```bash
say "Exercise 1: node2 pauses its replay; the lag, in bytes of WAL, grows on node1's side, then goes back to 0"
sql 5434 -Atc 'SELECT pg_wal_replay_pause()' -o /dev/null
until_true 5434 learn "SELECT pg_get_wal_replay_pause_state() = 'paused'"
sql 5433 -q -c "INSERT INTO notes SELECT i, repeat('x', 100) FROM generate_series(1, 1000) AS i"
lag="SELECT application_name, pg_wal_lsn_diff(sent_lsn, replay_lsn) > 0 AS behind FROM pg_stat_replication ORDER BY 1"
until_true 5433 learn "SELECT bool_and(sent_lsn = pg_current_wal_lsn())
                         AND bool_and(replay_lsn = sent_lsn) FILTER (WHERE application_name = 'node3') FROM pg_stat_replication"
sql 5433 -c "$lag"
sql 5434 -Atc 'SELECT pg_wal_replay_resume()' -o /dev/null
until_true 5433 learn "SELECT bool_and(replay_lsn = sent_lsn) FROM pg_stat_replication"
sql 5433 -c "$lag"
```

```text
-- Exercise 1: node2 pauses its replay; the lag, in bytes of WAL, grows on node1's side, then goes back to 0
 application_name | behind
------------------+--------
 node2            | t
 node3            | f
(2 rows)

 application_name | behind
------------------+--------
 node2            | f
 node3            | f
(2 rows)
```

`pg_wal_lsn_diff` soustrait deux positions dans le WAL, en octets. `sent_lsn` a avancé pour les deux standbys : `node2` reçoit encore le WAL pendant que son rejeu est en pause, donc `sent_lsn - replay_lsn` est le retard de rejeu. Le script affiche s'il est positif, puisque le nombre exact d'octets change d'une exécution à l'autre.

</details>

2. Fais attendre les commits de l'un ou l'autre standby, `ANY 1 (node2, node3)`, puis arrête `node2`. Un commit passe-t-il encore ?

<details>
<summary>Solution</summary>

[Lignes 45-51](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh#L45-L51) :

```bash
say "Exercise 2: ANY 1 (node2, node3): a commit waits for one of the two, so it goes through with node2 stopped"
sql 5433 -qc "ALTER SYSTEM SET synchronous_standby_names = 'ANY 1 (node2, node3)'" -c 'SELECT pg_reload_conf()' -o /dev/null
until_true 5433 learn "SELECT count(*) = 2 FROM pg_stat_replication WHERE sync_state = 'quorum'"
sql 5433 -c "SELECT application_name, sync_state FROM pg_stat_replication ORDER BY 1"
pg_ctl -D node2 -m fast -w stop > /dev/null
sql 5433 -c "INSERT INTO notes VALUES (1001, 'one standby is enough')"
sql 5433 -qc "ALTER SYSTEM RESET synchronous_standby_names" -c 'SELECT pg_reload_conf()' -o /dev/null
```

```text
-- Exercise 2: ANY 1 (node2, node3): a commit waits for one of the two, so it goes through with node2 stopped
 application_name | sync_state
------------------+------------
 node2            | quorum
 node3            | quorum
(2 rows)

INSERT 0 1
```

Avec `ANY`, un quorum : les deux standbys sont candidats `quorum`, et une confirmation suffit. `FIRST 1 (node2, node3)` aurait aussi continué avec `node3`, comme premier standby *connecté* de la liste ; la différence se voit quand les deux sont en marche, où `FIRST` attend toujours `node2`, et `ANY` celui qui répond le premier.

</details>

3. Promeus `node3` pour qu'il devienne indépendant, puis réplique vers lui une table avec une colonne générée stockée. Sur `node3`, la colonne est une colonne ordinaire. Que reçoit-elle ?

<details>
<summary>Solution</summary>

[Lignes 53-62](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh#L53-L62) :

```bash
say "Exercise 3: node3 becomes a primary of its own, and subscribes to a table with a stored generated column"
sql 5435 -Atc 'SELECT pg_promote()' -o /dev/null
sql 5433 -q -c "CREATE TABLE sizes (id int PRIMARY KEY, body text NOT NULL, length int GENERATED ALWAYS AS (length(body)) STORED)"
# Sur node3, la colonne est une colonne ordinaire : elle reçoit les valeurs calculées sur node1
sql 5435 -q -c "CREATE TABLE sizes (id int PRIMARY KEY, body text NOT NULL, length int)"
sql 5433 -c "INSERT INTO sizes (id, body) VALUES (1, 'partition'), (2, 'replication')"
sql 5433 -c "CREATE PUBLICATION sizes_all FOR TABLE sizes WITH (publish_generated_columns = stored)"
sql 5435 -c "CREATE SUBSCRIPTION sizes_from_node1 CONNECTION 'port=5433 dbname=learn' PUBLICATION sizes_all"
until_true 5435 learn "SELECT count(*) = 2 FROM sizes"
sql 5435 -c "SELECT * FROM sizes ORDER BY id"
```

```text
-- Exercise 3: node3 becomes a primary of its own, and subscribes to a table with a stored generated column
INSERT 0 2
CREATE PUBLICATION
NOTICE:  created replication slot "sizes_from_node1" on publisher
CREATE SUBSCRIPTION
 id |    body     | length
----+-------------+--------
  1 | partition   |      9
  2 | replication |     11
(2 rows)
```

`node3` a encore `notes`, copiée avant sa promotion, mais pas `sizes` : il crée la sienne. [`publish_generated_columns = stored`](https://www.postgresql.org/docs/18/logical-replication-gencols.html), nouveau dans PostgreSQL 18, envoie les valeurs calculées sur `node1`. Par défaut, « generated columns are not published ». Seules les colonnes stockées peuvent être publiées : PostgreSQL 18 a aussi ajouté les colonnes générées virtuelles, la nouvelle valeur par défaut, qui ne le peuvent pas.

</details>

## Sources

- Documentation de PostgreSQL 18 : [WAL](https://www.postgresql.org/docs/18/wal-intro.html), [haute disponibilité et réplication](https://www.postgresql.org/docs/18/high-availability.html), [serveurs standby par log shipping](https://www.postgresql.org/docs/18/warm-standby.html), [basculement](https://www.postgresql.org/docs/18/warm-standby-failover.html), [réglages de la réplication](https://www.postgresql.org/docs/18/runtime-config-replication.html), [réglages du WAL](https://www.postgresql.org/docs/18/runtime-config-wal.html), [`initdb`](https://www.postgresql.org/docs/18/app-initdb.html), [`pg_ctl`](https://www.postgresql.org/docs/18/app-pg-ctl.html), [`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html), [`pg_rewind`](https://www.postgresql.org/docs/18/app-pgrewind.html), [fonctions de contrôle de la récupération](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-RECOVERY-CONTROL), [statistiques de supervision](https://www.postgresql.org/docs/18/monitoring-stats.html), [réplication logique](https://www.postgresql.org/docs/18/logical-replication.html), [filtres de lignes](https://www.postgresql.org/docs/18/logical-replication-row-filter.html), [colonnes générées](https://www.postgresql.org/docs/18/logical-replication-gencols.html), [conflits](https://www.postgresql.org/docs/18/logical-replication-conflicts.html), [restrictions](https://www.postgresql.org/docs/18/logical-replication-restrictions.html), [basculement des slots logiques](https://www.postgresql.org/docs/18/logical-replication-failover.html), [`CREATE PUBLICATION`](https://www.postgresql.org/docs/18/sql-createpublication.html), [`CREATE SUBSCRIPTION`](https://www.postgresql.org/docs/18/sql-createsubscription.html), [`pg_createsubscriber`](https://www.postgresql.org/docs/18/app-pgcreatesubscriber.html), [notes de version de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html), [notes de version de PostgreSQL 17](https://www.postgresql.org/docs/17/release-17.html)
- SQL Server : [modes de disponibilité](https://learn.microsoft.com/sql/database-engine/availability-groups/windows/availability-modes-always-on-availability-groups), [réplicas secondaires accessibles en lecture](https://learn.microsoft.com/sql/database-engine/availability-groups/windows/active-secondaries-readable-secondary-replicas-always-on-availability-groups), [modes de basculement](https://learn.microsoft.com/sql/database-engine/availability-groups/windows/failover-and-failover-modes-always-on-availability-groups), [log shipping](https://learn.microsoft.com/sql/database-engine/log-shipping/about-log-shipping-sql-server), [réplication transactionnelle](https://learn.microsoft.com/sql/relational-databases/replication/transactional/transactional-replication)
- AWS : [réplication Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html), [réplication avec Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html), [réplication logique](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.html), [sa configuration](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.Configure.html), [pglogical](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.html), [zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html) et [ses versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.Zero-ETL.html), toutes lues le 2026-09-16
