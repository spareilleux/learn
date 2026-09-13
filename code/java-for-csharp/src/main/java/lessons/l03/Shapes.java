package lessons.l03;

/** Lesson 3: interfaces with default and static methods, sealed hierarchies, and nested classes. */
public class Shapes {

    sealed interface Shape permits Circle, Square {
        double area();

        default String describe() {
            return getClass().getSimpleName() + " with area " + String.format("%.1f", area());
        }

        static Shape unitSquare() {
            return new Square(1);
        }
    }

    record Circle(double radius) implements Shape {
        public double area() {
            return Math.PI * radius * radius;
        }
    }

    record Square(double side) implements Shape {
        public double area() {
            return side * side;
        }
    }

    private int created;

    // An inner class: each instance holds a hidden reference to a Shapes instance.
    class Counter {
        void increment() {
            created++;
        }
    }

    public static void main(String[] args) {
        Shape[] shapes = { new Circle(1), new Square(2), Shape.unitSquare() };
        for (Shape shape : shapes) {
            System.out.println(shape.describe());
        }

        var outer = new Shapes();
        Shapes.Counter counter = outer.new Counter();
        counter.increment();
        counter.increment();
        System.out.println(outer.created);
    }
}
