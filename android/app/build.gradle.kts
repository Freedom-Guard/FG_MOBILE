plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.freedom.guard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "25.2.9519653"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.freedom.guard"
        minSdk =  flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        release {
            val props = java.util.Properties()
            val keyPropsFile = rootProject.file("key.properties")
            if (keyPropsFile.exists()) {
                props.load(java.io.FileInputStream(keyPropsFile))
                storeFile = file(props["storeFile"] ?: "")
                storePassword = props["storePassword"] as String?
                keyAlias = props["keyAlias"] as String?
                keyPassword = props["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release") 
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }


    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

}

flutter {
    source = "../.."
}
