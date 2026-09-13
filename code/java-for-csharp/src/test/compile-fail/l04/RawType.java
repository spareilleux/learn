import java.util.ArrayList;
import java.util.List;

class Legacy {
    void run() {
        List names = new ArrayList();
        names.add("Ada");
    }
}
// expect-warning: compiler.warn.raw.class.use
// expect-warning: compiler.warn.unchecked.call.mbr.of.raw.type
