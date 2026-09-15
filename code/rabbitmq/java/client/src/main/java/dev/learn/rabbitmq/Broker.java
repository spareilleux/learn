package dev.learn.rabbitmq;

import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.GetResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/** What every example needs: a connection to the course broker, and text in and out of message bodies. */
final class Broker {

    private Broker() {
    }

    static final String HOST = System.getenv().getOrDefault("RABBITMQ_HOST", "localhost");

    // One connection per application, opened once and kept. The name shows up in the management UI.
    static Connection connect(String name) throws IOException, TimeoutException {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost(HOST);
        return factory.newConnection(name);
    }

    static byte[] bytes(String text) {
        return text.getBytes(StandardCharsets.UTF_8);
    }

    static String text(byte[] body) {
        return new String(body, StandardCharsets.UTF_8);
    }

    // Empties a queue with basic.get and prints the bodies it held, in queue order.
    static void printQueue(Channel channel, String queue) throws IOException {
        List<String> lines = new ArrayList<>();
        GetResponse message;
        while ((message = channel.basicGet(queue, true)) != null) {
            lines.add(text(message.getBody()));
        }
        System.out.println(queue + ": " + (lines.isEmpty() ? "(empty)" : String.join(" | ", lines)));
    }

    // Waits for a consumer callback, and fails the example instead of hanging.
    static void await(CountDownLatch latch, String what) throws InterruptedException {
        if (!latch.await(10, TimeUnit.SECONDS)) {
            throw new IllegalStateException("timed out waiting for " + what);
        }
    }
}
