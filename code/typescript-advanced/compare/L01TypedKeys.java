// compare/L01TypedKeys.java
// Java has no literal types either: the typed key carries the payload type
import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

public class L01TypedKeys {
    record NavigateToPlanet(String target) {}
    record Connected(int connections) {}

    record HubEvent<T>(String name, Class<T> type) {}

    static final HubEvent<NavigateToPlanet> NAVIGATE_TO_PLANET = new HubEvent<>("NavigateToPlanet", NavigateToPlanet.class);
    static final HubEvent<Connected> CONNECTED = new HubEvent<>("Connected", Connected.class);

    static final Map<String, Consumer<Object>> handlers = new HashMap<>();

    // The Class<T> in the key also allows a checked cast, which Java's erased T can't do on its own
    static <T> void on(HubEvent<T> event, Consumer<T> handler) {
        handlers.put(event.name(), data -> handler.accept(event.type().cast(data)));
    }

    public static void main(String[] args) {
        on(NAVIGATE_TO_PLANET, data -> System.out.println("navigate to " + data.target()));
        on(CONNECTED, data -> System.out.println(data.connections() + " clients connected"));
        handlers.get("NavigateToPlanet").accept(new NavigateToPlanet("saturn"));
        handlers.get("Connected").accept(new Connected(2));
        try {
            handlers.get("Connected").accept(new NavigateToPlanet("mars"));
        } catch (ClassCastException e) {
            System.out.println("ClassCastException: " + e.getMessage());
        }
    }
}
