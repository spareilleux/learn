class Outer {
    class Inner {
    }

    static Inner create() {
        return new Inner();
    }
}
// expect: compiler.err.non-static.cant.be.ref
