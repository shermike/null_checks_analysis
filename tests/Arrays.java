
public class Arrays {

    public Object[] get_array() {
        return new Object[2];
    }

    public Object[][] get_marray() {
        return new Object[2][2];
    }

    public void test(Object[] arr) {
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (get_array() != null) {
            System.out.println("get_array() != null");
        }
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (get_marray() != null) {
            System.out.println("get_marray() != null");
        }
    }
}
