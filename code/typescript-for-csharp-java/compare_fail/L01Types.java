// compare_fail/L01Types.java
record Line(String product, double price, int quantity) {}

public class L01Types {
    public static void main(String[] args) {
        var lines = new Line[] { new Line("capo", "9.99", 2), new Line("strings", 12.5, 1) };
        for (var line : lines) {
            System.out.println(line.product() + " " + line.price() * 1.15 * line.quantity());
        }
    }
}
