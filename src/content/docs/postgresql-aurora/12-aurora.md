---
title: "12. Amazon Aurora PostgreSQL"
description: What Aurora changes for a PostgreSQL developer, from AWS's documentation read on 2026-09-16 — the shared cluster volume, Aurora Replicas and failover, endpoints and DNS, a failover reproduced locally with Npgsql and pgjdbc on a primary and a standby, Aurora Serverless, Global Database, RDS Proxy, IAM authentication, storage configurations, Limitless Database and the version calendar. No AWS account was used.
sidebar:
  order: 12
---

This lesson has no AWS account behind it: the course creates no AWS resource and uses no credentials. Everything it says about Aurora comes from AWS's documentation, read on 2026-09-16, and is *to verify*. AWS's pages carry no date of their own, so the date is when I read them. What can run locally does: a failover seen from C# and Java, in [`csharp/L12.cs`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/csharp/L12.cs) and [`java/…/L12.java`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L12.java), whose outputs `check.sh` compares with [`expected/l12-failover-cs.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/l12-failover-cs.txt) and [`expected/l12-failover-java.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/l12-failover-java.txt). The exercise is in [`sql/12-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/12-exercises.sql).

The previous lessons each ended with a section on Aurora; this one puts them together and adds what they left out.

| Azure SQL Database | Aurora PostgreSQL |
|---|---|
| logical server, databases | DB cluster: one writer instance, up to 15 Aurora Replicas, one cluster volume |
| [Hyperscale](https://learn.microsoft.com/azure/azure-sql/database/service-tier-hyperscale): compute separated from a distributed storage | the same idea: instances attached to a storage volume spread over three Availability Zones |
| failover groups, a read-write listener | the cluster endpoint, which moves to the new writer |
| read scale-out, `ApplicationIntent=ReadOnly` | the reader endpoint, or custom endpoints |
| serverless compute tier | Aurora Serverless, in Aurora capacity units (ACUs) |
| [active geo-replication](https://learn.microsoft.com/azure/azure-sql/database/active-geo-replication-overview) | Aurora Global Database |
| Microsoft Entra authentication | IAM database authentication |

## The cluster volume

An Aurora instance runs PostgreSQL's engine, but not on its own disk. "Aurora data is stored in the cluster volume, which is a single, virtual volume that uses solid state drives (SSDs). A cluster volume consists of copies of the data across three Availability Zones in a single AWS Region" ([Aurora storage](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html)), and "when data is written to the primary DB instance, Aurora synchronously replicates the data across Availability Zones to six storage nodes associated with your cluster volume" ([high availability](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.AuroraHighAvailability.html)).

What follows for the previous lessons:

- **Replicas without replication to set up.** "The cluster volume is shared among all instances in your Aurora PostgreSQL DB cluster" ([Aurora PostgreSQL replication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html)). Lesson 10's `pg_basebackup`, slots and `pg_rewind` have no equivalent to run: adding a replica doesn't copy the data.
- **Storage grows by itself.** The [quotas page](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html) gives a maximum volume of 256 TiB for Aurora PostgreSQL 17.5, 16.9, 15.13 and higher, and 128 TiB for earlier versions, and a maximum table size of 32 TiB. The same page's quota table still says 128 TiB without a version, and the [overview](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html) says 256 TiB without one: the version table is the precise one.
- **Backups without `archive_command`.** Lesson 11: continuous backups to S3, restores into new clusters.

## Replicas and failover

"After you create the primary (writer) instance, you can create up to 15 read-only Aurora Replicas" ([high availability](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.AuroraHighAvailability.html)). Their lag "is usually much less than 100 milliseconds after the primary instance has written an update" ([Aurora replication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html)).

When the writer fails, Aurora promotes a replica: the one with the best promotion tier, where "priorities range from 0 for the highest priority to 15 for the lowest priority", and among equal tiers "the replica that is largest in size". What the application sees: "A failure event results in a brief interruption, during which read and write operations fail with an exception. However, service is typically restored in less than 60 seconds, and often less than 30 seconds." With no replica, a new instance has to be created, which "typically takes less than 10 minutes".

## Endpoints and DNS

Lesson 3 introduced the endpoints ([Aurora endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html)):

- The **cluster endpoint** is a DNS name that points to the writer. "The physical IP address pointed to by the cluster endpoint changes when the failover mechanism promotes a new DB instance to be the read/write primary instance for the cluster" ([cluster endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Cluster.html)).
- The **reader endpoint** "balances connections to available Aurora Replicas in an Aurora DB cluster. It doesn't balance individual queries" ([reader endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Reader.html)). A pool that opened its connections on the reader endpoint stays on the replicas it reached.
- **Custom endpoints** group chosen instances, "up to five custom endpoints for each provisioned Aurora cluster or Aurora serverless cluster" ([custom endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Custom.html)); **instance endpoints** reach one instance.

A failover changes a DNS record, and a client that caches DNS keeps connecting to the old writer. AWS's [best practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html): "If your client application is caching the Domain Name Service (DNS) data of your DB instances, set a time-to-live (TTL) value of less than 30 seconds." The JVM caches DNS answers itself; AWS's [fast failover page for Java](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.FastFailover.html) sets `networkaddress.cache.ttl` to 1.

## A failover from C# and Java, locally

The cluster endpoint hides the change behind a DNS name. Lesson 4's other approach gives the driver every instance and lets it find the writer. That can run locally: [`ops/12-cluster.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/12-cluster.sh) starts `node1`, a primary on port 5433, and `node2`, its standby on 5434, inside the course container, as in lesson 10; `server.sh` publishes both ports ([lines 15-35](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/12-cluster.sh#L15-L35)):

```bash
# The postgres password is the course server's; Unix-socket connections inside the container need none
echo learn > password
initdb -D node1 --auth-local=trust --auth-host=scram-sha-256 --pwfile=password > /dev/null
rm password
cat >> node1/postgresql.conf <<'EOF'
listen_addresses = '*'
shared_buffers = 32MB
EOF
# Connections from the host come through Docker's network, not from 127.0.0.1
echo "host all all all scram-sha-256" >> node1/pg_hba.conf
pg_ctl -D node1 -l node1.log -o "-p 5433" -w start > /dev/null || exit 1
psql -X -q -p 5433 -c 'CREATE DATABASE learn'
psql -X -q -p 5433 -d learn -c 'CREATE TABLE orders (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, written_on int NOT NULL DEFAULT inet_server_port())'

pg_basebackup -p 5433 -D node2 -R -X stream -c fast
pg_ctl -D node2 -l node2.log -o "-p 5434" -w start > /dev/null || exit 1
for _ in $(seq 150); do
  [ "$(psql -X -Atq -p 5433 -c "SELECT count(*) FROM pg_stat_replication WHERE state = 'streaming'")" = 1 ] && break
  sleep 0.2
done
echo "node1: primary on port 5433, node2: standby on port 5434"
```

`check.sh` runs it again before each program. The C# program ([`L12.cs`, lines 33-93](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/csharp/L12.cs#L33-L93)):

```csharp
    public static async Task Failover()
    {
        await using var cluster = new NpgsqlDataSourceBuilder(Cluster).BuildMultiHost();
        var writer = cluster.WithTargetSession(TargetSessionAttributes.ReadWrite);
        var standby = cluster.WithTargetSession(TargetSessionAttributes.Standby);
        await using (var connection = await standby.OpenConnectionAsync())
        {
            Console.WriteLine($"standby: {await Describe(connection)}");
        }
        Console.WriteLine($"before: {await Write(writer)}");

        // A connection opened before the failover, and node1 stopped by its own server: pg_ctl -W doesn't wait
        await using var open = await writer.OpenConnectionAsync();
        await using (var admin = await writer.OpenConnectionAsync())
        {
            await using var stop = new NpgsqlCommand("COPY (SELECT) TO PROGRAM '/usr/lib/postgresql/18/bin/pg_ctl -D /tmp/node1 -m fast -W stop'", admin);
            try
            {
                await stop.ExecuteNonQueryAsync();
            }
            catch (NpgsqlException)
            {
                // The shutdown may end this session before COPY returns
            }
        }
        while (true)
        {
            try
            {
                await using var direct = new NpgsqlConnection(Cluster.Replace("localhost:5433,localhost:5434", "localhost:5433"));
                await direct.OpenAsync();
                await Task.Delay(100);
            }
            catch (NpgsqlException)
            {
                break;
            }
        }
        Console.WriteLine("node1 stopped");
        await using var query = new NpgsqlCommand("SELECT 1", open);
        try
        {
            await query.ExecuteScalarAsync();
        }
        catch (NpgsqlException)
        {
            // The exception depends on the machine: a PostgresException 57P01 on Linux in CI, "Exception while reading
            // from stream" through Docker Desktop on Windows. The connection's state is the same on both
            Console.WriteLine($"open connection: the query fails, FullState = {open.FullState}");
        }
        Console.WriteLine($"no primary: {await Write(writer)}");

        // The promotion, which Aurora does by itself: node2 stops replaying WAL and accepts writes
        await using (var connection = await standby.OpenConnectionAsync())
        {
            await using var promote = new NpgsqlCommand("SELECT pg_promote()", connection);
            Console.WriteLine($"pg_promote() on node2: {await promote.ExecuteScalarAsync()}");
        }
        // The same data source, with the same host list, now finds its writer on node2
        Console.WriteLine($"after: {await Write(writer)}");
    }
```

```text
standby: port 5434, pg_is_in_recovery() = True
before: order written on port 5433
node1 stopped
open connection: the query fails, FullState = Broken
no primary: NpgsqlException: No suitable host was found.
pg_promote() on node2: True
after: order written on port 5434
```

The Java program does the same with pgjdbc's `targetServerType` ([`L12.java`, lines 31-75](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L12.java#L31-L75)):

```java
    static void failover() throws Exception {
        String primary = CLUSTER + "&targetServerType=primary";
        String secondary = CLUSTER + "&targetServerType=secondary";
        try (Connection connection = DriverManager.getConnection(secondary);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("SELECT inet_server_port(), pg_is_in_recovery()")) {
            rs.next();
            System.out.println("secondary: port " + rs.getInt(1) + ", pg_is_in_recovery() = " + rs.getBoolean(2));
        }
        System.out.println("before: " + write(primary));

        // A connection opened before the failover, and node1 stopped by its own server: pg_ctl -W doesn't wait
        try (Connection open = DriverManager.getConnection(primary)) {
            try (Connection admin = DriverManager.getConnection(primary); Statement statement = admin.createStatement()) {
                statement.execute("COPY (SELECT) TO PROGRAM '/usr/lib/postgresql/18/bin/pg_ctl -D /tmp/node1 -m fast -W stop'");
            } catch (SQLException e) {
                // The shutdown may end this session before COPY returns
            }
            String node1 = CLUSTER.replace("localhost:5433,localhost:5434", "localhost:5433");
            while (true) {
                try (Connection direct = DriverManager.getConnection(node1)) {
                    Thread.sleep(100);
                } catch (SQLException e) {
                    break;
                }
            }
            System.out.println("node1 stopped");
            try (Statement statement = open.createStatement()) {
                statement.execute("SELECT 1");
            } catch (SQLException e) {
                System.out.println("open connection: " + e.getSQLState() + ": " + e.getMessage());
            }
        }
        System.out.println("no primary: " + write(primary));

        // The promotion, which Aurora does by itself: node2 stops replaying WAL and accepts writes
        try (Connection connection = DriverManager.getConnection(secondary);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("SELECT pg_promote()")) {
            rs.next();
            System.out.println("pg_promote() on node2: " + rs.getBoolean(1));
        }
        // The same URL now finds its primary on node2
        System.out.println("after: " + write(primary));
    }
```

```text
secondary: port 5434, pg_is_in_recovery() = true
before: order written on port 5433
node1 stopped
open connection: 57P01: FATAL: terminating connection due to administrator command
no primary: 08001: Could not find a server with specified targetServerType: primary
pg_promote() on node2: true
after: order written on port 5434
```

- **The failure.** The program stops `node1` from inside: [`COPY … TO PROGRAM`](https://www.postgresql.org/docs/18/sql-copy.html) runs `pg_ctl` on the server, as the `postgres` superuser, and `-W` returns without waiting. It stands in for the instance failure that Aurora detects.
- **The open connection breaks.** pgjdbc receives the server's `57P01`, "terminating connection due to administrator command". Npgsql's exception depends on the machine: the same `PostgresException` with `57P01` on Linux in CI, only "Exception while reading from stream" on Windows through Docker Desktop, where the socket closed before the message was read; so the C# program prints the connection's `FullState`, `Broken` on both. Either way, the transaction in progress on that connection is lost, as AWS's "read and write operations fail with an exception" says.
- **No writer for a moment.** Between the failure and the promotion, [Npgsql](https://www.npgsql.org/doc/failover-and-load-balancing.html) finds "No suitable host" and pgjdbc "Could not find a server with specified targetServerType: primary". The standby still answers, read-only.
- **The promotion.** On Aurora, AWS does it. Here, the program calls `pg_promote()` on `node2`, through a `Standby` or `secondary` connection.
- **The same connection string finds the new writer.** Neither program changes its host list: each driver checks which host accepts writes, and now it is `node2`. Both drivers cache host states, for 10 seconds by default (`Host Recheck Seconds` in Npgsql, [`hostRecheckSeconds`](https://jdbc.postgresql.org/documentation/use/) in pgjdbc); the write right after the promotion still found `node2`. How each driver treats a host it remembers as a standby when no primary is known is *to verify* in their source.

What this doesn't reproduce: on Aurora, the host names of the instances don't move, but the application usually knows only the endpoints. AWS's drivers follow the cluster's topology instead. "The AWS drivers rely on monitoring DB cluster status and being aware of the cluster topology to determine the new writer. This approach reduces switchover and failover times to single-digit seconds, compared to tens of seconds for open-source drivers" ([AWS drivers](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/IAMDBAuth.Connecting.Drivers.html)):

- In Java, the [AWS Advanced JDBC Wrapper](https://github.com/aws/aws-advanced-jdbc-wrapper/blob/4.4.0/README.md), 4.4.0 released on 2026-08-20, wraps pgjdbc; its [failover plugin v2](https://github.com/aws/aws-advanced-jdbc-wrapper/blob/4.4.0/docs/using-the-jdbc-driver/using-plugins/UsingTheFailover2Plugin.md) watches the topology from a separate thread.
- In .NET, the [AWS Advanced .NET Data Provider Wrapper](https://github.com/aws/aws-advanced-dotnet-data-provider-wrapper/blob/2.2.0/README.md), 2.2.0 released on 2026-08-05, "does not connect directly to any database, but enables support of AWS and Aurora functionalities on top of an underlying .NET driver", with a package for Npgsql. The Aurora user guide's list of AWS drivers doesn't mention it yet.

## Aurora Serverless

An Aurora Serverless instance changes size while it runs. Its unit is the ACU: "Each ACU is a combination of approximately 2 gibibytes (GiB) of memory, corresponding CPU, and networking. […] Aurora serverless offers capacity from 0 ACUs to 256 ACUs" ([how it works](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html)), "in increments of 0.5 ACU" ([requirements](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.requirements.html)). AWS's guide now calls it "Aurora serverless"; the page URLs still say `serverless-v2`, and "Aurora Serverless v1" is the deprecated product.

- **Down to zero.** An instance with a minimum of 0 ACUs pauses "if they don't have any connections initiated by user activity within a specified time period", from Aurora PostgreSQL 16.3, 15.7, 14.12 or 13.15 ([auto-pause](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2-auto-pause.html)). Whether the idle connections of an application's pool keep an instance from pausing is *to verify*.
- **Mixed clusters.** "You can set up a cluster that contains both Aurora serverless and provisioned capacity, called a mixed-configuration cluster": a provisioned writer with serverless readers, for example.
- **Versions.** The capacity table lists versions up to 16 "and higher". That PostgreSQL 18 versions have the 0 to 256 ACU range is *to verify*.

## Global Database

"An Aurora global database has a primary DB cluster in one Region, and up to 10 secondary DB clusters in different Regions", replicated "with latency typically under a second", and "Aurora uses the cluster storage volume and not the database engine for fast, low-overhead replication" ([Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html)).

- **Switchover** is planned: "Because this feature synchronizes secondary DB clusters with the primary before making any other changes, RPO is 0 (no data loss)". **Failover** is for a Regional outage, and "the RPO for this approach is typically a non-zero value measured in seconds" ([disaster recovery](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-disaster-recovery.html)): lesson 10's lost commit, across Regions. The `rds.global_db_rpo` parameter sets an upper bound on it, "but doing so might affect transaction processing on the primary".
- **Write forwarding.** A secondary cluster can forward writes to the primary: "In Aurora PostgreSQL version 16 and higher major versions, global write forwarding is supported in all minor versions" ([write forwarding](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-write-forwarding-apg.html)).

## RDS Proxy

Lesson 4 covered [RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/rds-proxy.html)'s connection sharing and the statements that pin a session. For availability, AWS adds that it "bypasses Domain Name System (DNS) caches to reduce failover times by up to 66% for Aurora Multi-AZ databases" ([planning](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/rds-proxy-planning.html)). Two limits of the same page matter to PostgreSQL clients:

- "RDS Proxy doesn't currently support canceling a query from a client by issuing a CancelRequest": Npgsql's `NpgsqlCommand.Cancel()` and pgjdbc's `Statement.cancel()` send one.
- "Any statement with a text size greater than 16 KB causes the proxy to pin the session to the current connection."

The [RDS Proxy version table](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.RDS_Proxy.html) lists Aurora PostgreSQL 18.3 and higher.

## IAM database authentication

Lesson 4 showed how the drivers refresh a token. The rest, from [IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.html):

- The database user needs a role: `GRANT rds_iam TO db_userx`, and then "IAM authentication takes precedence over password authentication, so the user must log in as an IAM user" ([creating a database account](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.DBAccounts.html)).
- The IAM policy allows the action `rds-db:connect` on a resource that names the cluster and the database user ([IAM policy](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html)).
- Token checks cost the server: "You must have between 300 and 1000 MiB extra memory on your database for reliable connectivity."
- AWS's `psql` example connects with `sslmode=verify-full`.

## Storage configurations, sizing and Limitless

- **Standard or I/O-Optimized.** With Aurora Standard, "you also pay a standard rate per 1 million requests for I/O operations"; with I/O-Optimized, "you pay only for the usage and storage of your DB clusters, with no additional charges for read and write I/O operations". AWS's rule: "Aurora I/O-Optimized is the best choice when your I/O spending is 25% or more of your total Aurora database spending", and a cluster can switch to it "once every 30 days" ([storage](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html)). Lesson 13 comes back to costs.
- **max_connections** follows the instance's memory: `LEAST({DBInstanceClassMemory/9531392},5000)` ([performance and scaling](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.html)). `DBInstanceClassMemory` starts from the instance class's memory, then "subtracts memory reserved for the operating system and the RDS processes that manage the instance" ([parameter formulas](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_ParamValuesRef.html)). The exercise computes it.
- **Limitless Database** shards tables across instances "to process millions of write transactions per second" ([Limitless](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless.html)). It runs special versions, "16.X-limitless", and "supports only the Aurora I/O-Optimized DB cluster storage configuration" ([requirements](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless-reqs-limits.html)); the release calendar has no 17 or 18 Limitless version.

## Versions and support

The [Aurora PostgreSQL release calendar](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html):

| Major version | First Aurora release | End of standard support |
|---|---|---|
| 13 | | February 28, 2026, then Extended Support until February 28, 2029 |
| 14 | | February 28, 2027, then Extended Support until February 28, 2030 |
| 17 | | February 28, 2030 |
| 18 | June 11, 2026, with 18.3 | February 28, 2031 |

- **Minor versions** have their own end dates: 18.3 until November 30, 2027, and 18.4, released on August 21, 2026, until December 31, 2027.
- **Extended Support** "allows you to continue running a database on a major engine version past the Aurora end of standard support date for an additional cost" ([Extended Support](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/extended-support.html)). Aurora PostgreSQL 13 is in it since March 1, 2026.
- **A date not to copy.** The calendar's major-version table gives PostgreSQL 18 a "community release date" of February 26, 2026. PostgreSQL 18.0 was released on September 25, 2025, according to its [release notes](https://www.postgresql.org/docs/18/release-18.html); February 26, 2026 is the date the minor table gives for 18.3.
- **Features follow later.** PostgreSQL 18 has a column in the RDS Proxy table, but not yet in the blue/green or zero-ETL tables ([lesson 11](../11-backup/#on-aurora), [lesson 10](../10-replication/#on-aurora)).

## Key takeaways

- Aurora instances share one cluster volume, six copies over three Availability Zones: no replication to set up between instances.
- A failover takes typically less than 60 seconds, and the transactions in progress fail: applications retry.
- The cluster endpoint follows the writer through DNS: keep DNS caches under 30 seconds, or use a driver that follows the topology.
- A multi-host connection string finds the new writer by itself, as the local failover showed with Npgsql and pgjdbc.
- Serverless scales in 0.5 ACU steps, down to zero with auto-pause; Global Database copies to other Regions in about a second, with an RPO of seconds on failover.
- RDS Proxy shortens failovers but doesn't forward cancel requests; IAM tokens need extra memory on the server.
- Check a feature's version table before assuming it supports Aurora PostgreSQL 18.

## Exercises

1. Compute Aurora's default `max_connections` for instances with 2, 4, 16, 32 and 64 GiB of memory, as if `DBInstanceClassMemory` were the whole memory. From what size does the cap of 5,000 apply?

<details>
<summary>Solution</summary>

[`sql/12-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/12-exercises.sql):

```sql
-- Lesson 12, exercise 1: Aurora's default max_connections, LEAST({DBInstanceClassMemory/9531392}, 5000), for a few memory
-- sizes. DBInstanceClassMemory is somewhat less than the instance class's memory: these are upper bounds.
SELECT memory_gib, least(memory_gib::bigint * 1024 * 1024 * 1024 / 9531392, 5000) AS max_connections
FROM unnest(ARRAY[2, 4, 16, 32, 64]) AS memory_gib
ORDER BY memory_gib;
```

```text
 memory_gib | max_connections
------------+-----------------
          2 |             225
          4 |             450
         16 |            1802
         32 |            3604
         64 |            5000
(5 rows)
```

The division is an integer division of bytes: about 112.7 connections per GiB. The cap applies from 5,000 × 9,531,392 bytes, about 44.4 GiB of `DBInstanceClassMemory`, so a little more memory on the instance. A pool of 50 connections in each of 40 application instances needs 2,000: a 16 GiB instance is too small, however fast its CPU.

</details>

2. An application writes through the cluster endpoint, then, in the same request, reads the row back through the reader endpoint, and sometimes doesn't find it. Why, and what are two fixes?

<details>
<summary>Solution</summary>

Aurora Replicas are asynchronous: their lag is "usually much less than 100 milliseconds", not zero. The read reached a replica that hadn't applied the write yet: lesson 10's standby, which the script had to wait for before reading.

- Read your own writes on the writer: the same connection, or the cluster endpoint, for reads that follow a write.
- Send to the reader endpoint only what tolerates slightly old data: reports, searches, lists.

Waiting on the replica for a position, as `until_true` did in lesson 10, isn't something an application should do per request.

</details>

3. During the local failover, why did the connection opened before the failure not come back by itself, while the next `OpenConnectionAsync()` or `getConnection` found `node2`?

<details>
<summary>Solution</summary>

A connection is a session on one server process: when `node1` stopped, that process ended, with its transaction. Nothing can move a session to another server, on Aurora either, where AWS writes that "read and write operations fail with an exception". Opening a *new* connection runs the driver's host selection again, which checks each host's role: `node2` had been promoted. An application survives a failover by catching the error, and retrying the whole transaction on a new connection, as lesson 6's retry loop did for `40001`.

</details>

## Sources

- AWS, all read on 2026-09-16: [Aurora storage](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html), [high availability](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.AuroraHighAvailability.html), [overview](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html), [quotas and limits](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html), [Aurora replication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html), [Aurora PostgreSQL replication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html), [endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html), [cluster endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Cluster.html), [reader endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Reader.html), [custom endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Custom.html), [best practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html), [fast failover with Java](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.FastFailover.html), [AWS drivers](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/IAMDBAuth.Connecting.Drivers.html), [Serverless: how it works](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html), [requirements](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.requirements.html), [auto-pause](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2-auto-pause.html), [Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html), [its disaster recovery](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-disaster-recovery.html), [write forwarding](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-write-forwarding-apg.html), [RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/rds-proxy.html), [its planning](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/rds-proxy-planning.html) and [versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.RDS_Proxy.html), [IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.html), [database accounts](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.DBAccounts.html), [IAM policy](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html), [performance and scaling](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.html), [parameter formulas](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_ParamValuesRef.html), [Limitless Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless.html), [its requirements](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless-reqs-limits.html), [release calendar](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html), [Extended Support](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/extended-support.html)
- AWS drivers on GitHub: [AWS Advanced JDBC Wrapper 4.4.0](https://github.com/aws/aws-advanced-jdbc-wrapper/blob/4.4.0/README.md), [failover plugin v2](https://github.com/aws/aws-advanced-jdbc-wrapper/blob/4.4.0/docs/using-the-jdbc-driver/using-plugins/UsingTheFailover2Plugin.md), [AWS Advanced .NET Data Provider Wrapper 2.2.0](https://github.com/aws/aws-advanced-dotnet-data-provider-wrapper/blob/2.2.0/README.md)
- Npgsql: [failover and load balancing](https://www.npgsql.org/doc/failover-and-load-balancing.html); pgjdbc: [connection parameters](https://jdbc.postgresql.org/documentation/use/)
- PostgreSQL 18: [`COPY`](https://www.postgresql.org/docs/18/sql-copy.html), [release notes](https://www.postgresql.org/docs/18/release-18.html)
- Microsoft: [Hyperscale](https://learn.microsoft.com/azure/azure-sql/database/service-tier-hyperscale), [active geo-replication](https://learn.microsoft.com/azure/azure-sql/database/active-geo-replication-overview)
