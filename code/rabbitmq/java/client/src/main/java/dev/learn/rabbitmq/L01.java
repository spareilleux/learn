package dev.learn.rabbitmq;

import static dev.learn.rabbitmq.Broker.*;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import java.util.concurrent.CountDownLatch;

/** Lesson 1: the same producer and consumer as the C# ones, printing the same lines. */
final class L01 {

    private L01() {
    }

    static void send() throws Exception {
        try (Connection connection = connect("l01-send-java");
             Channel channel = connection.createChannel()) {
            var server = connection.getServerProperties();
            System.out.println("connected to " + server.get("product") + " " + server.get("version"));

            AMQP.Queue.DeclareOk queue = channel.queueDeclare("hello", true, false, false, null);
            System.out.println("queue " + queue.getQueue() + ": " + queue.getMessageCount() + " message(s) waiting");

            for (int i = 1; i <= 3; i++) {
                // exchange "", routing key = queue name, no properties
                channel.basicPublish("", "hello", null, bytes("Hello " + i));
                System.out.println("sent Hello " + i);
            }
        }
    }

    static void receive() throws Exception {
        try (Connection connection = connect("l01-receive-java");
             Channel channel = connection.createChannel()) {
            AMQP.Queue.DeclareOk queue = channel.queueDeclare("hello", true, false, false, null);
            System.out.println("queue " + queue.getQueue() + ": " + queue.getMessageCount() + " message(s) waiting");

            CountDownLatch waiting = new CountDownLatch(queue.getMessageCount());
            // The callback runs on the client's consumer thread pool, one message at a time per channel.
            channel.basicConsume("hello", true,
                    (consumerTag, delivery) -> {
                        System.out.println("received " + text(delivery.getBody()));
                        waiting.countDown();
                    },
                    consumerTag -> { });
            await(waiting, "the waiting messages");
        }
    }
}
