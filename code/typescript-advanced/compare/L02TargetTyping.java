// compare/L02TargetTyping.java
import java.util.ArrayList;
import java.util.List;

public class L02TargetTyping {
    // Java infers T from the target type, as tsc does from the declared type of the variable
    static <T> List<T> emptyList() {
        return new ArrayList<>();
    }

    public static void main(String[] args) {
        List<String> chords = emptyList();
        chords.add("Cmaj7");
        System.out.println(chords);
    }
}
