
public class Example5 {
    private static final String MESSAGE = "Hello, world!"; 

    public void test() {
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (MESSAGE != null) { // *
            System.out.println(MESSAGE);
        }
    }
}
