package lessons.l04;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/** Lesson 4: use-site variance with wildcards, and the array covariance hole. */
public class Variance {

    // Reads numbers: any List of a subtype of Number is accepted ("producer extends").
    static double sum(List<? extends Number> numbers) {
        double total = 0;
        for (Number n : numbers) {
            total += n.doubleValue();
        }
        return total;
    }

    // Writes integers: any List that can hold an Integer is accepted ("consumer super").
    static void addOneTwoThree(List<? super Integer> target) {
        target.add(1);
        target.add(2);
        target.add(3);
    }

    // A bounded type parameter, like `where T : IComparable<T>`.
    static <T extends Comparable<? super T>> T max(List<T> items) {
        T best = items.getFirst();
        for (T item : items) {
            if (item.compareTo(best) > 0) {
                best = item;
            }
        }
        return best;
    }

    public static void main(String[] args) {
        List<Integer> ints = List.of(1, 2, 3);
        List<Double> doubles = List.of(1.5, 2.5);
        System.out.println(sum(ints) + " " + sum(doubles));

        List<Number> numbers = new ArrayList<>();
        List<Object> objects = new ArrayList<>();
        addOneTwoThree(numbers);
        addOneTwoThree(objects);
        System.out.println(numbers + " " + objects);

        System.out.println(max(List.of("pear", "apple", "quince")));

        var byLength = Comparator.comparingInt(String::length);
        System.out.println(List.of("kiwi", "fig", "banana").stream().max(byLength).orElseThrow());

        // Arrays are covariant, so this compiles and fails at run time.
        Object[] slots = new String[2];
        try {
            slots[0] = 42;
        } catch (ArrayStoreException e) {
            System.out.println("ArrayStoreException: " + e.getMessage());
        }
    }
}
