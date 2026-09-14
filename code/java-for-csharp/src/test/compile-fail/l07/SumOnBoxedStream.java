import java.util.List;

class Totals {
    static int total(List<Integer> quantities) {
        return quantities.stream().sum();
    }
}
// expect: compiler.err.cant.resolve.location.args
