package lessons.l02;

/** Lesson 2: var, final, text blocks, formatting and switch expressions. */
public class Expressions {
    enum Size { SMALL, MEDIUM, LARGE }

    public static void main(String[] args) {
        var name = "Ada";          // inferred as String
        final var year = 1843;     // cannot be reassigned; C# has no equivalent for locals
        System.out.println("%s published her notes in %d.".formatted(name, year));

        String json = """
                {
                  "name": "%s",
                  "year": %d
                }
                """.formatted(name, year);
        System.out.print(json);

        var size = Size.MEDIUM;
        int price = switch (size) {
            case SMALL -> 3;
            case MEDIUM -> 4;
            case LARGE -> {
                int base = 4;
                yield base + 1;
            }
        };
        System.out.println(price);

        String label = price > 3 ? "expensive" : "cheap";
        System.out.println(label);
    }
}
