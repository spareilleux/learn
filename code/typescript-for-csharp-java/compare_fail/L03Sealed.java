// compare_fail/L03Sealed.java
sealed interface MusicEvent permits Note, Chord, Rest, Tie {}
record Note(int pitch, int beats) implements MusicEvent {}
record Chord(int[] pitches, int beats) implements MusicEvent {}
record Rest(int beats) implements MusicEvent {}
record Tie(int beats) implements MusicEvent {}

public class L03Sealed {
    static String describe(MusicEvent e) {
        return switch (e) {
            case Note n -> "note " + n.pitch();
            case Chord c -> "chord of " + c.pitches().length;
            case Rest r -> "rest";
        };
    }

    public static void main(String[] args) {
        System.out.println(describe(new Tie(1)));
    }
}
