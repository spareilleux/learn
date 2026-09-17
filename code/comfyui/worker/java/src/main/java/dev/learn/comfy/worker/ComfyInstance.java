package dev.learn.comfy.worker;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CompletionException;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import dev.learn.comfy.worker.Jobs.Job;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.MissingNode;
import tools.jackson.databind.node.ObjectNode;

/**
 * One ComfyUI server: in production, one process per GPU, started with --cuda-device and its own --port.
 * The calls are lesson 4's, split so that the worker can retry, catch up and interrupt.
 */
public final class ComfyInstance {
    static final ObjectMapper JSON = JsonMapper.builder().build();

    private final String name;
    private final URI baseUri;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build();

    public ComfyInstance(String name, URI baseUri) {
        this.name = name;
        // resolve("prompt") needs a trailing slash to stay under the base URI
        this.baseUri = baseUri.toString().endsWith("/") ? baseUri : URI.create(baseUri + "/");
    }

    public String name() {
        return name;
    }

    public record GpuHealth(String name, boolean healthy, String device, long vramFree, int queueLength, String error) {
        @Override
        public String toString() {
            return healthy
                    ? name + ": healthy, device " + device + ", " + vramFree / (1024 * 1024) + " MiB free, " + queueLength + " prompt(s) in its queue"
                    : name + ": unreachable (" + error + ")";
        }
    }

    /** Numbers: each prompt's position number, which also appears in its history entry (prompt[0]). */
    public record QueueState(List<String> running, List<String> pending, Map<String, Double> numbers) {
        boolean contains(String promptId) {
            return running.contains(promptId) || pending.contains(promptId);
        }
    }

    public record Submitted(int status, String body) {
    }

    /** GET /system_stats and GET /queue, with a short timeout: a hung server counts as down. */
    public GpuHealth checkHealth() throws InterruptedException {
        try {
            JsonNode stats = getJson("system_stats", Duration.ofSeconds(3));
            JsonNode device = stats.path("devices").path(0);
            QueueState queue = getQueue(Duration.ofSeconds(3));
            return new GpuHealth(name, true, device.path("name").asString(), device.path("vram_free").asLong(),
                    queue.running().size() + queue.pending().size(), null);
        } catch (IOException | RuntimeException e) {
            return new GpuHealth(name, false, "", 0, 0, e.getClass().getSimpleName());
        }
    }

    /** GET /queue: each entry is [number, prompt_id, prompt, extra_data, outputs_to_execute]. */
    public QueueState getQueue(Duration timeout) throws IOException, InterruptedException {
        JsonNode queue = getJson("queue", timeout);
        var running = new ArrayList<String>();
        var pending = new ArrayList<String>();
        var numbers = new HashMap<String, Double>();
        for (JsonNode entry : queue.path("queue_running")) {
            running.add(entry.path(1).asString());
            numbers.merge(entry.path(1).asString(), entry.path(0).asDouble(), Math::max);
        }
        for (JsonNode entry : queue.path("queue_pending")) {
            pending.add(entry.path(1).asString());
            numbers.merge(entry.path(1).asString(), entry.path(0).asDouble(), Math::max);
        }
        return new QueueState(running, pending, numbers);
    }

    /** GET /history/{prompt_id}: null while the prompt is unknown, queued or running. */
    public JsonNode getHistory(String promptId) throws IOException, InterruptedException {
        JsonNode entry = getJson("history/" + promptId, Duration.ofSeconds(30)).path(promptId);
        return entry.isMissingNode() ? null : entry;
    }

    /** POST /prompt with the job id as prompt_id. The status code decides between retry and dead letter. */
    public Submitted submit(Job job, String clientId) throws IOException, InterruptedException {
        ObjectNode request = JSON.createObjectNode();
        request.set("prompt", job.workflow().deepCopy());
        request.put("client_id", clientId);
        request.put("prompt_id", job.id());
        HttpResponse<String> response = post("prompt", request, Duration.ofSeconds(30));
        return new Submitted(response.statusCode(), response.body());
    }

    /**
     * POST /interrupt for this prompt only, POST /queue to remove it if it hadn't started, then wait until it has
     * left the queue: a retry with the same prompt id must not receive this run's last messages.
     */
    public void cancelPrompt(String promptId) throws IOException, InterruptedException {
        long end = System.nanoTime() + Duration.ofSeconds(10).toNanos();
        post("interrupt", JSON.createObjectNode().put("prompt_id", promptId), Duration.ofSeconds(10));
        ObjectNode delete = JSON.createObjectNode();
        delete.putArray("delete").add(promptId);
        post("queue", delete, Duration.ofSeconds(10));
        while (getQueue(Duration.ofSeconds(10)).contains(promptId)) {
            if (System.nanoTime() > end) {
                throw new IOException("the prompt is still in the queue after 10 s");
            }
            Thread.sleep(50);
        }
    }

    public byte[] view(JsonNode image) throws IOException, InterruptedException {
        String query = "filename=" + encode(image.path("filename").asString())
                + "&subfolder=" + encode(image.path("subfolder").asString(""))
                + "&type=" + encode(image.path("type").asString("output"));
        HttpResponse<byte[]> response = http.send(HttpRequest.newBuilder(baseUri.resolve("view?" + query)).timeout(Duration.ofSeconds(60)).build(),
                HttpResponse.BodyHandlers.ofByteArray());
        if (response.statusCode() != 200) {
            throw new IOException("GET /view: " + response.statusCode());
        }
        return response.body();
    }

    /** GET /ws?clientId=…: connect before posting, reconnect with the same id after a drop. */
    public Socket connect(String clientId) throws IOException, InterruptedException {
        var messages = new LinkedBlockingQueue<JsonNode>();
        URI uri = URI.create(baseUri.toString().replaceFirst("^http", "ws") + "ws?clientId=" + clientId);
        try {
            WebSocket socket = http.newWebSocketBuilder().connectTimeout(Duration.ofSeconds(5)).buildAsync(uri, new Collector(messages)).join();
            return new Socket(socket, messages);
        } catch (CompletionException e) {
            throw new IOException("WebSocket connection failed: " + e.getCause(), e.getCause());
        }
    }

    /** The messages of one connection, in order. A missing node marks the end: closed or broken. */
    public record Socket(WebSocket webSocket, BlockingQueue<JsonNode> messages) {
        static final JsonNode CLOSED = MissingNode.getInstance();

        /** The next text message, null if none arrived within the timeout; throws once the connection is gone. */
        JsonNode receive(Duration timeout) throws IOException, InterruptedException {
            JsonNode message = messages.poll(timeout.toMillis(), TimeUnit.MILLISECONDS);
            if (message != null && message.isMissingNode()) {
                messages.add(message); // stays closed
                throw new IOException("the WebSocket is closed");
            }
            return message;
        }

        void close() {
            webSocket.abort();
        }
    }

    JsonNode getJson(String path, Duration timeout) throws IOException, InterruptedException {
        HttpResponse<String> response = http.send(HttpRequest.newBuilder(baseUri.resolve(path)).timeout(timeout).build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            throw new IOException("GET /" + path + ": " + response.statusCode());
        }
        return JSON.readTree(response.body());
    }

    HttpResponse<String> post(String path, JsonNode body, Duration timeout) throws IOException, InterruptedException {
        return http.send(HttpRequest.newBuilder(baseUri.resolve(path)).timeout(timeout)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(body))).build(), HttpResponse.BodyHandlers.ofString());
    }

    static String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    /** Puts each complete text message in a queue; binary messages (previews) are skipped. */
    static final class Collector implements WebSocket.Listener {
        private final BlockingQueue<JsonNode> messages;
        private final StringBuilder text = new StringBuilder();

        Collector(BlockingQueue<JsonNode> messages) {
            this.messages = messages;
        }

        @Override
        public CompletionStage<?> onText(WebSocket socket, CharSequence data, boolean last) {
            text.append(data);
            if (last) {
                messages.add(JSON.readTree(text.toString()));
                text.setLength(0);
            }
            socket.request(1);
            return null;
        }

        @Override
        public CompletionStage<?> onBinary(WebSocket socket, ByteBuffer data, boolean last) {
            socket.request(1);
            return null;
        }

        @Override
        public CompletionStage<?> onClose(WebSocket socket, int statusCode, String reason) {
            messages.add(Socket.CLOSED);
            return null;
        }

        @Override
        public void onError(WebSocket socket, Throwable error) {
            messages.add(Socket.CLOSED);
        }
    }
}
