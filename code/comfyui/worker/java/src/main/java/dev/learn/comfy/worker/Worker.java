package dev.learn.comfy.worker;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ThreadLocalRandom;
import java.util.function.Consumer;

import dev.learn.comfy.worker.Cancellation.CancelledException;
import dev.learn.comfy.worker.Jobs.Delivery;
import dev.learn.comfy.worker.Jobs.Job;
import dev.learn.comfy.worker.Jobs.JobQueue;
import dev.learn.comfy.worker.Jobs.Outcome;

/**
 * Takes jobs from a queue and runs them on a pool of ComfyUI instances: one consumer thread per GPU (virtual threads),
 * retries with exponential backoff, a dead-letter queue for what will never work, and a result store that makes a
 * job id run once even when the queue delivers it twice.
 */
public final class Worker {
    private final JobQueue queue;
    private final GpuPool pool;
    private final ResultStore store;
    private final WorkerOptions options;
    private final Consumer<String> log;
    private final JobRunner runner;

    public Worker(JobQueue queue, GpuPool pool, ResultStore store, WorkerOptions options, Consumer<String> log) {
        this.queue = queue;
        this.pool = pool;
        this.store = store;
        this.options = options;
        this.log = log;
        this.runner = new JobRunner(store, options, log);
    }

    /**
     * Runs until the queue is drained, or until {@code stopReceiving} fires. Jobs already running then get to finish,
     * until {@code abort} fires: those are interrupted and requeued.
     */
    public void run(Cancellation stopReceiving, Cancellation abort) throws InterruptedException {
        log.accept("worker " + options.name() + ": " + pool.size() + " GPU(s), up to " + options.maxAttempts() + " attempts, job timeout "
                + seconds(options.jobTimeout()) + " s");
        List<Thread> threads = new ArrayList<>();
        for (int i = 0; i < pool.size(); i++) {
            threads.add(Thread.ofVirtual().name(options.name() + "-" + i).start(() -> consume(stopReceiving, abort)));
        }
        for (Thread thread : threads) {
            thread.join();
        }
        log.accept("worker " + options.name() + ": stopped");
    }

    private void consume(Cancellation stopReceiving, Cancellation abort) {
        try {
            while (!stopReceiving.isCancelled()) {
                Delivery delivery = queue.receive(Duration.ofMillis(50));
                if (delivery == null) {
                    if (queue.isDrained()) {
                        return;
                    }
                    continue;
                }
                handle(delivery, abort);
            }
        } catch (Exception e) {
            log.accept("worker " + options.name() + ": consumer stopped by " + e);
        }
    }

    private void handle(Delivery delivery, Cancellation abort) throws Exception {
        Job job = delivery.job();
        if (store.isDone(job.id())) {
            log.accept("job " + job.shortId() + ": already done, acknowledged without running");
            delivery.ack();
            return;
        }
        if (!store.tryClaim(job.id(), options.name(), options.claimLease())) {
            log.accept("job " + job.shortId() + ": claimed by another worker, acknowledged without running");
            delivery.ack();
            return;
        }
        if (store.isDone(job.id())) {
            // Finished by another worker between the first check and the claim.
            store.releaseClaim(job.id(), options.name());
            log.accept("job " + job.shortId() + ": already done, acknowledged without running");
            delivery.ack();
            return;
        }

        ComfyInstance last = null;
        for (int attempt = 1;; attempt++) {
            ComfyInstance gpu;
            Outcome outcome;
            try {
                gpu = pool.acquire(last, abort);
                try {
                    outcome = runner.run(job, gpu, attempt, abort);
                } finally {
                    pool.release(gpu);
                }
            } catch (CancelledException e) {
                requeue(delivery, job);
                return;
            }
            last = gpu;

            switch (outcome.kind()) {
                case SUCCEEDED -> {
                    store.complete(job.id(), options.name(), gpu.name(), attempt, outcome.files());
                    delivery.ack();
                    log.accept("job " + job.shortId() + ": done on " + gpu.name() + " after " + attempt + " attempt(s), " + outcome.detail());
                    return;
                }
                case PERMANENT -> {
                    store.fail(job.id(), options.name(), outcome.detail());
                    delivery.deadLetter(outcome.detail());
                    log.accept("job " + job.shortId() + ": dead-lettered, " + outcome.detail());
                    return;
                }
                case TRANSIENT -> {
                    if (attempt >= options.maxAttempts()) {
                        String reason = "gave up after " + attempt + " attempts, last: " + outcome.detail();
                        store.fail(job.id(), options.name(), reason);
                        delivery.deadLetter(reason);
                        log.accept("job " + job.shortId() + ": dead-lettered, " + reason);
                        return;
                    }
                    Duration delay = backoff(attempt);
                    log.accept("job " + job.shortId() + ": attempt " + attempt + " failed, " + outcome.detail() + "; retry in " + delay.toMillis() + " ms");
                    try {
                        abort.sleep(delay);
                    } catch (CancelledException e) {
                        requeue(delivery, job);
                        return;
                    }
                }
            }
        }
    }

    private void requeue(Delivery delivery, Job job) throws Exception {
        store.releaseClaim(job.id(), options.name());
        delivery.requeue();
        log.accept("job " + job.shortId() + ": requeued at shutdown");
    }

    /** Exponential: base × 2^(attempt−1), capped; with full jitter, a random delay between 0 and that. */
    public Duration backoff(int attempt) {
        double capped = Math.min(options.maxDelay().toMillis(), options.baseDelay().toMillis() * Math.pow(2, attempt - 1));
        return Duration.ofMillis(Math.round(options.jitter() ? ThreadLocalRandom.current().nextDouble() * capped : capped));
    }

    static String seconds(Duration duration) {
        return new DecimalFormat("0.#", DecimalFormatSymbols.getInstance(Locale.ROOT)).format(duration.toMillis() / 1000.0);
    }

    /** The options of the C# worker, with the same defaults. */
    public record WorkerOptions(String name, int maxAttempts, Duration baseDelay, Duration maxDelay, boolean jitter, Duration jobTimeout,
            Duration historyPoll, int maxReconnects, Duration claimLease) {
        public static WorkerOptions defaults(String name) {
            return new WorkerOptions(name, 4, Duration.ofSeconds(2), Duration.ofMinutes(1), true, Duration.ofMinutes(10), Duration.ofSeconds(5), 5,
                    Duration.ofHours(1));
        }

        public WorkerOptions withAttempts(int value) {
            return new WorkerOptions(name, value, baseDelay, maxDelay, jitter, jobTimeout, historyPoll, maxReconnects, claimLease);
        }

        public WorkerOptions withBaseDelay(Duration value) {
            return new WorkerOptions(name, maxAttempts, value, maxDelay, jitter, jobTimeout, historyPoll, maxReconnects, claimLease);
        }

        public WorkerOptions withJitter(boolean value) {
            return new WorkerOptions(name, maxAttempts, baseDelay, maxDelay, value, jobTimeout, historyPoll, maxReconnects, claimLease);
        }

        public WorkerOptions withJobTimeout(Duration value) {
            return new WorkerOptions(name, maxAttempts, baseDelay, maxDelay, jitter, value, historyPoll, maxReconnects, claimLease);
        }

        public WorkerOptions withHistoryPoll(Duration value) {
            return new WorkerOptions(name, maxAttempts, baseDelay, maxDelay, jitter, jobTimeout, value, maxReconnects, claimLease);
        }
    }
}
