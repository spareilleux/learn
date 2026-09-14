// LadybugDB course, lesson 8: transactions and concurrency from Java, with the com.ladybugdb:lbug package.
// Run from code/ladybugdb: mvn -q -f java/pom.xml exec:java -Dexec.mainClass=graph.Transactions [-Dexec.args=refused-begin]
// Lines starting with "# " depend on the operating system or on timing: check.sh prints them without comparing them.
package graph;

import com.ladybugdb.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

public class Transactions {
    public static void main(String[] args) throws Exception {
        if (args.length > 0 && args[0].equals("refused-begin")) {
            refusedBegin();
            return;
        }
        section("1. Two connections, one write transaction");
        try (var database = new Database(""); var first = new Connection(database); var second = new Connection(database)) {
            execute(first, "CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING)");
            execute(first, "COPY Project FROM (LOAD FROM 'data/ga/projects.csv' (HEADER = true) RETURN path, name)");
            print("first: BEGIN", execute(first, "BEGIN TRANSACTION"));
            print("first: CREATE One", execute(first, "CREATE (:Project {path: 'New/One.csproj', name: 'One'})"));
            print("first sees", execute(first, "MATCH (p:Project) RETURN count(*)"));
            print("second sees", execute(second, "MATCH (p:Project) RETURN count(*)"));
            print("second: CREATE Two", execute(second, "CREATE (:Project {path: 'New/Two.csproj', name: 'Two'})"));
            print("first: COMMIT", execute(first, "COMMIT"));
            print("second: CREATE Two", execute(second, "CREATE (:Project {path: 'New/Two.csproj', name: 'Two'})"));

            section("2. A read-only transaction reads a snapshot");
            print("second: BEGIN READ ONLY", execute(second, "BEGIN TRANSACTION READ ONLY"));
            print("second sees", execute(second, "MATCH (p:Project) RETURN count(*)"));
            print("first: CREATE Three", execute(first, "CREATE (:Project {path: 'New/Three.csproj', name: 'Three'})"));
            print("first sees", execute(first, "MATCH (p:Project) RETURN count(*)"));
            print("second sees", execute(second, "MATCH (p:Project) RETURN count(*)"));
            print("second: COMMIT", execute(second, "COMMIT"));
            print("second sees", execute(second, "MATCH (p:Project) RETURN count(*)"));
            print("second: CREATE Two", execute(second, "CREATE (:Project {path: 'New/Two.csproj', name: 'Two'})"));

            section("3. An error ends the transaction");
            print("first: BEGIN", execute(first, "BEGIN TRANSACTION"));
            print("first: CREATE Four", execute(first, "CREATE (:Project {path: 'New/Four.csproj', name: 'Four'})"));
            print("first: CREATE GA.Core again", execute(first, "CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'GA.Core'})"));
            print("first: CREATE Five", execute(first, "CREATE (:Project {path: 'New/Five.csproj', name: 'Five'})"));
            print("first: ROLLBACK", execute(first, "ROLLBACK"));
            print("new projects", execute(first, "MATCH (p:Project) WHERE p.path STARTS WITH 'New/' RETURN string(list_sort(collect(p.name)))"));

            section("4. Exercise 1: a transaction that stops at the first error");
            print("transaction", transaction(first, List.of(
                    "CREATE (:Project {path: 'New/Six.csproj', name: 'Six'})",
                    "CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'GA.Core'})",
                    "CREATE (:Project {path: 'New/Seven.csproj', name: 'Seven'})")));
            print("transaction", transaction(first, List.of(
                    "CREATE (:Project {path: 'New/Six.csproj', name: 'Six'})",
                    "CREATE (:Project {path: 'New/Seven.csproj', name: 'Seven'})")));
            print("new projects", execute(first, "MATCH (p:Project) WHERE p.path STARTS WITH 'New/' RETURN string(list_sort(collect(p.name)))"));

            section("5. Exercise 2: eight threads that write");
            var failures = new AtomicInteger();
            try (var pool = Executors.newFixedThreadPool(8)) {
                var tasks = new ArrayList<Callable<Integer>>();
                for (int t = 0; t < 8; t++) {
                    final int thread = t;
                    tasks.add(() -> {
                        int retries = 0;
                        try (var own = new Connection(database)) {
                            for (int i = 0; i < 25; i++) {
                                var statement = "CREATE (:Project {path: 'Thread/" + thread + "/" + i + "', name: 'T" + thread + "'})";
                                retries += withRetry(() -> transaction(own, List.of(statement)), failures);
                            }
                        }
                        return retries;
                    });
                }
                int retries = 0;
                for (var future : pool.invokeAll(tasks)) retries += future.get();
                print("# retries", retries);
            }
            print("thread projects", execute(first, "MATCH (p:Project) WHERE p.path STARTS WITH 'Thread/' RETURN count(*)"));
            print("# refused transactions", failures.get());
        }

        section("6. A database file");
        var directory = Path.of("out/java-files");
        if (Files.exists(directory)) {
            try (var files = Files.list(directory)) {
                for (var file : files.toList()) Files.delete(file);
            }
        }
        Files.createDirectories(directory);
        var path = directory.resolve("ga.lbdb").toString();
        try (var database = new Database(path); var connection = new Connection(database)) {
            execute(connection, "CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING)");
            execute(connection, "CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'GA.Core'})");
            print("files", files(directory));
            print("# a second read-write Database, same process", open(path, false));
            print("# a read-only Database, same process", open(path, true));
            print("BEGIN", execute(connection, "BEGIN TRANSACTION"));
            print("CREATE One", execute(connection, "CREATE (:Project {path: 'New/One.csproj', name: 'One'})"));
        }
        print("files after close", files(directory));
        print("reopened", open(path, false));
        try (var database = new Database(path, config(true))) {
            print("a read-only Database, then another one", open(path, true));
            print("# a read-only Database, then a read-write one", open(path, false));
        }
        print("a missing file, read-only", open(directory.resolve("missing.lbdb").toString(), true));
    }

    // A BEGIN refused because another connection writes breaks the connection: the next query throws on Windows
    // and crashes the JVM on Linux and macOS. Run on its own, not compared.
    static void refusedBegin() {
        try (var database = new Database(""); var first = new Connection(database); var second = new Connection(database)) {
            execute(first, "CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING)");
            print("first: BEGIN", execute(first, "BEGIN TRANSACTION"));
            print("second: BEGIN", execute(second, "BEGIN TRANSACTION"));
            print("first: COMMIT", execute(first, "COMMIT"));
            System.out.flush();
            print("second: MATCH", execute(second, "MATCH (p:Project) RETURN count(*)"));
            print("second: BEGIN", execute(second, "BEGIN TRANSACTION"));
            print("second: MATCH", execute(second, "MATCH (p:Project) RETURN count(*)"));
            print("second: COMMIT", execute(second, "COMMIT"));
        }
    }

    static void section(String title) {
        System.out.println("\n== " + title);
    }

    static void print(String label, Object value) {
        System.out.println(label + ": " + value);
    }

    // Runs a statement and returns its first value, "ok", or the error, whether the result reports it or the call throws
    static String execute(Connection connection, String cypher) {
        try (var result = connection.query(cypher)) {
            if (!result.isSuccess()) {
                return "error: " + result.getErrorMessage();
            }
            return result.hasNext() ? String.valueOf((Object) result.getNext().getValue(0).getValue()) : "ok";
        } catch (RuntimeException e) {
            return "thrown " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    // Exercise 1: all the statements or none. A failure stops before the next statement, which would run in auto-commit
    static String transaction(Connection connection, List<String> statements) {
        var begin = execute(connection, "BEGIN TRANSACTION");
        if (!begin.equals("ok")) {
            return begin;
        }
        for (var statement : statements) {
            var outcome = execute(connection, statement);
            if (outcome.startsWith("error") || outcome.startsWith("thrown")) {
                // The engine has already rolled back; ROLLBACK is for the errors that leave the transaction open
                execute(connection, "ROLLBACK");
                return outcome;
            }
        }
        return execute(connection, "COMMIT");
    }

    // Exercise 2: retry a transaction the engine refuses because another one is writing
    static int withRetry(Callable<String> transaction, AtomicInteger failures) throws Exception {
        for (int retries = 0; ; retries++) {
            var outcome = transaction.call();
            if (!outcome.contains("Only one write transaction at a time")) {
                if (!outcome.equals("ok")) {
                    throw new IllegalStateException(outcome);
                }
                return retries;
            }
            failures.incrementAndGet();
            Thread.sleep(1 + ThreadLocalRandom.current().nextInt(5));
        }
    }

    static SystemConfig config(boolean readOnly) {
        var config = new SystemConfig();
        config.readOnly = readOnly;
        return config;
    }

    // Opens a Database and lists the projects; the constructor throws java.lang.Exception, a checked exception it doesn't declare
    static String open(String path, boolean readOnly) {
        try (var database = new Database(path, config(readOnly)); var connection = new Connection(database)) {
            return execute(connection, "MATCH (p:Project) RETURN string(list_sort(collect(p.name)))");
        } catch (Exception e) {
            return e.getClass().getName() + ": " + e.getMessage().replace(Path.of(path).toAbsolutePath().toString(), path).lines().findFirst().orElse("");
        }
    }

    static String files(Path directory) throws Exception {
        try (var files = Files.list(directory)) {
            return files.map(file -> file.getFileName().toString()).sorted().toList().toString();
        }
    }
}
