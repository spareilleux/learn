package lessons.l09;

import java.util.concurrent.Executors;

/** Lesson 9: ThreadLocal and ScopedValue, where C# uses AsyncLocal. */
public class ScopedValues {

    static final ThreadLocal<String> CURRENT_USER = new ThreadLocal<>();

    // A ScopedValue is bound for the duration of a call, then unbound again.
    static final ScopedValue<String> REQUEST_USER = ScopedValue.newInstance();

    static String greet() {
        return "hello " + (REQUEST_USER.isBound() ? REQUEST_USER.get() : "nobody");
    }

    public static void main(String[] args) throws Exception {
        CURRENT_USER.set("ada");
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            // A ThreadLocal belongs to one thread: a task on another thread doesn't see it.
            System.out.println("caller thread: " + CURRENT_USER.get());
            System.out.println("executor task: " + executor.submit(CURRENT_USER::get).get());
        } finally {
            CURRENT_USER.remove();
        }

        ScopedValue.where(REQUEST_USER, "grace").run(() -> {
            System.out.println("inside the scope: " + greet());
            ScopedValue.where(REQUEST_USER, "alan").run(() -> System.out.println("nested scope: " + greet()));
            System.out.println("back in the outer scope: " + greet());
        });
        System.out.println("after the scope: " + greet());

        // Scoped values don't flow into an ordinary executor either: that needs structured concurrency (preview).
        ScopedValue.where(REQUEST_USER, "grace").run(() -> {
            try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
                System.out.println("executor task in the scope: " + executor.submit(ScopedValues::greet).get());
            } catch (Exception e) {
                throw new IllegalStateException(e);
            }
        });
    }
}
