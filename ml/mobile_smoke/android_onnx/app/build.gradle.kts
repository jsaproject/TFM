plugins {
    id("com.android.application")
}

android {
    namespace = "com.animalspredictor.onnxsmoke"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.animalspredictor.onnxsmoke"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"

        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets["main"].assets.directories.add("build/generated/smokeAssets")
}

val prepareModelAssets by tasks.registering(Copy::class) {
    from("../../../artifacts/tinyclip_39m/tinyclip_39m_classifier.int8.onnx")
    into(layout.buildDirectory.dir("generated/smokeAssets"))
    rename { "tinyclip.int8.onnx" }
}

tasks.named("preBuild").configure {
    dependsOn(prepareModelAssets)
}

dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.29.0")
}
