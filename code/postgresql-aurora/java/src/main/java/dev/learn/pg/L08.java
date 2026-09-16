package dev.learn.pg;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;

/** Lesson 8: calling functions and procedures with JDBC's escape syntax, and what escapeSyntaxCallMode changes. */
final class L08 {
    private L08() {
    }

    static void routines() throws SQLException {
        try (Connection connection = DriverManager.getConnection(L04.url()); Statement statement = connection.createStatement()) {
            // One statement per call: the driver doesn't split a statement at the semicolons of BEGIN ATOMIC,
            // and doesn't split a string that contains one either
            statement.execute("DROP PROCEDURE IF EXISTS ci.count_runs");
            statement.execute("DROP FUNCTION IF EXISTS ci.failure_rate");
            statement.execute("""
                    CREATE FUNCTION ci.failure_rate(workflow text) RETURNS numeric
                    LANGUAGE sql STABLE
                    BEGIN ATOMIC
                        SELECT round(avg((conclusion = 'failure')::int), 2) FROM ci.runs WHERE workflow_name = workflow;
                    END
                    """);
            statement.execute("""
                    CREATE PROCEDURE ci.count_runs(workflow text, OUT runs bigint, OUT failures bigint)
                    LANGUAGE sql
                    BEGIN ATOMIC
                        SELECT count(*), count(*) FILTER (WHERE conclusion = 'failure') FROM ci.runs WHERE workflow_name = workflow;
                    END
                    """);

            // {? = call f(?)} runs a function: the driver sends SELECT
            try (CallableStatement call = connection.prepareCall("{? = call ci.failure_rate(?)}")) {
                call.registerOutParameter(1, Types.NUMERIC);
                call.setString(2, "Rust course examples");
                call.execute();
                System.out.println("{? = call ci.failure_rate(?)}: " + call.getBigDecimal(1));
            }

            // {call p(?, ?, ?)} on a procedure: with the default escapeSyntaxCallMode=select, the driver still sends SELECT
            try (CallableStatement call = connection.prepareCall("{call ci.count_runs(?, ?, ?)}")) {
                call.setString(1, "Rust course examples");
                call.registerOutParameter(2, Types.BIGINT);
                call.registerOutParameter(3, Types.BIGINT);
                call.execute();
            } catch (SQLException e) {
                System.out.println("{call ci.count_runs(?, ?, ?)}, escapeSyntaxCallMode=select: " + e.getSQLState() + ": "
                        + e.getMessage().lines().findFirst().orElseThrow());
            }
        }

        try (Connection connection = DriverManager.getConnection(L04.url() + "&escapeSyntaxCallMode=callIfNoReturn");
             CallableStatement call = connection.prepareCall("{call ci.count_runs(?, ?, ?)}")) {
            call.setString(1, "Rust course examples");
            call.registerOutParameter(2, Types.BIGINT);
            call.registerOutParameter(3, Types.BIGINT);
            call.execute();
            System.out.println("{call ci.count_runs(?, ?, ?)}, escapeSyntaxCallMode=callIfNoReturn: runs = " + call.getLong(2)
                    + ", failures = " + call.getLong(3));
        }
    }
}
