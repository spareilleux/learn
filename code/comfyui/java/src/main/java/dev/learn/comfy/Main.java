package dev.learn.comfy;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.WebSocket;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;
import java.util.UUID;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

import javax.imageio.ImageIO;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.ObjectNode;

/** ComfyUI course, lesson 4: queue a workflow, follow it on the WebSocket, download its images. */
public final class Main {
    private static final ObjectMapper JSON = JsonMapper.builder().build();

    public static void main(String[] args) throws Exception {
        if (args.length < 3 || !args[0].equals("run")) {
            System.err.println("usage: java -jar comfy.jar run <server> <api.json> [--set node.input=json]... [--out dir]");
            System.exit(2);
        }
        System.exit(run(URI.create(args[1]), Path.of(args[2]), args));
    }

    static int run(URI server, Path workflowPath, String[] args) throws Exception {
        var workflow = (ObjectNode) JSON.readTree(workflowPath.toFile());
        Path outDir = Path.of("out");
        for (int i = 3; i < args.length; i += 2) {
            switch (args[i]) {
                case "--out" -> outDir = Path.of(args[i + 1]);
                case "--set" -> {
                    // --set 3.seed=43 or --set 6.text="a lighthouse"
                    String[] parts = args[i + 1].split("=", 2);
                    String[] target = parts[0].split("\\.", 2);
                    JsonNode value;
                    try {
                        value = JSON.readTree(parts[1]);
                    } catch (tools.jackson.core.JacksonException e) {
                        value = JSON.getNodeFactory().stringNode(parts[1]);
                    }
                    ((ObjectNode) workflow.get(target[0]).get("inputs")).set(target[1], value);
                }
                default -> throw new IllegalArgumentException("unknown option " + args[i]);
            }
        }

        var http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();

        // Connect first: the server sends a prompt's events only to the client id it was queued with.
        String clientId = UUID.randomUUID().toString().replace("-", "");
        var messages = new LinkedBlockingQueue<Message>();
        URI wsUri = URI.create(server.toString().replaceFirst("^http", "ws") + "/ws?clientId=" + clientId);
        WebSocket socket = http.newWebSocketBuilder().buildAsync(wsUri, new Collector(messages)).join();

        String promptId = UUID.randomUUID().toString();
        ObjectNode request = JSON.createObjectNode();
        request.set("prompt", workflow);
        request.put("client_id", clientId);
        request.put("prompt_id", promptId);
        HttpResponse<String> response = http.send(
                HttpRequest.newBuilder(server.resolve("/prompt"))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(request)))
                        .build(),
                HttpResponse.BodyHandlers.ofString());
        System.out.println("POST /prompt: " + response.statusCode());
        JsonNode body = JSON.readTree(response.body());
        if (response.statusCode() != 200) {
            System.out.println("error " + body.path("error").path("type").asString() + ": " + body.path("error").path("message").asString());
            for (var node : body.path("node_errors").properties()) {
                for (JsonNode error : node.getValue().path("errors")) {
                    System.out.printf("  node %s (%s): %s: %s%n", node.getKey(), node.getValue().path("class_type").asString(),
                            error.path("type").asString(), error.path("details").asString());
                }
            }
            socket.abort();
            return 1;
        }

        String outcome = followEvents(messages, promptId);
        socket.sendClose(WebSocket.NORMAL_CLOSURE, "done").join();
        if (!outcome.equals("execution_success")) {
            return 1;
        }

        JsonNode history = JSON.readTree(get(http, server.resolve("/history/" + promptId), HttpResponse.BodyHandlers.ofString()));
        Files.createDirectories(outDir);
        for (var output : history.path(promptId).path("outputs").properties()) {
            for (JsonNode image : output.getValue().path("images")) {
                String filename = image.path("filename").asString();
                String subfolder = image.path("subfolder").asString();
                String query = "filename=" + URLEncoder.encode(filename, StandardCharsets.UTF_8)
                        + "&subfolder=" + URLEncoder.encode(subfolder, StandardCharsets.UTF_8)
                        + "&type=" + image.path("type").asString();
                byte[] png = get(http, server.resolve("/view?" + query), HttpResponse.BodyHandlers.ofByteArray());
                Path path = outDir.resolve(filename);
                Files.write(path, png);
                var picture = ImageIO.read(path.toFile());
                System.out.printf("GET /view node %s: %s/%s, %d x %d, pixel SHA-256 %s%n", output.getKey(), subfolder, filename,
                        picture.getWidth(), picture.getHeight(), pixelHash(picture));
            }
        }
        return 0;
    }

    static String followEvents(BlockingQueue<Message> messages, String promptId) throws InterruptedException {
        while (true) {
            Message message = messages.poll(20, TimeUnit.MINUTES);
            if (message == null) {
                throw new IllegalStateException("no message for 20 minutes");
            }
            if (message.binary() != null) {
                ByteBuffer bytes = message.binary();
                System.out.printf("binary message: type %d, %d bytes%n", bytes.getInt(0), bytes.remaining());
                continue;
            }
            JsonNode json = JSON.readTree(message.text());
            String type = json.path("type").asString();
            JsonNode data = json.path("data");
            if (data.has("prompt_id") && !data.path("prompt_id").asString().equals(promptId)) {
                continue;
            }
            switch (type) {
                case "status" -> {
                    // The first status answers the connection; how many follow depends on timing.
                    if (data.has("sid")) {
                        System.out.println("status: connected, queue_remaining " + data.path("status").path("exec_info").path("queue_remaining").asInt());
                    }
                }
                case "execution_start" -> System.out.println("execution_start");
                case "execution_cached" -> System.out.println("execution_cached: " + join(data.path("nodes")));
                case "executing" -> System.out.println("executing: node " + data.path("node").asString());
                case "progress" -> System.out.printf("progress: node %s, %d/%d%n", data.path("node").asString(), data.path("value").asInt(), data.path("max").asInt());
                case "progress_state" -> { } // the state of every node so far, sent again at each change
                case "executed" -> System.out.println("executed: node " + data.path("node").asString() + ", "
                        + StreamSupport.stream(data.path("output").path("images").spliterator(), false)
                                .map(i -> i.path("subfolder").asString() + "/" + i.path("filename").asString())
                                .collect(Collectors.joining(", ")));
                case "execution_success" -> {
                    System.out.println("execution_success");
                    return type;
                }
                case "execution_error" -> {
                    System.out.printf("execution_error: node %s (%s): %s%n", data.path("node_id").asString(),
                            data.path("node_type").asString(), data.path("exception_message").asString());
                    return type;
                }
                case "execution_interrupted" -> {
                    System.out.println("execution_interrupted: node " + data.path("node_id").asString());
                    return type;
                }
                default -> System.out.println(type);
            }
        }
    }

    static String join(JsonNode array) {
        return StreamSupport.stream(array.spliterator(), false).map(JsonNode::asString).collect(Collectors.joining(", ", "[", "]"));
    }

    static <T> T get(HttpClient http, URI uri, HttpResponse.BodyHandler<T> handler) throws IOException, InterruptedException {
        HttpResponse<T> response = http.send(HttpRequest.newBuilder(uri).build(), handler);
        if (response.statusCode() != 200) {
            throw new IOException("GET " + uri + ": " + response.statusCode());
        }
        return response.body();
    }

    // The same bytes the C# tool hashes: R, G, B for each pixel, row by row.
    static String pixelHash(java.awt.image.BufferedImage picture) throws NoSuchAlgorithmException {
        var digest = MessageDigest.getInstance("SHA-256");
        for (int y = 0; y < picture.getHeight(); y++) {
            for (int x = 0; x < picture.getWidth(); x++) {
                int rgb = picture.getRGB(x, y);
                digest.update(new byte[] {(byte) (rgb >> 16), (byte) (rgb >> 8), (byte) rgb});
            }
        }
        return HexFormat.of().formatHex(digest.digest()).substring(0, 16);
    }

    record Message(String text, ByteBuffer binary) { }

    /** Puts each complete message in a queue; a message can arrive in several parts. */
    static final class Collector implements WebSocket.Listener {
        private final BlockingQueue<Message> messages;
        private final StringBuilder text = new StringBuilder();
        private ByteBuffer binary = ByteBuffer.allocate(0);

        Collector(BlockingQueue<Message> messages) {
            this.messages = messages;
        }

        @Override
        public CompletionStage<?> onText(WebSocket socket, CharSequence data, boolean last) {
            text.append(data);
            if (last) {
                messages.add(new Message(text.toString(), null));
                text.setLength(0);
            }
            socket.request(1);
            return null;
        }

        @Override
        public CompletionStage<?> onBinary(WebSocket socket, ByteBuffer data, boolean last) {
            binary = ByteBuffer.allocate(binary.remaining() + data.remaining()).put(binary).put(data).flip();
            if (last) {
                messages.add(new Message(null, binary));
                binary = ByteBuffer.allocate(0);
            }
            socket.request(1);
            return null;
        }
    }
}
