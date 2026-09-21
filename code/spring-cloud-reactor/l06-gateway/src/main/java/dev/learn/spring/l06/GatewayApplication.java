package dev.learn.spring.l06;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class GatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }

    @Bean
    RouteLocator courseRoutes(RouteLocatorBuilder routes, @Value("${course.scales-uri}") String scalesUri) {
        return routes.routes()
                .route("scales", route -> route.path("/api/scales/**")
                        .filters(filters -> filters.stripPrefix(1)
                                .addRequestHeader("X-Course", "spring-cloud-gateway"))
                        .uri(scalesUri))
                .build();
    }
}
