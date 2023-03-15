
public class Example3 {
    private final Object x;
    
    public Example3() {
        x = new Object();
    }

    public void test() {
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (x == null) { // *
            System.out.println("x == null");
        }
    }
}
