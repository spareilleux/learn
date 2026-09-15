// compare_fail/L04Checked.java
// Java's checked exceptions are part of the signature: the caller must catch them or declare them
import java.io.IOException;

public class L04Checked {
    static String loadGraph(String url) throws IOException {
        throw new IOException("fetch failed: " + url);
    }

    public static void main(String[] args) {
        System.out.println(loadGraph("/api/governance"));
    }
}
