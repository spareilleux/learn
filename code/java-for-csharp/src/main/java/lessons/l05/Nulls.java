package lessons.l05;

import java.util.Map;
import java.util.Objects;
import java.util.Optional;

/** Lesson 5: null, helpful NullPointerException messages and Optional. */
public class Nulls {

    record Address(String city) {}

    record Customer(String name, Address address) {}

    static final Map<String, Customer> CUSTOMERS = Map.of(
            "ada", new Customer("Ada", new Address("London")),
            "alan", new Customer("Alan", null));

    static Customer lookup(String id) {
        return CUSTOMERS.get(id); // null when the id is unknown
    }

    static Optional<Customer> find(String id) {
        return Optional.ofNullable(CUSTOMERS.get(id));
    }

    static String defaultCity() {
        System.out.println("  computing default city");
        return "unknown";
    }

    public static void main(String[] args) {
        try {
            System.out.println(lookup("grace").name().length());
        } catch (NullPointerException e) {
            System.out.println(e.getMessage());
        }

        try {
            new Customer(Objects.requireNonNull(null, "name"), null);
        } catch (NullPointerException e) {
            System.out.println("requireNonNull: " + e.getMessage());
        }

        // C#: customer?.Address?.City ?? "unknown"
        for (String id : new String[] {"ada", "alan", "grace"}) {
            String city = find(id).map(Customer::address).map(Address::city).orElse("unknown");
            System.out.println(id + " -> " + city);
        }

        // orElse evaluates its argument every time; orElseGet only when the Optional is empty.
        System.out.println("orElse:");
        find("ada").map(Customer::name).orElse(defaultCity());
        System.out.println("orElseGet:");
        find("ada").map(Customer::name).orElseGet(Nulls::defaultCity);

        try {
            find("grace").orElseThrow();
        } catch (RuntimeException e) {
            System.out.println(e.getClass().getSimpleName() + ": " + e.getMessage());
        }
    }
}
