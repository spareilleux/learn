package dev.learn.scales;

import dev.learn.music.Mode;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import org.springframework.stereotype.Component;

// IHealthCheck: Actuator adds every HealthIndicator bean to /actuator/health, named after the bean.
@Component
class ScaleCatalogHealthIndicator implements HealthIndicator {

    @Override
    public Health health() {
        int modes = Mode.values().length;
        return modes == 7
                ? Health.up().withDetail("modes", modes).build()
                : Health.down().withDetail("modes", modes).build();
    }
}
