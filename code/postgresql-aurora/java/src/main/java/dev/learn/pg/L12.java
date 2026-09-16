package dev.learn.pg;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Lesson 12: a failover seen from the JDBC driver. ops/12-cluster.sh starts node1, a primary on port 5433, and node2,
 * its standby on port 5434; the URL lists both hosts, as an application would list an Aurora cluster's instances.
 */
final class L12 {
    private L12() {
    }

    private static final String CLUSTER =
            "jdbc:postgresql://localhost:5433,localhost:5434/learn?user=postgres&password=learn&ApplicationName=learn-java";

    private static String write(String url) {
        try (Connection connection = DriverManager.getConnection(url);
             Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("INSERT INTO orders DEFAULT VALUES RETURNING written_on")) {
            rs.next();
            return "order written on port " + rs.getInt(1);
        } catch (SQLException e) {
            return e.getSQLState() + ": " + e.getMessage();
        }
    }

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
}
