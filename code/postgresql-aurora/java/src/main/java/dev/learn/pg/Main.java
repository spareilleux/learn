package dev.learn.pg;

import java.util.LinkedHashMap;
import java.util.Map;

/** Runs one example of the course: java -jar java/target/pg.jar name. PG_JDBC_URL overrides the connection URL. */
public final class Main {
    @FunctionalInterface
    interface Example {
        void run() throws Exception;
    }

    public static void main(String[] args) throws Exception {
        Map<String, Example> examples = new LinkedHashMap<>();
        examples.put("l04-connect", L04::connect);
        examples.put("l04-parameters", L04::parameters);
        examples.put("l04-pool", L04::pool);
        examples.put("l04-prepare", L04::prepare);
        examples.put("l04-copy", L04::copy);
        examples.put("l04-generated-keys", L04::generatedKeys);
        examples.put("l04-exercise-batch", L04::exerciseBatch);
        examples.put("l04-target", L04::target);
        examples.put("l06-lost-update", L06::lostUpdate);
        examples.put("l06-retry", L06::retry);
        examples.put("l08-routines", L08::routines);
        examples.put("l12-failover", L12::failover);
        Example example = args.length == 1 ? examples.get(args[0]) : null;
        if (example == null) {
            System.err.println("usage: pg <" + String.join("|", examples.keySet()) + ">");
            System.exit(2);
        }
        example.run();
    }
}
