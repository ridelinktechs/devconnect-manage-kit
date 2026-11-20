# DevConnect Manage Kit — Android SDK

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](../../LICENSE)
[![Android](https://img.shields.io/badge/Android-SDK%2021%2B-3DDC84?logo=android)](https://developer.android.com)

Debug your Android app with [DevConnect Manage Tool](https://github.com/ridelinktechs/devconnect-manage-kit) — network, state, logs, storage, database, performance — all in one desktop tool.

## Install

The SDK is published to **Maven Central** as `io.github.buivietphi:devconnect-android`.
`mavenCentral()` is usually already in your repository list, but if you've
stripped it down, add it back:

```gradle
// settings.gradle.kts
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

// app/build.gradle.kts
dependencies {
    implementation("io.github.buivietphi:devconnect-android:1.1.0")
}
```

## Runtime dependencies

The AAR does **not** bundle its runtime dependencies — Gradle AAR
consumption does not pull transitive `implementation` deps. You must
declare the following in your `app/build.gradle` if you use the matching
features (skip any line for features you don't use):

```gradle
dependencies {
    // Always required (SDK's own implementation deps).
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.json:json:20260522")
    implementation("org.jetbrains.kotlin:kotlin-reflect:2.2.0")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.11.0")

    // Required only if you wire the OkHttp interceptor (compileOnly in the SDK).
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // Required only if you call DevConnect.stateObserver().observe(...) manually.
    // (autoViewModelDiscovery does NOT need these — it reflects directly.)
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.11.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.11.0")
}
```

If you forget `kotlin-reflect`, the app crashes on first Activity resume
with `NoClassDefFoundError: kotlin/reflect/full/KClasses` (the
`ViewModelAutoDiscoverer` uses `KClass.memberProperties` reflection).

## Quick Start

The fastest way to wire DevConnect is `installForApp()` — one call turns on
all auto-wiring flags: ANR detection, ViewModel state auto-discovery,
auto-intercepted logs, performance, memory-leak and benchmark monitors.

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

### Recommended: `DevConnectJava` facade

Calling every entry point through `DevConnect.INSTANCE` and passing every
default argument positionally gets tedious. The SDK ships with a
Java-friendly facade — `com.devconnect.DevConnectJava` — that exposes
every public method as a plain `static` and overloads the most useful
default-argument combinations:

```java
import com.devconnect.DevConnectJava;

public class MyApplication extends Application {
    @Override public void onCreate() {
        super.onCreate();
        DevConnectJava.installForApp(this, "MyApp", BuildConfig.DEBUG);
    }
}
```

The full Java reference lives in
[`docs/java-usage.md`](docs/java-usage.md). The short version:

```java
// Lifecycle
DevConnectJava.installForApp(this, "MyApp", BuildConfig.DEBUG);
DevConnectJava.isConnected();
DevConnectJava.disconnect();

// Network — add to OkHttpClient.Builder (Retrofit, Firebase, OAuth2…)
OkHttpClient client = new OkHttpClient.Builder()
    .addInterceptor(DevConnectJava.okHttpInterceptor())
    .build();

// Logs
DevConnectJava.log("User logged in", "AuthService");
DevConnectJava.error("Network failed", "AuthService", stackTrace);
DevConnectJava.sendLog("info", "Custom", "MyTag", null);

// Storage reporters
SharedPrefsReporter sp = DevConnectJava.sharedPrefsReporter();
sp.reportWrite("token", "abc");

// Custom command (Java-friendly functional interface)
DevConnectJava.registerCommand("clearCache", args -> {
    // … do work …
    return java.util.Collections.singletonMap("cleared", true);
});

// Reload override (skip the default Activity.recreate)
DevConnectJava.setOnReloadRequest(() -> {
    // wipe in-memory state, then trigger your own reload
});
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
    autoInterceptHttp = true,       // no-op: HttpURLConnection can't be auto-captured; use okHttpInterceptor()
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

#### Controls from the desktop

State Inspector › **Controls** watches state paths with no app code. Restoring
a snapshot and dispatching an action call these handlers, on the main thread,
so they can update views and LiveData directly:

```kotlin
// Restore: apply a snapshot sent from the desktop
DevConnect.onStateRestore = { state -> viewModel.restore(state) }

// Dispatch action: the desktop sends a map such as {"type": "LOGOUT"}
DevConnect.onReduxDispatch = { action -> viewModel.handle(action) }
```

Values arrive as maps and lists; a JSON `null` member is left out of its map,
so reading that key gives `null`. A throw in either handler shows in the
desktop's Console.

### Crash & ANR detection

When `autoAnrWatchdog = true` (the default for `installForApp`), a
daemon thread pings the main `Looper` every 500 ms and reports an
`anr` `performance_metric` event the moment the main thread is blocked
for ≥6 seconds. The event payload includes the first 20 frames of the
main thread's stack trace. The same monitor reports uncaught Java/Kotlin
exceptions, which show in the desktop's **Errors** tab with their stack
trace.

**Native (C++/JNI) crashes** are captured automatically by the bundled
NDK signal handler — call `NativeCrashHandler.start()` once after
install and SIGSEGV/SIGABRT/SIGBUS/SIGFPE/SIGILL crashes report a
native backtrace before the process dies. You can still report your
own via `ErrorMonitor.reportNativeCrash(signal, stackTrace)`.

### WebSocket inspector

Open OkHttp WebSockets through `DevConnect.newWebSocket` to stream
open / frame / close events (`client:ws_*`) to the desktop, including
the frames your app sends:

```kotlin
val ws = DevConnect.newWebSocket(client, request, listener)
ws.send("subscribe") // shows as a sent frame
```

Your `listener` gets that same `ws` in its callbacks, so sends made there
are captured too. `client.newWebSocket(request, devConnectWrap(listener))`
still works, but only sees incoming frames, open and close.

### GraphQL / gRPC

```kotlin
// Apollo Kotlin
apolloClient.addInterceptor(DevConnect.apolloInterceptor())

// gRPC (io.grpc.ClientInterceptor)
channel = ManagedChannelBuilder.forAddress(host, port)
    .intercept(DevConnect.grpcClientInterceptor())
    .build()
```

### Mock Server

Rules you save in the desktop's **Mock** tab reach the app over the
websocket when you click **Push all**; each mocked request is listed in the
desktop's **Network › Mock Audit**. Add the mock interceptor to your OkHttp
client, **after** DevConnect's own interceptor so mocked responses still
show in the HTTP tab:

```kotlin
val client = OkHttpClient.Builder()
    .addInterceptor(DevConnect.okHttpInterceptor())
    .addInterceptor(DevConnect.mockServerInterceptor())
    .build()
```

A request that matches an enabled rule (method + URL regex + optional
header regexes, within the rule's device scope and before its
`expiresAt`) gets the canned response, after the optional delay, instead
of going to the network. Push rules programmatically with
`DevConnect.installMockRulesFromJson(json)`.

### Jetpack Compose

`ComposeStateObserver.start()` reports composable state reads/writes so
the desktop State Inspector can show Compose state alongside
ViewModel/StateFlow/LiveData. Call `stop()` when done.

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

With `autoPerformance` (on by default) the desktop's **Perf** tab fills in on
its own: FPS, jank frames, frame build time, CPU, memory and its peak,
threads and startup time. Report your own metrics too:

```kotlin
DevConnect.reportPerformanceMetric(metricType = "fps", value = 58.5, label = "Main Thread FPS")
```

### Benchmark

With `autoBenchmark` (on by default) the desktop's **Bench** tab times the
app's startup and each stay in the background. Time your own flows step by
step:

```kotlin
DevConnect.benchmarkStart("loadHome")
fetchUser()
DevConnect.benchmarkStep("loadHome")
fetchPosts()
DevConnect.benchmarkStop("loadHome")
```

Or time a screen; the returned function stops the timer:

```kotlin
val stop = com.devconnect.plugins.benchmarkScreen("HomeScreen")
// ... once the screen is shown
stop()
```

### Memory Leaks

`MemoryLeakDetector` (`autoMemoryLeak`, on by default) reports to the
desktop's **Leaks** tab. Report your own:

```kotlin
DevConnect.reportMemoryLeak(
    leakType = "growing_collection",
    severity = "critical", // info, warning or critical
    objectName = "imageCache",
    detail = "Map grows without bound: 15,200 entries, expected under 500",
    retainedSizeBytes = 48_000_000,
)
```

From Java: `DevConnectJava.reportMemoryLeak("growing_collection", "critical", "imageCache");`

### Display

Send any value to watch in the desktop's **Display** tab; each call adds a
snapshot:

```kotlin
DevConnect.display(
    "Feature Flags",
    value = mapOf("newCheckout" to true, "wishlist" to false),
    preview = "newCheckout on · wishlist off",
)
```

From Java: `DevConnectJava.display("Feature Flags", flags, "newCheckout on");`

### Async Operations

Report the start and the end of async work; the desktop's **Async** tab
shows each with its duration:

```kotlin
DevConnect.reportAsyncOperation("background_job", "syncCart", "start")
syncCart()
DevConnect.reportAsyncOperation("background_job", "syncCart", "resolve", duration = 840)
// or "reject", with error = "..."
```

From Java: `DevConnectJava.reportAsyncOperation("background_job", "syncCart", "resolve", 840L, null, null, null);`

### Custom Commands

```kotlin
DevConnect.registerCommand("clearCache") { args ->
    mapOf("cleared" to true)
}
```

Registered commands show up in the desktop's **Commands** tab, where you
run them with optional JSON args and see what they return.

### Database Browser

Let the desktop's **Database** tab browse your SQLite tables and run SQL —
pass a function that runs one statement and returns its cursor (the SDK
reads and closes it):

```kotlin
DevConnect.registerDatabase("app.db") { sql -> db.rawQuery(sql, null) }
// Room
DevConnect.registerDatabase("room") { sql -> roomDb.openHelper.readableDatabase.query(sql) }
```

Java: `DevConnectJava.registerDatabase("app.db", sql -> db.rawQuery(sql, null));`.
Results are capped at 1000 rows.

### Storage Editing

The desktop's **Storage** tab lists, edits, deletes and clears stores
wrapped with `DevConnectSharedPrefs` / `DevConnectMMKV`. For any other:

```kotlin
DevConnect.registerStorage("settings", object : DevConnect.StorageAdapter {
    override fun getAll() = store.all()
    override fun set(key: String, value: Any?) = store.put(key, value)
    override fun remove(key: String) = store.remove(key)
    override fun clear() = store.clear()
})
```

### Layout Inspector

Nothing to set up: the desktop's **Layout** tab captures a screenshot of
the current activity and its view tree, with each view's bounds,
properties, padding and margin (Compose content shows as its `ComposeView`).
Click **Capture** whenever you want the current screen;
[the desktop guide](https://github.com/ridelinktechs/devconnect-manage-kit#layout-inspector)
covers picking elements, zooming and measuring.

### Reload from Desktop

The desktop's reload (<kbd>⌘</kbd> <kbd>R</kbd>, or <kbd>Ctrl</kbd> <kbd>R</kbd>
on Windows; add <kbd>Shift</kbd> for a restart) recreates the current
activity: the closest Android has to a hot reload. To wipe in-memory state
first, set your own handler, which then does the reload itself:

```kotlin
DevConnect.onReloadRequest = {
    viewModelCache.clear()
    startActivity(
        Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK),
    )
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
- [Full Documentation](https://github.com/ridelinktechs/devconnect-manage-kit#sdks)
- [Using the desktop app, page by page](https://github.com/ridelinktechs/devconnect-manage-kit#using-the-desktop-app)

## License

MIT - by [buivietphi](https://github.com/buivietphi)
