// compare_fail/L02Wildcard.java
import java.util.ArrayList;
import java.util.List;

public class L02Wildcard {
    record Instrument(String name) {}

    public static void main(String[] args) {
        List<String> names = new ArrayList<>(List.of("guitar"));
        // ? extends: read as Object, and nothing can be added, the use-site version of out T
        List<? extends Object> objects = names;
        objects.add(new Instrument("piano"));
    }
}
