class Base {
    String describe() {
        return "base";
    }
}

class Derived extends Base {
    @Override
    String descibe() {
        return "derived";
    }
}
// expect: compiler.err.method.does.not.override.superclass
