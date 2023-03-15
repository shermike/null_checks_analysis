import java.util.Random;

public class FinalFields {
    final Object x1;
    final Object x2;
    final Object x3;
    final Object x4 = new Object();

    public FinalFields() {
        x1 = new Object();
        x2 = new Random().nextInt() == 0 ? null : new Object();
        x3 = new Random().nextInt() == 0 ? new Object() : new Object();
    }

    public FinalFields(int n) {
        x1 = null;
        x2 = new Random().nextInt() == 0 ? null : new Object();
        x3 = new Random().nextInt() == 0 ? new Object() : new Object();
    }

    public void test1() {
        // No null check elimination: we can't prove value of `x` here
        if (x1 == null) { // *
            System.out.println("x1 == null");
        }
        // No null check elimination: we can't prove value of `x` here
        if (x1 != null) { // *
            System.out.println("x1 != null");
        }
        // No null check elimination: we can't prove value of `x` here
        if (x2 == null) {
            System.out.println("x2 is null");
        }
        // No null check elimination: we can't prove value of `x` here
        if (x2 != null) {
            System.out.println("x2 is not null");
        }
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x3 == null) {
            System.out.println("x3 is null");
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (x3 != null) {
            System.out.println("x3 is not null");
        }
    }

    public void test2() {
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x4 == null) {
            System.out.println("x4 is null");
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (x4 != null) {
            System.out.println("x4 is not null");
        }
    }
}
