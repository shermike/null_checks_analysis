package test;

public class Example2 {
    public static void test1(Object x) {
        if (x == null) return;
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (x != null) { // *
            System.out.println("x != null");
        }
    }

    public static void test2(Object x) {
        System.out.println(x.hashCode());
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x == null) { // *
            System.out.println("x == null");
        }
    }
}
