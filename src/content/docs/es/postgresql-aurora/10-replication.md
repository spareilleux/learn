---
title: "10. Replicación y alta disponibilidad"
description: Replicación en PostgreSQL 18 para desarrolladores SQL Server — un standby construido con pg_basebackup y un slot de replicación, consultas de solo lectura sobre él, commits síncronos y lo que hace realmente cancelar uno, una conmutación por error que pierde un commit asíncrono, pg_rewind para recuperar el antiguo primario, replicación lógica con un filtro de filas y un conflicto — ejecutado en tres pequeños clústeres dentro del contenedor del curso, y comparado después con las Aurora Replicas.
sidebar:
  order: 10
---

El script de la lección es [`ops/10-replication.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh), y los ejercicios están en [`ops/10-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh). Son scripts de shell, no scripts SQL: la replicación necesita varios servidores. `check.sh ops` los ejecuta en el contenedor del curso y compara su salida con [`expected/10-replication.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/10-replication.txt) y [`expected/10-exercises.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/10-exercises.txt).

| SQL Server | PostgreSQL |
|---|---|
| registro de transacciones | write-ahead log (WAL), en archivos de segmento de 16 MB |
| grupo de disponibilidad, réplica secundaria | un servidor standby que reproduce el WAL del primario (replicación física) |
| secundaria legible | hot standby |
| modos de confirmación síncrona y asíncrona | `synchronous_standby_names` y `synchronous_commit` |
| conmutación por error automática con un gestor de clúster | `pg_promote()`; la detección y la decisión quedan para otras herramientas |
| trasvase de registros | archivado del WAL y `restore_command` ([lección 11](../11-backup/)) |
| replicación transaccional, publicaciones y suscripciones | replicación lógica, publicaciones y suscripciones |

## Tres clústeres en un contenedor

Todo cambio en los datos se escribe primero en el [write-ahead log](https://www.postgresql.org/docs/18/wal-intro.html), como el registro de transacciones de SQL Server. Un standby es un servidor que recibe ese WAL del primario y lo reproduce, de modo que sus archivos siguen siendo una copia de los del primario: la [replicación física](https://www.postgresql.org/docs/18/warm-standby.html).

La replicación necesita varios servidores. En lugar de varios contenedores, el script arranca pequeños clústeres *dentro* del contenedor del curso, junto al servidor del curso: [`initdb`](https://www.postgresql.org/docs/18/app-initdb.html) crea el directorio de un clúster, [`pg_ctl`](https://www.postgresql.org/docs/18/app-pg-ctl.html) lo arranca en su propio puerto, y `psql` lo alcanza por el socket Unix. Se ejecuta con:

```bash
bash server.sh start
bash server.sh sh < ops/10-replication.sh
```

`server.sh sh` pasa el script a `bash` en el contenedor, como usuario `postgres`. Primero vienen unas cuantas funciones auxiliares ([líneas 10-28](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L10-L28)):

```bash
# say <text>: un título en la salida; lsn: oculta las posiciones del WAL, que cambian de una ejecución a otra
say() { printf '\n-- %s\n' "$*"; }
lsn() { sed -E 's#[0-9A-F]+/[0-9A-F]{1,8}#X/XXXXXXXX#g'; }
# start <node> <port>: el puerto y el nombre que comunican los standbys van en la línea de comandos, y la configuración copiada no guarda ninguno
start() { pg_ctl -D "$1" -l "$1.log" -o "-p $2 -c cluster_name=$1" -w start > /dev/null || exit 1; }
# until_true <port> <database> <query>: repite hasta que la consulta devuelve true, 30 segundos como mucho
until_true() {
  for _ in $(seq 150); do
    [ "$(psql -X -Atq -p "$1" -d "$2" -c "$3" 2>/dev/null)" = t ] && return 0
    sleep 0.2
  done
  echo "timed out on port $1: $3"
}
sql() { local port=$1; shift; psql -X -p "$port" -d learn "$@" 2>&1; }
# add_run <port> <run id> <workflow name> [psql options]: inserta una ejecución de la rama main
add_run() {
  sql "$1" "${@:4}" -c "INSERT INTO ci.runs VALUES ($2, '$3', 'push', 'success', 'main', repeat('a', 40), 1,
                        '2026-09-16 12:00+00', '2026-09-16 12:00+00', '2026-09-16 12:00+00')"
}
```

- `until_true` repite una consulta: la replicación es asíncrona, y el script espera a un estado antes de imprimirlo, para que la salida sea la misma en cada ejecución.
- `lsn` oculta las posiciones del WAL, que cambian de una ejecución a otra.
- `start` da a cada nodo su puerto y su `cluster_name` en la línea de comandos: un standby copia los archivos de configuración del primario, y si no copiaría también su puerto.

El primer nodo, con el esquema del curso ([líneas 30-41](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L30-L41)):

```bash
say "node1: a new cluster, with enough WAL for logical decoding, and the course schema"
initdb -D node1 --auth=trust > /dev/null
cat >> node1/postgresql.conf <<'EOF'
shared_buffers = 32MB
wal_level = logical
# pg_rewind lee el WAL hasta el último checkpoint que comparten ambos nodos: conservar unos segmentos en lugar de reciclarlos
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

`wal_level = logical` escribe WAL suficiente para la replicación lógica, al final de la lección; el valor por defecto, `replica`, basta para un standby. `data_checksums` está a `on`: PostgreSQL 18 «change[d] initdb default to enable data checksums» ([notas de versión](https://www.postgresql.org/docs/18/release-18.html)), lo que `pg_rewind` necesitará.

## Un standby

[`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html) copia un clúster en marcha a través de una conexión de replicación ([líneas 43-50](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L43-L50)):

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

- `-R` escribe `standby.signal`, que arranca la copia como standby, y `primary_conninfo` en `postgresql.auto.conf`, que le dice dónde está el primario.
- `-C -S node2` crea un [slot de replicación](https://www.postgresql.org/docs/18/warm-standby.html#STREAMING-REPLICATION-SLOTS) en el primario y lo usa: el primario conserva el WAL que `node2` aún no ha recibido, incluso mientras `node2` está parado. `wal_status = reserved` indica que el WAL se conserva. Un slot cuyo standby no vuelve nunca conserva WAL para siempre; [`max_slot_wal_keep_size`](https://www.postgresql.org/docs/18/runtime-config-replication.html#GUC-MAX-SLOT-WAL-KEEP-SIZE) lo limita.
- `-X stream` transmite con la copia el WAL escrito durante ella.
- [`pg_stat_replication`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-REPLICATION-VIEW) en el primario enumera sus standbys: `node2`, el `cluster_name` que comunica, está en `streaming`, de forma asíncrona.

Un standby es un *hot standby*: responde a consultas, y rechaza las escrituras ([líneas 52-57](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L52-L57)):

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

El script espera hasta que `node2` haya reproducido la posición que `node1` había alcanzado tras el `INSERT`, y después lee. Sin esa espera, una lectura en un standby puede no ver una escritura recién confirmada en el primario: el retraso que la lección 3 describió para las Aurora Replicas.

## Replicación síncrona

Por defecto, un commit vuelve en cuanto el primario ha escrito su WAL. [`synchronous_standby_names`](https://www.postgresql.org/docs/18/runtime-config-replication.html#GUC-SYNCHRONOUS-STANDBY-NAMES) hace que espere también a los standbys ([líneas 59-73](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L59-L73)):

```bash
say "Synchronous replication: node1's commits now wait for node2 to confirm"
sql 5433 -qc "ALTER SYSTEM SET synchronous_standby_names = 'FIRST 1 (node2)'" -c 'SELECT pg_reload_conf()' -o /dev/null
until_true 5433 learn "SELECT EXISTS (SELECT FROM pg_stat_replication WHERE sync_state = 'sync')"
sql 5433 -c "SELECT application_name, sync_state FROM pg_stat_replication"
pg_ctl -D node2 -m fast -w stop > /dev/null
echo "node2 stopped"
# El commit se escribe localmente, y luego espera a un standby que no está. statement_timeout no cubre esa espera:
# otra sesión la cancela, lo que termina la espera pero no el commit
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

- `FIRST 1 (node2)` espera a un standby, el primero de la lista que esté conectado. `sync_state` pasa a `sync`.
- Con `node2` parado, el `INSERT` espera: `pg_stat_activity` lo muestra en el evento de espera `SyncRep`, y esperaría para siempre.
- El commit ya está en el WAL de node1. Cancelar la espera no lo deshace: el aviso lo dice, y la ejecución 2 está en la tabla. Un cliente que pierde su conexión durante esa espera no puede saber si su transacción se confirmó.
- Una primera versión de este script ponía `SET statement_timeout = '2s'` antes del `INSERT`: el `INSERT` esperó igualmente, diez minutos, hasta que lo cancelé a mano. La espera viene después de la instrucción, en el commit: PostgreSQL desactiva el timeout de la instrucción antes de confirmar ([`postgres.c`, `finish_xact_command`](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/tcop/postgres.c#L2826-L2833), en `REL_18_6`).

[`synchronous_commit`](https://www.postgresql.org/docs/18/runtime-config-wal.html#GUC-SYNCHRONOUS-COMMIT) fija a qué espera el primario: `on`, al vaciado a disco del standby; `remote_write`, a su escritura; `remote_apply`, a su reproducción, que «will cause each commit to wait until the current synchronous standbys report that they have replayed the transaction, making it visible to user queries» ([la documentación](https://www.postgresql.org/docs/18/warm-standby.html#SYNCHRONOUS-REPLICATION)). Se puede fijar por transacción, para las escrituras que no se deben perder.

## Conmutación por error, y el commit perdido

De nuevo con replicación asíncrona y `node2` todavía parado, `node1` confirma la ejecución 3 y se detiene. `node2` arranca y se promueve con [`pg_promote()`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-RECOVERY-CONTROL) ([líneas 75-85](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L75-L85)):

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

- `node2` es ahora un primario, en la **timeline** 2: los ocho primeros dígitos hexadecimales del nombre de un archivo WAL. Una nueva timeline empieza en cada promoción, para que el WAL escrito después no se pueda confundir con el WAL que el antiguo primario haya podido escribir.
- Faltan las ejecuciones 2 y 3. La ejecución 2 se confirmó mientras `node2` estaba parado, y la 3 también. Una conmutación por error a un standby asíncrono pierde lo que el standby no había recibido.
- PostgreSQL no decide por sí mismo conmutar: «PostgreSQL does not provide the system software required to identify a failure on the primary and notify the standby database server» ([conmutación por error](https://www.postgresql.org/docs/18/warm-standby-failover.html)). Herramientas externas a PostgreSQL vigilan el primario, promueven un standby y redirigen a los clientes; en Aurora, lo hace AWS.

## Recuperar el antiguo primario con pg_rewind

`node1` tiene las ejecuciones 2 y 3 en sus archivos, en la timeline 1, después del punto en que `node2` divergió. No puede seguir a `node2` tal como está. [`pg_rewind`](https://www.postgresql.org/docs/18/app-pgrewind.html) copia desde `node2` los bloques que han cambiado desde su último checkpoint común, en lugar de una copia completa nueva ([líneas 87-94](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L87-L94)):

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

- `pg_rewind` «requires that the target server either has the `wal_log_hints` option enabled in `postgresql.conf` or data checksums enabled», y necesita el WAL del destino hasta el checkpoint común. Una primera versión del script falló con `could not open file "node1/pg_wal/000000010000000000000002"`: `node1` ya había reciclado ese segmento. `wal_keep_size = 128MB` lo conserva.
- `-R` escribe `standby.signal` y un `primary_conninfo` que apunta a `node2`.
- `node1` vuelve como standby de `node2`, a través de un slot creado para él: las ejecuciones 2 y 3 han desaparecido, la ejecución 4 está.

## Replicación lógica

La replicación física copia un clúster entero, bloque a bloque, a servidores de la misma versión mayor. La [replicación lógica](https://www.postgresql.org/docs/18/logical-replication.html) envía *filas*: los cambios de las tablas elegidas, decodificados del WAL, a cualquier servidor PostgreSQL que tenga tablas equivalentes. `node3` es un clúster nuevo e independiente ([líneas 96-108](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L96-L108)):

```bash
say "Logical replication: node3, a separate cluster, subscribes to the runs table of node2"
initdb -D node3 --auth=trust > /dev/null
echo "shared_buffers = 32MB" >> node3/postgresql.conf
start node3 5435
psql -X -q -p 5435 -c 'CREATE DATABASE learn'
# La replicación lógica transporta filas, no el esquema: la tabla se crea primero
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

- «The database schema and DDL commands are not replicated» ([restricciones](https://www.postgresql.org/docs/18/logical-replication-restrictions.html)): `pg_dump --schema-only` crea primero las tablas en `node3`, que es también lo que sugiere la documentación.
- [`CREATE PUBLICATION`](https://www.postgresql.org/docs/18/sql-createpublication.html) en el publicador enumera las tablas, aquí con un [filtro de filas](https://www.postgresql.org/docs/18/logical-replication-row-filter.html): solo las ejecuciones de `main`.
- [`CREATE SUBSCRIPTION`](https://www.postgresql.org/docs/18/sql-createsubscription.html) en el suscriptor crea un slot de replicación lógica en el publicador, copia las filas existentes, y después aplica los cambios a medida que llegan. `pg_subscription_rel` muestra el estado de cada tabla; `r` significa listo.
- 125 ejecuciones de `main` en `node3`, y no las otras dos.

El suscriptor es un primario como cualquier otro, y nada impide escribir en él ([líneas 110-119](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-replication.sh#L110-L119)):

```bash
say "The subscriber is an ordinary primary: it accepts writes, which can conflict with replicated rows"
add_run 5435 5 'Written on node3'
add_run 5434 5 'Written on node2' -q
until_true 5435 learn "SELECT confl_insert_exists > 0 FROM pg_stat_subscription_stats WHERE subname = 'runs_from_node2'"
sql 5435 -c "SELECT subname, apply_error_count > 0 AS apply_errors, confl_insert_exists > 0 AS insert_conflicts FROM pg_stat_subscription_stats"
grep -o 'ERROR:  conflict detected on relation "ci.runs": conflict=insert_exists' node3.log | head -1
# Borrar la fila del suscriptor permite al apply worker, que reintenta, superar el conflicto
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

- La ejecución 5 se inserta en `node3`, y después en `node2`. Cuando llega la fila de `node2`, la clave ya existe: un [conflicto `insert_exists`](https://www.postgresql.org/docs/18/logical-replication-conflicts.html). «In this case, an error will be raised until the conflict is resolved manually.»
- PostgreSQL 18 cuenta los conflictos por tipo en [`pg_stat_subscription_stats`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-SUBSCRIPTION-STATS).
- El apply worker se detiene en el error y vuelve a arrancar más tarde, fallando cada vez: la replicación de toda la suscripción queda bloqueada detrás de esa única fila. Borrar la fila de `node3` la desbloquea, y llega la versión de `node2`. La documentación describe también cómo saltarse la transacción con `ALTER SUBSCRIPTION … SKIP` y el LSN escrito en el log.

Dos novedades de PostgreSQL 17 completan el panorama, no ejecutadas aquí:

- [`pg_createsubscriber`](https://www.postgresql.org/docs/18/app-pgcreatesubscriber.html) «creates a new logical replica from a physical standby server», sin volver a copiar los datos.
- Los slots lógicos pueden seguir una conmutación por error: una suscripción creada con `failover = true`, y [`sync_replication_slots`](https://www.postgresql.org/docs/18/runtime-config-replication.html#GUC-SYNC-REPLICATION-SLOTS) en el standby, permiten a los suscriptores «resume replication from the new primary server after failover» ([conmutación por error de la replicación lógica](https://www.postgresql.org/docs/18/logical-replication-failover.html)).

## En Aurora

*Por verificar: nada de esta sección se ejecutó en AWS.* Aurora no replica sus instancias como lo hace esta lección.

- **Aurora Replicas.** «The cluster volume is shared among all instances in your Aurora PostgreSQL DB cluster. Thus, no extra work is needed to replicate a copy of the data for each Aurora Replica» ([replicación con Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html)). No hay `pg_basebackup` que ejecutar, ni slot que vigilar, y un clúster «can contain up to 15 Aurora Replicas» ([replicación de Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html)), con un retraso «usually much less than 100 milliseconds». La lección 12 trata su conmutación por error.
- **Ningún standby físico externo.** Las opciones de replicación que esa página enumera para Aurora PostgreSQL son las Aurora Replicas, Global Database, la replicación lógica, y un origen RDS for PostgreSQL hacia Aurora; un standby propio, alimentado por `pg_basebackup` y streaming, no está entre ellas. No encontré ninguna página que lo diga con esas palabras.
- **La replicación lógica** funciona como en esta lección, una vez activada: fija `rds.logical_replication` a 1 en un grupo de parámetros de clúster personalizado, y después «reboot the writer instance of your Aurora PostgreSQL DB cluster so that your changes takes effect» ([configurar la replicación lógica](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.Configure.html)). La misma página advierte que «leaving a logical replication slot inactive prevents the vacuum from removing obsolete tuples from tables».
- **Desde réplicas.** «PostgreSQL 16 added support for logical decoding from read replicas. This feature isn't supported on Aurora PostgreSQL» ([replicación lógica en Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.html)).
- **pglogical** también está disponible: «all currently available Aurora PostgreSQL versions support the pglogical extension» ([pglogical](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.html)).
- **Construido sobre la replicación lógica.** Los Blue/Green Deployments ([lección 11](../11-backup/#en-aurora)) y las [integraciones zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html) con Amazon Redshift, que hacen «transactional data available in your analytics destination after it is written to an Aurora DB cluster». La [tabla de versiones de zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.Zero-ETL.html) de AWS solo da Aurora PostgreSQL 16 y 17.

## Puntos clave

- Un standby reproduce el WAL del primario; `pg_basebackup -R` crea uno, y un slot conserva el WAL que aún necesita.
- Los standbys responden a consultas de solo lectura, con un poco de retraso respecto al primario.
- Un commit síncrono se escribe primero localmente: una espera cancelada, o una conexión perdida, no indican que haya fallado. `statement_timeout` no cubre la espera.
- Una conmutación por error a un standby asíncrono pierde los commits que no había recibido, y empieza una nueva timeline.
- `pg_rewind` convierte el antiguo primario en un standby, descartando sus commits divergentes; necesita checksums o `wal_log_hints`, y el WAL hasta la divergencia.
- La replicación lógica envía filas de las tablas elegidas, no el esquema, y un conflicto bloquea toda la suscripción hasta que alguien lo resuelve.
- PostgreSQL promueve, pero no decide cuándo: eso es trabajo de una herramienta, o de AWS en Aurora.

## Ejercicios

Las soluciones están en [`ops/10-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh), que arranca `node1` y dos standbys, `node2` y `node3` ([líneas 20-31](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh#L20-L31)).

1. Pausa la reproducción en `node2` con [`pg_wal_replay_pause()`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-RECOVERY-CONTROL), escribe en `node1`, y muestra desde `node1` qué standby va con retraso, en bytes de WAL. Después reanúdala.

<details>
<summary>Solución</summary>

[Líneas 33-43](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh#L33-L43):

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

`pg_wal_lsn_diff` resta dos posiciones del WAL, en bytes. `sent_lsn` ha avanzado para ambos standbys: `node2` sigue recibiendo WAL mientras su reproducción está en pausa, así que `sent_lsn - replay_lsn` es el retraso de reproducción. El script imprime si es positivo, ya que el número exacto de bytes cambia de una ejecución a otra.

</details>

2. Haz que los commits esperen a cualquiera de los dos standbys, `ANY 1 (node2, node3)`, y después detén `node2`. ¿Sigue pasando un commit?

<details>
<summary>Solución</summary>

[Líneas 45-51](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh#L45-L51):

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

Con `ANY`, un quórum: ambos standbys son candidatos `quorum`, y basta con una confirmación. `FIRST 1 (node2, node3)` también habría continuado con `node3`, como primer standby *conectado* de la lista; la diferencia se ve cuando ambos están activos, donde `FIRST` espera siempre a `node2`, y `ANY` al que responda primero.

</details>

3. Promueve `node3` para que pase a ser independiente, y replica hacia él una tabla con una columna generada almacenada. En `node3`, la columna es una columna normal. ¿Qué recibe?

<details>
<summary>Solución</summary>

[Líneas 53-62](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/10-exercises.sh#L53-L62):

```bash
say "Exercise 3: node3 becomes a primary of its own, and subscribes to a table with a stored generated column"
sql 5435 -Atc 'SELECT pg_promote()' -o /dev/null
sql 5433 -q -c "CREATE TABLE sizes (id int PRIMARY KEY, body text NOT NULL, length int GENERATED ALWAYS AS (length(body)) STORED)"
# En node3 la columna es una columna normal: recibe los valores calculados en node1
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

`node3` todavía tiene `notes`, copiada antes de su promoción, pero no `sizes`: crea la suya. [`publish_generated_columns = stored`](https://www.postgresql.org/docs/18/logical-replication-gencols.html), nuevo en PostgreSQL 18, envía los valores calculados en `node1`. Por defecto, «generated columns are not published». Solo se pueden publicar las columnas almacenadas: PostgreSQL 18 también añadió las columnas generadas virtuales, el nuevo valor por defecto, que no se publican.

</details>

## Fuentes

- Documentación de PostgreSQL 18: [WAL](https://www.postgresql.org/docs/18/wal-intro.html), [alta disponibilidad y replicación](https://www.postgresql.org/docs/18/high-availability.html), [servidores standby por trasvase de registros](https://www.postgresql.org/docs/18/warm-standby.html), [conmutación por error](https://www.postgresql.org/docs/18/warm-standby-failover.html), [ajustes de replicación](https://www.postgresql.org/docs/18/runtime-config-replication.html), [ajustes del WAL](https://www.postgresql.org/docs/18/runtime-config-wal.html), [`initdb`](https://www.postgresql.org/docs/18/app-initdb.html), [`pg_ctl`](https://www.postgresql.org/docs/18/app-pg-ctl.html), [`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html), [`pg_rewind`](https://www.postgresql.org/docs/18/app-pgrewind.html), [funciones de control de la recuperación](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-RECOVERY-CONTROL), [estadísticas de supervisión](https://www.postgresql.org/docs/18/monitoring-stats.html), [replicación lógica](https://www.postgresql.org/docs/18/logical-replication.html), [filtros de filas](https://www.postgresql.org/docs/18/logical-replication-row-filter.html), [columnas generadas](https://www.postgresql.org/docs/18/logical-replication-gencols.html), [conflictos](https://www.postgresql.org/docs/18/logical-replication-conflicts.html), [restricciones](https://www.postgresql.org/docs/18/logical-replication-restrictions.html), [conmutación por error de los slots lógicos](https://www.postgresql.org/docs/18/logical-replication-failover.html), [`CREATE PUBLICATION`](https://www.postgresql.org/docs/18/sql-createpublication.html), [`CREATE SUBSCRIPTION`](https://www.postgresql.org/docs/18/sql-createsubscription.html), [`pg_createsubscriber`](https://www.postgresql.org/docs/18/app-pgcreatesubscriber.html), [notas de versión de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html), [notas de versión de PostgreSQL 17](https://www.postgresql.org/docs/17/release-17.html)
- SQL Server: [modos de disponibilidad](https://learn.microsoft.com/sql/database-engine/availability-groups/windows/availability-modes-always-on-availability-groups), [réplicas secundarias legibles](https://learn.microsoft.com/sql/database-engine/availability-groups/windows/active-secondaries-readable-secondary-replicas-always-on-availability-groups), [modos de conmutación por error](https://learn.microsoft.com/sql/database-engine/availability-groups/windows/failover-and-failover-modes-always-on-availability-groups), [trasvase de registros](https://learn.microsoft.com/sql/database-engine/log-shipping/about-log-shipping-sql-server), [replicación transaccional](https://learn.microsoft.com/sql/relational-databases/replication/transactional/transactional-replication)
- AWS: [replicación de Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html), [replicación con Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html), [replicación lógica](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.html), [su configuración](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.Logical.Configure.html), [pglogical](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.html), [zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html) y [sus versiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.Zero-ETL.html), todas consultadas el 2026-09-16
