// Settings shared by every project that applies this plugin, like Directory.Build.props
plugins {
    java
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}
