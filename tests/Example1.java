
public class Example1 {
    public static void test1() {
        Object x = null;
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (x == null) { // *
            System.out.println("x is null");
        }
    }

    public static void test2() {
        Object x = new Object();
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x == null) { // *
            System.out.println("x is null");
        }
    }

    public static void test3() {
        Object x = "Hello, world!";
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x == null) { // *
            System.out.println("x is null");
        }
    }
}
