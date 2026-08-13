import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La clave de distribución no se versiona. Copia key.properties.example a
// key.properties y guarda el almacén de claves fuera del repositorio.
val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.exists()) {
    releasePropertiesFile.inputStream().use(releaseProperties::load)
}

android {
    namespace = "com.tfm.animalspredictor"
    // permission_handler_android 14 requiere compilar contra Android API 37.
    // targetSdk se mantiene gestionado por Flutter para no introducir cambios
    // de comportamiento en tiempo de ejecución junto con esta actualización.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tfm.animalspredictor"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        if (releasePropertiesFile.exists()) {
            create("release") {
                keyAlias = releaseProperties["keyAlias"] as String
                keyPassword = releaseProperties["keyPassword"] as String
                storeFile = file(releaseProperties["storeFile"] as String)
                storePassword = releaseProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Permite probar la modernización junto a una instalación antigua
            // firmada con otra clave, sin desinstalarla ni perder sus datos.
            applicationIdSuffix = ".debug"
        }
        release {
            // El plugin TFLite heredado referencia delegados GPU opcionales que
            // R8 no puede resolver. Se conserva el código nativo sin minimizar.
            isMinifyEnabled = false
            isShrinkResources = false
            if (releasePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.configureEach {
    if (name == "assembleRelease" || name == "bundleRelease") {
        doFirst {
            check(releasePropertiesFile.exists()) {
                "Falta android/key.properties. Consulta android/RELEASE.md para generar y configurar una clave de firma."
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.tensorflow:tensorflow-lite:2.17.0")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test:runner:1.6.2")
}
