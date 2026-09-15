// compare_fail/L02Scope.java
class L02Scope {
    public static void main(String[] args) {
        for (String text : new String[] { "E", "A", "D" }) {
            String last = text.toLowerCase();
        }
        System.out.println(text + last);
    }
}
