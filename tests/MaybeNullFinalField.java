public class MaybeNullFinalField {
    private final Object f;

    MaybeNullFinalField() {
        f = null;
    }

    public void test1() {
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (f == null) { // *
            System.out.println("x == null");
        }
    }
}
