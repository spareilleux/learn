sealed interface Shape permits Circle {
}

record Circle(double radius) implements Shape {
}

record Triangle(double base, double height) implements Shape {
}
// expect: compiler.err.cant.inherit.from.sealed
