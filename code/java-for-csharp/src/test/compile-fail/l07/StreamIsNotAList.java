import java.util.List;

class Upper {
    static List<String> upper(List<String> names) {
        return names.stream().map(String::toUpperCase);
    }
}
// expect: compiler.err.prob.found.req
