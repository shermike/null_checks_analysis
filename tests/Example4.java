package test;

public class Example4 {
    public final Object foo() {
        return new Object();
    }

    public void test() {
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (foo() != null) { // *
            System.out.println("foo() != null");
        }
    }
}
