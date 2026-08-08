plugins {
    id("com.android.library") version "8.4.0"
    id("org.jetbrains.kotlin.android") version "2.2.0"
    id("maven-publish")
}

android {
    namespace = "com.devconnect"
    compileSdk = 36

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
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.json:json:20260522")
    // Required by ViewModelAutoDiscoverer (KClass.memberProperties).
    implementation("org.jetbrains.kotlin:kotlin-reflect:2.2.0")

    // Optional - OkHttp interceptor (compileOnly = user provides their own version)
    compileOnly("com.squareup.okhttp3:okhttp:4.12.0")

    // Optional - Lifecycle ViewModel observer
    compileOnly("androidx.lifecycle:lifecycle-viewmodel-ktx:2.11.0")
    compileOnly("androidx.lifecycle:lifecycle-runtime-ktx:2.11.0")
    // LiveData is touched at runtime by ViewModelAutoDiscoverer, so it
    // can't be compileOnly. Consumers who don't use LiveData pay the
    // ~150 KB AAR cost.
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.11.0")

    // Tests
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.10.2")
    testImplementation("androidx.lifecycle:lifecycle-runtime-ktx:2.11.0")
    testImplementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.11.0")
    testImplementation("androidx.lifecycle:lifecycle-livedata-ktx:2.11.0")
    // OkHttp is compileOnly in the main source set, but reflectively
    // touching DevConnect (which references okhttp3.Interceptor) at test
    // time requires it on the runtime classpath.
    testImplementation("com.squareup.okhttp3:okhttp:4.12.0")
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
