import java.util.ArrayList;
import java.util.List;

class Zoo {
    void run() {
        List<String> names = new ArrayList<>();
        List<Object> objects = names;
    }
}
// expect: compiler.err.prob.found.req
