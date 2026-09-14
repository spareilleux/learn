package lessons.l07;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;
import java.util.stream.Gatherers;
import java.util.stream.IntStream;
import java.util.stream.Stream;

/** Lesson 7: streams compared with LINQ. */
public class Streams {

    record Order(String customer, String product, int quantity, double price) {
        double total() {
            return quantity * price;
        }
    }

    static final List<Order> ORDERS = List.of(
            new Order("ada", "keyboard", 1, 80.0),
            new Order("alan", "mouse", 2, 25.0),
            new Order("ada", "monitor", 2, 199.0),
            new Order("grace", "mouse", 1, 25.0),
            new Order("alan", "cable", 5, 4.5));

    public static void main(String[] args) {
        // Where / Select / OrderBy / ToList
        List<String> bigOrders = ORDERS.stream()
                .filter(o -> o.total() >= 50)
                .sorted(Comparator.comparingDouble(Order::total).reversed())
                .map(o -> o.customer() + ":" + o.product())
                .toList();
        System.out.println(bigOrders);

        // GroupBy + Sum, with a sorted map for a stable order
        Map<String, Double> totals = ORDERS.stream()
                .collect(Collectors.groupingBy(Order::customer, TreeMap::new, Collectors.summingDouble(Order::total)));
        System.out.println(totals);

        // Any / All / First / Distinct / Count
        System.out.println(ORDERS.stream().anyMatch(o -> o.quantity() > 4) + " "
                + ORDERS.stream().allMatch(o -> o.price() > 1) + " "
                + ORDERS.stream().filter(o -> o.product().equals("mouse")).findFirst().map(Order::customer).orElse("none") + " "
                + ORDERS.stream().map(Order::product).distinct().count());

        // SelectMany, Chunk (Java 24 gatherers) and primitive streams
        System.out.println(Stream.of("a,b", "c").flatMap(s -> Stream.of(s.split(","))).toList());
        System.out.println(IntStream.rangeClosed(1, 7).boxed().gather(Gatherers.windowFixed(3)).toList());
        var stats = ORDERS.stream().mapToInt(Order::quantity).summaryStatistics();
        System.out.println("quantities: sum " + stats.getSum() + ", min " + stats.getMin() + ", max " + stats.getMax());

        // Streams are lazy: nothing runs until a terminal operation, and elements flow one at a time.
        Stream<String> pipeline = Stream.of("one", "two", "three")
                .peek(s -> System.out.println("  filter " + s))
                .filter(s -> s.length() == 3)
                .peek(s -> System.out.println("  map " + s))
                .map(String::toUpperCase);
        System.out.println("pipeline built");
        System.out.println(pipeline.findFirst().orElseThrow());

        // A stream can be consumed only once, unlike an IEnumerable.
        Stream<String> once = Stream.of("x");
        once.count();
        try {
            once.count();
        } catch (IllegalStateException e) {
            System.out.println(e.getMessage());
        }

        // toList() is unmodifiable; toMap rejects duplicate keys.
        try {
            bigOrders.add("more");
        } catch (UnsupportedOperationException e) {
            System.out.println("toList() result is unmodifiable");
        }
        try {
            ORDERS.stream().collect(Collectors.toMap(Order::customer, Order::product));
        } catch (IllegalStateException e) {
            System.out.println(e.getMessage());
        }
    }
}
