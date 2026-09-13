package lessons.l04;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.IntStream;

/** Lesson 4: generics over primitives box every element. */
public class Boxing {
    public static void main(String[] args) {
        List<Integer> numbers = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            numbers.add(i * 10);
        }

        // remove(int) removes by index; remove(Object) removes by value.
        numbers.remove(1);
        System.out.println(numbers);
        numbers.remove(Integer.valueOf(30));
        System.out.println(numbers);

        // Primitive streams avoid boxing for numeric pipelines.
        int total = IntStream.rangeClosed(1, 100).sum();
        System.out.println(total);
    }
}
