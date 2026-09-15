// compare/L03Modify.java
import java.util.ArrayList;
import java.util.ConcurrentModificationException;
import java.util.LinkedHashMap;
import java.util.List;

class L03Modify {
    public static void main(String[] args) {
        var stock = new LinkedHashMap<String, Integer>();
        stock.put("capo", 2);
        stock.put("strings", 0);
        stock.put("picks", 50);
        stock.put("tuner", 0);
        try {
            for (var entry : stock.entrySet()) {
                if (entry.getValue() == 0) stock.remove(entry.getKey());
            }
        } catch (ConcurrentModificationException e) {
            System.out.println(e.getClass().getSimpleName());
        }
        stock.values().removeIf(count -> count == 0); // the supported way
        System.out.println(stock);

        // subList is a view: writing to it writes to the list
        List<String> tuning = new ArrayList<>(List.of("E", "A", "D", "G", "B", "E"));
        List<String> bass = tuning.subList(0, 3);
        bass.set(0, "D");
        System.out.println(bass + " " + tuning);
    }
}
