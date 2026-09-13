package lessons.l03;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.Objects;
import org.junit.jupiter.api.Test;

/** Lesson 3 exercise solutions. */
class SolutionsTest {

    record Product(String name, BigDecimal price) {
        Product {
            if (name == null || name.isBlank()) {
                throw new IllegalArgumentException("name required");
            }
            if (price.signum() < 0) {
                throw new IllegalArgumentException("price must not be negative");
            }
        }
    }

    @Test
    void exercise1RecordValidation() {
        assertEquals("Product[name=book, price=12.5]", new Product("book", new BigDecimal("12.5")).toString());
        assertThrows(IllegalArgumentException.class, () -> new Product(" ", BigDecimal.ONE));
        assertThrows(IllegalArgumentException.class, () -> new Product("book", new BigDecimal("-1")));
    }

    static class Tag {
        private final String name;

        Tag(String name) {
            this.name = name;
        }

        @Override
        public boolean equals(Object other) {
            return other instanceof Tag tag && tag.name.equals(name);
        }

        @Override
        public int hashCode() {
            return name.hashCode();
        }
    }

    record TagRecord(String name) {}

    @Test
    void exercise2HashCode() {
        var tags = new HashSet<Tag>();
        tags.add(new Tag("java"));
        assertTrue(tags.contains(new Tag("java")));

        var records = new HashSet<TagRecord>();
        records.add(new TagRecord("java"));
        assertTrue(records.contains(new TagRecord("java")));
        assertEquals(Objects.hash("java"), Objects.hash(new Tag("java").name));
    }

    enum Permission { READ, WRITE, DELETE }

    @Test
    void exercise3EnumSet() {
        EnumSet<Permission> granted = EnumSet.of(Permission.READ, Permission.WRITE);
        boolean canWrite = granted.contains(Permission.WRITE);
        assertTrue(canWrite);
        assertEquals(EnumSet.of(Permission.DELETE), EnumSet.complementOf(granted));
    }
}
