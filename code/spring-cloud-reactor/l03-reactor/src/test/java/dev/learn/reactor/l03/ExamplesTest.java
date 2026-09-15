package dev.learn.reactor.l03;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;

/** Runs every example of the lesson and compares what it prints with {@code expected/<Example>.txt}. */
class ExamplesTest {

    @TestFactory
    Stream<DynamicTest> examplesPrintWhatTheLessonShows() {
        return Stream.of(ThreadHops.class, Backpressure.class, ErrorsAndRetries.class, ContextPropagation.class, BlockingCalls.class)
                .map(example -> DynamicTest.dynamicTest(example.getSimpleName(), () -> run(example)));
    }

    private static void run(Class<?> example) throws Exception {
        var buffer = new ByteArrayOutputStream();
        var out = System.out;
        var err = System.err;
        var capture = new PrintStream(buffer, true, StandardCharsets.UTF_8);
        System.setOut(capture);
        System.setErr(capture);
        try {
            example.getMethod("main", String[].class).invoke(null, (Object) new String[0]);
        } finally {
            System.setOut(out);
            System.setErr(err);
        }
        Expected.check(example.getSimpleName(), buffer.toString(StandardCharsets.UTF_8));
    }

    // Schedulers read the system property once, so each run needs a JVM of its own.
    @Test
    void boundedElasticOnPlatformAndVirtualThreads() throws Exception {
        String platform = runInNewJvm(BoundedElasticThreads.class);
        String virtual = runInNewJvm(BoundedElasticThreads.class, "-Dreactor.schedulers.defaultBoundedElasticOnVirtualThreads=true");
        Expected.check("BoundedElasticThreads", "default:\n" + platform + "with the property:\n" + virtual);
    }

    // This JVM has BlockHound's agent; a new one shows what happens without it.
    @Test
    void hiddenBlockingWithAndWithoutBlockHound() throws Exception {
        String without = runInNewJvm(HiddenBlocking.class);
        String with = runInNewJvm(HiddenBlocking.class,
                "-javaagent:" + System.getProperty("blockhound.jar"), "-XX:+AllowRedefinitionToAddDeleteMethods");
        Expected.check("HiddenBlocking", "without BlockHound:\n" + without + "with BlockHound:\n" + with);
    }

    private static String runInNewJvm(Class<?> main, String... jvmOptions) throws Exception {
        List<String> command = new ArrayList<>();
        command.add(Path.of(System.getProperty("java.home"), "bin", "java").toString());
        command.addAll(List.of(jvmOptions));
        command.addAll(List.of("-cp", System.getProperty("java.class.path"), main.getName()));
        // Standard output only: the JVM prints its warnings about agents and deprecated flags on standard error.
        Process process = new ProcessBuilder(command).redirectError(ProcessBuilder.Redirect.DISCARD).start();
        String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        process.waitFor(30, TimeUnit.SECONDS);
        assertEquals(0, process.exitValue(), output);
        return output.replace("\r\n", "\n");
    }
}
