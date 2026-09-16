---
title: "12. Amazon Aurora PostgreSQL"
description: Ce qu'Aurora change pour un développeur PostgreSQL, d'après la documentation d'AWS lue le 2026-09-16 — le volume de cluster partagé, les Aurora Replicas et le basculement, les endpoints et le DNS, un basculement reproduit localement avec Npgsql et pgjdbc sur un primaire et un standby, Aurora Serverless, Global Database, RDS Proxy, l'authentification IAM, les configurations de stockage, Limitless Database et le calendrier des versions. Aucun compte AWS n'a été utilisé.
sidebar:
  order: 12
---

Cette leçon n'a pas de compte AWS derrière elle : le cours ne crée aucune ressource AWS et n'utilise aucun identifiant. Tout ce qu'elle dit d'Aurora vient de la documentation d'AWS, lue le 2026-09-16, et est *à vérifier*. Les pages d'AWS ne portent pas de date, donc la date est celle où je les ai lues. Ce qui peut tourner localement tourne : un basculement vu depuis C# et Java, dans [`csharp/L12.cs`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/csharp/L12.cs) et [`java/…/L12.java`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L12.java), dont `check.sh` compare les sorties à [`expected/l12-failover-cs.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/l12-failover-cs.txt) et [`expected/l12-failover-java.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/l12-failover-java.txt). L'exercice est dans [`sql/12-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/12-exercises.sql).

Les leçons précédentes se terminaient chacune par une section sur Aurora ; celle-ci les rassemble et ajoute ce qu'elles ont laissé de côté.

| Azure SQL Database | Aurora PostgreSQL |
|---|---|
| serveur logique, bases de données | cluster de bases : une instance writer, jusqu'à 15 Aurora Replicas, un volume de cluster |
| [Hyperscale](https://learn.microsoft.com/azure/azure-sql/database/service-tier-hyperscale) : le calcul séparé d'un stockage distribué | la même idée : des instances attachées à un volume de stockage réparti sur trois zones de disponibilité |
| groupes de basculement, un écouteur en lecture-écriture | le cluster endpoint, qui passe au nouveau writer |
| scale-out en lecture, `ApplicationIntent=ReadOnly` | le reader endpoint, ou des custom endpoints |
| niveau de calcul serverless | Aurora Serverless, en unités de capacité Aurora (ACU) |
| [géo-réplication active](https://learn.microsoft.com/azure/azure-sql/database/active-geo-replication-overview) | Aurora Global Database |
| authentification Microsoft Entra | authentification IAM de base de données |

## Le volume de cluster

Une instance Aurora exécute le moteur de PostgreSQL, mais pas sur son propre disque. « Aurora data is stored in the cluster volume, which is a single, virtual volume that uses solid state drives (SSDs). A cluster volume consists of copies of the data across three Availability Zones in a single AWS Region » ([stockage Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html)), et « when data is written to the primary DB instance, Aurora synchronously replicates the data across Availability Zones to six storage nodes associated with your cluster volume » ([haute disponibilité](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.AuroraHighAvailability.html)).

Ce qui en découle pour les leçons précédentes :

- **Des réplicas sans réplication à mettre en place.** « The cluster volume is shared among all instances in your Aurora PostgreSQL DB cluster » ([réplication Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html)). Le `pg_basebackup`, les slots et le `pg_rewind` de la leçon 10 n'ont pas d'équivalent à exécuter : ajouter un réplica ne copie pas les données.
- **Le stockage grandit tout seul.** La [page des quotas](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html) donne un volume maximal de 256 Tio pour Aurora PostgreSQL 17.5, 16.9, 15.13 et plus, et de 128 Tio pour les versions antérieures, et une taille maximale de table de 32 Tio. Le tableau des quotas de la même page dit encore 128 Tio sans version, et la [présentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html) dit 256 Tio sans version : le tableau par version est le plus précis.
- **Des sauvegardes sans `archive_command`.** Leçon 11 : sauvegardes continues vers S3, restaurations dans de nouveaux clusters.

## Réplicas et basculement

« After you create the primary (writer) instance, you can create up to 15 read-only Aurora Replicas » ([haute disponibilité](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.AuroraHighAvailability.html)). Leur retard « is usually much less than 100 milliseconds after the primary instance has written an update » ([réplication Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html)).

Quand le writer tombe, Aurora promeut un réplica : celui qui a le meilleur niveau de promotion, où « priorities range from 0 for the highest priority to 15 for the lowest priority », et à niveau égal « the replica that is largest in size ». Ce que voit l'application : « A failure event results in a brief interruption, during which read and write operations fail with an exception. However, service is typically restored in less than 60 seconds, and often less than 30 seconds. » Sans réplica, une nouvelle instance doit être créée, ce qui « typically takes less than 10 minutes ».

## Endpoints et DNS

La leçon 3 a présenté les endpoints ([endpoints Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html)) :

- Le **cluster endpoint** est un nom DNS qui pointe vers le writer. « The physical IP address pointed to by the cluster endpoint changes when the failover mechanism promotes a new DB instance to be the read/write primary instance for the cluster » ([cluster endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Cluster.html)).
- Le **reader endpoint** « balances connections to available Aurora Replicas in an Aurora DB cluster. It doesn't balance individual queries » ([reader endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Reader.html)). Un pool qui a ouvert ses connexions sur le reader endpoint reste sur les réplicas qu'il a atteints.
- Les **custom endpoints** regroupent des instances choisies, « up to five custom endpoints for each provisioned Aurora cluster or Aurora serverless cluster » ([custom endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Custom.html)) ; les **instance endpoints** atteignent une instance.

Un basculement change un enregistrement DNS, et un client qui met le DNS en cache continue de se connecter à l'ancien writer. Les [bonnes pratiques](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html) d'AWS : « If your client application is caching the Domain Name Service (DNS) data of your DB instances, set a time-to-live (TTL) value of less than 30 seconds. » La JVM met elle-même les réponses DNS en cache ; la [page d'AWS sur le basculement rapide en Java](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.FastFailover.html) règle `networkaddress.cache.ttl` à 1.

## Un basculement depuis C# et Java, en local

Le cluster endpoint cache le changement derrière un nom DNS. L'autre approche de la leçon 4 donne au pilote toutes les instances et le laisse trouver le writer. Cela peut tourner en local : [`ops/12-cluster.sh`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/12-cluster.sh) démarre `node1`, un primaire sur le port 5433, et `node2`, son standby sur 5434, dans le conteneur du cours, comme dans la leçon 10 ; `server.sh` publie les deux ports ([lignes 15-35](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/ops/12-cluster.sh#L15-L35)) :

```bash
# Le mot de passe de postgres est celui du serveur du cours ; les connexions par socket Unix dans le conteneur n'en ont pas besoin
echo learn > password
initdb -D node1 --auth-local=trust --auth-host=scram-sha-256 --pwfile=password > /dev/null
rm password
cat >> node1/postgresql.conf <<'EOF'
listen_addresses = '*'
shared_buffers = 32MB
EOF
# Les connexions depuis l'hôte passent par le réseau de Docker, pas par 127.0.0.1
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

`check.sh` le réexécute avant chaque programme. Le programme C# ([`L12.cs`, lignes 33-93](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/csharp/L12.cs#L33-L93)) :

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

        // Une connexion ouverte avant le basculement, et node1 arrêté par son propre serveur : pg_ctl -W n'attend pas
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
                // L'arrêt peut terminer cette session avant que COPY revienne
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
            // L'exception dépend de la machine : une PostgresException 57P01 sous Linux en CI, « Exception while reading
            // from stream » à travers Docker Desktop sous Windows. L'état de la connexion est le même dans les deux cas
            Console.WriteLine($"open connection: the query fails, FullState = {open.FullState}");
        }
        Console.WriteLine($"no primary: {await Write(writer)}");

        // La promotion, qu'Aurora fait d'elle-même : node2 arrête de rejouer le WAL et accepte les écritures
        await using (var connection = await standby.OpenConnectionAsync())
        {
            await using var promote = new NpgsqlCommand("SELECT pg_promote()", connection);
            Console.WriteLine($"pg_promote() on node2: {await promote.ExecuteScalarAsync()}");
        }
        // La même source de données, avec la même liste d'hôtes, trouve maintenant son writer sur node2
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

Le programme Java fait de même avec le `targetServerType` de pgjdbc ([`L12.java`, lignes 31-75](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/java/src/main/java/dev/learn/pg/L12.java#L31-L75)) :

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

        // Une connexion ouverte avant le basculement, et node1 arrêté par son propre serveur : pg_ctl -W n'attend pas
        try (Connection open = DriverManager.getConnection(primary)) {
            try (Connection admin = DriverManager.getConnection(primary); Statement statement = admin.createStatement()) {
                statement.execute("COPY (SELECT) TO PROGRAM '/usr/lib/postgresql/18/bin/pg_ctl -D /tmp/node1 -m fast -W stop'");
            } catch (SQLException e) {
                // L'arrêt peut terminer cette session avant que COPY revienne
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

        // La promotion, qu'Aurora fait d'elle-même : node2 arrête de rejouer le WAL et accepte les écritures
        try (Connection connection = DriverManager.getConnection(secondary);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("SELECT pg_promote()")) {
            rs.next();
            System.out.println("pg_promote() on node2: " + rs.getBoolean(1));
        }
        // La même URL trouve maintenant son primaire sur node2
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

- **La panne.** Le programme arrête `node1` de l'intérieur : [`COPY … TO PROGRAM`](https://www.postgresql.org/docs/18/sql-copy.html) exécute `pg_ctl` sur le serveur, en tant que superutilisateur `postgres`, et `-W` revient sans attendre. Cela tient lieu de la panne d'instance qu'Aurora détecte.
- **La connexion ouverte se rompt.** pgjdbc reçoit le `57P01` du serveur, « terminating connection due to administrator command » ; L'exception de Npgsql dépend de la machine : la même `PostgresException` avec `57P01` sous Linux en CI, seulement « Exception while reading from stream » sous Windows à travers Docker Desktop, où le socket s'est fermé avant que le message soit lu ; le programme C# affiche donc le `FullState` de la connexion, `Broken` dans les deux cas. Dans les deux cas, la transaction en cours sur cette connexion est perdue, comme le dit le « read and write operations fail with an exception » d'AWS.
- **Pas de writer pendant un moment.** Entre la panne et la promotion, [Npgsql](https://www.npgsql.org/doc/failover-and-load-balancing.html) trouve « No suitable host » et pgjdbc « Could not find a server with specified targetServerType: primary ». Le standby répond toujours, en lecture seule.
- **La promotion.** Sur Aurora, AWS s'en charge. Ici, le programme appelle `pg_promote()` sur `node2`, par une connexion `Standby` ou `secondary`.
- **La même chaîne de connexion trouve le nouveau writer.** Aucun des deux programmes ne change sa liste d'hôtes : chaque pilote vérifie quel hôte accepte les écritures, et c'est maintenant `node2`. Les deux pilotes mettent en cache l'état des hôtes, 10 secondes par défaut (`Host Recheck Seconds` dans Npgsql, [`hostRecheckSeconds`](https://jdbc.postgresql.org/documentation/use/) dans pgjdbc) ; l'écriture juste après la promotion a quand même trouvé `node2`. Comment chaque pilote traite un hôte dont il se souvient comme standby quand aucun primaire n'est connu est *à vérifier* dans leur code source.

Ce que cela ne reproduit pas : sur Aurora, les noms d'hôtes des instances ne bougent pas, mais l'application ne connaît en général que les endpoints. Les pilotes d'AWS suivent plutôt la topologie du cluster. « The AWS drivers rely on monitoring DB cluster status and being aware of the cluster topology to determine the new writer. This approach reduces switchover and failover times to single-digit seconds, compared to tens of seconds for open-source drivers » ([pilotes AWS](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/IAMDBAuth.Connecting.Drivers.html)) :

- En Java, l'[AWS Advanced JDBC Wrapper](https://github.com/aws/aws-advanced-jdbc-wrapper/blob/4.4.0/README.md), 4.4.0 publié le 2026-08-20, enveloppe pgjdbc ; son [plugin de basculement v2](https://github.com/aws/aws-advanced-jdbc-wrapper/blob/4.4.0/docs/using-the-jdbc-driver/using-plugins/UsingTheFailover2Plugin.md) surveille la topologie depuis un thread séparé.
- En .NET, l'[AWS Advanced .NET Data Provider Wrapper](https://github.com/aws/aws-advanced-dotnet-data-provider-wrapper/blob/2.2.0/README.md), 2.2.0 publié le 2026-08-05, « does not connect directly to any database, but enables support of AWS and Aurora functionalities on top of an underlying .NET driver », avec un paquet pour Npgsql. La liste des pilotes AWS du guide de l'utilisateur d'Aurora ne le mentionne pas encore.

## Aurora Serverless

Une instance Aurora Serverless change de taille pendant qu'elle tourne. Son unité est l'ACU : « Each ACU is a combination of approximately 2 gibibytes (GiB) of memory, corresponding CPU, and networking. […] Aurora serverless offers capacity from 0 ACUs to 256 ACUs » ([fonctionnement](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html)), « in increments of 0.5 ACU » ([exigences](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.requirements.html)). Le guide d'AWS l'appelle maintenant « Aurora serverless » ; les URL des pages disent encore `serverless-v2`, et « Aurora Serverless v1 » est le produit déprécié.

- **Jusqu'à zéro.** Une instance avec un minimum de 0 ACU se met en pause « if they don't have any connections initiated by user activity within a specified time period », depuis Aurora PostgreSQL 16.3, 15.7, 14.12 ou 13.15 ([mise en pause automatique](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2-auto-pause.html)). Que les connexions inactives du pool d'une application empêchent une instance de se mettre en pause est *à vérifier*.
- **Clusters mixtes.** « You can set up a cluster that contains both Aurora serverless and provisioned capacity, called a mixed-configuration cluster » : un writer provisionné avec des readers serverless, par exemple.
- **Versions.** Le tableau des capacités liste les versions jusqu'à 16 « and higher ». Que les versions PostgreSQL 18 aient la plage de 0 à 256 ACU est *à vérifier*.

## Global Database

« An Aurora global database has a primary DB cluster in one Region, and up to 10 secondary DB clusters in different Regions », répliqués « with latency typically under a second », et « Aurora uses the cluster storage volume and not the database engine for fast, low-overhead replication » ([Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html)).

- **La bascule (switchover)** est planifiée : « Because this feature synchronizes secondary DB clusters with the primary before making any other changes, RPO is 0 (no data loss) ». **Le basculement (failover)** sert en cas de panne régionale, et « the RPO for this approach is typically a non-zero value measured in seconds » ([reprise après sinistre](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-disaster-recovery.html)) : le commit perdu de la leçon 10, entre régions. Le paramètre `rds.global_db_rpo` lui fixe une borne supérieure, « but doing so might affect transaction processing on the primary ».
- **Transfert des écritures.** Un cluster secondaire peut transférer les écritures au primaire : « In Aurora PostgreSQL version 16 and higher major versions, global write forwarding is supported in all minor versions » ([transfert des écritures](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-write-forwarding-apg.html)).

## RDS Proxy

La leçon 4 a couvert le partage de connexions de [RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/rds-proxy.html) et les instructions qui épinglent une session. Pour la disponibilité, AWS ajoute qu'il « bypasses Domain Name System (DNS) caches to reduce failover times by up to 66% for Aurora Multi-AZ databases » ([planification](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/rds-proxy-planning.html)). Deux limites de la même page comptent pour les clients PostgreSQL :

- « RDS Proxy doesn't currently support canceling a query from a client by issuing a CancelRequest » : le `NpgsqlCommand.Cancel()` de Npgsql et le `Statement.cancel()` de pgjdbc en envoient une.
- « Any statement with a text size greater than 16 KB causes the proxy to pin the session to the current connection. »

Le [tableau des versions de RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.RDS_Proxy.html) liste Aurora PostgreSQL 18.3 et plus.

## Authentification IAM de base de données

La leçon 4 a montré comment les pilotes rafraîchissent un jeton. Le reste, d'après l'[authentification IAM de base de données](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.html) :

- L'utilisateur de la base a besoin d'un rôle : `GRANT rds_iam TO db_userx`, et ensuite « IAM authentication takes precedence over password authentication, so the user must log in as an IAM user » ([créer un compte de base de données](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.DBAccounts.html)).
- La politique IAM autorise l'action `rds-db:connect` sur une ressource qui nomme le cluster et l'utilisateur de la base ([politique IAM](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html)).
- La vérification des jetons coûte au serveur : « You must have between 300 and 1000 MiB extra memory on your database for reliable connectivity. »
- L'exemple `psql` d'AWS se connecte avec `sslmode=verify-full`.

## Configurations de stockage, dimensionnement et Limitless

- **Standard ou I/O-Optimized.** Avec Aurora Standard, « you also pay a standard rate per 1 million requests for I/O operations » ; avec I/O-Optimized, « you pay only for the usage and storage of your DB clusters, with no additional charges for read and write I/O operations ». La règle d'AWS : « Aurora I/O-Optimized is the best choice when your I/O spending is 25% or more of your total Aurora database spending », et un cluster peut y passer « once every 30 days » ([stockage](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html)). La leçon 13 revient sur les coûts.
- **max_connections** suit la mémoire de l'instance : `LEAST({DBInstanceClassMemory/9531392},5000)` ([performances et mise à l'échelle](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.html)). `DBInstanceClassMemory` part de la mémoire de la classe d'instance, puis « subtracts memory reserved for the operating system and the RDS processes that manage the instance » ([formules des paramètres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_ParamValuesRef.html)). L'exercice le calcule.
- **Limitless Database** répartit les tables en shards sur plusieurs instances « to process millions of write transactions per second » ([Limitless](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless.html)). Elle tourne sur des versions spéciales, « 16.X-limitless », et « supports only the Aurora I/O-Optimized DB cluster storage configuration » ([exigences](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless-reqs-limits.html)) ; le calendrier des versions n'a pas de version Limitless 17 ou 18.

## Versions et support

Le [calendrier des versions d'Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html) :

| Version majeure | Première version Aurora | Fin du support standard |
|---|---|---|
| 13 | | 28 février 2026, puis Extended Support jusqu'au 28 février 2029 |
| 14 | | 28 février 2027, puis Extended Support jusqu'au 28 février 2030 |
| 17 | | 28 février 2030 |
| 18 | 11 juin 2026, avec 18.3 | 28 février 2031 |

- **Les versions mineures** ont leurs propres dates de fin : 18.3 jusqu'au 30 novembre 2027, et 18.4, publiée le 21 août 2026, jusqu'au 31 décembre 2027.
- **Extended Support** « allows you to continue running a database on a major engine version past the Aurora end of standard support date for an additional cost » ([Extended Support](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/extended-support.html)). Aurora PostgreSQL 13 y est depuis le 1er mars 2026.
- **Une date à ne pas recopier.** Le tableau des versions majeures du calendrier donne à PostgreSQL 18 une « community release date » du 26 février 2026. PostgreSQL 18.0 est sorti le 25 septembre 2025, d'après ses [notes de version](https://www.postgresql.org/docs/18/release-18.html) ; le 26 février 2026 est la date que le tableau des versions mineures donne pour 18.3.
- **Les fonctionnalités suivent plus tard.** PostgreSQL 18 a une colonne dans le tableau de RDS Proxy, mais pas encore dans ceux de blue/green ou de zero-ETL ([leçon 11](../11-backup/#sur-aurora), [leçon 10](../10-replication/#sur-aurora)).

## À retenir

- Les instances Aurora partagent un volume de cluster, six copies sur trois zones de disponibilité : aucune réplication à mettre en place entre instances.
- Un basculement prend en général moins de 60 secondes, et les transactions en cours échouent : les applications réessaient.
- Le cluster endpoint suit le writer par le DNS : garde les caches DNS sous 30 secondes, ou utilise un pilote qui suit la topologie.
- Une chaîne de connexion multi-hôtes trouve d'elle-même le nouveau writer, comme l'a montré le basculement local avec Npgsql et pgjdbc.
- Serverless évolue par pas de 0,5 ACU, jusqu'à zéro avec la mise en pause automatique ; Global Database copie vers d'autres régions en une seconde environ, avec un RPO de quelques secondes en cas de basculement.
- RDS Proxy raccourcit les basculements mais ne transmet pas les demandes d'annulation ; les jetons IAM demandent de la mémoire en plus sur le serveur.
- Vérifie le tableau des versions d'une fonctionnalité avant de supposer qu'elle prend en charge Aurora PostgreSQL 18.

## Exercices

1. Calcule le `max_connections` par défaut d'Aurora pour des instances de 2, 4, 16, 32 et 64 Gio de mémoire, comme si `DBInstanceClassMemory` était toute la mémoire. À partir de quelle taille le plafond de 5 000 s'applique-t-il ?

<details>
<summary>Solution</summary>

[`sql/12-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/12-exercises.sql) :

```sql
-- Leçon 12, exercice 1 : le max_connections par défaut d'Aurora, LEAST({DBInstanceClassMemory/9531392}, 5000), pour quelques tailles
-- de mémoire. DBInstanceClassMemory est un peu inférieur à la mémoire de la classe d'instance : ce sont des bornes supérieures.
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

La division est une division entière d'octets : environ 112,7 connexions par Gio. Le plafond s'applique à partir de 5 000 × 9 531 392 octets, environ 44,4 Gio de `DBInstanceClassMemory`, donc un peu plus de mémoire sur l'instance. Un pool de 50 connexions dans chacune de 40 instances de l'application en demande 2 000 : une instance de 16 Gio est trop petite, quelle que soit la rapidité de son CPU.

</details>

2. Une application écrit par le cluster endpoint, puis, dans la même requête, relit la ligne par le reader endpoint, et parfois ne la trouve pas. Pourquoi, et quelles sont deux corrections possibles ?

<details>
<summary>Solution</summary>

Les Aurora Replicas sont asynchrones : leur retard est « usually much less than 100 milliseconds », pas nul. La lecture a atteint un réplica qui n'avait pas encore appliqué l'écriture : le standby de la leçon 10, que le script devait attendre avant de lire.

- Relis tes propres écritures sur le writer : la même connexion, ou le cluster endpoint, pour les lectures qui suivent une écriture.
- N'envoie au reader endpoint que ce qui tolère des données un peu anciennes : rapports, recherches, listes.

Attendre une position sur le réplica, comme le faisait `until_true` dans la leçon 10, n'est pas quelque chose qu'une application devrait faire à chaque requête.

</details>

3. Pendant le basculement local, pourquoi la connexion ouverte avant la panne n'est-elle pas revenue d'elle-même, alors que l'`OpenConnectionAsync()` ou le `getConnection` suivant a trouvé `node2` ?

<details>
<summary>Solution</summary>

Une connexion est une session sur un processus serveur : quand `node1` s'est arrêté, ce processus a pris fin, avec sa transaction. Rien ne peut déplacer une session vers un autre serveur, sur Aurora non plus, où AWS écrit que « read and write operations fail with an exception ». Ouvrir une *nouvelle* connexion relance la sélection d'hôte du pilote, qui vérifie le rôle de chaque hôte : `node2` avait été promu. Une application survit à un basculement en attrapant l'erreur, et en réessayant toute la transaction sur une nouvelle connexion, comme la boucle de nouvelle tentative de la leçon 6 le faisait pour `40001`.

</details>

## Sources

- AWS, toutes lues le 2026-09-16 : [stockage Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.StorageReliability.html), [haute disponibilité](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.AuroraHighAvailability.html), [présentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html), [quotas et limites](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html), [réplication Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html), [réplication Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Replication.html), [endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html), [cluster endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Cluster.html), [reader endpoint](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Reader.html), [custom endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Endpoints.Custom.html), [bonnes pratiques](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html), [basculement rapide en Java](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.FastFailover.html), [pilotes AWS](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/IAMDBAuth.Connecting.Drivers.html), [Serverless : fonctionnement](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html), [exigences](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.requirements.html), [mise en pause automatique](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2-auto-pause.html), [Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html), [sa reprise après sinistre](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-disaster-recovery.html), [transfert des écritures](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-write-forwarding-apg.html), [RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/rds-proxy.html), [sa planification](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/rds-proxy-planning.html) et [ses versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.Aurora_Fea_Regions_DB-eng.Feature.RDS_Proxy.html), [authentification IAM de base de données](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.html), [comptes de base de données](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.DBAccounts.html), [politique IAM](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/UsingWithRDS.IAMDBAuth.IAMPolicy.html), [performances et mise à l'échelle](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.html), [formules des paramètres](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_ParamValuesRef.html), [Limitless Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless.html), [ses exigences](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless-reqs-limits.html), [calendrier des versions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html), [Extended Support](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/extended-support.html)
- Pilotes AWS sur GitHub : [AWS Advanced JDBC Wrapper 4.4.0](https://github.com/aws/aws-advanced-jdbc-wrapper/blob/4.4.0/README.md), [plugin de basculement v2](https://github.com/aws/aws-advanced-jdbc-wrapper/blob/4.4.0/docs/using-the-jdbc-driver/using-plugins/UsingTheFailover2Plugin.md), [AWS Advanced .NET Data Provider Wrapper 2.2.0](https://github.com/aws/aws-advanced-dotnet-data-provider-wrapper/blob/2.2.0/README.md)
- Npgsql : [basculement et répartition de charge](https://www.npgsql.org/doc/failover-and-load-balancing.html) ; pgjdbc : [paramètres de connexion](https://jdbc.postgresql.org/documentation/use/)
- PostgreSQL 18 : [`COPY`](https://www.postgresql.org/docs/18/sql-copy.html), [notes de version](https://www.postgresql.org/docs/18/release-18.html)
- Microsoft : [Hyperscale](https://learn.microsoft.com/azure/azure-sql/database/service-tier-hyperscale), [géo-réplication active](https://learn.microsoft.com/azure/azure-sql/database/active-geo-replication-overview)
