plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.galaxyandsun.daidatanhhung"
    // TODO(pre-release): raise compileSdk/targetSdk to 36 before any Play upload
    // (Play requires API 36 for new apps and updates since 2026-08-31). Luan: 35 for now.
    compileSdk = 35

    defaultConfig {
        applicationId = "com.galaxyandsun.daidatanhhung"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures { buildConfig = true }

    // Shared content (ADR-0001): data/ ships in every build; the sample hero only in debug builds.
    sourceSets {
        getByName("main") { assets.srcDirs("../../content/data") }
        getByName("debug") { assets.srcDirs("../../content/samples") }
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation(libs.kotlinx.serialization.json)
    testImplementation(libs.junit)
}
