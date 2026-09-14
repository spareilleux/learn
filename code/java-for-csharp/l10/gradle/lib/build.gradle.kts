plugins {
    id("books.java-conventions")
    `java-library`
}

dependencies {
    // implementation: core is on lib's compile class path, but not on the compile class path of lib's consumers
    implementation(project(":core"))
}
