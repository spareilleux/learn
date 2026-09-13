class Singleton<T> {
    static T instance;
}
// expect: compiler.err.non-static.cant.be.ref
