// Lesson 3, the Java side: javac L03Closures.java rejects a lambda that captures a changing variable
import java.util.ArrayList;
import java.util.List;
import java.util.function.IntSupplier;

public class L03Closures {
    public static void main(String[] args) {
        List<IntSupplier> suppliers = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            suppliers.add(() -> i);
        }
    }
}
