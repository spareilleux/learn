// DuckDB course, lesson 6: DuckDB from Java with the JDBC driver
// Run from code/duckdb: mvn -q -f java/pom.xml compile exec:java -Dexec.args=check (or timings)
package ci;

import java.sql.Array;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Arrays;
import java.util.Map;
import org.duckdb.DuckDBConnection;
import org.duckdb.DuckDBStruct;

public class CiQueries {
    public static void main(String[] args) throws SQLException {
        String mode = args.length > 0 ? args[0] : "check";

        // An in-memory database, like the CLI started without a file name
        try (Connection connection = DriverManager.getConnection("jdbc:duckdb:")) {
            System.out.println("DuckDB " + connection.getMetaData().getDatabaseProductVersion());
            if (mode.equals("timings")) {
                timings(connection);
            } else {
                check(connection);
            }
        }
    }

    static void check(Connection connection) throws SQLException {
        section("1. A query with a result set");
        try (var statement = connection.createStatement();
             var rs = statement.executeQuery("""
                 SELECT workflowName, count(*) AS runs, count(*) FILTER (conclusion = 'failure') AS failures
                 FROM 'data/runs.json'
                 GROUP BY ALL
                 ORDER BY runs DESC, workflowName
                 LIMIT 3
                 """)) {
            while (rs.next()) {
                System.out.printf("%-24s %3d runs %2d failures%n", rs.getString(1), rs.getLong("runs"), rs.getLong("failures"));
            }
        }

        section("2. Parameters");
        try (var ps = connection.prepareStatement(
                "SELECT count(*) FROM read_json(?) WHERE workflowName = ? AND conclusion = ?")) {
            ps.setString(1, "data/runs.json");
            ps.setString(2, "Rust course examples");
            ps.setString(3, "failure");
            try (var rs = ps.executeQuery()) {
                rs.next();
                System.out.println("Rust course failures: " + rs.getLong(1));
            }
        }

        section("3. DuckDB types as Java types");
        try (var statement = connection.createStatement();
             var rs = statement.executeQuery("""
                 SELECT workflowName, databaseId, createdAt, createdAt::DATE AS day, updatedAt - startedAt AS took,
                        createdAt AT TIME ZONE 'UTC' AS created_utc, sum(databaseId) OVER () AS total,
                        [event, conclusion] AS pair, {'event': event, 'attempt': attempt} AS info
                 FROM 'data/runs.json'
                 ORDER BY createdAt
                 LIMIT 1
                 """)) {
            var metadata = rs.getMetaData();
            rs.next();
            for (int i = 1; i <= metadata.getColumnCount(); i++) {
                System.out.printf("%-12s %-38s %s%n", metadata.getColumnName(i), metadata.getColumnTypeName(i), metadata.getColumnClassName(i));
            }
            System.out.println("took: " + rs.getObject("took"));
            OffsetDateTime createdUtc = rs.getObject("created_utc", OffsetDateTime.class);
            System.out.println("created_utc as an instant: " + createdUtc.toInstant());
            System.out.println("created_utc in UTC: " + createdUtc.withOffsetSameInstant(ZoneOffset.UTC));
        }

        section("4. Lists and structs");
        try (var statement = connection.createStatement();
             var rs = statement.executeQuery("SELECT labels, steps FROM 'data/jobs.json' WHERE id = 104004920113")) {
            rs.next();
            Array labels = rs.getArray("labels");
            System.out.println("labels: " + Arrays.toString((Object[]) labels.getArray()));
            Object[] steps = (Object[]) rs.getArray("steps").getArray();
            for (int i = 0; i < 3; i++) {
                Map<String, Object> step = ((DuckDBStruct) steps[i]).getMap();
                System.out.println("step " + step.get("number") + ": " + step.get("name") + ", " + step.get("conclusion")
                        + ", started_at is a " + step.get("started_at").getClass().getName());
            }
        }

        section("5. Errors");
        try (var statement = connection.createStatement()) {
            try {
                statement.executeQuery("SELECT workflow_name FROM 'data/runs.json'");
            } catch (SQLException e) {
                String[] lines = e.getMessage().split("\n");
                System.out.println(e.getClass().getName() + ", SQLState = " + e.getSQLState());
                System.out.println(lines[0]);
                System.out.println(lines[1]);
            }
            System.out.println("statement closed after the error: " + statement.isClosed());
            try {
                statement.executeQuery("SELECT 42");
            } catch (SQLException e) {
                System.out.println("next query on the same statement: " + e.getMessage());
            }
        }
    }

    // Bulk loading: the appender, a batch and single INSERT statements; timings only, not compared by CI
    static void timings(Connection connection) throws SQLException {
        try (var statement = connection.createStatement()) {
            statement.execute("CREATE TABLE numbers (i INTEGER, label VARCHAR)");
        }

        int appended = 1_000_000;
        long start = System.nanoTime();
        try (var appender = connection.unwrap(DuckDBConnection.class).createAppender(DuckDBConnection.DEFAULT_SCHEMA, "numbers")) {
            for (int i = 0; i < appended; i++) {
                appender.beginRow();
                appender.append(i);
                appender.append("n" + i);
                appender.endRow();
            }
        }
        System.out.printf("appender: %,d rows in %d ms%n", appended, (System.nanoTime() - start) / 1_000_000);

        int inserted = 10_000;
        connection.setAutoCommit(false);
        start = System.nanoTime();
        try (var ps = connection.prepareStatement("INSERT INTO numbers VALUES (?, ?)")) {
            for (int i = 0; i < inserted; i++) {
                ps.setInt(1, i);
                ps.setString(2, "n" + i);
                ps.addBatch();
            }
            ps.executeBatch();
        }
        connection.commit();
        System.out.printf("INSERT batch: %,d rows in %d ms%n", inserted, (System.nanoTime() - start) / 1_000_000);

        start = System.nanoTime();
        try (var ps = connection.prepareStatement("INSERT INTO numbers VALUES (?, ?)")) {
            for (int i = 0; i < inserted; i++) {
                ps.setInt(1, i);
                ps.setString(2, "n" + i);
                ps.executeUpdate();
            }
        }
        connection.commit();
        System.out.printf("INSERT one by one: %,d rows in %d ms%n", inserted, (System.nanoTime() - start) / 1_000_000);
    }

    static void section(String title) {
        System.out.println();
        System.out.println("== " + title);
    }
}
