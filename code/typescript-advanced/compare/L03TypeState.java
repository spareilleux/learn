// compare/L03TypeState.java
// Java 25: sealed interfaces and records, where each state offers only the transitions it allows
public class L03TypeState {
    sealed interface Voice permits Idle, Listening, Processing, Failed {}

    record Idle() implements Voice {
        Listening start(long at) { return new Listening(at); }
    }

    record Listening(long startedAt) implements Voice {
        Processing finalResult(String transcript) { return new Processing(transcript); }
        Idle stop() { return new Idle(); }
    }

    record Processing(String transcript) implements Voice {
        Failed sendFailed(String error) { return new Failed(transcript, error); }
    }

    record Failed(String transcript, String error) implements Voice {}

    // The switch over a sealed interface must cover every permitted type
    static String label(Voice state) {
        return switch (state) {
            case Idle i -> "mic off";
            case Listening l -> "listening since " + l.startedAt() + " ms";
            case Processing p -> "sending \"" + p.transcript() + "\"";
            case Failed f -> "could not send \"" + f.transcript() + "\": " + f.error();
        };
    }

    public static void main(String[] args) {
        Voice state = new Idle().start(120).finalResult("show me drop D voicings").sendFailed("HTTP 503");
        System.out.println(label(state));
    }
}
