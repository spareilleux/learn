package lessons.l07;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/** Lesson 7: the collections framework seen from System.Collections.Generic. */
public class CollectionsTour {

    static void attempt(String label, Runnable action) {
        try {
            action.run();
            System.out.println(label + ": ok");
        } catch (RuntimeException e) {
            System.out.println(label + ": " + e.getClass().getSimpleName());
        }
    }

    public static void main(String[] args) {
        // List.of is unmodifiable, but its type is still List: the error comes at run time.
        List<String> fixed = List.of("a", "b");
        attempt("List.of add", () -> fixed.add("c"));
        attempt("List.of with null", () -> List.of("a", null));

        // Arrays.asList is a fixed-size view that writes through to the array.
        String[] array = {"x", "y"};
        List<String> view = Arrays.asList(array);
        view.set(0, "changed");
        System.out.println(array[0]);
        attempt("Arrays.asList add", () -> view.add("z"));

        // Map.get returns null for a missing key instead of throwing.
        Map<String, Integer> stock = new HashMap<>(Map.of("apples", 3));
        System.out.println(stock.get("pears") + " " + stock.getOrDefault("pears", 0));

        // merge and computeIfAbsent replace the TryGetValue dance.
        Map<String, Integer> counts = new TreeMap<>();
        for (String word : "to be or not to be".split(" ")) {
            counts.merge(word, 1, Integer::sum);
        }
        System.out.println(counts);
        Map<String, List<String>> byInitial = new LinkedHashMap<>();
        for (String word : List.of("tea", "coffee", "tonic")) {
            byInitial.computeIfAbsent(word.substring(0, 1), k -> new ArrayList<>()).add(word);
        }
        System.out.println(byInitial);

        // Java 21 sequenced collections: first, last and a reversed view.
        List<Integer> numbers = new ArrayList<>(List.of(1, 2, 3, 4, 5, 6));
        System.out.println(numbers.getFirst() + " " + numbers.getLast() + " " + numbers.reversed());

        // Removing while iterating fails fast; removeIf is the safe way.
        attempt("remove in for-each", () -> {
            for (Integer n : numbers) {
                if (n % 2 == 0) {
                    numbers.remove(n);
                }
            }
        });
        numbers.removeIf(n -> n % 2 == 0);
        System.out.println(numbers);
    }
}
