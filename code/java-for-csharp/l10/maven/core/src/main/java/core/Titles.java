package core;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.Strings;

public final class Titles {

    private Titles() {}

    // Strings was added in commons-lang3 3.18.0.
    public static String withoutArticle(String title) {
        return StringUtils.capitalize(Strings.CI.removeStart(title, "the "));
    }
}
