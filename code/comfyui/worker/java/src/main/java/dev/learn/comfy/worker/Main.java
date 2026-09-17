package dev.learn.comfy.worker;

import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import dev.learn.comfy.worker.ComfyInstance.GpuHealth;
import dev.learn.comfy.worker.Jobs.DeadLetter;
import dev.learn.comfy.worker.Jobs.InMemoryJobQueue;
import dev.learn.comfy.worker.Jobs.Job;
import dev.learn.comfy.worker.Worker.WorkerOptions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.node.ObjectNode;

/** ComfyUI course, lesson 12: the worker's command line, the same commands and options as the C# worker. */
public final class Main {
    private Main() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 0) {
            System.err.println("""
                    usage: java -jar comfy-worker.jar <command> ...
                      run --gpu name=url [--gpu name=url]... --store dir (--jobs jobs.jsonl | --rabbitmq amqp://host --queue name)
                          [--name worker] [--attempts 4] [--base-delay-ms 2000] [--no-jitter] [--timeout-s 600] [--poll-ms 5000] [--grace-s 30]
                      enqueue --rabbitmq amqp://host --queue name --jobs jobs.jsonl
                      health --gpu name=url [--gpu name=url]...""");
            System.exit(2);
        }
        List<String[]> options = parse(args);
        Consumer<String> log = line -> {
            synchronized (System.out) {
                System.out.println(line);
            }
        };
        switch (args[0]) {
            case "health" -> {
                List<GpuHealth> health = new GpuPool(gpus(options), log, Duration.ofSeconds(5)).health();
                health.forEach(System.out::println);
                System.exit(health.stream().anyMatch(GpuHealth::healthy) ? 0 : 1);
            }
            case "enqueue" -> {
                for (Job job : readJobs(Path.of(single(options, "--jobs")))) {
                    RabbitMqJobQueue.publish(URI.create(single(options, "--rabbitmq")), single(options, "--queue"), job);
                    System.out.println("published job " + job.shortId());
                }
            }
            case "run" -> run(options, log);
            default -> {
                System.err.println("unknown command " + args[0]);
                System.exit(2);
            }
        }
    }

    private static void run(List<String[]> options, Consumer<String> log) throws Exception {
        String name = get(options, "--name", ProcessHandle.current().pid() + "");
        var workerOptions = WorkerOptions.defaults(name)
                .withAttempts(Integer.parseInt(get(options, "--attempts", "4")))
                .withBaseDelay(Duration.ofMillis(Long.parseLong(get(options, "--base-delay-ms", "2000"))))
                .withJitter(options.stream().noneMatch(o -> o[0].equals("--no-jitter")))
                .withJobTimeout(Duration.ofMillis(Math.round(Double.parseDouble(get(options, "--timeout-s", "600")) * 1000)))
                .withHistoryPoll(Duration.ofMillis(Long.parseLong(get(options, "--poll-ms", "5000"))));
        var pool = new GpuPool(gpus(options), log, Duration.ofSeconds(5));
        var store = new ResultStore(Path.of(single(options, "--store")));
        var grace = Duration.ofSeconds(Long.parseLong(get(options, "--grace-s", "30")));

        // SIGTERM or Ctrl+C: the JVM runs shutdown hooks, and exits when they return. The hook stops the worker
        // from taking jobs, gives running ones the grace period, then waits for the worker to requeue what is left.
        Cancellation stopReceiving = Cancellation.create();
        Cancellation abort = Cancellation.create();
        Thread main = Thread.currentThread();
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            if (!main.isAlive()) {
                return;
            }
            log.accept("shutdown: no new jobs, " + grace.toSeconds() + " s for the running ones");
            stopReceiving.cancel();
            abort.cancelAfter(grace);
            try {
                main.join();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }));

        if (get(options, "--rabbitmq", null) instanceof String broker) {
            try (var queue = RabbitMqJobQueue.connect(URI.create(broker), single(options, "--queue"), pool.size())) {
                new Worker(queue, pool, store, workerOptions, log).run(stopReceiving, abort);
            }
            return;
        }

        var memory = new InMemoryJobQueue();
        for (Job job : readJobs(Path.of(single(options, "--jobs")))) {
            memory.enqueue(job);
        }
        memory.complete();
        new Worker(memory, pool, store, workerOptions, log).run(stopReceiving, abort);
        System.out.println("summary: " + memory.acked() + " acknowledged, " + memory.deadLetters().size() + " dead-lettered");
        memory.deadLetters().stream().sorted(Comparator.comparing((DeadLetter d) -> d.job().id()))
                .forEach(d -> System.out.println("  dead letter " + d.job().shortId() + ": " + d.reason()));
    }

    private static List<String[]> parse(String[] args) {
        List<String[]> options = new ArrayList<>();
        for (int i = 1; i < args.length; i++) {
            options.add(args[i].equals("--no-jitter") ? new String[] {args[i], null} : new String[] {args[i], args[++i]});
        }
        return options;
    }

    private static String get(List<String[]> options, String key, String fallback) {
        String value = fallback;
        for (String[] option : options) {
            if (option[0].equals(key)) {
                value = option[1];
            }
        }
        return value;
    }

    private static String single(List<String[]> options, String key) {
        String value = get(options, key, null);
        if (value == null) {
            throw new IllegalArgumentException(key + " is required");
        }
        return value;
    }

    private static List<ComfyInstance> gpus(List<String[]> options) {
        return options.stream().filter(o -> o[0].equals("--gpu")).map(o -> o[1].split("=", 2))
                .map(p -> new ComfyInstance(p[0], URI.create(p[1]))).toList();
    }

    /** One job per line: {"id": "<uuid>", "workflow": "file.api.json" or {…}, "set": {"3.seed": 42}}. */
    static List<Job> readJobs(Path path) throws IOException {
        Path dir = path.toAbsolutePath().getParent();
        List<Job> jobs = new ArrayList<>();
        for (String line : Files.readAllLines(path)) {
            if (line.isBlank()) {
                continue;
            }
            JsonNode json = ComfyInstance.JSON.readTree(line);
            ObjectNode workflow = json.path("workflow").isString()
                    ? (ObjectNode) ComfyInstance.JSON.readTree(Files.readString(dir.resolve(json.path("workflow").asString())))
                    : (ObjectNode) json.path("workflow").deepCopy();
            for (Map.Entry<String, JsonNode> set : json.path("set").properties()) {
                String[] target = set.getKey().split("\\.", 2);
                ((ObjectNode) workflow.path(target[0]).path("inputs")).set(target[1], set.getValue().deepCopy());
            }
            jobs.add(Job.create(json.path("id").asString(), workflow));
        }
        return jobs;
    }
}
