import java.util.Random;

public class CalleeReturnsMayBeNull {
    private Object foo() {
        if (new Random().nextInt() == 0) {
            return null;
        } else {
            return new Object();
        }
    }
    public void test() {
        if (foo() == null) { // May return both null and not-null
            System.out.println("foo returns null");
        }
    }
}
