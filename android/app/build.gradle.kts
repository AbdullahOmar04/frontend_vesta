plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.vesta"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.vesta"  // change to your prod id later
        minSdk = 26
        targetSdk = 33
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // keep debug nice for development
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }

        release {
            isDebuggable = false          
            isMinifyEnabled = true       
            isShrinkResources = true   

            signingConfig = signingConfigs.getByName("debug")

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {

  // Import the Firebase BoM

  implementation(platform("com.google.firebase:firebase-bom:34.1.0"))
  implementation("com.google.firebase:firebase-auth")

  // TODO: Add the dependencies for Firebase products you want to use

  // When using the BoM, don't specify versions in Firebase dependencies

  implementation("com.google.firebase:firebase-analytics")


  // Add the dependencies for any other desired Firebase products

  // https://firebase.google.com/docs/android/setup#available-libraries

}
