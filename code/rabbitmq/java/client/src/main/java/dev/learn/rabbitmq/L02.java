package dev.learn.rabbitmq;

import static dev.learn.rabbitmq.Broker.*;

import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;

/** Lesson 2: the topic example of the C# program, with the Java client. Its output is compared with the same file. */
final class L02 {

    private L02() {
    }

    static void topic() throws Exception {
        String[][] bindings = {
            {"orders.all", "order.#"},
            {"created.anywhere", "*.created.*"},
            {"europe", "#.eu"},
            {"orders.two-words", "order.*"},
        };
        try (Connection connection = connect("l02-topic-java");
             Channel channel = connection.createChannel()) {
            channel.exchangeDelete("events.topic");
            for (String[] binding : bindings) {
                channel.queueDelete(binding[0]);
            }

            channel.exchangeDeclare("events.topic", BuiltinExchangeType.TOPIC, true);
            for (String[] binding : bindings) {
                channel.queueDeclare(binding[0], true, false, false, null);
                channel.queueBind(binding[0], "events.topic", binding[1]);
                System.out.println("bind " + binding[0] + " to " + binding[1]);
            }

            for (String key : new String[] {"order.created.eu", "order.shipped.us", "invoice.created.eu", "order", "order.cancelled", "eu"}) {
                channel.basicPublish("events.topic", key, null, bytes(key));
            }

            for (String[] binding : bindings) {
                printQueue(channel, binding[0]);
            }
        }
    }
}
