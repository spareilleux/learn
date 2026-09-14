// LadybugDB course, lesson 6: the project graph of GuitarAlchemist/ga from Java, with the com.ladybugdb:lbug package.
// Run from code/ladybugdb: mvn -q -f java/pom.xml exec:java -Dexec.args="check | timings | create <file> | open <file> | temp"
package graph;

import com.ladybugdb.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Function;
import java.util.regex.Pattern;

public class ProjectGraph {
    record Project(String name, String path, String language) {}

    static Connection connection;

    public static void main(String[] args) throws Exception {
        var mode = args.length > 0 ? args[0] : "check";
        switch (mode) {
            case "create" -> { createFile(args[1]); return; }
            case "open" -> { openFile(args[1]); return; }
            case "temp" -> { temp(); return; }
            default -> {}
        }

        section("1. Open a database");
        System.out.println("LadybugDB " + Version.getVersion() + ", storage version " + Version.getStorageVersion());
        // An empty path: an in-memory database, like the CLI started without a file name
        try (var database = new Database(""); var conn = new Connection(database)) {
            connection = conn;

            section("2. Create and load");
            run("CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING, language STRING, sdk STRING, frameworks STRING, in_solution BOOLEAN)");
            run("CREATE NODE TABLE Package(name STRING PRIMARY KEY)");
            run("CREATE REL TABLE REFERENCES(FROM Project TO Project)");
            run("CREATE REL TABLE USES(FROM Project TO Package, version STRING)");
            run("COPY Project FROM 'data/ga/projects.csv' (HEADER = true)");
            // A failed query doesn't throw: the result says it failed
            try (var result = connection.query("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true)")) {
                System.out.println("isSuccess: " + result.isSuccess() + ", " + result.getErrorMessage());
            }
            run("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true, IGNORE_ERRORS = true)");
            run("COPY Package FROM (LOAD FROM 'data/ga/package_refs.csv' (HEADER = true) RETURN DISTINCT package)");
            run("COPY USES FROM 'data/ga/package_refs.csv' (HEADER = true)");

            section("3. Read rows");
            try (var result = connection.query("""
                    MATCH (p:Project)-[:REFERENCES]->(core:Project)
                    RETURN core.name, count(*) AS referenced_by
                    ORDER BY referenced_by DESC, core.name
                    LIMIT 3
                    """)) {
                System.out.println(result.getColumnName(0) + " " + result.getColumnDataType(0).getID() + ", "
                        + result.getColumnName(1) + " " + result.getColumnDataType(1).getID() + ": " + result.getNumTuples() + " rows");
                var kept = new ArrayList<FlatTuple>();
                while (result.hasNext()) {
                    FlatTuple row = result.getNext();
                    Object count = row.getValue(1).getValue();
                    System.out.printf("%-20s %2s (%s)%n", row.getValue(0).getValue(), count, count.getClass().getName());
                    kept.add(row);
                }
                // The tuples returned by getNext() share one buffer: the kept ones all hold the last row
                System.out.println("kept rows: " + kept.stream().map(row -> (String) row.getValue(0).getValue()).toList());
                result.resetIterator();
                System.out.println("after resetIterator: " + result.getNext().getValue(0).getValue());
            }

            section("4. Parameters");
            try (var statement = connection.prepare("""
                    MATCH (p:Project {name: $name})-[:REFERENCES*1..10]->(d:Project)
                    RETURN count(DISTINCT d) AS dependencies
                    """)) {
                for (var name : List.of("GaApi", "GaCli", "GaMcpServer", "GA.Domain.Core")) {
                    try (var result = connection.execute(statement, Map.of("name", name))) {
                        System.out.println(name + " depends on " + result.getNext().getValue(0).getValue() + " projects");
                    }
                }
            }
            try (var statement = connection.prepare(
                    "MATCH (p:Project) WHERE COUNT { MATCH (p)-[:REFERENCES]->(:Project) } > $n RETURN count(*)")) {
                for (Object value : List.of(2, "2", new BigDecimal("2.5"), 2.5)) {
                    try (var result = connection.execute(statement, Map.of("n", value))) {
                        System.out.println(value.getClass().getSimpleName() + " " + value + ": " + result.getNext().getValue(0).getValue() + " projects");
                    }
                }
                // A misspelt name is ignored, and the statement keeps the value of its previous execution
                try (var result = connection.execute(statement, Map.of("nom", 5))) {
                    System.out.println("{nom=5} after {n=2.5}: " + result.getNext().getValue(0).getValue() + " projects");
                }
                var withNull = new HashMap<String, Object>();
                withNull.put("n", null);
                attempt(() -> connection.execute(statement, withNull));
            }
            try (var statement = connection.prepare(
                    "MATCH (p:Project) WHERE COUNT { MATCH (p)-[:REFERENCES]->(:Project) } > $n RETURN count(*)");
                 var result = connection.execute(statement, Map.of("nom", 5))) {
                System.out.println("{nom=5}, new statement: " + result.getErrorMessage());
            }
            try (var statement = connection.prepare("COPY Package FROM $file (HEADER = true)")) {
                System.out.println("prepare COPY FROM $file: " + statement.isSuccess() + ", " + statement.getErrorMessage());
            }
            attempt(() -> connection.execute(connection.prepare("RETURN $t"), Map.of("t", LocalDateTime.of(2026, 9, 14, 9, 30))));

            section("5. Nodes, relationships and paths");
            try (var result = connection.query("""
                    MATCH path = (app:Project {name: 'GaApi'})-[:REFERENCES* ALL SHORTEST 1..10]->(assets:Project {name: 'GA.Business.Assets'})
                    RETURN app, path
                    """)) {
                var paths = new ArrayList<String>();
                InternalID appId = null;
                InternalID firstSource = null;
                while (result.hasNext()) {
                    var row = result.getNext();
                    Value app = row.getValue(0);
                    appId = ValueNodeUtil.getID(app);
                    if (paths.isEmpty()) {
                        System.out.println(ValueNodeUtil.getLabelName(app) + " (" + appId.getClass().getSimpleName() + "): " + properties(app));
                    }
                    Value path = row.getValue(1);
                    var nodes = new LbugList(ValueRecursiveRelUtil.getNodeList(path)).toArray();
                    var rels = new LbugList(ValueRecursiveRelUtil.getRelList(path)).toArray();
                    paths.add(rels.length + " relationships: " + String.join(" -> ",
                            Arrays.stream(nodes).map(node -> (String) properties(node).get("name")).toList()));
                    if (firstSource == null) {
                        firstSource = ValueRelUtil.getSrcID(rels[0]);
                        System.out.println("first relationship: " + ValueRelUtil.getLabelName(rels[0]) + ", starts at GaApi: " + firstSource.equals(appId));
                    }
                }
                // Several shortest paths, in no particular order: sort them before printing
                paths.stream().sorted().forEach(System.out::println);
            }

            section("6. Lists, structs and maps");
            try (var result = connection.query("""
                    MATCH (p:Project)-[u:USES]->(k:Package)
                    WITH k, count(*) AS projects, collect(DISTINCT u.version) AS versions
                    WHERE size(versions) > 1
                    RETURN k.name, versions, {projects: projects, versions: size(versions)} AS usage, map(['projects'], [projects]) AS counts
                    ORDER BY size(versions) DESC, k.name
                    LIMIT 3
                    """)) {
                while (result.hasNext()) {
                    var row = result.getNext();
                    var versions = Arrays.stream(new LbugList(row.getValue(1)).toArray()).map(v -> (String) v.getValue()).sorted().toList();
                    var usage = new LbugStruct(row.getValue(2));
                    System.out.println(row.getValue(0).getValue() + ": " + String.join(", ", versions)
                            + " (" + usage.getValueByFieldName("projects").getValue() + " projects)");
                }
                result.resetIterator();
                var row = result.getNext();
                attempt(() -> row.getValue(1).getValue());
                attempt(() -> row.getValue(3).getValue());
                var counts = new LbugMap(row.getValue(3));
                System.out.println("LbugMap: " + counts.getKey(0).getValue() + " = " + counts.getValue(0).getValue());
            }
            // The bug of lessons 4 and 5, in 0.20.4: an aggregate after a DISTINCT one in the same projection is wrong
            try (var result = connection.query("""
                    MATCH (p:Project)-[u:USES]->(k:Package {name: 'MongoDB.Driver'})
                    RETURN k.name, collect(DISTINCT u.version) AS versions, count(*) AS projects
                    """)) {
                var row = result.getNext();
                System.out.println("DISTINCT first: " + row.getValue(0).getValue() + ", " + new LbugList(row.getValue(1)).getListSize()
                        + " versions, " + row.getValue(2).getValue() + " projects");
            }

            section("7. Rows as records");
            query("MATCH (p:Project) WHERE NOT p.in_solution RETURN p.name, p.path, p.language ORDER BY p.path LIMIT 3",
                    row -> new Project((String) row.get(0), (String) row.get(1), (String) row.get(2)))
                    .forEach(System.out::println);
            System.out.println(query("MATCH (p:Project) WHERE NOT p.in_solution RETURN count(*)", row -> (long) row.get(0)).getFirst()
                    + " projects are not in AllProjects.slnx");

            section("8. Dates and times");
            try (var statement = connection.prepare("""
                    RETURN $instant AS instant, timestamp('2026-09-14T09:30:00-04:00') AS literal,
                           CAST('2026-09-14T09:30:00-04:00' AS TIMESTAMP_TZ) AS tz, date('2026-09-14') AS day,
                           $duration AS duration, interval('1 month 2 days') AS month
                    """);
                 var result = connection.execute(statement, Map.of(
                         "instant", OffsetDateTime.of(2026, 9, 14, 9, 30, 0, 0, ZoneOffset.ofHours(-4)).toInstant(),
                         "duration", Duration.ofMinutes(90)))) {
                var row = result.getNext();
                for (int i = 0; i < result.getNumColumns(); i++) {
                    Object value = row.getValue(i).getValue();
                    System.out.printf("%-9s %-12s %s %s%n", result.getColumnName(i), result.getColumnDataType(i).getID(),
                            value.getClass().getSimpleName(), value);
                }
            }

            section("9. Errors, several statements, timeouts");
            for (var cypher : List.of("MATCH (p:Projet) RETURN p", "MATCH (p:Project) RETURN p.nam",
                    "CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'GA.Core'})")) {
                try (var result = connection.query(cypher)) {
                    System.out.println(result.getErrorMessage());
                    attempt(result::getNext);
                }
            }
            try (var result = connection.query("MATCH (p:Project) RETURN count(*) AS projects; MATCH (k:Package) RETURN count(*) AS packages")) {
                System.out.println(result.getColumnName(0) + " = " + result.getNext().getValue(0).getValue());
                if (result.hasNextQueryResult()) {
                    try (var next = result.getNextQueryResult()) {
                        System.out.println(next.getColumnName(0) + " = " + next.getNext().getValue(0).getValue());
                    }
                }
            }
            connection.setQueryTimeout(1);
            try (var result = connection.query("MATCH (a:Project)-[:REFERENCES*1..30]->(b:Project) RETURN count(*)")) {
                System.out.println("timeout of 1 ms: " + result.getErrorMessage());
            }
            connection.setQueryTimeout(0);
            try (var result = connection.query("MATCH (a:Project)-[:REFERENCES*1..10]->(b:Project) RETURN count(*)")) {
                System.out.println("no timeout: " + result.getNext().getValue(0).getValue() + " walks");
            }

            section("Exercise 1. Rows that outlive the iterator");
            var rows = rows("MATCH (p:Project) RETURN p.name, p.language ORDER BY p.path LIMIT 3");
            System.out.println(rows);

            section("Exercise 2. Parameters checked");
            try (var dependents = new Statement("MATCH (d:Project)-[:REFERENCES*1..10]->(:Project {name: $name}) RETURN count(DISTINCT d)")) {
                System.out.println("parameters: " + dependents.names);
                System.out.println("GA.Core: " + dependents.execute(Map.of("name", "GA.Core")).getFirst().getFirst() + " dependents");
                attempt(() -> dependents.execute(Map.of("nom", "GA.Core")));
                attempt(() -> dependents.execute(Map.of()));
            }

            section("Exercise 3. Conflicts in every package");
            // The packages that the PackageReference Update items of ga's Directory.Build.props set to one version
            var aligned = List.of("Microsoft.Build.Tasks.Core", "Microsoft.Extensions.Caching.Abstractions", "Microsoft.Extensions.Caching.Memory",
                    "Microsoft.Extensions.DependencyInjection.Abstractions", "Microsoft.Extensions.Http", "Microsoft.Extensions.Options",
                    "Microsoft.ML.OnnxRuntime", "Microsoft.SemanticKernel", "Microsoft.SemanticKernel.Abstractions", "Microsoft.SemanticKernel.Core",
                    "Newtonsoft.Json", "System.Drawing.Common", "System.Numerics.Tensors", "System.Security.Cryptography.Xml");
            try (var statement = new Statement("""
                    MATCH (a:Project)-[ua:USES]->(k:Package), (a)-[:REFERENCES*1..10]->(b:Project)-[ub:USES]->(k)
                    WHERE split_part(ua.version, '.', 1) <> split_part(ub.version, '.', 1) AND NOT list_contains($aligned, k.name)
                    WITH DISTINCT k.name AS package, a.path AS project
                    RETURN package, count(*) AS projects
                    ORDER BY projects DESC, package
                    """);
                 var list = new LbugList(aligned.stream().map(Value::new).toArray(Value[]::new))) {
                statement.execute(Map.of("aligned", list.getValue())).forEach(row -> System.out.println(row.get(0) + ": " + row.get(1) + " projects"));
            }

            if (mode.equals("timings")) {
                section("Timings (not compared)");
                final String walks = "MATCH (a:Project)-[:REFERENCES*1..10]->(b:Project) RETURN count(*)";
                long start = System.nanoTime();
                try (var result = connection.query(walks)) {
                    System.out.println(result.getNext().getValue(0).getValue() + " walks, one query: " + (System.nanoTime() - start) / 1_000_000 + " ms, "
                            + "compiling " + result.getQuerySummary().getCompilingTime() + " ms, executing " + result.getQuerySummary().getExecutionTime() + " ms");
                }
                try (var pool = Executors.newFixedThreadPool(4)) {
                    start = System.nanoTime();
                    var futures = new ArrayList<Future<?>>();
                    for (int i = 0; i < 4; i++) {
                        futures.add(pool.submit(() -> { try (var result = connection.query(walks)) { result.getNext(); } }));
                    }
                    for (var future : futures) future.get();
                    System.out.println("4 queries on one connection, 4 threads: " + (System.nanoTime() - start) / 1_000_000 + " ms");
                    start = System.nanoTime();
                    futures.clear();
                    for (int i = 0; i < 4; i++) {
                        futures.add(pool.submit(() -> { try (var own = new Connection(database); var result = own.query(walks)) { result.getNext(); } }));
                    }
                    for (var future : futures) future.get();
                    System.out.println("4 queries on 4 connections, 4 threads: " + (System.nanoTime() - start) / 1_000_000 + " ms");
                }
            }
        }
    }

    static void section(String title) {
        System.out.println("\n== " + title);
    }

    // Runs a statement, prints the first column of its rows, and throws when it fails
    static void run(String cypher) {
        try (var result = connection.query(cypher)) {
            if (!result.isSuccess()) {
                throw new IllegalStateException(result.getErrorMessage());
            }
            while (result.hasNext()) {
                System.out.println((Object) result.getNext().getValue(0).getValue());
            }
        }
    }

    // Converts a value to a Java object: lists, structs and maps included, which Value.getValue() doesn't support
    static Object toJava(Value value) {
        if (value.isNull()) {
            return null;
        }
        return switch (value.getDataType().getID()) {
            case LIST, ARRAY -> Arrays.stream(new LbugList(value).toArray()).map(ProjectGraph::toJava).toList();
            case STRUCT -> {
                var struct = new LbugStruct(value);
                var fields = new LinkedHashMap<String, Object>();
                for (long i = 0; i < struct.getNumFields(); i++) {
                    fields.put(struct.getFieldNameByIndex(i), toJava(struct.getValueByIndex(i)));
                }
                yield fields;
            }
            case MAP -> {
                var map = new LbugMap(value);
                var entries = new LinkedHashMap<Object, Object>();
                for (long i = 0; i < map.getNumFields(); i++) {
                    entries.put(toJava(map.getKey(i)), toJava(map.getValue(i)));
                }
                yield entries;
            }
            default -> value.getValue();
        };
    }

    static Map<String, Object> properties(Value node) {
        var properties = new LinkedHashMap<String, Object>();
        for (long i = 0; i < ValueNodeUtil.getPropertySize(node); i++) {
            properties.put(ValueNodeUtil.getPropertyNameAt(node, i), toJava(ValueNodeUtil.getPropertyValueAt(node, i)));
        }
        return properties;
    }

    static <T> List<T> query(String cypher, Function<List<Object>, T> map) {
        return rows(cypher).stream().map(map).toList();
    }

    // Exercise 1: copy every row while its tuple is current
    static List<List<Object>> rows(String cypher) {
        try (var result = connection.query(cypher)) {
            if (!result.isSuccess()) {
                throw new IllegalStateException(result.getErrorMessage());
            }
            var rows = new ArrayList<List<Object>>();
            while (result.hasNext()) {
                var tuple = result.getNext();
                var row = new ArrayList<Object>();
                for (long i = 0; i < result.getNumColumns(); i++) {
                    row.add(toJava(tuple.getValue(i)));
                }
                rows.add(row);
            }
            return rows;
        }
    }

    // Exercise 2: a prepared statement that checks its parameters on every execution
    static final class Statement implements AutoCloseable {
        private static final Pattern PARAMETER = Pattern.compile("\\$(\\w+)");
        final Set<String> names = new TreeSet<>();
        private final PreparedStatement prepared;

        Statement(String cypher) {
            PARAMETER.matcher(cypher).results().forEach(match -> names.add(match.group(1)));
            prepared = connection.prepare(cypher);
            if (!prepared.isSuccess()) {
                throw new IllegalStateException(prepared.getErrorMessage());
            }
        }

        List<List<Object>> execute(Map<String, ?> parameters) {
            if (!parameters.keySet().equals(names)) {
                throw new IllegalArgumentException("expected parameters " + names + ", got " + new TreeSet<>(parameters.keySet()));
            }
            try (var result = connection.execute(prepared, parameters)) {
                if (!result.isSuccess()) {
                    throw new IllegalStateException(result.getErrorMessage());
                }
                var rows = new ArrayList<List<Object>>();
                while (result.hasNext()) {
                    var tuple = result.getNext();
                    var row = new ArrayList<Object>();
                    for (long i = 0; i < result.getNumColumns(); i++) {
                        row.add(toJava(tuple.getValue(i)));
                    }
                    rows.add(row);
                }
                return rows;
            }
        }

        @Override
        public void close() {
            prepared.close();
        }
    }

    interface Attempt {
        Object run() throws Exception;
    }

    static void attempt(Attempt action) {
        try {
            action.run();
        } catch (Exception e) {
            System.out.println(e.getClass().getSimpleName() + ": " + e.getMessage());
        }
    }

    static void createFile(String path) {
        try (var database = new Database(path); var conn = new Connection(database)) {
            connection = conn;
            run("CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING)");
            run("CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'GA.Core'})");
            System.out.println("created " + path + " with LadybugDB " + Version.getVersion());
        }
    }

    static void openFile(String path) {
        try (var database = new Database(path); var conn = new Connection(database); var result = conn.query("MATCH (p:Project) RETURN p.name")) {
            System.out.println("opened " + path + ": " + result.getNext().getValue(0).getValue());
        } catch (RuntimeException e) {
            System.out.println(e.getClass().getSimpleName() + ": " + e.getMessage());
        }
    }

    // The native library is copied to the temporary directory each time the package loads
    static void temp() throws IOException {
        var directory = Path.of(System.getProperty("java.io.tmpdir"));
        try (var files = Files.list(directory)) {
            var copies = files.filter(file -> file.getFileName().toString().startsWith("liblbug_java_native")).toList();
            long bytes = 0;
            for (var file : copies) bytes += Files.size(file);
            System.out.println(copies.size() + " copies of the native library in the temporary directory, " + bytes / 1_000_000 + " MB");
        }
    }
}
