package dev.learn.comfy.worker;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.Semaphore;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import dev.learn.comfy.worker.Cancellation.CancelledException;
import dev.learn.comfy.worker.ComfyInstance.GpuHealth;

/**
 * The ComfyUI instances a worker can use, one per GPU. A worker sends at most one job at a time to each instance
 * it owns, and picks, among its free instances, the one whose server queue is shortest.
 */
public final class GpuPool {
    private final List<ComfyInstance> instances;
    private final boolean[] busy;
    private final Semaphore free;
    private final Consumer<String> log;
    private final Duration unhealthyWait;

    public GpuPool(List<ComfyInstance> instances, Consumer<String> log, Duration unhealthyWait) {
        if (instances.isEmpty()) {
            throw new IllegalArgumentException("a pool needs at least one ComfyUI instance");
        }
        this.instances = List.copyOf(instances);
        this.busy = new boolean[instances.size()];
        this.free = new Semaphore(instances.size());
        this.log = log;
        this.unhealthyWait = unhealthyWait;
    }

    public int size() {
        return instances.size();
    }

    /** Waits for a free, healthy instance, and reserves it. {@code prefer} wins ties: a retry goes back to the same server. */
    public ComfyInstance acquire(ComfyInstance prefer, Cancellation cancel) throws InterruptedException, CancelledException {
        while (!free.tryAcquire(20, java.util.concurrent.TimeUnit.MILLISECONDS)) {
            cancel.throwIfCancelled();
        }
        try {
            while (true) {
                List<Integer> candidates = new ArrayList<>();
                synchronized (this) {
                    for (int i = 0; i < busy.length; i++) {
                        if (!busy[i]) {
                            candidates.add(i);
                        }
                    }
                }
                List<GpuHealth> health = probe(candidates.stream().map(instances::get).toList());
                List<Integer> healthy = new ArrayList<>();
                for (int k = 0; k < candidates.size(); k++) {
                    if (health.get(k).healthy()) {
                        healthy.add(k);
                    }
                }
                if (healthy.isEmpty()) {
                    log.accept("no healthy GPU among " + health.stream().map(GpuHealth::toString).collect(Collectors.joining(", "))
                            + ": waiting " + Worker.seconds(unhealthyWait) + " s");
                    cancel.sleep(unhealthyWait);
                    continue;
                }
                healthy.sort(Comparator.<Integer>comparingInt(k -> health.get(k).queueLength())
                        .thenComparingInt(k -> instances.get(candidates.get(k)) == prefer ? 0 : 1)
                        .thenComparingInt(candidates::get));
                synchronized (this) {
                    for (int k : healthy) {
                        int index = candidates.get(k);
                        if (!busy[index]) {
                            busy[index] = true;
                            if (health.size() > 1) {
                                log.accept("scheduler: " + instances.get(index).name() + " chosen, queue lengths "
                                        + health.stream().map(h -> h.healthy() ? h.name() + " " + h.queueLength() : h.name() + " down").collect(Collectors.joining(", ")));
                            }
                            return instances.get(index);
                        }
                    }
                }
            }
        } catch (InterruptedException | CancelledException | RuntimeException e) {
            free.release();
            throw e;
        }
    }

    public void release(ComfyInstance instance) {
        synchronized (this) {
            busy[instances.indexOf(instance)] = false;
        }
        free.release();
    }

    /** What a readiness probe would report: every instance, busy or not. */
    public List<GpuHealth> health() throws InterruptedException {
        return probe(instances);
    }

    private static List<GpuHealth> probe(List<ComfyInstance> targets) throws InterruptedException {
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            List<Callable<GpuHealth>> calls = targets.stream().<Callable<GpuHealth>>map(i -> i::checkHealth).toList();
            List<GpuHealth> result = new ArrayList<>();
            for (Future<GpuHealth> future : executor.invokeAll(calls)) {
                result.add(future.get());
            }
            return result;
        } catch (ExecutionException e) {
            throw new IllegalStateException(e.getCause());
        }
    }
}
