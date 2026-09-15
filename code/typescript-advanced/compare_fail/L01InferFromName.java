// compare_fail/L01InferFromName.java
import java.util.function.Consumer;

public class L01InferFromName {
    record NavigateToPlanet(String target) {}

    static <T> void on(String name, Consumer<T> handler) {}

    public static void main(String[] args) {
        on("NavigateToPlanet", data -> System.out.println(data.target()));
    }
}
