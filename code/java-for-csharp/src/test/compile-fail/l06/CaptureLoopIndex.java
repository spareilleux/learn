import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;

class Loop {
    static List<Supplier<Integer>> suppliers() {
        List<Supplier<Integer>> result = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            result.add(() -> i);
        }
        return result;
    }
}
// expect: compiler.err.cant.ref.non.effectively.final.var
