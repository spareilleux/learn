package dev.learn.scales.reactive;

import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.Banner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

@ExtendWith(OutputCaptureExtension.class)
class StartupTest {

    @Test
    void startupLog(CapturedOutput output) {
        var application = new SpringApplication(ReactiveScalesApplication.class);
        application.setMainApplicationClass(ReactiveScalesApplication.class);
        application.setBannerMode(Banner.Mode.OFF);
        var context = application.run("--server.port=0");
        // Read the log before closing: the shutdown lines come from another thread, in no fixed order.
        String log = output.getOut();
        context.close();
        Expected.check("startup-log", log.lines()
                .filter(line -> line.contains(" INFO "))
                .map(line -> line.substring(line.indexOf(" INFO "))
                        .replaceAll(" INFO \\d+ --- ", " INFO <pid> --- ")
                        .replaceAll("with PID \\d+ \\(.*\\)", "with PID <pid> (<path>)")
                        .replaceAll("port \\d+", "port <port>")
                        .replaceAll("in \\d+\\.\\d+ seconds \\(process running for \\d+\\.\\d+\\)", "in <n> seconds (process running for <n>)")
                        .replaceAll("Java \\d+(\\.\\d+)*", "Java <version>")
                        .replaceAll("\\s+:", " :"))
                .collect(Collectors.joining("\n")));
    }
}
