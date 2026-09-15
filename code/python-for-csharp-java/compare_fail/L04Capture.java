// compare_fail/L04Capture.java
import java.util.ArrayList;
import java.util.List;
import java.util.function.IntUnaryOperator;

class L04Capture {
    public static void main(String[] args) {
        List<IntUnaryOperator> transposers = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            transposers.add(note -> note + i);
        }
    }
}
