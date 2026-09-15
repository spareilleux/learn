// Lesson 3, the Java side: java L03MethodRef.java (Java 25)
import java.util.ArrayList;
import java.util.List;
import java.util.function.IntSupplier;
import java.util.function.Supplier;

class Player {
    String name = "GA";

    String play() {
        return name + " plays";
    }
}

void main() {
    List<IntSupplier> suppliers = new ArrayList<>();
    for (int i = 0; i < 3; i++) {
        int copy = i; // effectively final: one per iteration
        suppliers.add(() -> copy);
    }
    IO.println("copies: " + suppliers.stream().map(s -> String.valueOf(s.getAsInt())).toList());

    // A bound method reference keeps its object
    Supplier<String> play = new Player()::play;
    IO.println("method reference: " + play.get());
}
