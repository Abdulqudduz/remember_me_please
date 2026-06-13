plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.remember_me_please"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.remember_me_please"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // Enable shrinking (your requirement)
            // minifyEnabled true
            // shrinkResources true

            // Attach Proguard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Force Gradle to remove the default non-browser package during debug builds
configurations {
    named("debugImplementation") {
        exclude(group = "io.objectbox", module = "objectbox-android")
    }
}


dependencies {
    // Play Core (fixes missing splitinstall errors)
    implementation("com.google.android.play:core:1.10.3")
    implementation("com.google.android.play:core-ktx:1.8.1")

    // MediaPipe (fixes proto missing classes if used by plugins)
    // implementation("com.google.mediapipe:solution-core:0.10.0")

// ObjectBox for admin web interface (optional, only in debug builds)
    debugImplementation("io.objectbox:objectbox-android-objectbrowser:5.4.1")
}

flutter {
    source = "../.."
}