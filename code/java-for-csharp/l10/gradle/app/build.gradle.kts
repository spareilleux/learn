plugins {
    id("books.java-conventions")
    application
}

dependencies {
    implementation(libs.commons.text)
    implementation(project(":lib"))
}

application {
    mainClass = "app.Main"
}

// A second source set that uses core directly, to show that lib doesn't leak it
sourceSets {
    create("leak")
}

dependencies {
    "leakImplementation"(project(":lib"))
}

// Exercise 2: ./gradlew -PfailOnConflict fails instead of choosing the highest version
if (providers.gradleProperty("failOnConflict").isPresent) {
    configurations.all {
        resolutionStrategy.failOnVersionConflict()
    }
}

// Exercise 3: ./gradlew -PstrictLang3 forces the old version, as Maven's nearest-wins rule did
if (providers.gradleProperty("strictLang3").isPresent) {
    dependencies {
        implementation(libs.commons.lang3) {
            version {
                strictly("3.14.0")
            }
        }
    }
}
