
public class Example8 {
    public static void test1(int n) {
        Object x = null;
        if (n > 0) {
            x = new Object();
        }
        // No null check elimination: we can't prove value of `x` here
        if (x == null) { // *
            System.out.println("x is null");
        }
    }

    public static void test2(int n) {
        Object x = null;
        if (n > 0) {
            x = null;
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (x == null) { // *
            System.out.println("x is null");
        }
    }
}