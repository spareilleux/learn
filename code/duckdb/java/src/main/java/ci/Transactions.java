// DuckDB course, lesson 8: two connections, two transactions, and the conflicts between them
// Run from code/duckdb: mvn -q -f java/pom.xml compile exec:java -Dexec.mainClass=ci.Transactions
package ci;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class Transactions {
    public static void main(String[] args) throws SQLException, IOException {
        Files.createDirectories(Path.of("out"));
        Files.deleteIfExists(Path.of("out/transactions.duckdb"));
        Files.deleteIfExists(Path.of("out/transactions.duckdb.wal"));

        // Two connections to the same file in the same process share one database
        try (Connection a = DriverManager.getConnection("jdbc:duckdb:out/transactions.duckdb");
             Connection b = DriverManager.getConnection("jdbc:duckdb:out/transactions.duckdb")) {
            execute(a, "a", "CREATE TABLE counters (name VARCHAR PRIMARY KEY, n INTEGER)");
            execute(a, "a", "INSERT INTO counters VALUES ('builds', 0)");
            a.setAutoCommit(false);
            b.setAutoCommit(false);

            section("1. Isolation: b doesn't see what a hasn't committed");
            execute(a, "a", "UPDATE counters SET n = n + 1 WHERE name = 'builds'");
            execute(b, "b", "SELECT n FROM counters WHERE name = 'builds'");

            section("2. Two updates of the same row");
            execute(b, "b", "UPDATE counters SET n = n + 1 WHERE name = 'builds'");
            execute(b, "b", "SELECT n FROM counters WHERE name = 'builds'");
            commit(a, "a");
            commit(b, "b");
            execute(a, "a", "SELECT n FROM counters WHERE name = 'builds'");
            commit(a, "a");

            section("3. Two inserts with different keys");
            execute(a, "a", "INSERT INTO counters VALUES ('deploys', 1)");
            execute(b, "b", "INSERT INTO counters VALUES ('tests', 1)");
            commit(a, "a");
            commit(b, "b");

            section("4. Two inserts with the same key");
            execute(a, "a", "INSERT INTO counters VALUES ('lint', 1)");
            execute(b, "b", "INSERT INTO counters VALUES ('lint', 2)");
            commit(a, "a");
            commit(b, "b");

            section("5. What was committed");
            execute(a, "a", "SELECT string_agg(name || '=' || n, ', ' ORDER BY name) FROM counters");
            commit(a, "a");
        }
    }

    // Runs one statement and prints its first value, "ok" or the first two lines of the error
    static void execute(Connection connection, String name, String sql) {
        try (var statement = connection.createStatement()) {
            String result = "ok";
            if (statement.execute(sql)) {
                try (var rs = statement.getResultSet()) {
                    rs.next();
                    result = String.valueOf(rs.getObject(1));
                }
            }
            System.out.println(name + ": " + sql + " -> " + result);
        } catch (SQLException e) {
            System.out.println(name + ": " + sql + " -> " + e.getMessage().replace("\n", " | "));
        }
    }

    static void commit(Connection connection, String name) {
        try {
            connection.commit();
            System.out.println(name + ": commit -> ok");
        } catch (SQLException e) {
            System.out.println(name + ": commit -> " + e.getMessage().replace("\n", " | "));
        }
    }

    static void section(String title) {
        System.out.println();
        System.out.println("== " + title);
    }
}
