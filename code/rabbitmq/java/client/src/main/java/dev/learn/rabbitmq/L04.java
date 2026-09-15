package dev.learn.rabbitmq;

import static dev.learn.rabbitmq.Broker.*;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.MessageProperties;
import java.util.Map;

/** Lesson 4: publisher confirms with the Java client, on the same five messages as the C# example. */
final class L04 {

    private L04() {
    }

    static void confirms() throws Exception {
        try (Connection connection = connect("l04-confirms-java");
             Channel channel = connection.createChannel()) {
            channel.queueDelete("orders.confirmed");
            channel.queueDelete("orders.limited");
            channel.queueDeclare("orders.confirmed", true, false, false, null);
            channel.queueDeclare("orders.limited", true, false, false, Map.of("x-max-length", 1, "x-overflow", "reject-publish"));

            // Puts the channel in confirm mode: from now on the broker acks or nacks every publish, numbered from 1.
            channel.confirmSelect();
            // Runs on the connection's thread when basic.return arrives, before the confirm that follows it.
            channel.addReturnListener(r -> System.out.println("   basic.return " + r.getReplyCode() + " " + r.getReplyText()));

            publish(channel, "orders.confirmed", false, "order 1");
            publish(channel, "no-such-queue", false, "order 2");
            publish(channel, "no-such-queue", true, "order 3");
            publish(channel, "orders.limited", false, "order 4");
            publish(channel, "orders.limited", false, "order 5");
        }
    }

    private static void publish(Channel channel, String routingKey, boolean mandatory, String body) throws Exception {
        long sequence = channel.getNextPublishSeqNo();
        AMQP.BasicProperties persistent = MessageProperties.PERSISTENT_BASIC;
        channel.basicPublish("", routingKey, mandatory, persistent, bytes(body));
        // Blocks until every outstanding publish on the channel is confirmed; false if the broker nacked one.
        boolean acked = channel.waitForConfirms(5_000);
        System.out.println("#" + sequence + " " + body + " to " + routingKey + ": " + (acked ? "confirmed" : "nacked"));
    }
}
