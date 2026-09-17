package dev.learn.comfy.worker;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.function.UnaryOperator;
import java.util.stream.IntStream;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;

import dev.learn.comfy.worker.Jobs.DeadLetter;
import dev.learn.comfy.worker.Jobs.InMemoryJobQueue;
import dev.learn.comfy.worker.Jobs.Job;
import dev.learn.comfy.worker.Worker.WorkerOptions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.node.ObjectNode;

/** The worker against the fake ComfyUI server of the C# project, started as a process: no GPU, no model, no Python. */
@Timeout(120)
class WorkerTest {
    private final List<Fake> fakes = new ArrayList<>();
    private final InMemoryJobQueue queue = new InMemoryJobQueue();
    private final Queue<String> log = new ConcurrentLinkedQueue<>();
    private ResultStore store;

    @Test
    void success_stores_the_files_and_a_duplicate_delivery_does_not_run_again() throws Exception {
        Fake fake = start("ok", 20, 0);
        Job job = job(1);
        queue.enqueue(job);
        queue.enqueue(job);

        runAll(worker("w1", o -> o));

        assertTrue(store.isDone(job.id()));
        try (var files = Files.list(store.root().resolve(job.id()).resolve("outputs"))) {
            assertEquals(2, files.count());
        }
        assertEquals(1, fake.stats().path("executed").path(job.id()).asInt());
        assertEquals(2, queue.acked());
        assertTrue(queue.deadLetters().isEmpty());
        assertTrue(log.stream().anyMatch(l -> l.endsWith("already done, acknowledged without running")));
    }

    @Test
    void server_error_500_is_retried_with_backoff() throws Exception {
        Fake fake = start("500,ok", 20, 0);
        Job job = job(2);
        queue.enqueue(job);

        runAll(worker("w1", o -> o));

        assertTrue(store.isDone(job.id()));
        assertEquals(2, fake.stats().path("posted").path(job.id()).asInt());
        assertEquals(1, fake.stats().path("executed").path(job.id()).asInt());
        assertTrue(log.stream().anyMatch(l -> l.contains("attempt 1 failed, POST /prompt 500, 500 Internal Server Error; retry in 20 ms")), String.join("\n", log));
    }

    @Test
    void websocket_dropping_mid_job_is_followed_again_without_posting_twice() throws Exception {
        Fake fake = start("drop", 50, 0);
        Job job = job(3);
        queue.enqueue(job);

        runAll(worker("w1", o -> o));

        assertTrue(store.isDone(job.id()), String.join("\n", log));
        assertEquals(1, fake.stats().path("drops").size());
        assertEquals(1, fake.stats().path("posted").path(job.id()).asInt());
        assertTrue(log.stream().anyMatch(l -> l.contains("WebSocket lost, reconnecting with the same client id")), String.join("\n", log));
    }

    @Test
    void validation_error_goes_to_the_dead_letter_queue_without_retry() throws Exception {
        Fake fake = start("invalid", 20, 0);
        Job job = job(4);
        queue.enqueue(job);

        runAll(worker("w1", o -> o));

        DeadLetter dead = single(queue.deadLetters());
        assertEquals(job.id(), dead.job().id());
        assertEquals("POST /prompt 400, prompt_outputs_failed_validation: node 3 (KSampler): exception_during_inner_validation", dead.reason());
        assertEquals(1, fake.stats().path("posted").path(job.id()).asInt());
        assertFalse(store.isDone(job.id()));
    }

    @Test
    void timeout_interrupts_the_prompt_and_gives_up_after_the_last_attempt() throws Exception {
        Fake fake = start("hang,hang", 20, 0);
        Job job = job(5);
        queue.enqueue(job);

        runAll(worker("w1", o -> o.withAttempts(2).withJobTimeout(Duration.ofMillis(500))));

        assertEquals("gave up after 2 attempts, last: timed out after 0.5 s", single(queue.deadLetters()).reason());
        assertEquals(List.of(job.id(), job.id()), strings(fake.stats().path("interrupts")));
        assertTrue(store.tryClaim(job.id(), "operator", Duration.ofMinutes(1)));
    }

    @Test
    void out_of_memory_is_retried_and_other_execution_errors_are_not() throws Exception {
        start("oom,ok,error", 20, 0);
        Job oom = job(6);
        Job broken = job(7);
        queue.enqueue(oom);
        queue.enqueue(broken);

        runAll(worker("w1", o -> o));

        assertTrue(store.isDone(oom.id()));
        assertTrue(log.stream().anyMatch(l -> l.contains("attempt 1 failed, execution_error, node 2 (ImageInvert): torch.OutOfMemoryError: Allocation on device ; retry in 20 ms")),
                String.join("\n", log));
        DeadLetter dead = single(queue.deadLetters());
        assertEquals(broken.id(), dead.job().id());
        assertEquals("execution_error, node 2 (ImageInvert): IndexError: index 3 is out of bounds for dimension 3 with size 3", dead.reason());
    }

    @Test
    void two_workers_competing_for_the_same_jobs_run_each_job_once() throws Exception {
        start("", 30, 0);
        start("", 30, 0);
        List<Job> jobs = IntStream.range(10, 18).mapToObj(WorkerTest::job).toList();
        jobs.forEach(queue::enqueue);
        jobs.forEach(queue::enqueue);

        runAll(worker("w1", o -> o), worker("w2", o -> o));

        for (Job job : jobs) {
            assertTrue(store.isDone(job.id()));
            int executed = 0;
            for (Fake fake : fakes) {
                executed += fake.stats().path("executed").path(job.id()).asInt(0);
            }
            assertEquals(1, executed, job.id());
        }
        for (Fake fake : fakes) {
            assertFalse(fake.stats().path("executed").isEmpty());
        }
        assertEquals(16, queue.acked());
        assertTrue(queue.deadLetters().isEmpty());
    }

    @Test
    void scheduler_picks_the_instance_with_the_shortest_queue() throws Exception {
        Fake busy = start("", 20, 3);
        Fake idle = start("", 20, 0);
        Job job = job(20);
        queue.enqueue(job);

        runAll(worker("w1", o -> o));

        assertEquals(1, idle.stats().path("executed").path(job.id()).asInt());
        assertTrue(busy.stats().path("executed").isEmpty());
        assertTrue(log.contains("scheduler: gpu1 chosen, queue lengths gpu0 3, gpu1 0"), String.join("\n", log));
    }

    @Test
    void shutdown_after_the_grace_period_interrupts_and_requeues() throws Exception {
        Fake fake = start("hang", 20, 0);
        Job job = job(32);
        queue.enqueue(job);
        Cancellation stop = Cancellation.create();
        Cancellation abort = Cancellation.create();

        Worker worker = worker("w1", o -> o);
        Thread run = Thread.ofVirtual().start(() -> {
            try {
                worker.run(stop, abort);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        while (log.stream().noneMatch(l -> l.contains("POST /prompt 200"))) {
            Thread.sleep(10);
        }
        stop.cancel();
        abort.cancelAfter(Duration.ofMillis(300));
        run.join(Duration.ofSeconds(30));

        assertEquals(List.of(job.id()), strings(fake.stats().path("interrupts")));
        assertTrue(log.stream().anyMatch(l -> l.endsWith("requeued at shutdown")), String.join("\n", log));
        assertEquals(job.id(), queue.receive(Duration.ofSeconds(1)).job().id());
    }

    // --- harness

    private Fake start(String script, int stepMs, int busy) throws IOException {
        Fake fake = Fake.start(script, stepMs, busy);
        fakes.add(fake);
        return fake;
    }

    private Worker worker(String name, UnaryOperator<WorkerOptions> configure) throws IOException {
        if (store == null) {
            store = new ResultStore(Files.createTempDirectory("comfy-worker-tests"));
        }
        List<ComfyInstance> instances = IntStream.range(0, fakes.size()).mapToObj(i -> new ComfyInstance("gpu" + i, fakes.get(i).uri())).toList();
        var pool = new GpuPool(instances, this::write, Duration.ofMillis(100));
        var options = WorkerOptions.defaults(name).withAttempts(3).withBaseDelay(Duration.ofMillis(20)).withJitter(false)
                .withJobTimeout(Duration.ofSeconds(10)).withHistoryPoll(Duration.ofMillis(200));
        return new Worker(queue, pool, store, configure.apply(options), this::write);
    }

    private void write(String line) {
        log.add(line);
        System.out.println(line);
    }

    private void runAll(Worker... workers) throws InterruptedException {
        queue.complete();
        List<Thread> threads = new ArrayList<>();
        for (Worker worker : workers) {
            threads.add(Thread.ofVirtual().start(() -> {
                try {
                    worker.run(Cancellation.create(), Cancellation.create());
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        for (Thread thread : threads) {
            thread.join(Duration.ofSeconds(60));
        }
    }

    private static List<String> strings(JsonNode array) {
        List<String> result = new ArrayList<>();
        for (JsonNode item : array) {
            result.add(item.asString());
        }
        return result;
    }

    private static <T> T single(Queue<T> items) {
        assertEquals(1, items.size(), items.toString());
        return items.peek();
    }

    /** The CI workflow of lesson 4: two images, no model. */
    static Job job(int n) {
        String workflow = """
                {
                  "1": { "class_type": "EmptyImage", "inputs": { "width": 64, "height": 48, "batch_size": 1, "color": 3368601 } },
                  "2": { "class_type": "ImageInvert", "inputs": { "image": ["1", 0] } },
                  "3": { "class_type": "SaveImage", "inputs": { "filename_prefix": "ci/solid", "images": ["1", 0] } },
                  "4": { "class_type": "SaveImage", "inputs": { "filename_prefix": "ci/inverted", "images": ["2", 0] } }
                }""";
        return Job.create("%08d-0000-4000-8000-000000000000".formatted(n), (ObjectNode) ComfyInstance.JSON.readTree(workflow));
    }

    @AfterEach
    void stopFakes() {
        fakes.forEach(Fake::close);
    }

    /** fake-comfy.dll in its own process: it prints its URL, and exits when its standard input closes. */
    record Fake(Process process, URI uri) implements AutoCloseable {
        static Fake start(String script, int stepMs, int busy) throws IOException {
            String dll = System.getProperty("fake.comfy");
            var command = new ArrayList<>(List.of("dotnet", dll, "--port", "0", "--step-ms", String.valueOf(stepMs), "--busy", String.valueOf(busy), "--until-input-closes"));
            if (!script.isEmpty()) {
                command.addAll(List.of("--script", script));
            }
            Process process = new ProcessBuilder(command).redirectError(ProcessBuilder.Redirect.INHERIT).start();
            var reader = new BufferedReader(new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8));
            String line = reader.readLine();
            if (line == null || !line.startsWith("listening on ")) {
                process.destroyForcibly();
                throw new IOException("fake-comfy did not start: " + line);
            }
            return new Fake(process, URI.create(line.substring("listening on ".length())));
        }

        JsonNode stats() throws IOException, InterruptedException {
            try (HttpClient http = HttpClient.newHttpClient()) {
                String body = http.send(HttpRequest.newBuilder(uri.resolve("fake/stats")).build(), HttpResponse.BodyHandlers.ofString()).body();
                return ComfyInstance.JSON.readTree(body);
            }
        }

        @Override
        public void close() {
            try {
                process.getOutputStream().close();
                if (!process.waitFor(5, java.util.concurrent.TimeUnit.SECONDS)) {
                    process.destroyForcibly();
                }
            } catch (IOException | InterruptedException e) {
                process.destroyForcibly();
            }
        }
    }

    static {
        // Make sure a failed assertion shows the fake's path when the property is missing.
        if (System.getProperty("fake.comfy") == null) {
            System.setProperty("fake.comfy", Path.of("../csharp/FakeComfy/bin/Release/net10.0/fake-comfy.dll").toAbsolutePath().toString());
        }
    }
}
