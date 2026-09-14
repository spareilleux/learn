package lessons.l05;

/** Lesson 5: try-with-resources, closing order and suppressed exceptions. */
public class Resources {

    record Connection(String name, boolean failOnClose) implements AutoCloseable {
        Connection {
            System.out.println("open " + name);
        }

        @Override
        public void close() {
            System.out.println("close " + name);
            if (failOnClose) {
                throw new IllegalStateException("close failed: " + name);
            }
        }
    }

    public static void main(String[] args) {
        // Resources close in reverse order, before any catch or finally block runs.
        try (var db = new Connection("db", false);
                var cache = new Connection("cache", false)) {
            System.out.println("using " + db.name() + " and " + cache.name());
        } finally {
            System.out.println("finally");
        }

        // The body fails, then close fails too: the body's exception wins,
        // and the close exception is attached to it instead of replacing it.
        try (var db = new Connection("db", true)) {
            throw new IllegalArgumentException("query failed on " + db.name());
        } catch (IllegalArgumentException e) {
            System.out.println("caught: " + e.getMessage());
            for (Throwable suppressed : e.getSuppressed()) {
                System.out.println("suppressed: " + suppressed.getMessage());
            }
        }
    }
}
