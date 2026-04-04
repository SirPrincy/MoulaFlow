buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // C'est ce plugin qui permet de comprendre le NDK et le SDK
        classpath("com.android.tools.build:gradle:8.2.1") 
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Ta logique de dossier build (on la garde)
rootProject.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir("../../build").get())
subprojects {
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.get().dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}