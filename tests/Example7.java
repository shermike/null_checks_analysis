package test;

public class Example7 {
    public final Object foo(int n) {
        return n > 0 ? new Object() : null;
    }

    public void test() {
        // No null check elimination: `foo` can return both null and non-null
        if (foo(2) != null) { // *
            System.out.println("foo() != null");
        }
    }
}