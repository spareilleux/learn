package lessons.l12;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Lesson 12 exercise solutions. */
class SolutionsTest {

    static LocalDate addBusinessDays(LocalDate start, int days) {
        LocalDate date = start;
        int added = 0;
        while (added < days) {
            date = date.plusDays(1);
            if (date.getDayOfWeek() != DayOfWeek.SATURDAY && date.getDayOfWeek() != DayOfWeek.SUNDAY) {
                added++;
            }
        }
        return date;
    }

    @Test
    void exercise1BusinessDays() {
        LocalDate friday = LocalDate.of(2026, 9, 11);
        assertEquals(LocalDate.of(2026, 9, 14), addBusinessDays(friday, 1));
        assertEquals(LocalDate.of(2026, 9, 18), addBusinessDays(friday, 5));
        assertEquals(friday, addBusinessDays(friday, 0));
    }

    static List<BigDecimal> split(BigDecimal total, int people) {
        BigDecimal share = total.divide(BigDecimal.valueOf(people), 2, RoundingMode.DOWN);
        BigDecimal cent = new BigDecimal("0.01");
        int extraCents = total.subtract(share.multiply(BigDecimal.valueOf(people))).divide(cent).intValueExact();
        List<BigDecimal> shares = new ArrayList<>();
        for (int i = 0; i < people; i++) {
            shares.add(i < extraCents ? share.add(cent) : share);
        }
        return shares;
    }

    @Test
    void exercise2SplitTheBill() {
        List<BigDecimal> shares = split(new BigDecimal("100.00"), 3);
        assertEquals(List.of(new BigDecimal("33.34"), new BigDecimal("33.33"), new BigDecimal("33.33")), shares);
        assertEquals(0, shares.stream().reduce(BigDecimal.ZERO, BigDecimal::add).compareTo(new BigDecimal("100.00")));
        assertEquals(List.of(new BigDecimal("5.00"), new BigDecimal("5.00")), split(new BigDecimal("10.00"), 2));
    }

    static String getString(HttpClient client, URI uri) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(100)).build();
        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() > 299) {
            throw new IOException("Response status code does not indicate success: " + response.statusCode());
        }
        return response.body();
    }

    @Test
    void exercise3GetString() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0), 0);
        server.createContext("/old", exchange -> {
            exchange.getResponseHeaders().add("Location", "/new");
            exchange.sendResponseHeaders(302, -1);
            exchange.close();
        });
        server.createContext("/new", exchange -> {
            byte[] body = "moved here".getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, body.length);
            exchange.getResponseBody().write(body);
            exchange.close();
        });
        server.createContext("/missing", exchange -> {
            exchange.sendResponseHeaders(404, -1);
            exchange.close();
        });
        server.start();
        String base = "http://127.0.0.1:" + server.getAddress().getPort();
        try (HttpClient client = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).build()) {
            assertEquals("moved here", getString(client, URI.create(base + "/old")));
            var e = assertThrows(IOException.class, () -> getString(client, URI.create(base + "/missing")));
            assertEquals("Response status code does not indicate success: 404", e.getMessage());
        } finally {
            server.stop(0);
        }
    }
}
