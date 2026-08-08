# DevConnect Manage Kit — Android SDK

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../../LICENSE)
[![Android](https://img.shields.io/badge/Android-SDK%2021%2B-3DDC84?logo=android)](https://developer.android.com)

Debug your Android app with [DevConnect Manage Tool](https://github.com/ridelinktechs/devconnect-manage-kit) — network, state, logs, storage, database, performance — all in one desktop tool.

## Install

```gradle
// settings.gradle.kts
dependencyResolutionManagement {
    repositories {
        maven { url = uri("https://jitpack.io") }
    }
}

// app/build.gradle.kts
dependencies {
    implementation("com.github.ridelinktechs.devconnect-manage-kit:devconnect-manage-android:v1.0.0")
}
```

## Quick Start

The fastest way to wire DevConnect is `installForApp()` — one call turns on
all auto-wiring flags: ANR detection, ViewModel state auto-discovery,
auto-intercepted logs and HTTP, performance, memory-leak and benchmark monitors.

```kotlin
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        DevConnect.installForApp(
            context = this,
            appName = "MyApp",
            enabled = BuildConfig.DEBUG,
        )
    }
}
```

Java callers reach the Kotlin `object` singleton via `DevConnect.INSTANCE`:

```java
DevConnect.INSTANCE.installForApp(
    /* context     = */ this,
    /* appName     = */ "MyApp",
    /* appVersion  = */ BuildConfig.VERSION_NAME,
    /* host        = */ null,
    /* port        = */ 9090,
    /* enabled     = */ BuildConfig.DEBUG,
    /* versionCode = */ String.valueOf(BuildConfig.VERSION_CODE)
);
```

`installForApp` looks for OkHttp and Timber on the classpath and prints a
one-time hint (via `android.util.Log`) telling you how to wire them. The
SDK does not auto-wire Retrofit/Timber — see [Wiring OkHttp / Retrofit](#wiring-okhttp--retrofit)
and [Wiring Timber](#wiring-timber) below.

If you need finer control over which auto-* flags are enabled, call
[`init`](#config) directly instead.

## Config

Use `init()` when you need fine-grained control over which auto-* flags
are turned on:

```kotlin
DevConnect.init(
    context = this,
    appName = "MyApp",
    appVersion = "1.0.0",
    host = null,                    // null = auto-detect, "192.168.1.5" = manual
    port = 9090,                    // default: 9090
    enabled = BuildConfig.DEBUG,    // false in release
    autoInterceptLogs = true,       // true = auto-capture println()
    autoInterceptHttp = true,       // true = auto-capture HttpURLConnection
    autoPerformance = true,         // true = auto-start performance monitor
    autoMemoryLeak = true,          // true = auto-start memory leak detection
    autoBenchmark = true,           // true = auto-start benchmark collector
    autoAnrWatchdog = true,         // true = auto-start the main-thread ANR watchdog
    autoViewModelDiscovery = true,  // true = auto-discover StateFlow/LiveData on ViewModels
)
```

Disable auto-intercept if you want manual control:

```kotlin
DevConnect.init(
    context = this,
    appName = "MyApp",
    autoInterceptLogs = false,      // disable auto — use DevConnect.sendLog() manually
)
```

## Features

### Network

#### Wiring OkHttp / Retrofit

The SDK cannot auto-wire your `OkHttpClient` — you build it inside a DI
module (Hilt, Koin, Dagger), and the SDK has no hook to reach it. Add
`DevConnect.okHttpInterceptor()` once in the same `Builder` chain and
every Retrofit / OkHttp / Glide / Coil / Firebase call goes through the
inspector:

```kotlin
// OkHttp (captures Retrofit, Firebase, OAuth2, Glide, Coil)
val client = OkHttpClient.Builder()
    .addInterceptor(DevConnect.okHttpInterceptor())
    .build()

// Retrofit (Hilt / Dagger module)
@Provides @Singleton
fun provideRetrofit(client: OkHttpClient): Retrofit = Retrofit.Builder()
    .baseUrl(BuildConfig.API_BASE_URL)
    .client(client)
    .addConverterFactory(MoshiConverterFactory.create())
    .build()
```

#### Wiring Ktor

```kotlin
// Ktor
val client = HttpClient {
    install(DevConnect.ktorPlugin())
}
```

If you skip the wiring step, `installForApp` prints a single logcat line
pointing back to this section on startup.

### Logs

```kotlin
// Drop-in replacement for android.util.Log
import com.devconnect.interceptors.DCLog as Log

Log.d("MyTag", "Hello")       // -> Logcat + DevConnect
Log.e("MyTag", "Error", exception)

// Kermit (KMP)
Logger.addLogWriter(DevConnect.kermitWriter())

// Napier (KMP)
Napier.base(DevConnect.napierAntilog())
```

#### Wiring Timber

The SDK does not auto-plant a Timber tree — `Timber.plant()` is an
explicit action in your `Application.onCreate()` and the SDK can't safely
do it for you. Plant a `Tree` that forwards to `DevConnect.sendLog(...)`:

```kotlin
class DevConnectTree : Timber.Tree() {
    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        DevConnectTimberHelper.log(priority, tag, message, t)
    }
}

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Timber.plant(DevConnectTree())
        Timber.plant(Timber.DebugTree())  // optional: also keep logcat
        DevConnect.installForApp(this, "MyApp", enabled = BuildConfig.DEBUG)
    }
}
```

If you skip the Timber wiring, `installForApp` prints a single logcat
line pointing back to this section on startup.

### State

```kotlin
// ViewModel + StateFlow
val observer = DevConnect.stateObserver()
observer.observe(lifecycleScope, viewModel.state, "UserState")

// LiveData
observer.observe(viewLifecycleOwner, viewModel.userLiveData, "UserLiveData")
```

#### Auto-discovery

When `autoViewModelDiscovery = true` (the default for `installForApp`),
the SDK installs an `ActivityLifecycleCallbacks` hook that walks every
`ViewModelStore` for every Activity/Fragment in your app and reflects on
its `StateFlow`/`LiveData` properties. You don't need to call
`stateObserver().observe(...)` per ViewModel — the SDK does it for you.

Turn it off if you only want to expose a small subset of state:

```kotlin
DevConnect.init(
    context = this,
    appName = "MyApp",
    enabled = BuildConfig.DEBUG,
    autoViewModelDiscovery = false,
)
DevConnect.stateObserver().observe(lifecycleScope, viewModel.userState, "UserState")
```

### Crash & ANR detection

When `autoAnrWatchdog = true` (the default for `installForApp`), a
daemon thread pings the main `Looper` every 500 ms and reports an
`anr` `performance_metric` event the moment the main thread is blocked
for ≥6 seconds. The event payload includes the first 20 frames of the
main thread's stack trace.

The watchdog runs entirely on the JVM — no NDK, no native signal
handlers. C++/JNI crashes are not covered; report them via
`ErrorMonitor.reportNativeCrash(signal, stackTrace)` from your own
signal handler if you need them.

### Storage

Supports: SharedPreferences, DataStore, MMKV, Realm, ObjectBox, SQLDelight.

Each library has 2 options: **auto** (wrap once, everything reported) or **manual** (you control what gets reported). Choose per library.

#### SharedPreferences

```kotlin
// Option 1: Auto — wrap once, all get/put/remove auto-reported
val prefs = DevConnectSharedPrefs.wrap(
    context.getSharedPreferences("my_prefs", Context.MODE_PRIVATE)
)
prefs.edit().putString("token", "abc").apply()  // auto-reported
prefs.getString("token", null)                   // auto-reported

// Option 2: Manual — report only what you want
val sp = DevConnect.sharedPrefsReporter()
prefs.edit().putString("token", "abc").apply()
sp.reportWrite("token", "abc")                   // only this gets reported
```

#### MMKV

```kotlin
// Option 1: Auto
val mmkv = com.devconnect.wrappers.DevConnectMMKV.wrap(MMKV.defaultMMKV())
mmkv.encode("token", "abc")   // auto-reported
mmkv.decodeString("token")     // auto-reported

// Option 2: Manual
val reporter = DevConnect.mmkvReporter()
mmkv.encode("token", "abc")
reporter.reportWrite("token", "abc")
```

#### DataStore, Realm, ObjectBox, SQLDelight (manual only)

```kotlin
// DataStore
val ds = DevConnect.dataStoreReporter()
ds.reportWrite("darkMode", true)
ds.reportRead("darkMode", true)

// Realm
val realm = DevConnect.realmReporter()
realm.reportWrite("User", mapOf("name" to "John"))
realm.reportQuery("User", results)
realm.reportDelete("User", mapOf("id" to 1))

// ObjectBox
val obx = DevConnect.objectBoxReporter()
obx.reportWrite("User", mapOf("name" to "John"))
obx.reportQuery("User", results)

// SQLDelight
val sdl = DevConnect.sqlDelightReporter()
sdl.reportQuery("SELECT * FROM users", results)
sdl.reportExecute("INSERT INTO users (name) VALUES (?)", mapOf("name" to "John"))
```

### Database

Supports: Room, SQLDelight.

```kotlin
// Room
val room = DevConnect.roomReporter()
room.reportQuery("SELECT * FROM users", results)
room.reportInsert("users", rowId)

// SQLDelight
val sdl = DevConnect.sqlDelightReporter()
sdl.reportQuery("SELECT * FROM users", results)
sdl.reportExecute("INSERT INTO users (name) VALUES (?)", mapOf("name" to "John"))
```

### Performance

```kotlin
DevConnect.reportPerformanceMetric(metricType = "fps", value = 58.5, label = "Main Thread FPS")
```

### Benchmark

```kotlin
DevConnect.benchmarkStart("loadHome")
fetchUser()
DevConnect.benchmarkStep("loadHome")
fetchPosts()
DevConnect.benchmarkStop("loadHome")
```

### Custom Commands

```kotlin
DevConnect.registerCommand("clearCache") { args ->
    mapOf("cleared" to true)
}
```

## Production Safety

Disabled when `enabled = false` — zero runtime overhead. Use `BuildConfig.DEBUG` to auto-disable in release.

```kotlin
DevConnect.init(context = this, appName = "MyApp", enabled = BuildConfig.DEBUG)
```

## Links

- [Main Repository](https://github.com/ridelinktechs/devconnect-manage-kit)
- [Desktop App Download](https://github.com/ridelinktechs/devconnect-manage-kit/releases)
- [Full Documentation](https://github.com/ridelinktechs/devconnect-manage-kit#android-native-sdk)

## License

MIT - by [ridelinktechs](https://github.com/ridelinktechs)
