import java.util.Date;

class Legacy {
    // Year 2026 is written 126, and September is month 8.
    static Date lessonDay() {
        return new Date(126, 8, 13);
    }
}
// expect-warning: compiler.warn.has.been.deprecated
