import java.util.Properties
import java.io.FileInputStream

// Release signing credentials, kept outside the repo and gitignored.
//
// Absent on a machine that has not been given the keystore — CI, a fresh
// clone, a colleague — in which case the release build falls back to debug
// signing below rather than failing outright.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}
val hasReleaseSigning = keystoreProperties.getProperty("storeFile") != null

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.thehometuitions.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time, which minSdk 23 predates.
        // Desugaring back-ports it rather than forcing minSdk up and dropping
        // older phones — a real share of this audience.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.thehometuitions.app"
        // Razorpay, google_sign_in and flutter_secure_storage all require 23+.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // The real upload key when this machine has it, debug otherwise so
            // a clone without the keystore can still produce a running build.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
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
    // Required by the desugaring flag above.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
