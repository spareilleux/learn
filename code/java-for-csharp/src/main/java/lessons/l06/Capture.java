package lessons.l06;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;

/** Lesson 6: what lambdas capture, and what this means inside them. */
public class Capture {

    private final String name = "outer";

    void showThis() {
        Runnable lambda = () -> System.out.println("lambda this: " + this.name);
        Runnable anonymous = new Runnable() {
            private final String name = "anonymous";

            @Override
            public void run() {
                System.out.println("anonymous this: " + this.name);
            }
        };
        lambda.run();
        anonymous.run();
    }

    public static void main(String[] args) {
        // Each iteration of an enhanced for loop has its own effectively final variable.
        List<Supplier<Integer>> suppliers = new ArrayList<>();
        for (int value : new int[] {0, 1, 2}) {
            suppliers.add(() -> value);
        }
        System.out.println(suppliers.stream().map(Supplier::get).toList());

        // Lambdas capture values, not variables: mutable state needs an object.
        AtomicInteger clicks = new AtomicInteger();
        Runnable click = clicks::incrementAndGet;
        click.run();
        click.run();
        System.out.println("clicks: " + clicks.get());

        new Capture().showThis();
    }
}
