package app;

import core.Titles;

public class Leak {

    public static void main(String[] args) {
        System.out.println(Titles.withoutArticle("the pragmatic programmer"));
    }
}
