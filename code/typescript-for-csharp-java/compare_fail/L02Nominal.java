// compare_fail/L02Nominal.java
record Celsius(double value) {}
record Fahrenheit(double value) {}

public class L02Nominal {
    public static void main(String[] args) {
        Celsius water = new Fahrenheit(212);
        System.out.println(water);
    }
}
