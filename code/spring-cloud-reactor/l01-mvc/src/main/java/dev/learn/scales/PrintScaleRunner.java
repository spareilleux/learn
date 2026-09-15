package dev.learn.scales;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

// Runs once the context has started, only with the "print" profile: a quick way to see the configuration at work.
@Component
@Profile("print")
class PrintScaleRunner implements ApplicationRunner {

    private final ScaleService scales;
    private final ScalesProperties properties;

    PrintScaleRunner(ScaleService scales, ScalesProperties properties) {
        this.scales = scales;
        this.properties = properties;
    }

    @Override
    public void run(ApplicationArguments args) {
        System.out.println("spelling: " + properties.spelling());
        System.out.println(scales.describe("A#", properties.defaultMode()));
    }
}
