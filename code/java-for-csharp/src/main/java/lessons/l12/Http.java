package lessons.l12;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

/** Lesson 12: java.net.http.HttpClient, where C# has HttpClient, against a local server. */
public class Http {

    static void respond(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.sendResponseHeaders(status, bytes.length == 0 ? -1 : bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }

    public static void main(String[] args) throws IOException, InterruptedException {
        // The JDK's own small HTTP server, in the jdk.httpserver module, on a free port.
        HttpServer server = HttpServer.create(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0), 0);
        server.createContext("/old", exchange -> {
            exchange.getResponseHeaders().add("Location", "/new");
            respond(exchange, 302, "");
        });
        server.createContext("/new", exchange -> respond(exchange, 200, "moved here"));
        server.createContext("/missing", exchange -> respond(exchange, 404, ""));
        server.createContext("/slow", exchange -> {
            try {
                Thread.sleep(1_000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            respond(exchange, 200, "too late");
        });
        server.start();
        String base = "http://127.0.0.1:" + server.getAddress().getPort();

        // HttpClient is AutoCloseable since Java 21.
        try (HttpClient client = HttpClient.newHttpClient()) {
            System.out.println("follows redirects: " + client.followRedirects() + ", connect timeout: " + client.connectTimeout());

            HttpResponse<String> old = client.send(HttpRequest.newBuilder(URI.create(base + "/old")).build(), HttpResponse.BodyHandlers.ofString());
            System.out.println("GET /old: " + old.statusCode() + ", Location: " + old.headers().firstValue("Location").orElseThrow());
            System.out.println("client version: " + client.version() + ", response version: " + old.version());

            // An error status is a normal response, not an exception.
            HttpResponse<String> missing = client.send(HttpRequest.newBuilder(URI.create(base + "/missing")).build(), HttpResponse.BodyHandlers.ofString());
            System.out.println("GET /missing: " + missing.statusCode());

            // No timeout unless the request sets one.
            try {
                client.send(HttpRequest.newBuilder(URI.create(base + "/slow")).timeout(Duration.ofMillis(100)).build(), HttpResponse.BodyHandlers.ofString());
            } catch (HttpTimeoutException e) {
                System.out.println("HttpTimeoutException: " + e.getMessage());
            }
        }

        // Following redirects is opt-in; sendAsync returns a CompletableFuture.
        try (HttpClient client = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).build()) {
            HttpResponse<String> response = client.sendAsync(HttpRequest.newBuilder(URI.create(base + "/old")).build(), HttpResponse.BodyHandlers.ofString()).join();
            System.out.println("GET /old, following redirects: " + response.statusCode() + " " + response.body() + " from " + response.uri().getPath());
        }
        server.stop(0);
    }
}
