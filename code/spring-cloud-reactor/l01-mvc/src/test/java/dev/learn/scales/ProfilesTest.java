package dev.learn.scales;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.test.context.ActiveProfiles;

class ProfilesTest {

    @Nested
    @SpringBootTest(webEnvironment = WebEnvironment.NONE)
    class DefaultProfile {

        @Autowired
        ScaleService scales;

        @Autowired
        ScalesProperties properties;

        @Test
        void sharpsAndIonian() {
            assertEquals(new ScalesProperties("ionian", ScalesProperties.Spelling.SHARPS), properties);
            assertEquals("[A#, C, D, D#, F, G, A]", scales.describe("Bb", properties.defaultMode()).notes().toString());
        }
    }

    @Nested
    @SpringBootTest(webEnvironment = WebEnvironment.NONE)
    @ActiveProfiles("flats")
    class FlatsProfile {

        @Autowired
        ScalesProperties properties;

        @Test
        void profileFileOverridesBothKeys() {
            assertEquals(new ScalesProperties("aeolian", ScalesProperties.Spelling.FLATS), properties);
        }
    }

    // Inline properties override the files, like an in-memory configuration source added last.
    @Nested
    @SpringBootTest(webEnvironment = WebEnvironment.NONE, properties = "scales.default-mode=dorian")
    @ActiveProfiles("flats")
    class InlineProperty {

        @Autowired
        ScalesProperties properties;

        @Test
        void inlinePropertyWinsOverTheProfileFile() {
            assertEquals(new ScalesProperties("dorian", ScalesProperties.Spelling.FLATS), properties);
        }
    }
}
