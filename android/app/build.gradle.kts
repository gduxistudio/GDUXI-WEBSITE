plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "studio.gduxi.app"
    compileSdk = 36

    defaultConfig {
        // The app's permanent ID on Google Play. Never change it after the first upload.
        applicationId = "studio.gduxi.app"
        minSdk = 26          // Android 8.0 and newer
        targetSdk = 36       // Android 16 (what Google Play asks for in 2026)
        // Raise versionCode by 1 every time you upload a new build to Google Play.
        versionCode = 1
        versionName = "1.0"
    }

    // A fixed test-signing key, so each new test APK from GitHub Actions installs over the
    // old one as an update (no uninstall). Test builds only; Play uploads use your own key.
    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.16.0")
    implementation("androidx.activity:activity-ktx:1.10.1")
    implementation("androidx.core:core-splashscreen:1.0.1")
}
