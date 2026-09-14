package lessons.l05;

/** Lesson 5: rethrowing keeps the stack trace, and finally can swallow a result. */
public class Rethrow {

    static void failDeep() {
        throw new IllegalStateException("deep failure");
    }

    static void rethrow() {
        try {
            failDeep();
        } catch (IllegalStateException e) {
            // In Java the stack trace is captured when the exception is created,
            // so "throw e" keeps it. C# needs "throw;" for the same result.
            throw e;
        }
    }

    @SuppressWarnings("finally")
    static int finallyWins() {
        try {
            return 1;
        } finally {
            return 2;
        }
    }

    public static void main(String[] args) {
        try {
            rethrow();
        } catch (IllegalStateException e) {
            System.out.println("thrown in " + e.getStackTrace()[0].getMethodName());
        }

        System.out.println(finallyWins());
    }
}
