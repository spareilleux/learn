// compare_fail/L04NewT.java
public class L04NewT {
    static <T> T create() {
        return new T();
    }

    static <T> boolean isOf(Object value) {
        return value instanceof T;
    }
}
