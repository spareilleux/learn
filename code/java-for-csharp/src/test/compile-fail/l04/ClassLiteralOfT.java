class Registry<T> {
    String typeName() {
        return T.class.getName();
    }
}
// expect: compiler.err.type.var.cant.be.deref
