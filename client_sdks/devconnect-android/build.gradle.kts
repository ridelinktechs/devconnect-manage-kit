plugins {
    id("com.android.library") version "8.4.0"
    id("org.jetbrains.kotlin.android") version "2.2.0"
    id("com.vanniktech.maven.publish") version "0.34.0"
}

android {
    namespace = "com.devconnect"
    compileSdk = 36

    defaultConfig {
        minSdk = 21
        aarMetadata {
            minCompileSdk = 21
        }
        // Native crash handler is built per-ABI and shipped inside
        // the AAR. We don't restrict ABIs because the consumer app's
        // APK packaging already merges the right .so files; letting
        // Gradle build all ABIs keeps the AAR universal without
        // requiring consumers to configure splits.
        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++17"
                // Limit NDK build to one ABI in CI to halve build
                // time — `arm64-v8a` covers 99% of devices.
                arguments += listOf(
                    "-DANDROID_STL=c++_static",
                )
            }
        }
    }

    // CMake build for libdc-native.so. The source is in
    // src/main/cpp/. Consumers don't need NDK installed; the .so
    // files ship pre-built inside the AAR.
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
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
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.json:json:20260522")
    // Required by ViewModelAutoDiscoverer (KClass.memberProperties).
    implementation("org.jetbrains.kotlin:kotlin-reflect:2.2.0")

    // Optional - OkHttp interceptor (compileOnly = user provides their own version)
    compileOnly("com.squareup.okhttp3:okhttp:5.4.0")

    // Optional - Apollo Kotlin interceptor (Round 3)
    compileOnly("com.apollographql.apollo3:apollo-runtime:3.8.5")
    // Optional - gRPC client interceptor (Round 3)
    compileOnly("io.grpc:grpc-stub:1.83.1")
    compileOnly("io.grpc:grpc-okhttp:1.83.1")
    // Optional - Compose state observer (Round 2)
    compileOnly("androidx.compose.runtime:runtime:1.6.8")

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
    testImplementation("com.squareup.okhttp3:okhttp:5.4.0")
    // Same rationale for the optional Round 2-5 deps: any test that
    // reflectively walks `DevConnect::class.java.getDeclaredMethods(...)`
    // will load every transitive class referenced by the public surface,
    // including Apollo / gRPC / Compose. Keep them on the test classpath
    // so JVM unit-test runs don't NoClassDefFoundError on init.
    testImplementation("com.apollographql.apollo3:apollo-runtime:3.8.5")
    testImplementation("io.grpc:grpc-stub:1.83.1")
    testImplementation("io.grpc:grpc-okhttp:1.83.1")
    testImplementation("androidx.compose.runtime:runtime:1.6.8")
}

// Publishing config for Maven Central via Sonatype Central Portal
// (https://central.sonatype.com/) using the Vanniktech plugin, which
// natively bundles the artifacts and uploads via Central Portal's
// bundle API (the standard `maven-publish` plugin can't hit this API).
//
// Credentials + GPG signing config are read from
// `~/.gradle/gradle.properties` — never committed to the repo.
//
// Required properties in ~/.gradle/gradle.properties:
//   mavenCentralUsername  — User Token username (Sonatype Central Portal)
//   mavenCentralPassword  — User Token password
//   signing.keyId          — GPG key ID (short form, last 8 hex of fingerprint)
//   signing.password       — GPG key passphrase
//   signing.secretKeyRingFile — path to legacy-format secring.gpg
//
// Publish commands:
//   ./gradlew :publishToMavenLocal                       (test config)
//   ./gradlew :publishMavenCentralPublicationToCentralPortal   (push to Central)
mavenPublishing {
    publishToMavenCentral(automaticRelease = false)
    signAllPublications()

    coordinates(
        groupId = "io.github.buivietphi",
        artifactId = "devconnect-android",
        version = "1.0.0"
    )

    pom {
        name.set("DevConnect Android SDK")
        description.set(
            "Android client SDK for DevConnect - auto-intercepts OkHttp, Retrofit, " +
            "Log, Timber, SharedPreferences. Includes ANR watchdog and ViewModel " +
            "auto-discovery (StateFlow/LiveData)."
        )
        url.set("https://github.com/buivietphi/devconnect")
        licenses {
            license {
                name.set("MIT License")
                url.set("https://opensource.org/licenses/MIT")
            }
        }
        developers {
            developer {
                id.set("buivietphi")
                name.set("Bùi Viết Phi")
                email.set("phibvcfc@gmail.com")
            }
        }
        scm {
            connection.set("scm:git:git://github.com/buivietphi/devconnect.git")
            developerConnection.set("scm:git:ssh://git@github.com/buivietphi/devconnect.git")
            url.set("https://github.com/buivietphi/devconnect")
        }
    }
}
