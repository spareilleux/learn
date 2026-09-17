package dev.learn.comfy.worker;

import java.time.Duration;
import java.util.List;
import java.util.Queue;
import java.util.UUID;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import tools.jackson.databind.node.ObjectNode;

/** The job, what an attempt gives, and the queue interface: the same shapes as the C# worker. */
public final class Jobs {
    private Jobs() {
    }

    /** A workflow in API format, and an id that is a lowercase UUID so that it can be ComfyUI's prompt_id. */
    public record Job(String id, ObjectNode workflow) {
        public static Job create(String id, ObjectNode workflow) {
            try {
                if (!UUID.fromString(id).toString().equals(id)) {
                    throw new IllegalArgumentException("job id " + id + " is not a lowercase hyphenated UUID");
                }
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("job id " + id + " is not a lowercase hyphenated UUID", e);
            }
            return new Job(id, workflow);
        }

        public String shortId() {
            return id.substring(0, 8);
        }
    }

    public enum Kind { SUCCEEDED, TRANSIENT, PERMANENT }

    public record StoredFile(String node, String name, long bytes, String sha256) {
    }

    public record Outcome(Kind kind, String detail, List<StoredFile> files) {
        static Outcome success(List<StoredFile> files, String detail) {
            return new Outcome(Kind.SUCCEEDED, detail, files);
        }

        static Outcome transientFailure(String detail) {
            return new Outcome(Kind.TRANSIENT, detail, List.of());
        }

        static Outcome permanent(String detail) {
            return new Outcome(Kind.PERMANENT, detail, List.of());
        }
    }

    /** A job handed to the worker, and what the worker tells the queue once it is done with it. */
    public interface Delivery {
        Job job();

        void ack() throws Exception;

        /** Gives the job back, for another worker: used at shutdown. */
        void requeue() throws Exception;

        void deadLetter(String reason) throws Exception;
    }

    public interface JobQueue {
        /** The next job, or null if none arrived within the timeout. */
        Delivery receive(Duration timeout) throws InterruptedException;

        /** True once no job will ever arrive again. */
        boolean isDrained();
    }

    public record DeadLetter(Job job, String reason) {
    }

    /** A queue in the worker's own process, over a {@link LinkedBlockingQueue}. */
    public static final class InMemoryJobQueue implements JobQueue {
        private final LinkedBlockingQueue<Job> jobs = new LinkedBlockingQueue<>();
        private final Queue<DeadLetter> deadLetters = new ConcurrentLinkedQueue<>();
        private final AtomicInteger acked = new AtomicInteger();
        private volatile boolean completed;

        public void enqueue(Job job) {
            jobs.add(job);
        }

        /** No more jobs: the workers stop once the queue is empty. */
        public void complete() {
            completed = true;
        }

        public Queue<DeadLetter> deadLetters() {
            return deadLetters;
        }

        public int acked() {
            return acked.get();
        }

        @Override
        public Delivery receive(Duration timeout) throws InterruptedException {
            Job job = jobs.poll(timeout.toMillis(), TimeUnit.MILLISECONDS);
            if (job == null) {
                return null;
            }
            return new Delivery() {
                @Override
                public Job job() {
                    return job;
                }

                @Override
                public void ack() {
                    acked.incrementAndGet();
                }

                @Override
                public void requeue() {
                    if (completed) {
                        deadLetters.add(new DeadLetter(job, "requeued after the queue was completed"));
                    } else {
                        jobs.add(job);
                    }
                }

                @Override
                public void deadLetter(String reason) {
                    deadLetters.add(new DeadLetter(job, reason));
                }
            };
        }

        @Override
        public boolean isDrained() {
            return completed && jobs.isEmpty();
        }
    }
}
