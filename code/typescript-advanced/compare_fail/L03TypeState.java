// compare_fail/L03TypeState.java
public class L03TypeState {
    record Idle() {
        Listening start(long at) { return new Listening(at); }
    }

    record Listening(long startedAt) {
        Idle stop() { return new Idle(); }
    }

    public static void main(String[] args) {
        // An idle microphone can't be stopped: the method doesn't exist on that state
        new Idle().stop();
    }
}
