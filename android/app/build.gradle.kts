import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}


val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
// Maps keys are per-flavor. prod and test are separate Google Cloud API keys,
// each restricted to its own package name + signing certificate. Using one in
// the other flavor fails silently -- the app builds and runs, the map is just
// blank -- so they must never be interchanged. A key restricted to iOS bundle
// ids (see ios/Runner/AppDelegate.swift) will not work on Android either.
val googlemapsKeyProd =
    localProperties.getProperty("googlemaps.Key")
        ?: System.getenv("GOOGLE_MAPS_KEY")
        ?: ""
val googlemapsKeyTest =
    localProperties.getProperty("googlemaps.KeyTest")
        ?: System.getenv("GOOGLE_MAPS_KEY_TEST")
        ?: ""

// Empty is a legitimate setup for outside contributors (see README), so this
// warns rather than fails -- but a distributable build with an empty key ships
// a blank map, which is easy to miss until a tester reports it.
if (googlemapsKeyProd.isEmpty()) {
    logger.warn("googlemaps.Key is empty: prod builds will show a blank map.")
}
if (googlemapsKeyTest.isEmpty()) {
    logger.warn("googlemaps.KeyTest is empty: dev/test builds will show a blank map.")
}

android {
    namespace = "com.example.mosquito_alert_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        // Required for the per-flavor resValue("string", "app_name", ...) below.
        // This defaults to off in this AGP setup, and without it configuring the
        // app project fails with "Product Flavor prod contains custom resource
        // values, but the feature is disabled".
        resValues = true
    }

    defaultConfig {
        applicationId = "ceab.movelab.tigatrapp"

        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // The flavor selects applicationId / app name / launcher icon /
    // google-services.json overlay. The Dart entrypoint is chosen separately
    // with --target (lib/main.dart vs lib/main_dev.dart), which is what picks
    // the assets/config/<env>.json backend.
    //
    // NOTE: once flavors exist Gradle requires one, so builds must now pass
    // --flavor, e.g.
    //   fvm flutter build appbundle --release --flavor prod --target lib/main.dart
    //   fvm flutter build appbundle --release --flavor dev  --target lib/main_dev.dart
    flavorDimensions += "env"

    // The two flavors are separate Play listings and must be signed with
    // separate keys. The prod key is also the Play App Signing key for the live
    // app, and Play rejects an upload signed with a key it already uses to sign
    // APKs delivered to users -- so the dev/Test listing gets its own upload key.
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.containsKey("keyAlias")) {
                keyAlias = keystoreProperties["keyAlias"].toString()
                keyPassword = keystoreProperties["keyPassword"].toString()
                storeFile = file(keystoreProperties["storeFile"].toString())
                storePassword = keystoreProperties["storePassword"].toString()
            }
        }
        create("devRelease") {
            if (keystoreProperties.containsKey("devKeyAlias")) {
                keyAlias = keystoreProperties["devKeyAlias"].toString()
                keyPassword = keystoreProperties["devKeyPassword"].toString()
                storeFile = file(keystoreProperties["devStoreFile"].toString())
                storePassword = keystoreProperties["devStorePassword"].toString()
            }
        }
    }

    productFlavors {
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Mosquito Alert")
            signingConfig = signingConfigs.getByName("release")
            manifestPlaceholders["googlemapsKey"] = googlemapsKeyProd
        }
        // Named "dev" rather than "test" because AGP rejects flavor names
        // starting with "test". The applicationId suffix is ".test" to match the
        // package name locked into the Test Mosquito Alert Play listing.
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".test"
            resValue("string", "app_name", "Test Mosquito Alert")
            signingConfig = signingConfigs.getByName("devRelease")
            manifestPlaceholders["googlemapsKey"] = googlemapsKeyTest
        }
    }

    buildTypes {
        release {
            // No signingConfig here: a build type's config would override the
            // per-flavor one set above, collapsing both flavors back onto one key.
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
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
    // See last version here: https://maven.google.com/web/index.html#com.google.android.material:material
    implementation("com.google.android.material:material:1.14.0")
}
