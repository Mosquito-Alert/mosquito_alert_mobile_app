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
val googlemapsKey =
    localProperties.getProperty("googlemaps.Key")
        ?: System.getenv("GOOGLE_MAPS_KEY")
        ?: ""

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

        manifestPlaceholders["googlemapsKey"] = googlemapsKey
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

    productFlavors {
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Mosquito Alert")
        }
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Test Mosquito Alert")
        }
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")

            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))

                keyAlias = keystoreProperties["keyAlias"].toString()
                keyPassword = keystoreProperties["keyPassword"].toString()
                storeFile = file(keystoreProperties["storeFile"].toString())
                storePassword = keystoreProperties["storePassword"].toString()
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
