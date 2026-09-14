package lib;

import core.Titles;

public final class Slugs {

    private Slugs() {}

    public static String slug(String title) {
        return Titles.withoutArticle(title).toLowerCase().replace(' ', '-');
    }
}
