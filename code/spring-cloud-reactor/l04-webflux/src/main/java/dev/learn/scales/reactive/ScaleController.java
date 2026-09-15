package dev.learn.scales.reactive;

import dev.learn.scales.reactive.ScaleCatalog.ScaleView;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

// The annotations of lesson 1's controller; only the return types change.
@RestController
@RequestMapping("/scales")
class ScaleController {

    private final ScaleCatalog catalog;

    ScaleController(ScaleCatalog catalog) {
        this.catalog = catalog;
    }

    // A Mono is a Task<ScaleView>: WebFlux subscribes to it and writes the value when it arrives.
    @GetMapping("/{root}")
    Mono<ScaleView> scale(@PathVariable String root, @RequestParam(defaultValue = "ionian") String mode) {
        return catalog.describe(root, mode);
    }

    // A Flux with a streaming media type is written element by element, one JSON document per line.
    @GetMapping(value = "/{root}/modes", produces = MediaType.APPLICATION_NDJSON_VALUE)
    Flux<ScaleView> modes(@PathVariable String root) {
        return catalog.allModes(root);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    ProblemDetail badName(IllegalArgumentException e) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, e.getMessage());
        problem.setTitle("Unknown note or mode");
        return problem;
    }
}
