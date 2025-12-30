import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "go.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("prodRelease") {
            storeFile = file(keystoreProperties["prodStoreFile"] as String? ?: "../keystores/prod-upload-keystore.jks")
            storePassword = keystoreProperties["prodStorePassword"] as String? ?: ""
            keyAlias = keystoreProperties["prodKeyAlias"] as String? ?: "prod-upload"
            keyPassword = keystoreProperties["prodKeyPassword"] as String? ?: ""
        }
        create("devRelease") {
            storeFile = file(keystoreProperties["devStoreFile"] as String? ?: "../keystores/dev-upload-keystore.jks")
            storePassword = keystoreProperties["devStorePassword"] as String? ?: ""
            keyAlias = keystoreProperties["devKeyAlias"] as String? ?: "dev-upload"
            keyPassword = keystoreProperties["devKeyPassword"] as String? ?: ""
        }
    }

    defaultConfig {
        applicationId = "go.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"
    productFlavors {
        create("dev") {
            dimension = "app"
            applicationIdSuffix = ".dev"  // go.mobile.dev になる
            versionNameSuffix = "-dev"
            signingConfig = signingConfigs.getByName("devRelease")
        }
        create("prod") {
            dimension = "app"
            // applicationId は defaultConfig の go.mobile をそのまま使用
            signingConfig = signingConfigs.getByName("prodRelease")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
