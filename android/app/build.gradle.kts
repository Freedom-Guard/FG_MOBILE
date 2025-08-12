import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.freedom.guard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.freedom.guard"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keyPropsFile = rootProject.file("key.properties")
    val keyProps = Properties()
    if (keyPropsFile.exists()) {
        keyProps.load(FileInputStream(keyPropsFile))
    }

    signingConfigs {
        create("release") {
            storeFile = file(keyProps["storeFile"] ?: "")
            storePassword = keyProps["storePassword"] as String?
            keyAlias = keyProps["keyAlias"] as String?
            keyPassword = keyProps["keyPassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false 
            signingConfig = signingConfigs.getByName("release")
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

val kotlin_version = "1.8.20"  

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:$kotlin_version")
}
