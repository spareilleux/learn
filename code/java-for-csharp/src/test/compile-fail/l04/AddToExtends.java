import java.util.List;

class Totals {
    void addZero(List<? extends Number> numbers) {
        numbers.add(0);
    }
}
// expect: compiler.err.prob.found.req
