package com.example.slugs;

import java.text.Normalizer;

public final class Slug {
    private Slug() {
    }

    // "Hello, Wörld!" -> "hello-world"
    public static String from(String text) {
        var decomposed = Normalizer.normalize(text, Normalizer.Form.NFD);
        var builder = new StringBuilder(decomposed.length());
        var pendingDash = false;
        for (var i = 0; i < decomposed.length(); i++) {
            var c = decomposed.charAt(i);
            if (Character.getType(c) == Character.NON_SPACING_MARK) {
                continue;
            }
            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
                if (pendingDash && !builder.isEmpty()) {
                    builder.append('-');
                }
                builder.append(Character.toLowerCase(c));
                pendingDash = false;
            } else {
                pendingDash = true;
            }
        }
        return builder.toString();
    }
}