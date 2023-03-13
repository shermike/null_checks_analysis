package test;

public class Example6 {
    private final Object x;

    public Example6() {
        x = new Object();
    }

    public Example6(int n) {
        x = null;
    }

    public void test() {
        // No null check elimination: we can't prove value of `x` here
        if (x == null) { // *
            System.out.println("x == null");
        }
    }
}
