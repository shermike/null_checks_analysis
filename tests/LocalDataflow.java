
public class LocalDataflow {

    public void test1(boolean flag) {
        Object x = null;
        if (flag) {
            x = new Object();
        } else {
            x = new Object();
        }
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x == null) { // *
            System.out.println("x is null");
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (x != null) { // *
            System.out.println("x is null");
        }

        if (flag) {
            x = null;
        }
        // Non deterministic
        if (x == null) { // *
            System.out.println("x is null");
        }
        // Non deterministic
        if (x != null) { // *
            System.out.println("x is null");
        }

        x = null;
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (x == null) { // *
            System.out.println("x is null");
        }
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x != null) { // *
            System.out.println("x is null");
        }
    }

    public void test2(boolean flag) {
        Object x = null;
        if (flag) {
            x = null;
        } else {
            x = new Object();
        }
        // Non deterministic
        if (x == null) { // *
            System.out.println("x is null");
        }
    }

    public boolean test3(Object x) {
        if (x == null) {
            x = new Object();
        }
        // TODO: NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x == null) { // *
            return false;
        }
        // TODO: NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (x != null) { // *
            return false;
        }
        return true;
    }
}
