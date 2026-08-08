# DevConnect Android SDK — Java Usage

This SDK is written in Kotlin, but it ships with a Java-friendly facade
— `com.devconnect.DevConnectJava` — that mirrors every public entry
point as a plain `static` method and overloads the most useful
default-argument combinations. Java callers do not need to touch
`DevConnect.INSTANCE.*` at all.

If you don't see a wrapper you need, file an issue or use
`DevConnect.INSTANCE.method(...)` directly — Kotlin objects are
callable from Java, just verbose.

## Quick start

```java
import android.app.Application;
import com.devconnect.DevConnectJava;

public class MyApplication extends Application {
    @Override public void onCreate() {
        super.onCreate();
        DevConnectJava.installForApp(this, "MyApp", BuildConfig.DEBUG);
    }
}
```

`installForApp` is the one-call setup — turns on every auto-* flag
(logs, HTTP, performance, memory-leak, benchmark, ANR watchdog,
ViewModel auto-discovery). For fine-grained control, use
`DevConnectJava.init(...)`.

## Wiring OkHttp / Retrofit

```java
import com.devconnect.DevConnectJava;
import okhttp3.OkHttpClient;

OkHttpClient client = new OkHttpClient.Builder()
    .addInterceptor(DevConnectJava.okHttpInterceptor())
    .build();

// Retrofit, Glide, Coil, Firebase, OAuth2 — every call through
// this client is captured automatically.
```

## Wiring Timber

The SDK does not auto-plant a Timber tree. Plant one that forwards to
the SDK's helper:

```java
import com.devconnect.DevConnectJava;
import timber.log.Timber;

public class DevConnectTree extends Timber.Tree {
    @Override protected void log(int priority, String tag, String message, Throwable t) {
        DevConnectJava.timberLog(priority, tag, message, t);
    }
}

// In Application.onCreate()
Timber.plant(new DevConnectTree());
Timber.plant(new Timber.DebugTree());  // optional — also keep logcat
DevConnectJava.installForApp(this, "MyApp", BuildConfig.DEBUG);
```

## Wiring Kermit / Napier

Both KMP loggers are duck-typed — the SDK has no hard dependency, so
you forward via a helper instance:

```java
import co.touchlab.kermit.LogWriter;
import co.touchlab.kermit.Logger;
import com.devconnect.DevConnectJava;

public class DevConnectKermitWriter extends LogWriter {
    private final com.devconnect.interceptors.DevConnectKermitWriter helper =
        DevConnectJava.kermitWriter();
    @Override public void log(co.touchlab.kermit.Severity severity, String message,
                              String tag, Throwable throwable) {
        helper.log(severity.name(), message, tag, throwable);
    }
}

// In Application.onCreate()
Logger.addLogWriter(new DevConnectKermitWriter());
```

The Napier equivalent uses `DevConnectJava.napierAntilog()` and the
helper's `performLog(...)` method.

## State observation

For manual control over which `LiveData` / `StateFlow` to publish to
the inspector, disable the auto-discovery and call the observer
explicitly:

```java
import com.devconnect.DevConnectJava;

DevConnectJava.init(
    /* context               = */ this,
    /* appName               = */ "MyApp",
    /* enabled               = */ BuildConfig.DEBUG,
    /* autoViewModelDiscovery = */ false
);
```

When you want to observe a single piece of state, use the raw Kotlin
observer — `DevConnect.stateObserver()` is reachable from Java:

```java
import com.devconnect.reporters.DevConnectStateObserver;

DevConnectStateObserver observer = DevConnect.INSTANCE.stateObserver();
// observer.observe(lifecycleOwner, viewModel.userData, "UserData");  // see Kotlin docs
```

## Custom commands

Java callers use the `CommandHandler` functional interface — return
any `Object` (or null):

```java
DevConnectJava.registerCommand("clearCache", args -> {
    MyCache.get().clear();
    return java.util.Collections.singletonMap("cleared", true);
});
```

## Listeners

Three listeners bridge Kotlin functional types to Java interfaces:

```java
DevConnectJava.setOnStateRestore(state -> {
    // state is a Map<String, Object> sent from the desktop
    Log.d("DC", "State restored: " + state);
});

DevConnectJava.setOnReduxDispatch(action -> {
    Log.d("DC", "Action: " + action);
});

DevConnectJava.setOnReloadRequest(() -> {
    // wipe in-memory caches, then trigger your own reload
});
```

Pass `null` or call `clearOnStateRestore()` / `clearOnReduxDispatch()`
/ `clearOnReloadRequest()` to revert to the SDK default (which calls
`Activity.recreate()`).

## Performance / memory / benchmarks

```java
DevConnectJava.reportPerformanceMetric("fps", 58.5, "Main Thread FPS");
DevConnectJava.reportMemoryLeak("growing_collection", "critical", "eventCache",
        "15000 items retained", 1_200_000L, null);

DevConnectJava.benchmarkStart("loadHome");
fetchUser();
DevConnectJava.benchmarkStep("loadHome");
fetchPosts();
DevConnectJava.benchmarkStop("loadHome");
```

## Storage reporters

Manual reporting (auto wrappers also exist — see Kotlin README):

```java
import com.devconnect.DevConnectJava;

DevConnectJava.sharedPrefsReporter().reportWrite("token", "abc");
DevConnectJava.dataStoreReporter().reportWrite("darkMode", true);
DevConnectJava.mmkvReporter().reportRead("token", "abc");
DevConnectJava.realmReporter().reportWrite("User",
        java.util.Collections.singletonMap("name", "John"));
DevConnectJava.roomReporter().reportQuery("SELECT * FROM users", null);
DevConnectJava.objectBoxReporter().reportWrite("User",
        java.util.Collections.singletonMap("name", "John"));
DevConnectJava.sqlDelightReporter().reportQuery("SELECT * FROM users", null);
```

## Async / saga tracking

```java
DevConnectJava.reportAsyncStart("saga_call", "Fetching user data", "userSaga");
// … later
DevConnectJava.reportAsyncResolve("saga_call", "Fetching user data",
        "userSaga", 350, result);
// or
DevConnectJava.reportAsyncReject("saga_call", "Fetching user data",
        "userSaga", e.getMessage());
```

## Custom display cards

```java
DevConnectJava.display("User Profile",
        java.util.Collections.singletonMap("name", "John"),
        "John, 30");
```

## Default arguments — what's available

`DevConnectJava.init(...)` mirrors `DevConnect.init` with the most
common combinations:

| Overload                                                | What it covers                                |
| ------------------------------------------------------- | --------------------------------------------- |
| `init(ctx, appName, enabled)`                           | All auto-* on, default host/port              |
| `init(ctx, appName, version, host, port, enabled, …)`   | Full — every auto-* flag explicit              |

`installForApp(...)` mirrors `DevConnect.installForApp`:

| Overload                                                       | What it covers                          |
| -------------------------------------------------------------- | --------------------------------------- |
| `installForApp(ctx, appName, enabled)`                         | All auto-* on, default host/port        |
| `installForApp(ctx, appName, version, enabled)`                | Same + explicit app version             |
| `installForApp(ctx, appName, version, host, port, enabled)`    | Same + manual host/port                 |

## What's NOT in the facade (use Kotlin directly)

The following are intentionally not wrapped — they're either Kotlin-only
patterns (Flow observation) or have idiomatic Java alternatives
already:

- `DevConnect.stateObserver()` — raw Kotlin observer; use the
  auto-discovery (`autoViewModelDiscovery = true`) instead.
- `DevConnectKtorPlugin` — manual Ktor reporting helpers; see Kotlin
  README. Java callers should call
  `DevConnect.INSTANCE.reportNetworkStart(...)` /
  `reportNetworkComplete(...)` directly.
- Extension functions / property delegates — none in this SDK, so no
  `*Kt` static accessor is needed.

For anything missing, the underlying Kotlin source is at
`com.devconnect.DevConnect` and reachable via
`DevConnect.INSTANCE.*` — the facade is convenience, not a wall.