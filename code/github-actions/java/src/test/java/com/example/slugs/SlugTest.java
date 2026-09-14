package com.example.slugs;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class SlugTest {
    @ParameterizedTest
    @CsvSource({
        "'Hello, Wörld!', hello-world",
        "'  GitHub   Actions  ', github-actions",
        "'C# 14 & .NET 10', c-14-net-10",
        "'', ''"
    })
    void fromBuildsALowercaseAsciiSlug(String text, String expected) {
        assertEquals(expected, Slug.from(text));
    }
}