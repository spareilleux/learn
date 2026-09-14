class Clicks {
    static int count() {
        int clicks = 0;
        Runnable click = () -> clicks++;
        click.run();
        return clicks;
    }
}
// expect: compiler.err.cant.ref.non.effectively.final.var
