plugins {
    id("com.android.library") version "8.4.0"
    id("org.jetbrains.kotlin.android") version "1.9.10"
    id("maven-publish")
}

android {
    namespace = "com.devconnect"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
        aarMetadata {
            minCompileSdk = 21
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.json:json:20231013")

    // Optional - OkHttp interceptor (compileOnly = user provides their own version)
    compileOnly("com.squareup.okhttp3:okhttp:4.12.0")

    // Optional - Lifecycle ViewModel observer
    compileOnly("androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0")
    compileOnly("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
}

// Publishing config for JitPack or Maven Local
publishing {
    publications {
        register<MavenPublication>("release") {
            groupId = "com.github.ridelinktechs"
            artifactId = "devconnect-android"
            version = "1.0.0"

            afterEvaluate {
                from(components["release"])
            }

            pom {
                name.set("DevConnect Android SDK")
                description.set("Android client SDK for DevConnect - auto-intercepts OkHttp, Retrofit, Log, Timber, SharedPreferences")
                url.set("https://github.com/ridelinktechs/devconnect")
                licenses {
                    license {
                        name.set("MIT License")
                        url.set("https://opensource.org/licenses/MIT")
                    }
                }
            }
        }
    }
}
