// compare_fail/L01Order.java
class L01Order {
    static double withTax(double price) {
        return price + price * 0.15;
    }

    static double lineTotal(String product, double price, int quantity) {
        if (quantity > 10) {
            return withTax(price) * quantity * discount;
        }
        return withTax(price) * quantity;
    }

    public static void main(String[] args) {
        System.out.println("capo " + lineTotal("capo", 9.99, 2));
        System.out.println("strings " + lineTotal("strings", "12.50", 1));
    }
}
