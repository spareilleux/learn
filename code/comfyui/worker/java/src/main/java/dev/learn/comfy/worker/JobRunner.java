package dev.learn.comfy.worker;

import java.io.IOException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import dev.learn.comfy.worker.Cancellation.CancelledException;
import dev.learn.comfy.worker.ComfyInstance.QueueState;
import dev.learn.comfy.worker.ComfyInstance.Socket;
import dev.learn.comfy.worker.Jobs.Job;
import dev.learn.comfy.worker.Jobs.Outcome;
import dev.learn.comfy.worker.Jobs.StoredFile;
import dev.learn.comfy.worker.Worker.WorkerOptions;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;

/** One attempt at one job on one ComfyUI instance: returns an {@link Outcome}, and the worker decides what follows. */
public final class JobRunner {
    private final ResultStore store;
    private final WorkerOptions options;
    private final Consumer<String> log;

    public JobRunner(ResultStore store, WorkerOptions options, Consumer<String> log) {
        this.store = store;
        this.options = options;
        this.log = log;
    }

    private record End(String type, JsonNode data) {
    }

    /** Throws {@link CancelledException} only when {@code abort} fires: the worker is shutting down. */
    public Outcome run(Job job, ComfyInstance gpu, int attempt, Cancellation abort) throws CancelledException, InterruptedException {
        Cancellation deadline = abort.withTimeout(options.jobTimeout());
        String prefix = "job " + job.shortId() + " attempt " + attempt + " on " + gpu.name();
        Socket[] socket = new Socket[1];
        try {
            // 1. Catch up: the prompt id is the job id, so a previous attempt's prompt can be in /queue or /history.
            JsonNode previous = gpu.getHistory(job.id());
            if (previous != null && succeeded(previous)) {
                log.accept(prefix + ": already in /history, downloading its outputs");
                return download(job, gpu, previous);
            }
            QueueState queue = gpu.getQueue(Duration.ofSeconds(30));
            boolean queued = queue.contains(job.id());

            // 2. Connect first, then post: the server sends events only to the client id the prompt was queued with.
            String clientId = UUID.randomUUID().toString().replace("-", "");
            socket[0] = gpu.connect(clientId);
            // This run's number: an older /history entry with the same prompt id belongs to an earlier attempt.
            double number;
            if (queued) {
                number = queue.numbers().get(job.id());
                log.accept(prefix + ": already in /queue, following it");
            } else {
                var submitted = gpu.submit(job, clientId);
                if (submitted.status() == 400) {
                    return Outcome.permanent("POST /prompt 400, " + describeErrors(submitted.body()));
                }
                if (submitted.status() >= 500) {
                    return Outcome.transientFailure("POST /prompt " + submitted.status() + ", " + submitted.body().split("\n")[0]);
                }
                if (submitted.status() != 200) {
                    return Outcome.transientFailure("POST /prompt " + submitted.status());
                }
                number = ComfyInstance.JSON.readTree(submitted.body()).path("number").asDouble();
                log.accept(prefix + ": POST /prompt 200");
            }

            // 3. Follow until the prompt ends, reconnecting when the WebSocket drops.
            End end = follow(job, gpu, clientId, prefix, socket, queue.running().contains(job.id()), number, deadline);
            switch (end.type()) {
                case "execution_success" -> {
                    // execution_success is sent before the history is written (execution.py, then main.py's task_done).
                    JsonNode history;
                    while ((history = gpu.getHistory(job.id())) == null || !isRun(history, number)) {
                        deadline.sleep(Duration.ofMillis(50));
                    }
                    return download(job, gpu, history);
                }
                case "execution_error" -> {
                    JsonNode data = end.data();
                    String type = data.path("exception_type").asString("");
                    String message = data.path("exception_message").asString("").split("\n")[0];
                    String where = "node " + data.path("node_id").asString() + " (" + data.path("node_type").asString() + "): " + type + ": " + message;
                    // Out of memory depends on what else the GPU held: worth another try. Anything else fails again.
                    return isOutOfMemory(type, data) ? Outcome.transientFailure("execution_error, " + where) : Outcome.permanent("execution_error, " + where);
                }
                default -> {
                    return Outcome.transientFailure("execution_interrupted at node " + end.data().path("node_id").asString() + ", by someone else");
                }
            }
        } catch (CancelledException e) {
            if (deadline.timedOut()) {
                log.accept(prefix + ": no result after " + Worker.seconds(options.jobTimeout()) + " s, POST /interrupt and remove it from the queue");
                tryCancel(gpu, job);
                return Outcome.transientFailure("timed out after " + Worker.seconds(options.jobTimeout()) + " s");
            }
            log.accept(prefix + ": shutdown, POST /interrupt");
            tryCancel(gpu, job);
            throw e;
        } catch (IOException | JacksonException e) {
            return Outcome.transientFailure(e.getClass().getSimpleName() + ": " + e.getMessage());
        } finally {
            if (socket[0] != null) {
                socket[0].close();
            }
        }
    }

    private End follow(Job job, ComfyInstance gpu, String clientId, String prefix, Socket[] socket, boolean started, double number, Cancellation cancel)
            throws IOException, InterruptedException, CancelledException {
        int reconnects = 0;
        long nextPoll = System.nanoTime() + options.historyPoll().toNanos();
        while (true) {
            cancel.throwIfCancelled();
            // Wake up now and then even if nothing arrives: an end message sent while we were
            // reconnecting is lost, and only /history has it.
            if (System.nanoTime() > nextPoll) {
                nextPoll = System.nanoTime() + options.historyPoll().toNanos();
                JsonNode history = gpu.getHistory(job.id());
                if (history != null && isRun(history, number)) {
                    return endFromHistory(history);
                }
            }
            JsonNode message;
            try {
                message = socket[0].receive(Duration.ofMillis(20));
            } catch (IOException e) {
                if (++reconnects > options.maxReconnects()) {
                    throw e;
                }
                log.accept(prefix + ": WebSocket lost, reconnecting with the same client id");
                cancel.sleep(Duration.ofMillis(100L * reconnects));
                socket[0].close();
                socket[0] = gpu.connect(clientId);
                started = true; // its execution_start may have been among the lost messages
                // The server doesn't replay what we missed: if the prompt ended meanwhile, /history says so.
                JsonNode history = gpu.getHistory(job.id());
                if (history != null && isRun(history, number)) {
                    return endFromHistory(history);
                }
                continue;
            }
            if (message == null) {
                continue;
            }
            String type = message.path("type").asString();
            JsonNode data = message.path("data");
            if (!data.path("prompt_id").asString("").equals(job.id())) {
                continue;
            }
            // An end message before this run's execution_start belongs to an earlier run with the same prompt id.
            if (type.equals("execution_start")) {
                started = true;
            } else if (started && (type.equals("execution_success") || type.equals("execution_error") || type.equals("execution_interrupted"))) {
                return new End(type, data);
            }
        }
    }

    /** history.status.messages holds the lifecycle messages: the last one says how the prompt ended. */
    private static End endFromHistory(JsonNode history) {
        if (succeeded(history)) {
            return new End("execution_success", ComfyInstance.JSON.createObjectNode());
        }
        JsonNode messages = history.path("status").path("messages");
        JsonNode last = messages.path(messages.size() - 1);
        return new End(last.path(0).asString("execution_error"), last.path(1));
    }

    private static boolean isRun(JsonNode history, double number) {
        return history.path("prompt").path(0).asDouble(Double.NaN) == number;
    }

    private static boolean succeeded(JsonNode history) {
        return history.path("status").path("status_str").asString("").equals("success");
    }

    private static boolean isOutOfMemory(String type, JsonNode data) {
        return type.endsWith("OutOfMemoryError") || data.path("exception_message").asString("").contains("ran out of memory");
    }

    private Outcome download(Job job, ComfyInstance gpu, JsonNode history) throws IOException, InterruptedException {
        List<StoredFile> files = new ArrayList<>();
        for (Map.Entry<String, JsonNode> output : history.path("outputs").properties()) {
            for (JsonNode image : output.getValue().path("images")) {
                byte[] bytes = gpu.view(image);
                files.add(store.saveFile(job.id(), output.getKey(), image.path("filename").asString(), bytes));
            }
        }
        return Outcome.success(files, files.size() + " file(s): " + files.stream().map(f -> f.name() + " " + f.sha256()).collect(Collectors.joining(", ")));
    }

    private static String describeErrors(String body) {
        try {
            JsonNode json = ComfyInstance.JSON.readTree(body);
            List<String> nodes = new ArrayList<>();
            for (Map.Entry<String, JsonNode> node : json.path("node_errors").properties()) {
                for (JsonNode error : node.getValue().path("errors")) {
                    nodes.add("node " + node.getKey() + " (" + node.getValue().path("class_type").asString() + "): " + error.path("type").asString());
                }
            }
            String type = json.path("error").path("type").asString();
            return nodes.isEmpty() ? type + ": " + json.path("error").path("message").asString() : type + ": " + String.join("; ", nodes);
        } catch (JacksonException e) {
            return body;
        }
    }

    private void tryCancel(ComfyInstance gpu, Job job) throws InterruptedException {
        try {
            gpu.cancelPrompt(job.id());
        } catch (IOException e) {
            log.accept("job " + job.shortId() + ": could not cancel on " + gpu.name() + ": " + e.getMessage());
        }
    }
}
