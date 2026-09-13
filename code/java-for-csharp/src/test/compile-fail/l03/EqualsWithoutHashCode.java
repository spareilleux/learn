class Tag {
    private final String name;

    Tag(String name) {
        this.name = name;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof Tag tag && tag.name.equals(name);
    }
}
// expect-warning: compiler.warn.override.equals.but.not.hashcode
