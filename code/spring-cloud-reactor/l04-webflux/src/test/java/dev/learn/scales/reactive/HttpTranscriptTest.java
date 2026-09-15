package dev.learn.scales.reactive;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.server.LocalServerPort;

/** The raw responses the lesson quotes, read with the JDK's HttpClient so that nothing reformats them. */
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT, properties = "progressions.beat=20ms")
class HttpTranscriptTest {

    @LocalServerPort
    int port;

    private final HttpClient client = HttpClient.newHttpClient();

    private String get(String path) throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path)).build();
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        return "GET " + path + "\n"
                + response.statusCode() + " " + response.headers().firstValue("Content-Type").orElse("") + "\n"
                + response.body() + "\n\n";
    }

    @Test
    void annotatedController() throws Exception {
        Expected.check("http-annotated", get("/scales/D?mode=dorian") + get("/scales/H"));
    }

    @Test
    void functionalEndpoint() throws Exception {
        Expected.check("http-functional", get("/fn/scales/Eb?mode=lydian") + get("/fn/scales/H"));
    }

    @Test
    void streams() throws Exception {
        Expected.check("http-ndjson", get("/scales/C/modes"));
        Expected.check("http-sse", get("/progressions/G"));
    }
}
