// compare/L03Numbers.java
class L03Numbers {
    public static void main(String[] args) {
        // / and % truncate toward zero; Math.floorDiv and Math.floorMod round like Python's // and %
        System.out.println((7 / 2) + " " + (-7 / 2) + " " + (-7 % 2) + " " + Math.floorDiv(-7, 2) + " " + Math.floorMod(-7, 2));

        // Math.round rounds half up; Math.rint rounds half to even
        System.out.println(Math.round(2.5) + " " + Math.round(3.5) + " " + Math.rint(2.5));
        System.out.println(0.1 + 0.2);

        // int has 32 bits and wraps around
        int max = Integer.MAX_VALUE;
        System.out.println(max + 1);
    }
}
