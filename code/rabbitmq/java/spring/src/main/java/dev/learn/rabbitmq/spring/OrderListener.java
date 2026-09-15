package dev.learn.rabbitmq.spring;

import dev.learn.rabbitmq.spring.OrdersApplication.Order;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.springframework.amqp.core.MessageProperties;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Receives orders with @RabbitListener. The container consumes, converts the JSON body to the parameter's type,
 * calls the method, and acknowledges when it returns (acknowledge mode AUTO).
 */
@Component
@Profile("listen")
class OrderListener implements ApplicationRunner {

    private final CountDownLatch expected;

    OrderListener(@Value("${orders.expected}") int expected) {
        this.expected = new CountDownLatch(expected);
    }

    @RabbitListener(queues = "orders.billing")
    void onOrder(Order order, MessageProperties properties) {
        System.out.println("#" + properties.getDeliveryTag() + " " + properties.getReceivedRoutingKey()
                + " message-id=" + properties.getMessageId() + " app-id=" + properties.getAppId()
                + " __TypeId__=" + properties.getHeader("__TypeId__"));
        System.out.println("   " + order);
        expected.countDown();
    }

    // Keeps the application running until the expected orders have arrived; main then closes the context.
    @Override
    public void run(ApplicationArguments args) throws InterruptedException {
        if (!expected.await(20, TimeUnit.SECONDS)) {
            throw new IllegalStateException(expected.getCount() + " order(s) still expected");
        }
    }
}
