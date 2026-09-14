import java.util.List;

class First {
    static String firstLong(List<String> words) {
        return words.stream().filter(w -> w.length() > 3).findFirst();
    }
}
// expect: compiler.err.prob.found.req
