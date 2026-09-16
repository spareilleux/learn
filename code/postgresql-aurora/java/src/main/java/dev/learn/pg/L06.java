package dev.learn.pg;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/** Lesson 6: transactions from JDBC, two connections A and B whose statements run in a fixed order. */
final class L06 {
    private L06() {
    }

    private static long scalar(Connection connection, String sql) throws SQLException {
        try (Statement statement = connection.createStatement(); ResultSet rs = statement.executeQuery(sql)) {
            rs.next();
            return rs.getLong(1);
        }
    }

    private static int update(Connection connection, String sql) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            return statement.executeUpdate(sql);
        }
    }

    private static final String READ_DEPLOY =
            "SELECT runs FROM ci.workflow_runs WHERE workflow_name = 'Deploy to GitHub Pages'";

    static void lostUpdate() throws SQLException {
        try (Connection a = DriverManager.getConnection(L04.url()); Connection b = DriverManager.getConnection(L04.url())) {
            update(a, "DROP TABLE IF EXISTS ci.workflow_runs");
            update(a, "CREATE TABLE ci.workflow_runs AS SELECT workflow_name, count(*)::int AS runs FROM ci.runs GROUP BY workflow_name");
            // JDBC starts a transaction with setAutoCommit(false); the isolation level applies to the next one
            int[] levels = {Connection.TRANSACTION_READ_COMMITTED, Connection.TRANSACTION_REPEATABLE_READ};
            String[] names = {"READ COMMITTED", "REPEATABLE READ"};
            for (int i = 0; i < levels.length; i++) {
                String name = names[i];
                for (Connection c : new Connection[] {a, b}) {
                    c.setAutoCommit(false);
                    c.setTransactionIsolation(levels[i]);
                }
                long readByA = scalar(a, READ_DEPLOY);
                long readByB = scalar(b, READ_DEPLOY);
                update(a, "UPDATE ci.workflow_runs SET runs = " + (readByA + 1) + " WHERE workflow_name = 'Deploy to GitHub Pages'");
                a.commit();
                try {
                    update(b, "UPDATE ci.workflow_runs SET runs = " + (readByB + 1) + " WHERE workflow_name = 'Deploy to GitHub Pages'");
                    b.commit();
                    System.out.println(name + ": A and B read " + readByA + ", both write " + (readByA + 1) + ", runs = " + scalar(a, READ_DEPLOY));
                } catch (SQLException e) {
                    b.rollback();
                    System.out.println(name + ": A and B read " + readByA + ", B's write gets " + e.getSQLState() + ": " + e.getMessage());
                }
                a.commit();
            }
        }
    }

    /** Exercise 2: retry a serializable transaction that fails with 40001, re-reading the data at each attempt. */
    static void retry() throws SQLException {
        try (Connection a = DriverManager.getConnection(L04.url()); Connection b = DriverManager.getConnection(L04.url())) {
            update(a, "DROP TABLE IF EXISTS ci.runner_images");
            update(a, "CREATE TABLE ci.runner_images (label text PRIMARY KEY, enabled boolean NOT NULL)");
            update(a, "INSERT INTO ci.runner_images VALUES ('macos-latest', true), ('windows-latest', true)");
            for (Connection c : new Connection[] {a, b}) {
                c.setAutoCommit(false);
                c.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            }
            // A's first attempt runs in the middle of B's transaction, so that both see two enabled images
            boolean[] interleave = {true};
            disableUnlessLast(b, "windows-latest", () -> {
                if (interleave[0]) {
                    interleave[0] = false;
                    disableUnlessLast(a, "macos-latest", () -> { });
                }
            });
            try (Statement statement = a.createStatement();
                 ResultSet rs = statement.executeQuery("SELECT string_agg(label, ', ' ORDER BY label) FROM ci.runner_images WHERE enabled")) {
                rs.next();
                System.out.println("enabled now: " + rs.getString(1));
            }
            a.commit();
        }
    }

    interface Step {
        void run() throws SQLException;
    }

    private static void disableUnlessLast(Connection connection, String label, Step beforeCommit) throws SQLException {
        String who = label.startsWith("windows") ? "B" : "A";
        for (int attempt = 1; ; attempt++) {
            try {
                long enabled = scalar(connection, "SELECT count(*) FROM ci.runner_images WHERE enabled");
                if (enabled < 2) {
                    connection.commit();
                    System.out.println(who + " attempt " + attempt + ": " + enabled + " enabled, keeps " + label);
                    return;
                }
                update(connection, "UPDATE ci.runner_images SET enabled = false WHERE label = '" + label + "'");
                beforeCommit.run();
                connection.commit();
                System.out.println(who + " attempt " + attempt + ": " + enabled + " enabled, disables " + label);
                return;
            } catch (SQLException e) {
                connection.rollback();
                if (!"40001".equals(e.getSQLState())) {
                    throw e;
                }
                System.out.println(who + " attempt " + attempt + ": " + e.getSQLState() + ", retrying");
            }
        }
    }
}
