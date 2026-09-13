package lessons.l04;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;

/** Lesson 4: generic type arguments are erased at run time. */
public class Erasure {

    // No `new T()`: pass a factory instead.
    static <T> List<T> filled(int count, Supplier<T> factory) {
        var list = new ArrayList<T>();
        for (int i = 0; i < count; i++) {
            list.add(factory.get());
        }
        return list;
    }

    // No `typeof(T)`: pass a Class<T> token when the type is needed at run time.
    static <T> T firstOfType(List<?> items, Class<T> type) {
        for (Object item : items) {
            if (type.isInstance(item)) {
                return type.cast(item);
            }
        }
        return null;
    }

    @SuppressWarnings({"rawtypes", "unchecked"}) // deliberately unsafe: the lesson explains heap pollution
    static void pollute(List<String> names) {
        List raw = names;
        raw.add(42);
    }

    public static void main(String[] args) {
        List<String> strings = new ArrayList<>();
        List<Integer> numbers = new ArrayList<>();
        System.out.println(strings.getClass() == numbers.getClass());
        System.out.println(strings.getClass().getName());

        System.out.println(filled(3, StringBuilder::new).size());
        List<Object> mixed = List.of(1, "two", 3.0);
        System.out.println(firstOfType(mixed, String.class));

        var names = new ArrayList<>(List.of("Ada"));
        pollute(names);
        System.out.println(names.size());
        try {
            String second = names.get(1);
            System.out.println(second);
        } catch (ClassCastException e) {
            System.out.println("ClassCastException: " + e.getMessage());
        }
    }
}
