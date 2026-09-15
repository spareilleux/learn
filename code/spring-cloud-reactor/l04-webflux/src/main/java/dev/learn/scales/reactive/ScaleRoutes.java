package dev.learn.scales.reactive;

import static org.springframework.web.reactive.function.server.RouterFunctions.route;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;

// Functional endpoints: routes declared in code, like app.MapGet(...) in a minimal API.
// The method is not called scaleRoutes: that is already the bean name of this class.
@Configuration
class ScaleRoutes {

    @Bean
    RouterFunction<ServerResponse> scaleRouter(ScaleCatalog catalog) {
        return route()
                .GET("/fn/scales/{root}", request -> catalog
                        .describe(request.pathVariable("root"), request.queryParam("mode").orElse("ionian"))
                        .flatMap(view -> ServerResponse.ok().bodyValue(view)))
                .onError(IllegalArgumentException.class, (error, request) -> {
                    ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, error.getMessage());
                    return ServerResponse.badRequest().bodyValue(problem);
                })
                .build();
    }
}
