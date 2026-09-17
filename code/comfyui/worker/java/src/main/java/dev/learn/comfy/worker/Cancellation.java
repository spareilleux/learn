package dev.learn.comfy.worker;

import java.time.Duration;

/**
 * What a CancellationToken is in C#: a flag that code checks between blocking steps, possibly linked to a parent
 * and to a deadline. Blocking waits in this worker are short slices that check it.
 */
public final class Cancellation {
    private final Cancellation parent;
    private final long deadline;
    private volatile boolean cancelled;

    private Cancellation(Cancellation parent, long deadline) {
        this.parent = parent;
        this.deadline = deadline;
    }

    public static Cancellation create() {
        return new Cancellation(null, Long.MAX_VALUE);
    }

    /** A child that is cancelled with this one, or when the timeout has passed. */
    public Cancellation withTimeout(Duration timeout) {
        return new Cancellation(this, System.nanoTime() + timeout.toNanos());
    }

    public void cancel() {
        cancelled = true;
    }

    public void cancelAfter(Duration delay) {
        Thread.ofVirtual().start(() -> {
            try {
                Thread.sleep(delay);
                cancel();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
    }

    public boolean isCancelled() {
        return cancelled || System.nanoTime() > deadline || (parent != null && parent.isCancelled());
    }

    /** True if this token's own deadline passed while its parent is still alive: a timeout, not a shutdown. */
    public boolean timedOut() {
        return System.nanoTime() > deadline && (parent == null || !parent.isCancelled());
    }

    public void throwIfCancelled() throws CancelledException {
        if (isCancelled()) {
            throw new CancelledException();
        }
    }

    public void sleep(Duration duration) throws CancelledException, InterruptedException {
        long end = System.nanoTime() + duration.toNanos();
        while (true) {
            throwIfCancelled();
            long left = end - System.nanoTime();
            if (left <= 0) {
                return;
            }
            Thread.sleep(Duration.ofNanos(Math.min(left, Duration.ofMillis(20).toNanos())));
        }
    }

    public static final class CancelledException extends Exception {
        private static final long serialVersionUID = 1L;

        public CancelledException() {
            super("cancelled");
        }
    }
}
