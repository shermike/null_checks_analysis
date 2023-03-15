import java.util.Iterator;

class Invokes implements Iterable {

    @Override
    public Iterator iterator() {
        return null;
    }

    public int test1() {
        // NEXTLINE: ALWAYS_FALSE_NULL_CHECK
        if (iterator() != null)
            return 1;
        return 0;
    }

    public int test2() {
        // NEXTLINE: ALWAYS_TRUE_NULL_CHECK
        if (iterator() == null)
            return 1;
        return 0;
    }
}
