package lessons.l08;

import java.util.List;
import java.util.Locale;

/** Lesson 8: sealed hierarchies, record patterns and exhaustive switches. */
public class Shapes {

    record Point(double x, double y) {}

    sealed interface Shape permits Circle, Rectangle, Triangle {}

    record Circle(Point center, double radius) implements Shape {}

    record Rectangle(Point topLeft, Point bottomRight) implements Shape {}

    record Triangle(Point a, Point b, Point c) implements Shape {}

    // No default branch: the compiler knows the three permitted subtypes.
    static double area(Shape shape) {
        return switch (shape) {
            case Circle(Point _, double r) -> Math.PI * r * r;
            case Rectangle(Point(var x1, var y1), Point(var x2, var y2)) -> Math.abs(x2 - x1) * Math.abs(y2 - y1);
            case Triangle(Point a, Point b, Point c) ->
                Math.abs((b.x() - a.x()) * (c.y() - a.y()) - (c.x() - a.x()) * (b.y() - a.y())) / 2;
        };
    }

    // Guards refine a case with a boolean condition.
    static String describe(Shape shape) {
        return switch (shape) {
            case Circle c when c.radius() == 0 -> "a point";
            case Circle c -> "a circle of radius " + c.radius();
            case Rectangle(Point(var x1, var y1), Point(var x2, var y2)) when x2 - x1 == y2 - y1 -> "a square";
            case Rectangle r -> "a rectangle";
            case Triangle t -> "a triangle";
        };
    }

    public static void main(String[] args) {
        List<Shape> shapes = List.of(
                new Circle(new Point(0, 0), 1),
                new Circle(new Point(2, 2), 0),
                new Rectangle(new Point(0, 0), new Point(3, 3)),
                new Rectangle(new Point(0, 0), new Point(4, 2)),
                new Triangle(new Point(0, 0), new Point(4, 0), new Point(0, 3)));
        for (Shape shape : shapes) {
            System.out.printf(Locale.ROOT, "%-24s %.2f%n", describe(shape), area(shape));
        }
    }
}
