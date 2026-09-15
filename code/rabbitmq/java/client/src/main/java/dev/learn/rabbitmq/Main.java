package dev.learn.rabbitmq;

import java.util.LinkedHashMap;
import java.util.Map;

/** Runs one example of the course: java -jar target/rabbitmq-client.jar &lt;name&gt;. RABBITMQ_HOST names the broker. */
public final class Main {

    @FunctionalInterface
    interface Example {
        void run() throws Exception;
    }

    public static void main(String[] args) throws Exception {
        Map<String, Example> examples = new LinkedHashMap<>();
        examples.put("l01-send", L01::send);
        examples.put("l01-receive", L01::receive);
        examples.put("l02-topic", L02::topic);
        examples.put("l03-publish", L03::publish);
        examples.put("l03-consume", L03::consume);
        examples.put("l04-confirms", L04::confirms);

        Example example = args.length == 1 ? examples.get(args[0]) : null;
        if (example == null) {
            System.err.println("usage: rabbitmq-client <" + String.join("|", examples.keySet()) + ">");
            System.exit(2);
        }
        example.run();
    }
}
