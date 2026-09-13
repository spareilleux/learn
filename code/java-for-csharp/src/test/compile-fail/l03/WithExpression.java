record Point(int x, int y) {
}

class Moves {
    Point right(Point p) {
        return p with { x = p.x() + 1; };
    }
}
// expect: compiler.err.expected
