package dev.learn.rabbitmq.spring;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.support.converter.JacksonJsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/**
 * The lesson 3 order producer and consumer with Spring AMQP. Run with --spring.profiles.active=publish or listen;
 * the application stops once its runner has finished.
 */
@SpringBootApplication
public class OrdersApplication {

    public record Order(String id, String sku, int quantity) {
    }

    // The same topology as the C# and Java client examples, declared by RabbitAdmin when the first connection opens.
    @Bean
    TopicExchange ordersExchange() {
        return new TopicExchange("orders.topic");
    }

    @Bean
    Queue billingQueue() {
        return new Queue("orders.billing");
    }

    @Bean
    Binding billingBinding(Queue billingQueue, TopicExchange ordersExchange) {
        return BindingBuilder.bind(billingQueue).to(ordersExchange).with("order.#");
    }

    // Replaces the default converter (byte[], String and Java serialization) for RabbitTemplate and @RabbitListener.
    @Bean
    MessageConverter jsonMessageConverter() {
        return new JacksonJsonMessageConverter();
    }

    public static void main(String[] args) {
        SpringApplication.run(OrdersApplication.class, args).close();
    }
}
