// compare/L04Erasure.java
import java.util.ArrayList;
import java.util.List;

public class L04Erasure {
    @SuppressWarnings("unchecked")
    static <T> List<T> parseList(Object... values) {
        var list = new ArrayList<T>();
        for (var value : values) {
            list.add((T) value); // an unchecked cast: T is erased to Object, so nothing is checked here
        }
        return list;
    }

    public static void main(String[] args) {
        System.out.println(new ArrayList<Integer>().getClass() == new ArrayList<String>().getClass());
        List<Integer> counts = parseList("twelve");
        System.out.println("counts: " + counts);
        try {
            Integer count = counts.get(0); // the cast that javac inserted runs here
            System.out.println(count);
        } catch (ClassCastException e) {
            System.out.println("counts.get(0): " + e.getClass().getSimpleName());
        }
    }
}
