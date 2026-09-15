package dev.learn.scales.reactive;

import dev.learn.scales.reactive.ScaleCatalog.ScaleView;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

/** Calls the scales API over HTTP, as another service would: HttpClient with a base address. */
public class ChordChartClient {

    private final WebClient client;

    public ChordChartClient(WebClient.Builder builder, String baseUrl) {
        this.client = builder.baseUrl(baseUrl).build();
    }

    public Mono<ScaleView> scale(String root, String mode) {
        return client.get()
                .uri(uri -> uri.path("/scales/{root}").queryParam("mode", mode).build(root))
                .retrieve()
                .bodyToMono(ScaleView.class);
    }

    /** A chord chart such as "| Dm | G | C |" for degrees 2, 5 and 1 of C major, counted from 1. */
    public Mono<String> chart(String root, String mode, List<Integer> degrees) {
        return scale(root, mode).map(view -> degrees.stream()
                .map(degree -> view.chords().get(degree - 1))
                .collect(Collectors.joining(" | ", "| ", " |")));
    }
}
