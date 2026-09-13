class Factory<T> {
    T create() {
        return new T();
    }
}
// expect: compiler.err.type.found.req
