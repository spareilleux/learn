// compare/L04Variance.java
import java.util.List;

public class L04Variance {
    record Instrument(String name) {}

    public static void main(String[] args) {
        String[] strings = { "E", "A" };
        Object[] objects = strings; // arrays are covariant in Java too
        try {
            objects[0] = 440;
        } catch (ArrayStoreException e) {
            System.out.println("objects[0] = 440: " + e.getClass().getSimpleName());
        }
        List<? extends Object> producer = List.of("E", "A"); // use-site variance: a wildcard
        System.out.println("producer.get(0): " + producer.get(0));
    }
}
