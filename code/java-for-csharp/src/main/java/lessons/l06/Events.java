package lessons.l06;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/** Lesson 6: Java has no events or multicast delegates; a listener list takes their place. */
public class Events {

    static class PriceFeed {
        private final List<Consumer<Double>> listeners = new ArrayList<>();

        void addListener(Consumer<Double> listener) {
            listeners.add(listener);
        }

        boolean removeListener(Consumer<Double> listener) {
            return listeners.remove(listener);
        }

        void publish(double price) {
            listeners.forEach(listener -> listener.accept(price));
        }
    }

    static class Display {
        void onPrice(double price) {
            System.out.println("display: " + price);
        }
    }

    public static void main(String[] args) {
        var feed = new PriceFeed();
        var display = new Display();

        feed.addListener(display::onPrice);
        feed.publish(10.5);

        // Each evaluation of display::onPrice creates a new object, and lambdas don't override equals.
        System.out.println("removed: " + feed.removeListener(display::onPrice));
        Consumer<Double> first = display::onPrice;
        Consumer<Double> second = display::onPrice;
        System.out.println("equal: " + first.equals(second));
        feed.publish(11.0);

        // Keep the reference you registered if you want to remove it.
        Consumer<Double> listener = display::onPrice;
        var other = new PriceFeed();
        other.addListener(listener);
        System.out.println("removed: " + other.removeListener(listener));
        other.publish(12.0);
    }
}
