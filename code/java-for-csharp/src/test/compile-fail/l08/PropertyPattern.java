record Point(int x, int y) {}

class Origins {
    static boolean onXAxis(Object o) {
        return o instanceof Point { y: 0 };
    }
}
// expect: compiler.err.not.stmt
