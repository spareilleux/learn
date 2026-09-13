enum Size {
    SMALL, LARGE
}

class Shop {
    Size custom = new Size();
}
// expect: compiler.err.enum.cant.be.instantiated
