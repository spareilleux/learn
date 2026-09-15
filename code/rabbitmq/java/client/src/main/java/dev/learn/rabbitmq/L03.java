package dev.learn.rabbitmq;

import static dev.learn.rabbitmq.Broker.*;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.CountDownLatch;
import java.util.stream.Collectors;
import tools.jackson.databind.json.JsonMapper;

/** Lesson 3: the order producer and consumer with the Java client, reading and writing the C# program's messages. */
final class L03 {

    private L03() {
    }

    record Order(String id, String sku, int quantity) {
    }

    private static final JsonMapper JSON = JsonMapper.builder().build();

    static void declare(Channel channel) throws Exception {
        channel.exchangeDeclare("orders.topic", BuiltinExchangeType.TOPIC, true);
        channel.queueDeclare("orders.billing", true, false, false, null);
        channel.queueBind("orders.billing", "orders.topic", "order.#");
    }

    static void publish() throws Exception {
        try (Connection connection = connect("l03-java-publisher");
             Channel channel = connection.createChannel()) {
            declare(channel);
            Order[] orders = {new Order("B-1", "TUNER", 1), new Order("B-2", "STRAP", 2)};
            for (Order order : orders) {
                // The properties the C# publisher sets with BasicProperties, through a builder.
                AMQP.BasicProperties properties = new AMQP.BasicProperties.Builder()
                        .contentType("application/json")
                        .messageId(order.id())
                        .type("order.created")
                        .appId("java")
                        .deliveryMode(2)
                        .headers(Map.of("region", "us"))
                        .build();
                byte[] body = JSON.writeValueAsBytes(order);
                channel.basicPublish("orders.topic", "order.created.us", properties, body);
                System.out.println("published " + order.id() + " " + text(body));
            }
        }
    }

    static void consume() throws Exception {
        try (Connection connection = connect("l03-java-consumer");
             Channel channel = connection.createChannel()) {
            declare(channel);
            channel.basicQos(10);
            CountDownLatch waiting = new CountDownLatch((int) channel.messageCount("orders.billing"));

            channel.basicConsume("orders.billing", false,
                    (consumerTag, delivery) -> {
                        AMQP.BasicProperties p = delivery.getProperties();
                        Order order = JSON.readValue(delivery.getBody(), Order.class);
                        String headers = p.getHeaders() == null ? "" : new TreeMap<>(p.getHeaders()).entrySet().stream()
                                .map(h -> h.getKey() + "=" + h.getValue())
                                .collect(Collectors.joining(", "));
                        long tag = delivery.getEnvelope().getDeliveryTag();
                        System.out.println("#" + tag + " " + delivery.getEnvelope().getRoutingKey()
                                + " content-type=" + p.getContentType() + " message-id=" + p.getMessageId()
                                + " type=" + p.getType() + " app-id=" + p.getAppId() + " headers=[" + headers + "]");
                        System.out.println("   " + order);
                        channel.basicAck(tag, false);
                        waiting.countDown();
                    },
                    consumerTag -> { });
            await(waiting, "the waiting orders");
        }
    }
}
