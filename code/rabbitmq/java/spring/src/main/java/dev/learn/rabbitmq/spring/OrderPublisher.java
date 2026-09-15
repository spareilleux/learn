package dev.learn.rabbitmq.spring;

import dev.learn.rabbitmq.spring.OrdersApplication.Order;
import org.springframework.amqp.core.MessageDeliveryMode;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/** Publishes two orders with RabbitTemplate, the Spring counterpart of a channel's basicPublish. */
@Component
@Profile("publish")
class OrderPublisher implements ApplicationRunner {

    private final RabbitTemplate rabbit;

    OrderPublisher(RabbitTemplate rabbit) {
        this.rabbit = rabbit;
    }

    @Override
    public void run(ApplicationArguments args) {
        for (Order order : new Order[] {new Order("C-1", "AMP", 1), new Order("C-2", "CABLE", 3)}) {
            // The converter writes the JSON body, content-type and the __TypeId__ header; the post-processor adds the rest.
            rabbit.convertAndSend("orders.topic", "order.created.ca", order, message -> {
                message.getMessageProperties().setMessageId(order.id());
                message.getMessageProperties().setType("order.created");
                message.getMessageProperties().setAppId("spring");
                message.getMessageProperties().setHeader("region", "ca");
                message.getMessageProperties().setDeliveryMode(MessageDeliveryMode.PERSISTENT);
                return message;
            });
            System.out.println("published " + order);
        }
    }
}
