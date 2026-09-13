package lessons.l03;

import java.util.HashSet;
import java.util.List;

/** Lesson 3: records, compact constructors, and a class that forgot hashCode. */
public class Records {

    record Point(int x, int y) {
        Point {
            if (x < 0 || y < 0) {
                throw new IllegalArgumentException("negative coordinate: " + x + ", " + y);
            }
        }

        Point withX(int newX) {
            return new Point(newX, y);
        }

        double length() {
            return Math.sqrt(x * x + y * y);
        }
    }

    record Order(String id, List<String> items) {}

    @SuppressWarnings("overrides") // deliberately broken: the lesson shows javac's warning
    static class Tag {
        private final String name;

        Tag(String name) {
            this.name = name;
        }

        @Override
        public boolean equals(Object other) {
            return other instanceof Tag tag && tag.name.equals(name);
        }
        // hashCode not overridden
    }

    public static void main(String[] args) {
        var p = new Point(3, 4);
        System.out.println(p);
        System.out.println(p.x() + " " + p.length());
        System.out.println(p.equals(new Point(3, 4)));
        System.out.println(p.withX(6));

        try {
            new Point(-1, 2);
        } catch (IllegalArgumentException e) {
            System.out.println(e.getMessage());
        }

        // A record is shallowly immutable: the list inside can still change.
        var items = new java.util.ArrayList<>(List.of("book"));
        var order = new Order("A-1", items);
        items.add("pen");
        System.out.println(order);

        var tags = new HashSet<Tag>();
        tags.add(new Tag("java"));
        System.out.println(new Tag("java").equals(new Tag("java")));
        System.out.println(tags.contains(new Tag("java")));
    }
}
