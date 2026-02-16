// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0") // Match your AGP version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10") // Kotlin plugin
        classpath("com.google.gms:google-services:4.3.15") // Google Services plugin
        // NOTE: Do not place your application dependencies here; they belong in the app-level build.gradle.kts
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build directories outside the project
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
