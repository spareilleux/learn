package app;

import lib.Slugs;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.text.WordUtils;

public class Main {

    public static void main(String[] args) {
        System.out.println("commons-lang3 on the class path: " + StringUtils.class.getPackage().getImplementationVersion());
        System.out.println(WordUtils.capitalizeFully("the art of computer programming"));
        System.out.println(Slugs.slug("The Art of Computer Programming"));
    }
}
