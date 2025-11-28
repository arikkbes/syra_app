plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ariksoftware.syra"  // ✅ FIXED: Correct package name
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ✅ ADDED: Signing configurations for release
    signingConfigs {
        create("release") {
            storeFile = file("syra_release_v2.jks")
            storePassword = "Defance.0"
            keyAlias = "syra_key"
            keyPassword = "Defance.0"
        }
    }

    defaultConfig {
        applicationId = "com.ariksoftware.syra"  // ✅ FIXED: Correct application ID
        minSdk = 21  // ✅ FIXED: Firebase minimum requirement
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true  // ✅ ADDED: Required for Firebase
    }

    buildTypes {
        release {
            minifyEnabled = false  // Keep false for now
            shrinkResources = false  // Keep false for now
            signingConfig = signingConfigs.getByName("release")  // ✅ FIXED: Use production keystore
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            applicationIdSuffix = ".debug"
            debuggable = true
        }
    }
}

flutter {
    source = "../.."
}

// ✅ ADDED: Firebase dependencies
dependencies {
    // Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // Firebase services
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-functions")
    
    // MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
}
