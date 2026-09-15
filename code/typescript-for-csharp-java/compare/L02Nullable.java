// compare/L02Nullable.java
import java.util.Map;

public class L02Nullable {
    static String initial(String name) {
        return name.substring(0, 1); // nothing in the type says name can be null
    }

    public static void main(String[] args) {
        var tunings = Map.of("standard", "EADGBE");
        String dropD = tunings.get("drop D");
        try {
            System.out.println(initial(dropD));
        } catch (NullPointerException e) {
            System.out.println("initial(dropD): " + e.getClass().getSimpleName());
        }
    }
}
