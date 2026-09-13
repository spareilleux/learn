package lessons.l02;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.junit.jupiter.api.Test;

/** Lesson 2 exercise solutions. */
class SolutionsTest {

    static boolean sameId(Integer left, Integer right) {
        return left == right;
    }

    @Test
    void exercise1IntegerCache() {
        assertTrue(sameId(42, 42));
        assertFalse(sameId(1000, 1000));
    }

    static long readUInt32LittleEndian(byte[] bytes) {
        return ByteBuffer.wrap(bytes, 0, 4)
                .order(ByteOrder.LITTLE_ENDIAN)
                .getInt() & 0xFFFFFFFFL;
    }

    @Test
    void exercise2UnsignedInt() {
        assertEquals(4_294_967_295L, readUInt32LittleEndian(new byte[] {-1, -1, -1, -1}));
        assertEquals(200L, readUInt32LittleEndian(new byte[] {(byte) 200, 0, 0, 0}));
        assertEquals(16_909_060L, readUInt32LittleEndian(new byte[] {4, 3, 2, 1}));
    }

    static String classify(int status) {
        return switch (status) {
            case 404 -> "not found";
            default -> status >= 200 && status < 300 ? "success" : "other";
        };
    }

    @Test
    void exercise3Switch() {
        assertEquals("success", classify(204));
        assertEquals("not found", classify(404));
        assertEquals("other", classify(500));
    }
}
