import java.util.Random;

public class InvokeSpecial {

    final static Object o;
    final static Object o1;
    final static Object o2;
    final static Object o3;
    final static Object o4 = new Object();

    static {
        o = null;
        o1 = new Object();
        o2 = new Random().nextInt() == 0 ? null : new Object();
        o3 = new Random().nextInt() == 0 ? null : null;
    }

    private Object foo() {
        return null;
    }

    public void test1() {
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (foo() == null) {
            System.out.println("foo() is null");
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (o == null) {
            System.out.println("o is null");
        }
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (o != null) {
            System.out.println("o is not null");
        }
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (o1 == null) {
            System.out.println("o1 is null");
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (o1 != null) {
            System.out.println("o1 is not null");
        }
        // May be both null and not null
        if (o2 != null) {
            System.out.println("o1 is not null");
        }
        // May be both null and not null
        if (o2 == null) {
            System.out.println("o1 is not null");
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (o3 == null) {
            System.out.println("o is null");
        }
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (o3 != null) {
            System.out.println("o is not null");
        }
    }

    public void test2() {
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (o4 == null) {
            System.out.println("o4 is null");
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (o4 != null) {
            System.out.println("o4 is not null");
        }
    }
}
