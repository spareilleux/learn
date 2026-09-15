package dev.learn.scales;

import dev.learn.broken.ambiguous.TwoSpellersApplication;
import dev.learn.broken.missing.MissingBeanApplication;
import java.util.Arrays;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

import static org.junit.jupiter.api.Assertions.assertThrows;

/** Starts applications the way main() does and keeps the log lines the lesson quotes. */
@ExtendWith(OutputCaptureExtension.class)
class StartupTest {

    @Test
    void startupLog(CapturedOutput output) {
        var application = new SpringApplication(ScalesApplication.class);
        // In a test, the class that called main() is Surefire's; java -jar logs ScalesApplication here.
        application.setMainApplicationClass(ScalesApplication.class);
        application.setBannerMode(org.springframework.boot.Banner.Mode.OFF);
        application.run("--server.port=0").close();
        String lines = output.getOut().lines()
                .filter(line -> line.contains(" INFO "))
                .map(StartupTest::normalizeLogLine)
                .collect(Collectors.joining("\n"));
        Expected.check("startup-log", lines);
    }

    @Test
    void missingBean(CapturedOutput output) {
        assertThrows(Exception.class, () -> nonWeb(MissingBeanApplication.class).run());
        Expected.check("failure-missing-bean", failureReport(output));
    }

    @Test
    void twoCandidates(CapturedOutput output) {
        assertThrows(Exception.class, () -> nonWeb(TwoSpellersApplication.class).run());
        Expected.check("failure-two-beans", failureReport(output));
    }

    @Test
    void invalidConfiguration(CapturedOutput output) {
        assertThrows(Exception.class, () -> nonWeb(ScalesApplication.class).run("--scales.default-mode="));
        Expected.check("failure-validation", failureReport(output));
    }

    private static SpringApplication nonWeb(Class<?> source) {
        var application = new SpringApplication(source);
        application.setWebApplicationType(WebApplicationType.NONE);
        application.setBannerMode(org.springframework.boot.Banner.Mode.OFF);
        return application;
    }

    /** The block Spring Boot's failure analyzers print, from the frame line to the end of the "Action" paragraph. */
    private static String failureReport(CapturedOutput output) {
        var lines = Arrays.asList(output.getAll().replace("\r\n", "\n").split("\n"));
        int start = lines.indexOf("***************************");
        int action = lines.subList(start, lines.size()).indexOf("Action:") + start;
        // "Action:", a blank line, then the advice up to the next blank line.
        int end = action + 2;
        while (end < lines.size() && !lines.get(end).isBlank()) {
            end++;
        }
        return lines.subList(start, end).stream().map(String::stripTrailing).collect(Collectors.joining("\n"));
    }

    /** Keeps level, logger and message; replaces what changes from one run or machine to the next. */
    static String normalizeLogLine(String line) {
        String message = line.substring(line.indexOf(" INFO "));
        return message
                .replaceAll(" INFO \\d+ --- ", " INFO <pid> --- ")
                .replaceAll("with PID \\d+ \\(.*\\)", "with PID <pid> (<path>)")
                .replaceAll("port \\d+", "port <port>")
                .replaceAll("in \\d+\\.\\d+ seconds \\(process running for \\d+\\.\\d+\\)", "in <n> seconds (process running for <n>)")
                .replaceAll("completed in \\d+ ms", "completed in <n> ms")
                .replaceAll("Apache Tomcat/[\\d.]+", "Apache Tomcat/<version>")
                .replaceAll("Java \\d+(\\.\\d+)*", "Java <version>")
                .replaceAll("\\s+:", " :");
    }
}
