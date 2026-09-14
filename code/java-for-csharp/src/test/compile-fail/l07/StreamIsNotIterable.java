import java.util.stream.Stream;

class Names {
    static void print(Stream<String> names) {
        for (String name : names) {
            System.out.println(name);
        }
    }
}
// expect: compiler.err.foreach.not.applicable.to.type
