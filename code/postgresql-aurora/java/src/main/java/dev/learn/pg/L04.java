package dev.learn.pg;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.io.BufferedReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.BatchUpdateException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.postgresql.PGConnection;
import org.postgresql.util.PSQLException;

/** Lesson 4: PostgreSQL from Java with the PostgreSQL JDBC driver, on the course model (sql/schema.sql). */
final class L04 {
    private L04() {
    }

    // The server of server.sh; the course runs as postgres to keep the examples short (lesson 1 creates roles)
    static String url() {
        String url = System.getenv("PG_JDBC_URL");
        return url != null ? url
                : "jdbc:postgresql://localhost:5432/learn?user=postgres&password=learn&ApplicationName=learn-java";
    }

    static void connect() throws SQLException {
        try (Connection connection = DriverManager.getConnection(url());
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT current_user, current_setting('server_version'), (SELECT count(*) FROM ci.runs),"
                             + " current_setting('TimeZone')")) {
            rs.next();
            System.out.println("driver: " + connection.getMetaData().getDriverVersion());
            // The driver sets the session's TimeZone to the JVM's default time zone
            System.out.println("JVM time zone: " + java.util.TimeZone.getDefault().getID() + ", session TimeZone: " + rs.getString(4));
            System.out.println("user: " + rs.getString(1));
            System.out.println("server: " + rs.getString(2));
            System.out.println("runs: " + rs.getLong(3));
        }
    }

    static void parameters() throws SQLException {
        try (Connection connection = DriverManager.getConnection(url())) {
            // JDBC's ? placeholders; the driver sends them as $1, $2
            try (PreparedStatement ps = connection.prepareStatement("""
                    SELECT run_id, started_at FROM ci.runs
                    WHERE workflow_name = ? AND started_at >= ?
                    ORDER BY started_at, run_id
                    LIMIT 2
                    """)) {
                ps.setString(1, "Rust course examples");
                ps.setObject(2, OffsetDateTime.of(2026, 9, 13, 18, 0, 0, 0, ZoneOffset.UTC));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        System.out.println(rs.getLong(1) + " " + rs.getObject(2, OffsetDateTime.class));
                    }
                }
            }

            // An array parameter: = ANY (?)
            try (PreparedStatement ps = connection.prepareStatement(
                    "SELECT labels[1], count(*) FROM ci.jobs WHERE labels[1] = ANY (?) GROUP BY 1 ORDER BY 1")) {
                ps.setArray(1, connection.createArrayOf("text", new String[] {"macos-latest", "windows-latest"}));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        System.out.println(rs.getString(1) + ": " + rs.getLong(2));
                    }
                }
            }

            // An OffsetDateTime keeps its offset; the server compares instants
            try (PreparedStatement ps = connection.prepareStatement("SELECT count(*) FROM ci.runs WHERE started_at >= ?")) {
                ps.setObject(1, OffsetDateTime.of(2026, 9, 14, 0, 0, 0, 0, ZoneOffset.ofHours(-4)));
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    System.out.println("runs since 2026-09-14 00:00 in Toronto: " + rs.getLong(1));
                }
            }

            // setString binds a varchar: PostgreSQL has no bigint = varchar operator
            try (PreparedStatement ps = connection.prepareStatement("SELECT count(*) FROM ci.runs WHERE run_id = ?")) {
                ps.setString(1, "34852867099");
                ps.executeQuery();
            } catch (PSQLException e) {
                System.out.println(e.getSQLState() + ": " + e.getServerErrorMessage().getMessage());
            }
        }
    }

    static int backendPid(Connection connection) throws SQLException {
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("SELECT pg_backend_pid()")) {
            rs.next();
            return rs.getInt(1);
        }
    }

    static void pool() throws SQLException {
        Set<Integer> backends = new HashSet<>();
        for (int i = 0; i < 20; i++) {
            try (Connection connection = DriverManager.getConnection(url())) {
                backends.add(backendPid(connection));
            }
        }
        System.out.println("DriverManager: 20 connections, " + backends.size() + " server process(es)");

        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(url().replace("learn-java", "learn-hikari"));
        config.setMaximumPoolSize(5);
        try (HikariDataSource pool = new HikariDataSource(config)) {
            backends.clear();
            for (int i = 0; i < 20; i++) {
                try (Connection connection = pool.getConnection()) {
                    backends.add(backendPid(connection));
                }
            }
            System.out.println("HikariCP: 20 connections, " + backends.size() + " server process(es)");
            // HikariCP opens connections in the background until minimumIdle, which defaults to maximumPoolSize
            try (Connection connection = pool.getConnection()) {
                long deadline = System.currentTimeMillis() + 10_000;
                long sessions;
                do {
                    try (Statement statement = connection.createStatement();
                         ResultSet rs = statement.executeQuery(
                                 "SELECT count(*) FROM pg_stat_activity WHERE application_name = 'learn-hikari'")) {
                        rs.next();
                        sessions = rs.getLong(1);
                    }
                } while (sessions < 5 && System.currentTimeMillis() < deadline && sleep(100));
                System.out.println("sessions opened by the pool: " + sessions);
            }
        }
    }

    private static boolean sleep(long millis) {
        try {
            Thread.sleep(millis);
            return true;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    static void prepare() throws SQLException {
        // The driver switches to a named server-side prepared statement on the prepareThreshold-th execution (default 5)
        try (Connection connection = DriverManager.getConnection(url());
             PreparedStatement count = connection.prepareStatement(
                     "SELECT count(*) FROM pg_prepared_statements WHERE statement ~ 'ci\\.jobs WHERE'")) {
            count.unwrap(org.postgresql.PGStatement.class).setPrepareThreshold(0);
            for (int i = 1; i <= 6; i++) {
                try (PreparedStatement ps = connection.prepareStatement("SELECT count(*) FROM ci.jobs WHERE run_id = ?")) {
                    ps.setLong(1, 34852867099L);
                    ps.executeQuery().close();
                }
                try (ResultSet rs = count.executeQuery()) {
                    rs.next();
                    System.out.println("after " + i + " execution(s): " + rs.getLong(1) + " prepared statement(s)");
                }
            }
        }
    }

    static void copy() throws Exception {
        try (Connection connection = DriverManager.getConnection(url())) {
            try (Statement statement = connection.createStatement()) {
                statement.execute("""
                        DROP TABLE IF EXISTS ga.package_refs_import;
                        CREATE TABLE ga.package_refs_import (LIKE ga.package_refs INCLUDING ALL);
                        """);
            }
            // COPY ... FROM STDIN: the file is on the client, the server parses the CSV
            try (BufferedReader csv = Files.newBufferedReader(Path.of("../ladybugdb/data/ga/package_refs.csv"))) {
                long rows = connection.unwrap(PGConnection.class).getCopyAPI()
                        .copyIn("COPY ga.package_refs_import FROM STDIN (FORMAT csv, HEADER match)", csv);
                System.out.println("copied: " + rows + " rows");
            }
            try (Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery("""
                         SELECT (SELECT count(*) FROM (TABLE ga.package_refs EXCEPT TABLE ga.package_refs_import) AS d),
                                (SELECT count(*) FROM (TABLE ga.package_refs_import EXCEPT TABLE ga.package_refs) AS d)
                         """)) {
                rs.next();
                System.out.println("rows only in the server-side load: " + rs.getLong(1)
                        + ", only in the client copy: " + rs.getLong(2));
            }
        }
    }

    static void generatedKeys() throws SQLException {
        try (Connection connection = DriverManager.getConnection(url())) {
            try (Statement statement = connection.createStatement()) {
                statement.execute("""
                        DROP TABLE IF EXISTS ci.notes;
                        CREATE TABLE ci.notes (
                            note_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            run_id  bigint NOT NULL REFERENCES ci.runs,
                            body    text NOT NULL,
                            created timestamptz NOT NULL DEFAULT '2026-09-15 00:00:00+00'
                        );
                        """);
            }
            // RETURN_GENERATED_KEYS: the driver appends RETURNING * to the INSERT
            try (PreparedStatement ps = connection.prepareStatement(
                    "INSERT INTO ci.notes (run_id, body) VALUES (?, ?)", Statement.RETURN_GENERATED_KEYS)) {
                ps.setLong(1, 34852867099L);
                ps.setString(2, "first deployment of the day");
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    int columns = keys.getMetaData().getColumnCount();
                    StringBuilder line = new StringBuilder("generated keys:");
                    for (int c = 1; c <= columns; c++) {
                        line.append(' ').append(keys.getMetaData().getColumnName(c)).append('=').append(keys.getString(c));
                    }
                    System.out.println(line);
                }
            }
            // Naming the columns asks for RETURNING note_id only
            try (PreparedStatement ps = connection.prepareStatement(
                    "INSERT INTO ci.notes (run_id, body) VALUES (?, ?)", new String[] {"note_id"})) {
                ps.setLong(1, 34852867099L);
                ps.setString(2, "second note");
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    System.out.println("generated keys: " + keys.getMetaData().getColumnCount() + " column, note_id="
                            + keys.getLong("note_id"));
                }
            }
        }
    }

    static void exerciseBatch() throws Exception {
        try (Connection connection = DriverManager.getConnection(url() + "&reWriteBatchedInserts=true")) {
            try (Statement statement = connection.createStatement()) {
                statement.execute("""
                        DROP TABLE IF EXISTS ga.package_refs_batch;
                        CREATE TABLE ga.package_refs_batch (LIKE ga.package_refs INCLUDING ALL);
                        """);
            }
            List<String> lines = Files.readAllLines(Path.of("../ladybugdb/data/ga/package_refs.csv"));
            List<String> rows = new java.util.ArrayList<>(lines.subList(1, lines.size()));
            rows.add(rows.get(0));
            connection.setAutoCommit(false);
            try (PreparedStatement ps = connection.prepareStatement("INSERT INTO ga.package_refs_batch VALUES (?, ?, ?)")) {
                for (String row : rows) {
                    String[] fields = row.split(",");
                    ps.setString(1, fields[0]);
                    ps.setString(2, fields[1]);
                    ps.setString(3, fields[2]);
                    ps.addBatch();
                }
                ps.executeBatch();
                connection.commit();
            } catch (BatchUpdateException e) {
                connection.rollback();
                SQLException cause = e.getNextException();
                System.out.println(cause.getSQLState() + ": " + ((PSQLException) cause).getServerErrorMessage().getMessage());
            }
            connection.setAutoCommit(true);
            try (Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery("SELECT count(*) FROM ga.package_refs_batch")) {
                rs.next();
                System.out.println("rows in the table: " + rs.getLong(1));
            }
        }
    }

    static void target() {
        // targetServerType: before handing out a connection, the driver checks the server's role, as it would for each
        // host of an Aurora cluster; the local server is a primary
        for (String target : List.of("primary", "preferSecondary", "secondary")) {
            try (Connection connection = DriverManager.getConnection(url() + "&targetServerType=" + target);
                 Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery("SELECT pg_is_in_recovery()")) {
                rs.next();
                System.out.println(target + ": connected, pg_is_in_recovery() = " + rs.getBoolean(1));
            } catch (SQLException e) {
                System.out.println(target + ": " + e.getSQLState() + ": " + e.getMessage());
            }
        }
    }
}
