// Lesson 4, the Java side: java L04Equality.java (Java 25)
import java.util.HashMap;
import java.util.Map;

record Point(int x, int y) {}

void main() {
    var a = new Point(1, 2);
    var b = new Point(1, 2);
    IO.println("a == b:                 " + (a == b));
    IO.println("a.equals(b):            " + a.equals(b));

    Map<Point, String> visits = new HashMap<>();
    visits.put(a, "first");
    visits.put(b, "second"); // same key: equals and hashCode come from the record
    IO.println("visits.size():          " + visits.size());
}
