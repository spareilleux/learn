// compare/L02Values.java
class L02Values {
    public static void main(String[] args) {
        // Autoboxing goes through Integer.valueOf, which caches the values from -128 to 127
        Integer small = 100, alsoSmall = 100;
        Integer big = 1000, alsoBig = 1000;
        System.out.println((small == alsoSmall) + " " + small.equals(alsoSmall));
        System.out.println((big == alsoBig) + " " + big.equals(alsoBig));

        // The compiler converts the int to text
        int quantity = 3;
        System.out.println("quantity: " + quantity);
    }
}
