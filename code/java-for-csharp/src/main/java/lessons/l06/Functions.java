package lessons.l06;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.function.BiFunction;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.IntBinaryOperator;
import java.util.function.Predicate;
import java.util.function.Supplier;
import java.util.function.ToIntFunction;
import java.util.function.UnaryOperator;

/** Lesson 6: functional interfaces, method references and composition. */
public class Functions {

    record Person(String name, int age) {}

    public static void main(String[] args) {
        // Func<string, int>, Func<int, int, int>, Func<string>, Action<string>, Predicate<string>
        Function<String, Integer> length = s -> s.length();
        BiFunction<Integer, Integer, Integer> add = (a, b) -> a + b;
        Supplier<String> greeting = () -> "hello";
        Consumer<String> print = s -> System.out.println("print: " + s);
        Predicate<String> isEmpty = s -> s.isEmpty();

        // Each interface has its own method name: apply, get, accept, test.
        System.out.println(length.apply("lambda") + " " + add.apply(2, 3) + " " + greeting.get());
        print.accept("consumer");
        System.out.println(isEmpty.test(""));

        // Primitive specialisations avoid boxing.
        ToIntFunction<String> fastLength = String::length;
        IntBinaryOperator multiply = (a, b) -> a * b;
        System.out.println(fastLength.applyAsInt("abc") + " " + multiply.applyAsInt(6, 7));

        // The four kinds of method reference.
        Function<String, Integer> parse = Integer::parseInt;        // static method
        Set<String> jvmLanguages = Set.of("java", "kotlin", "scala");
        Predicate<String> isJvmLanguage = jvmLanguages::contains;   // bound: jvmLanguages.contains(s)
        Function<String, String> upper = String::toUpperCase;       // unbound: s.toUpperCase()
        Supplier<List<String>> newList = ArrayList::new;            // constructor
        System.out.println(parse.apply("42") + " " + isJvmLanguage.test("kotlin") + " " + upper.apply("java"));
        System.out.println(newList.get().size());

        // Composition is a library feature: default methods on the interfaces.
        UnaryOperator<String> trim = String::strip;
        Function<String, Integer> trimmedLength = trim.andThen(String::length);
        System.out.println(trimmedLength.apply("  padded  "));
        Predicate<String> notBlank = Predicate.not(String::isBlank);
        System.out.println(notBlank.and(isJvmLanguage.negate()).test("csharp"));

        var people = new ArrayList<>(List.of(new Person("Ada", 36), new Person("Alan", 41), new Person("Grace", 36)));
        people.sort(Comparator.comparingInt(Person::age).reversed().thenComparing(Person::name));
        System.out.println(people);
    }
}
