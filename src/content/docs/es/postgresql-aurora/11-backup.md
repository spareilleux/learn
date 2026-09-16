---
title: "11. Copia de seguridad, restauración y actualizaciones"
description: Copias de seguridad en PostgreSQL 18 para desarrolladores SQL Server — el formato custom de pg_dump y un pg_restore en paralelo, los roles con pg_dumpall, copias base con manifiestos, copias incrementales y pg_combinebackup, archivado del WAL y una recuperación a un momento dado hasta un punto de restauración con nombre, y después una actualización mayor de 17 a 18 con pg_upgrade --swap y las estadísticas que conserva — y lo que hace Aurora en su lugar.
sidebar:
  order: 11
---

Los scripts de la lección son [`ops/11-backup.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh) y [`ops/11-upgrade.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh), y los ejercicios están en [`ops/11-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh). Como en la [lección 10](../10-replication/), arrancan pequeños clústeres dentro del contenedor del curso, y `check.sh ops` compara su salida con los archivos de los mismos nombres en [`expected`](https://github.com/spareilleux/learn/tree/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected):

```bash
bash server.sh sh < ops/11-backup.sh
```

| SQL Server | PostgreSQL |
|---|---|
| `BACKUP DATABASE`, un archivo `.bak` | `pg_dump`, un volcado lógico de una base de datos; `pg_basebackup`, una copia física del clúster |
| logins en `master` | roles, volcados por `pg_dumpall --globals-only` |
| copia de seguridad diferencial | copia de seguridad incremental (`pg_basebackup --incremental`), combinada con `pg_combinebackup` |
| copias de seguridad del registro | archivado del WAL (`archive_command`) |
| `RESTORE … WITH STOPAT`, `STOPATMARK` | `recovery_target_time`, `recovery_target_name`, `recovery_target_xid` |
| `RESTORE VERIFYONLY` | `pg_verifybackup` |
| actualización en el sitio con el programa de instalación | un clúster nuevo, y `pg_upgrade` desde el antiguo |

## Volcados lógicos

Un clúster con el esquema del curso, cuyos segmentos de WAL terminados se archivan; los ajustes se explican más abajo ([líneas 21-33](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L21-L33)):

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

[`pg_dump`](https://www.postgresql.org/docs/18/app-pgdump.html) escribe una base de datos como el SQL que la vuelve a crear, a partir de una única instantánea, mientras otras sesiones siguen trabajando. Su formato *custom*, `--format=custom`, va comprimido y permite a [`pg_restore`](https://www.postgresql.org/docs/18/app-pgrestore.html) elegir qué restaurar y trabajar en paralelo ([líneas 35-43](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L35-L43)):

```bash
say "A logical dump in the custom format, its table of contents, and a restore with two parallel jobs"
pg_dump -p 5433 -d learn --format=custom --file=learn.dump
# Cada línea de la lista empieza con un ID de volcado y dos IDs de objeto, quitados aquí
pg_restore --list learn.dump | grep ' TABLE DATA ' | sed -E 's/^[0-9]+; [0-9]+ [0-9]+ //'
psql -X -q -p 5433 -c 'CREATE DATABASE learn_copy'
pg_restore -p 5433 -d learn_copy --jobs=2 learn.dump
psql -X -p 5433 -d learn_copy -c "$counts"
# Los roles pertenecen al clúster, no a una base de datos: pg_dump los omite, pg_dumpall --globals-only los escribe
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

- `pg_restore --list` imprime la tabla de contenidos del volcado, una línea por objeto. Guardada en un archivo y editada, se puede volver a pasar con `--use-list` para restaurar solo algunos objetos, en el orden elegido.
- `--jobs=2` restaura con dos conexiones: los datos de varias tablas, y después sus índices, al mismo tiempo. Necesita el formato custom o el formato directorio.
- Un volcado no contiene los roles, que pertenecen al clúster: el `GRANT` a `reader` está, el rol no. [`pg_dumpall --globals-only`](https://www.postgresql.org/docs/18/app-pg-dumpall.html) escribe los roles y los tablespaces.

Un volcado es una copia en un momento dado. Lo que ocurrió después se pierde, y restaurar una base de datos grande significa volver a cargar todos sus datos y reconstruir cada índice.

## Copias base y copias incrementales

Una copia de seguridad física copia los archivos del clúster, como un standby de la lección 10 sin la replicación. [`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html) escribe un `backup_manifest` junto a ellos, con un checksum por archivo. Desde PostgreSQL 17, una copia posterior puede copiar solo lo que ha cambiado desde ese manifiesto ([líneas 45-54](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L45-L54)):

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

- `--incremental` necesita [`summarize_wal = on`](https://www.postgresql.org/docs/18/runtime-config-wal.html#GUC-SUMMARIZE-WAL) en el servidor: el WAL summarizer registra qué bloques cambió cada tramo de WAL.
- Sin su WAL, la copia incremental ocupa menos de un tercio de la completa: entre las dos solo se ejecutó un `UPDATE`.
- Una copia incremental no se puede arrancar directamente. [`pg_combinebackup`](https://www.postgresql.org/docs/18/app-pgcombinebackup.html) «is used to reconstruct a synthetic full backup from an incremental backup and the earlier backups upon which it depends».
- [`pg_verifybackup`](https://www.postgresql.org/docs/18/app-pgverifybackup.html) comprueba el resultado contra su manifiesto, y que el WAL que necesita se puede analizar.

La documentación añade una advertencia: «PostgreSQL has no built-in mechanism to figure out which backups are still needed as a basis for restoring later incremental backups» ([archivado continuo](https://www.postgresql.org/docs/18/continuous-archiving.html#BACKUP-INCREMENTAL-BACKUP)). Borrar una copia completa rompe todas las copias incrementales construidas sobre ella.

## Archivado del WAL y recuperación a un momento dado

Una copia base más cada segmento de WAL escrito desde entonces basta para reproducir el clúster hasta cualquier momento: la [recuperación a un momento dado](https://www.postgresql.org/docs/18/continuous-archiving.html). En `node1`, `archive_mode = on` y `archive_command` copian cada segmento terminado en `/tmp/archive`. `%p` es la ruta del segmento y `%f` su nombre; `test ! -f` se niega a sobrescribir un archivo ya archivado, el propio ejemplo de la documentación. En producción, el archivo está en otra máquina.

Un punto de restauración con nombre, y después un error ([líneas 56-61](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L56-L61)):

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

- [`pg_create_restore_point`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-BACKUP) escribe un nombre en el WAL, como una transacción marcada para el `STOPATMARK` de SQL Server.
- `TRUNCATE … CASCADE` vacía las tres tablas de CI.
- `pg_switch_wal()` termina el segmento en curso, para que se archive ahora en lugar de cuando se llene; [`pg_stat_archiver`](https://www.postgresql.org/docs/18/monitoring-stats.html#MONITORING-PG-STAT-ARCHIVER-VIEW) indica cuándo.

La recuperación, en `node2`, desde la copia combinada ([líneas 63-78](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-backup.sh#L63-L78)):

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

- `recovery.signal` arranca el servidor en recuperación. `restore_command` recupera los segmentos archivados, lo inverso de `archive_command`.
- [`recovery_target_name`](https://www.postgresql.org/docs/18/runtime-config-wal.html#RUNTIME-CONFIG-WAL-RECOVERY-TARGET) detiene la reproducción en el punto de restauración; `recovery_target_time`, `recovery_target_xid` y `recovery_target_lsn` son los otros objetivos. `recovery_target_action = 'promote'` abre el servidor a las escrituras cuando llega allí.
- Las tres tablas han vuelto, con el `UPDATE` hecho entre las dos copias: `failure`. El servidor recuperado continúa en la timeline 2, como tras una promoción en la lección 10.
- `archive_mode = off` en `node2`: la copia no debe escribir sus segmentos en el archivo de `node1`.

## Una actualización mayor con pg_upgrade

El programa de instalación de SQL Server actualiza una instancia en el sitio. Las versiones mayores de PostgreSQL cambian el formato de los catálogos del sistema, así que una actualización crea un clúster nuevo con el `initdb` de la nueva versión, y [`pg_upgrade`](https://www.postgresql.org/docs/18/pgupgrade.html) traslada a él las bases de datos: vuelca y restaura el esquema, y reutiliza los archivos de datos, cuyo formato rara vez cambia entre versiones mayores. Las versiones menores, de 18.5 a 18.6, solo necesitan los nuevos binarios.

[`ops/11-upgrade.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh) necesita los binarios de PostgreSQL 17 junto a los de 18. La imagen ya usa el [repositorio apt](https://wiki.postgresql.org/wiki/Apt) del proyecto PostgreSQL, así que `check.sh` los instala como root antes de ejecutar el script:

```bash
# Necesita los binarios de PostgreSQL 17 en el contenedor del curso, instalados antes como root (check.sh lo hace):
# docker exec pg sh -c 'apt-get update -qq && apt-get install -qq -y --no-install-recommends postgresql-17'
```

Un clúster de PostgreSQL 17 con las ejecuciones, sus estadísticas, y las estadísticas extendidas de la [lección 5](../05-indexes/) ([líneas 14-36](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L14-L36)):

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
# Solo la versión mayor: la menor cambia con los paquetes de Debian
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

La tabla es más sencilla que la de `schema.sql`, que usa una columna generada virtual, nueva en 18. El script imprime solo la versión mayor: la menor sigue a los paquetes de Debian.

Un primer intento, con `--check`, que solo ejecuta las comprobaciones ([líneas 38-42](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L38-L42)):

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

`initdb` 18 activa los checksums de datos por defecto, y 17 no lo hacía. Las notas de versión indican la salida: «Checksums can be disabled with the new initdb option `--no-data-checksums`. pg_upgrade requires matching cluster checksum settings». El clúster nuevo se vuelve a crear sin ellos.

La actualización ([líneas 44-51](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-upgrade.sh#L44-L51)):

```bash
say "The upgrade: --swap moves the old data directory into the new cluster, so the 17 cluster can't be started again"
$new/pg_upgrade --old-bindir=$old --new-bindir=$new --old-datadir=pg17 --new-datadir=pg18 --swap 2>&1 | grep -v '^$'
$new/pg_ctl -D pg18 -l pg18.log -o "-p 5436" -w start > /dev/null || exit 1
sql 5436 -c "SELECT current_setting('server_version_num')::int / 10000 AS version, count(*) AS runs FROM ci.runs"
# Las estadísticas de columna pasaron; las estadísticas extendidas no
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

- `pg_upgrade` comprueba, vuelca el esquema antiguo, lo restaura en el clúster nuevo, y después trae los IDs de transacción y los archivos de datos.
- `--swap`, nuevo en PostgreSQL 18, mueve los directorios de datos del clúster antiguo al nuevo en lugar de copiar o enlazar archivos; la documentación dice que «can outperform `--link`, `--clone`, `--copy`, and `--copy-file-range`, especially on clusters with many relations». El precio está en la salida: «the old cluster can no longer be safely started». Sin una copia de seguridad, no hay vuelta atrás.
- También nuevo en 18, `pg_upgrade` «will transfer most optimizer statistics from the old cluster to the new cluster»: las seis estadísticas de columna están, y el servidor puede planificar bien desde su primera consulta. Las estadísticas extendidas no.
- [`vacuumdb --analyze-only --missing-stats-only`](https://www.postgresql.org/docs/18/app-vacuumdb.html), otra opción de PostgreSQL 18, analiza solo lo que no tiene estadísticas, y recupera las estadísticas extendidas. El propio consejo de `pg_upgrade` es ejecutarlo primero con `--analyze-in-stages`.

## En Aurora

*Por verificar: nada de esta sección se ejecutó en AWS.* Aurora gestiona las copias de seguridad por sí mismo, y sus restauraciones crean clústeres nuevos.

- **Copias de seguridad continuas.** «Aurora automated backups are continuous and incremental, so you can quickly restore to any point within the backup retention period», que va «from 1–35 days», un día por defecto; «you can't disable automated backups on Aurora» ([copias de seguridad](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Backups.html)). No hay `archive_command` que configurar: «Amazon Aurora uploads log records for DB clusters to Amazon S3 continuously» ([recuperación a un momento dado](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-pitr.html)).
- **La recuperación a un momento dado** crea un DB cluster nuevo, como `node2` era aquí un clúster nuevo. El último momento restaurable «is typically within 5 minutes of the current time». Las instantáneas manuales conservan los datos más allá del periodo de retención: «Aurora DB cluster snapshots don't expire».
- **Sin rebobinado para PostgreSQL.** Backtrack, que rebobina un clúster en el sitio, es solo para Aurora MySQL ([Backtrack](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html)).
- **Clones.** «Aurora uses a copy-on-write protocol to create a clone», que comparte el almacenamiento con su origen hasta que uno de los dos lo modifica; «you can create up to 15 clones with copy-on-write protocol», en la misma región ([clonación](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Clone.html)). Un clon es la forma barata de probar una restauración o una actualización con datos reales.
- **Volcados y exportaciones.** `pg_dump` y `pg_restore` funcionan desde una máquina cliente; solo encontré el procedimiento de AWS en la [guía de RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Procedural.Importing.EC2.html), no en la de Aurora. La extensión [`aws_s3`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/postgresql-s3-export.html) exporta el resultado de una consulta directamente a S3 con `aws_s3.query_export_to_s3`.
- **Las actualizaciones mayores usan pg_upgrade.** «To safely upgrade the DB instances that make up your cluster, Aurora PostgreSQL uses the pg_upgrade utility» ([actualizaciones de versión mayor](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html)). Antes: «Drop logical replication slots. The upgrade process can't proceed if the Aurora PostgreSQL DB cluster is using any logical replication slots». Aurora toma una instantánea cuyo nombre lleva el prefijo `preupgrade`.
- **Estadísticas: una contradicción que comprobar.** La misma página dice «Optimizer statistics aren't transferred during a major version upgrade, so you need to regenerate all statistics», mientras que `pg_upgrade` 18 las transfiere, como mostró esta lección. Si una actualización a Aurora PostgreSQL 18 las conserva no está documentado: ejecuta `ANALYZE` de todos modos.
- **Los Blue/Green Deployments** copian un clúster en un entorno green mantenido sincronizado con replicación lógica, donde se ejecuta la actualización, y después conmutan; «the switchover typically takes under a minute with no data loss» ([descripción general](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-overview.html)). Los límites son los de la replicación lógica: «Data definition language (DDL) statements, such as CREATE TABLE and CREATE SCHEMA, aren't replicated from the blue environment to the green environment» ([consideraciones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html)). La [tabla de versiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.BlueGreenDeployments.html) se detiene en Aurora PostgreSQL 17.
- **Las versiones menores** se pueden aplicar con zero-downtime patching (ZDP), donde «application sessions are maintained except for those with dropped connections», con una caída del rendimiento que «typically lasts only for a few seconds or at most, approximately one minute» ([actualizaciones menores](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MinorUpgrade.html)).

## Puntos clave

- `pg_dump` copia una base de datos en un momento dado; los roles vienen de `pg_dumpall --globals-only`.
- El formato custom permite a `pg_restore` elegir objetos y restaurar en paralelo.
- Las copias base tienen manifiestos; las copias incrementales necesitan `summarize_wal`, las copias de las que dependen, y `pg_combinebackup`.
- El archivado del WAL más una copia base da la recuperación a un momento dado: hasta una hora, un punto con nombre, una transacción o un LSN.
- Una actualización mayor es un clúster nuevo: los checksums deben coincidir, `--swap` es rápido y sin vuelta atrás, y 18 conserva la mayoría de las estadísticas.
- En Aurora, las copias de seguridad son continuas, las restauraciones y los clones crean clústeres nuevos, y las actualizaciones siguen ejecutando `pg_upgrade`.

## Ejercicios

Las soluciones están en [`ops/11-exercises.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh), sobre un clúster como `node1` ([líneas 19-28](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L19-L28)).

1. Alguien borra todas las filas de `ga.iconic_chords`. Recupera las filas de esa tabla desde un volcado en formato custom, sin tocar las demás tablas.

<details>
<summary>Solución</summary>

[Líneas 30-34](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L30-L34):

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

`--table` selecciona la tabla y `--data-only` restaura sus filas en la tabla existente, sin intentar crearla de nuevo. Las filas son las del volcado: lo que cambió en esa tabla después del volcado se pierde, algo que la recuperación a un momento dado evita.

</details>

2. Tras una copia base, un `UPDATE` marca la última ejecución como `cancelled`, y después una transacción borra todos los pasos. Recupera una copia que tenga el `UPDATE` pero no el `DELETE`, usando el ID de la transacción como objetivo.

<details>
<summary>Solución</summary>

[Líneas 36-55](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/11-exercises.sh#L36-L55):

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

[`pg_current_xact_id()`](https://www.postgresql.org/docs/18/functions-info.html#FUNCTIONS-PG-SNAPSHOT) da el ID de la transacción desde dentro de ella. `recovery_target_xid` se detiene en el commit de esa transacción, y `recovery_target_inclusive = off` se detiene justo antes: los pasos están, y la ejecución está `cancelled`. En la práctica, rara vez se conoce el ID de una transacción errónea; una hora sacada de los logs de la aplicación, con `recovery_target_time`, es el objetivo habitual.

</details>

## Fuentes

- Documentación de PostgreSQL 18: [copia de seguridad y restauración](https://www.postgresql.org/docs/18/backup.html), [volcado SQL](https://www.postgresql.org/docs/18/backup-dump.html), [archivado continuo y PITR](https://www.postgresql.org/docs/18/continuous-archiving.html), [`pg_dump`](https://www.postgresql.org/docs/18/app-pgdump.html), [`pg_restore`](https://www.postgresql.org/docs/18/app-pgrestore.html), [`pg_dumpall`](https://www.postgresql.org/docs/18/app-pg-dumpall.html), [`pg_basebackup`](https://www.postgresql.org/docs/18/app-pgbasebackup.html), [`pg_combinebackup`](https://www.postgresql.org/docs/18/app-pgcombinebackup.html), [`pg_verifybackup`](https://www.postgresql.org/docs/18/app-pgverifybackup.html), [ajustes del WAL y objetivos de recuperación](https://www.postgresql.org/docs/18/runtime-config-wal.html), [funciones de control de copias de seguridad](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-ADMIN-BACKUP), [`pg_upgrade`](https://www.postgresql.org/docs/18/pgupgrade.html), [actualizar un clúster](https://www.postgresql.org/docs/18/upgrading.html), [`vacuumdb`](https://www.postgresql.org/docs/18/app-vacuumdb.html), [notas de versión de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html), [notas de versión de PostgreSQL 17](https://www.postgresql.org/docs/17/release-17.html); el [repositorio apt](https://wiki.postgresql.org/wiki/Apt)
- SQL Server: [descripción general de las copias de seguridad](https://learn.microsoft.com/sql/relational-databases/backup-restore/backup-overview-sql-server), [restaurar a un momento dado](https://learn.microsoft.com/sql/relational-databases/backup-restore/restore-a-sql-server-database-to-a-point-in-time-full-recovery-model), [elegir un método de actualización](https://learn.microsoft.com/sql/database-engine/install-windows/choose-a-database-engine-upgrade-method)
- AWS: [copias de seguridad](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Backups.html), [recuperación a un momento dado](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-pitr.html), [Backtrack](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html), [clonación](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Managing.Clone.html), [importar con pg_dump en RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Procedural.Importing.EC2.html), [exportar a S3](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/postgresql-s3-export.html), [actualizaciones de versión mayor](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MajorVersion.html), [actualizaciones de versión menor](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_UpgradeDBInstance.PostgreSQL.MinorUpgrade.html), [descripción general de blue/green](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-overview.html), [consideraciones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html) y [versiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.BlueGreenDeployments.html), todas consultadas el 2026-09-16
