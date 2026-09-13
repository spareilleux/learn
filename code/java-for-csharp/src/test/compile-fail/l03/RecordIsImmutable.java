record Point(int x, int y) {
    void moveRight() {
        x = x + 1;
    }
}
// expect: compiler.err.cant.assign.val.to.var
