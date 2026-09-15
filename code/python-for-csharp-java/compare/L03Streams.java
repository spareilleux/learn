// compare/L03Streams.java
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

class L03Streams {
    record Chord(String root, String quality, List<String> notes) {}

    public static void main(String[] args) {
        var chords = List.of(
            new Chord("C", "major", List.of("C", "E", "G")),
            new Chord("A", "minor", List.of("A", "C", "E")),
            new Chord("G", "dominant 7", List.of("G", "B", "D", "F")),
            new Chord("E", "minor", List.of("E", "G", "B")),
            new Chord("D", "major", List.of("D", "F#", "A")),
            new Chord("F", "major 7", List.of("F", "A", "C", "E")));

        System.out.println(chords.stream().filter(c -> c.quality().equals("minor")).map(c -> c.root() + "m").toList());
        System.out.println(chords.stream().flatMap(c -> c.notes().stream()).distinct().sorted().toList());
        System.out.println(chords.stream().anyMatch(c -> c.notes().size() == 4) + " " + chords.stream().allMatch(c -> c.notes().contains("E")));
        System.out.println(chords.stream().mapToInt(c -> c.notes().size()).sum());
        System.out.println(chords.stream().max(Comparator.comparingInt(c -> c.notes().size())).orElseThrow());

        chords.stream()
            .sorted(Comparator.comparingInt((Chord c) -> c.notes().size()).reversed().thenComparing(Chord::root))
            .forEach(c -> System.out.printf("%-2s %-11s %s%n", c.root(), c.quality(), String.join(" ", c.notes())));

        // groupingBy returns a HashMap: the order of its keys is the order of their hash codes
        System.out.println(chords.stream().collect(Collectors.groupingBy(Chord::quality, Collectors.mapping(Chord::root, Collectors.toList()))));
    }
}
