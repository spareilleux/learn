package dev.learn.comfy.worker;

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.MessageProperties;

import dev.learn.comfy.worker.Jobs.Delivery;
import dev.learn.comfy.worker.Jobs.Job;
import dev.learn.comfy.worker.Jobs.JobQueue;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.node.ObjectNode;

/**
 * The same {@link JobQueue} over RabbitMQ: a durable quorum queue of jobs, manual acknowledgements, a prefetch equal to
 * the number of GPUs, and a second queue for dead letters. The message is {"id": "…", "workflow": {…}}.
 */
public final class RabbitMqJobQueue implements JobQueue, AutoCloseable {
    private static final Map<String, Object> QUORUM = Map.of("x-queue-type", "quorum");

    private final Connection connection;
    private final Channel channel;
    private final String deadLetterQueue;
    private final LinkedBlockingQueue<Delivery> deliveries = new LinkedBlockingQueue<>();

    private RabbitMqJobQueue(Connection connection, Channel channel, String deadLetterQueue) {
        this.connection = connection;
        this.channel = channel;
        this.deadLetterQueue = deadLetterQueue;
    }

    public static RabbitMqJobQueue connect(URI broker, String queue, int prefetch) throws Exception {
        var factory = new ConnectionFactory();
        factory.setUri(broker);
        Connection connection = factory.newConnection("comfy-worker");
        Channel channel = connection.createChannel();
        channel.queueDeclare(queue, true, false, false, QUORUM);
        channel.queueDeclare(queue + ".dead", true, false, false, QUORUM);
        // Prefetch = GPUs: the broker never hands this worker more jobs than it can run.
        channel.basicQos(prefetch);
        var result = new RabbitMqJobQueue(connection, channel, queue + ".dead");
        channel.basicConsume(queue, false, (tag, message) -> {
            JsonNode json = ComfyInstance.JSON.readTree(new String(message.getBody(), StandardCharsets.UTF_8));
            Job job = Job.create(json.path("id").asString(), (ObjectNode) json.path("workflow"));
            result.deliveries.add(result.new RabbitDelivery(job, message.getEnvelope().getDeliveryTag(), message.getBody()));
        }, tag -> { });
        return result;
    }

    public static void publish(URI broker, String queue, Job job) throws Exception {
        var factory = new ConnectionFactory();
        factory.setUri(broker);
        try (Connection connection = factory.newConnection(); Channel channel = connection.createChannel()) {
            channel.queueDeclare(queue, true, false, false, QUORUM);
            channel.confirmSelect();
            ObjectNode body = ComfyInstance.JSON.createObjectNode().put("id", job.id());
            body.set("workflow", job.workflow().deepCopy());
            AMQP.BasicProperties properties = MessageProperties.PERSISTENT_BASIC.builder().messageId(job.id()).contentType("application/json").build();
            channel.basicPublish("", queue, true, properties, body.toString().getBytes(StandardCharsets.UTF_8));
            channel.waitForConfirmsOrDie(10_000);
        }
    }

    @Override
    public Delivery receive(Duration timeout) throws InterruptedException {
        return deliveries.poll(timeout.toMillis(), TimeUnit.MILLISECONDS);
    }

    @Override
    public boolean isDrained() {
        return false; // a broker queue never ends: the worker stops on a signal
    }

    @Override
    public void close() throws IOException, TimeoutException {
        channel.close();
        connection.close();
    }

    // A Channel is not meant to be shared between threads for publishing: the worker's consumer threads
    // serialize their acknowledgements and publications on it.
    private final class RabbitDelivery implements Delivery {
        private final Job job;
        private final long tag;
        private final byte[] body;

        RabbitDelivery(Job job, long tag, byte[] body) {
            this.job = job;
            this.tag = tag;
            this.body = body;
        }

        @Override
        public Job job() {
            return job;
        }

        @Override
        public void ack() throws IOException {
            synchronized (channel) {
                channel.basicAck(tag, false);
            }
        }

        @Override
        public void requeue() throws IOException {
            synchronized (channel) {
                channel.basicNack(tag, false, true);
            }
        }

        /** Published to the dead-letter queue with the reason in a header, then acked. */
        @Override
        public void deadLetter(String reason) throws IOException {
            AMQP.BasicProperties properties = MessageProperties.PERSISTENT_BASIC.builder()
                    .messageId(job.id()).contentType("application/json").headers(Map.of("x-worker-reason", reason)).build();
            synchronized (channel) {
                channel.basicPublish("", deadLetterQueue, properties, body);
                channel.basicAck(tag, false);
            }
        }
    }
}
