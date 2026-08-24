# Android SDK Expansion — Feature Parity with RN/Flutter

## Problem

The Android SDK currently has 3 notable gaps compared to the React Native and Flutter SDKs (see audit `a5866de2ca01f7bef`, 2026-08-09):

1. **ErrorMonitor is incomplete.** RN and Flutter both capture ANR + native crashes. Android only catches `Thread.UncaughtExceptionHandler` (Java/Kotlin exceptions). SIGSEGV, SIGABRT, SIGBUS, SIGILL, SIGFPE, and silent ANRs all pass through silently — a serious gap for any production Android app.
2. **No auto-discovery for ViewModels.** RN has 6+ state-management integrations (Redux, MobX, Zustand, Jotai, Valtio, XState). Android only ships a generic `StateFlowObserver` + `ViewModelObserver` that the consumer must wire manually for every ViewModel. If the consumer forgets, state changes are invisible.
3. **OkHttp interception requires manual wiring.** RN patches `global.fetch` and catches everything transparently. Android SDK only auto-installs `URLStreamHandlerFactory` for `HttpURLConnection`; Retrofit/OkHttp users must add `DevConnect.okHttpInterceptor()` to every `OkHttpClient.Builder` themselves. Easy to forget, easy to get wrong.

Goal: bring Android to feature parity on these three axes without regressing existing behaviour.

## Approach

Three independent subsystems, shipped in one AAR release. Order matters for testing — ErrorMonitor first (highest-value, hardest to verify), then state-management, then `installForApp`.

### Gap 1 — ErrorMonitor expansion

**ANR Watchdog** — a daemon thread posts a ping `Runnable` to `Looper.getMainLooper()` every 500 ms. The `Runnable` sets a flag when it runs. If the flag is not set within 5 s, we capture `Looper.getMainLooper().thread.stackTrace` and call `DevConnect.reportError(...)` with the stack + the watchdog's own main-thread-ping stack. Standard pattern (SalomonBrys/ANR-WatchDog), public domain.

**Native signal handler** — register `signal()` handlers for SIGSEGV, SIGABRT, SIGBUS, SIGILL, SIGFPE, SIGPIPE, SIGSYS in `JNI_OnLoad`. Signal handlers may only call async-signal-safe functions, so the handler writes the faulting PC + a fixed-size ring buffer of native stack frames (using `unwind.h` from `libunwind` on API 21+, fallback to `<execinfo.h>` `backtrace()`) into a pre-allocated `sig_atomic_t`-guarded slot. A coroutine on `Dispatchers.IO` polls the slot and, when set, reads it, formats the stack as a string, and calls `DevConnect.reportError(...)` via `Handler(Looper.getMainLooper()).post { ... }`.

The signal handler must **not** allocate, lock mutexes, or call into Kotlin/Java directly. It only touches a `volatile sig_atomic_t` and a pre-allocated `char` array. All Kotlin/Java interaction happens later, on a normal thread.

**Backward compatibility.** Existing `Thread.UncaughtExceptionHandler` path stays. `AnrWatchdog.start()` and `NativeCrashHandler.install()` are called from `ErrorMonitor.start()`, gated on `enabled`. Both can be disabled independently via init flags.

### Gap 2 — ViewModel auto-discoverer

**Activity/Fragment lifecycle hook.** `installActivityLifecycleTracker` (already present in `DevConnect.kt`) keeps a `WeakReference` to the topmost Activity. Extend it to also register a `FragmentLifecycleCallbacks` on every `FragmentActivity` we see. For each Activity / Fragment, walk the `ViewModelStore` via reflection (`getViewModelStore()` is public on `ComponentActivity`, internal otherwise — we use `ViewModelStoreOwner.getViewModelStore()` via the `androidx.lifecycle.ViewModelStoreOwner` interface).

**For each ViewModel** in the store, enumerate `KClass.memberProperties` via reflection and find any whose type is `StateFlow<*>` or `LiveData<*>` (or `MutableStateFlow<*>`, `MediatorLiveData<*>`, etc.). For each match, install an observer:
- `StateFlow`: `viewModelScope.launch { flow.collect { ... } }` — but we need a `CoroutineScope`; use `MainScope() + SupervisorJob()` per VM.
- `LiveData`: `liveData.observeForever { ... }` with a `WeakReference` to avoid leaking the VM.

Each state change reports `DevConnect.reportStateChange(stateManager = "<ClassName>", action = "set", newState = value)`. Old values are kept in a small map keyed by property name so we can include `previousState` in the payload.

**Opt-out.** Consumers who don't want auto-discovery can pass `autoViewModelDiscovery = false` to `init()`. Default `true` (matches RN/Flutter behaviour).

### Gap 3 — `installForApp()` helper + sample Hilt module

**Helper method** — add `fun installForApp(context, appName, ..., autoViewModelDiscovery = true, autoAnrWatchdog = true, autoNativeCrashHandler = true)` to `DevConnect`. It wraps `init(...)` and additionally calls:
- `DevConnectLogcatInterceptor.install()` (covers `Log.d/i/w/e`)
- `DevConnectURLStreamHandlerFactory.install()` (covers `HttpURLConnection`)
- `DevConnectLogInterceptor.interceptSystemOut()` (covers `System.out`)
- `com.devconnect.plugins.startErrorMonitor(context, anrWatchdog = autoAnrWatchdog, nativeCrashHandler = autoNativeCrashHandler)` (covers Gap 1)
- `com.devconnect.plugins.startViewModelAutoDiscoverer(context)` (covers Gap 2)

If the consumer still uses Retrofit/OkHttp/Timber, `installForApp` logs a one-time WARN to logcat pointing at the README section that shows the wiring. The wiring itself stays manual (no reflection magic — see "Out of scope" below).

**Sample Hilt module** — `client_sdks/devconnect-android/sample-integration/NetworkModule.kt.template`. A drop-in `@Module @InstallIn(SingletonComponent::class)` that exposes a `DevConnectOkHttpInterceptor` provider and shows how to add it to a `@Provides` for `OkHttpClient.Builder`. Documented as "copy this file into your project, delete the parts you don't need."

**README update.** Add a "Quick start" section that says: 1 line for `installForApp`, 1 file copy for Retrofit/OkHttp if needed, 1 line for Timber if needed. Old docs section keeps the manual wiring path for users who want fine-grained control.

## Data flow

```
┌─ app process ──────────────────────────────────────────────┐
│                                                             │
│  DevConnect.installForApp(ctx, ...)                        │
│      ├─ init(ctx, ...)               [set enabled, scope]  │
│      ├─ Logcat.install()             [patch Log.*]         │
│      ├─ URLStreamHandlerFactory      [patch URL.openConnection]
│      ├─ interceptSystemOut()          [patch System.out]   │
│      ├─ startErrorMonitor             [wire UEH + ANR + native]
│      └─ startViewModelAutoDiscoverer  [hook Activity/Fragment]
│                                                             │
│  ANR Watchdog thread ─── ping ──► main Looper              │
│      if no ack in 5s ──► DevConnect.reportError             │
│                                                             │
│  Signal handler (SIGSEGV etc) ──► ring buffer ─► coroutine │
│      coroutine ──► DevConnect.reportError                   │
│                                                             │
│  ViewModel auto-discoverer ──► StateFlow.collect / LiveData.observe
│      on change ──► DevConnect.reportStateChange             │
│                                                             │
│  DevConnect.send ──► WebSocketClient.send ──► desktop       │
└─────────────────────────────────────────────────────────────┘
```

## Error handling

| Failure | Behaviour |
|---|---|
| `URLStreamHandlerFactory.install()` throws (another factory already set) | WARN log already exists in SDK; surface the same message via `installForApp` so consumers see it once at boot. |
| `LogcatInterceptor.install()` reflection fails (no Square Logcat on classpath) | Existing handler already sends a WARN; no change. |
| `AnrWatchdog` ping itself fails (Looper hung) | Capture watchdog thread's own stack as fallback; the Looper is hung but the watchdog thread is not. |
| Native signal handler fires before `JNI_OnLoad` | Impossible — handlers are registered in `JNI_OnLoad`, not at constructor time. |
| Native handler re-entry (signal during handler) | Use a `static std::atomic_flag` to drop nested signals. |
| `ViewModelStore.getViewModelStore()` not accessible (pre-AndroidX app) | Catch `NoSuchMethodError`; skip auto-discovery silently. |
| Consumer hasn't initialised Retrofit/OkHttp at `installForApp` time | `installForApp` cannot help; WARN log + README pointer. |
| State change happens during shutdown (after `disconnect()`) | `send()` already drops events when `!enabled`. |

## Out of scope

- **Magic reflection auto-install for OkHttp.** Considered, rejected (brittle, breaks across OkHttp versions, hard to debug). Sample Hilt module + WARN log is the alternative.
- **MVI-specific reporters** (MVIKotlin, Orbit, MVI-Coroutines). Generic StateFlow/LiveData auto-discovery covers ~80% of Android apps; library-specific reporters can come later if there's demand.
- **WebView JS error capture.** Different subsystem; not in scope for parity.
- **iOS parity work.** Not in scope; this spec is Android only.

## Testing

For each gap:

- **Unit tests** (in `client_sdks/devconnect-android/src/test/java/com/devconnect/plugins/`):
  - `AnrWatchdogTest` — mock main looper, verify timeout triggers, verify stack capture
  - `ViewModelAutoDiscovererTest` — fake ViewModelStore, verify reflection picks up StateFlow/LiveData
  - `installForAppTest` — verify each install call is invoked exactly once, verify WARN log when init fails
- **Manual smoke tests** (run on ep_android):
  - Trigger ANR: post a 10-second sleep to main thread, confirm ANR event arrives on desktop
  - Native crash: trigger `System.exit(1)` from a JNI test, confirm signal handler fires
  - ViewModel state change: existing ViewModel updates `StateFlow`, confirm desktop sees the change without manual wiring
  - `installForApp`: replace `init()` with `installForApp()`, confirm same network/log events flow through

## Files

**New:**
- `client_sdks/devconnect-android/src/main/java/com/devconnect/plugins/AnrWatchdog.kt`
- `client_sdks/devconnect-android/src/main/java/com/devconnect/plugins/ViewModelAutoDiscoverer.kt`
- `client_sdks/devconnect-android/src/main/cpp/signal_handler.cpp`
- `client_sdks/devconnect-android/src/main/cpp/CMakeLists.txt`
- `client_sdks/devconnect-android/sample-integration/NetworkModule.kt.template`
- `client_sdks/devconnect-android/src/test/java/com/devconnect/plugins/AnrWatchdogTest.kt`
- `client_sdks/devconnect-android/src/test/java/com/devconnect/plugins/ViewModelAutoDiscovererTest.kt`
- `client_sdks/devconnect-android/src/test/java/com/devconnect/DevConnectInstallForAppTest.kt`

**Updated:**
- `client_sdks/devconnect-android/src/main/java/com/devconnect/plugins/ErrorMonitor.kt` — call AnrWatchdog + NativeCrashHandler
- `client_sdks/devconnect-android/src/main/java/com/devconnect/DevConnect.kt` — `installForApp()` method, init flag plumbing
- `client_sdks/devconnect-android/src/main/java/com/devconnect/DevConnect.java` template (consumer-side docs in KDoc)
- `client_sdks/devconnect-android/build.gradle.kts` — add `externalNativeBuild { cmake { ... } }` block
- `client_sdks/devconnect-android/README.md` — Quick start section

**Test integration:**
- `ep_android/app/src/main/java/jp/co/ecoplan/report/app/main/MainApplication.java` — switch from `DevConnect.INSTANCE.init(...)` to `DevConnect.INSTANCE.installForApp(this, ...)` after AAR rebuild

## Non-goals

- No commitment of any file (per standing instruction: "không commit bất kỳ commit nào").
- No breaking change to existing `init()` signature — `installForApp` is purely additive.
- No dependency on NDK / cmake at runtime — `externalNativeBuild` is compile-time only; consumers don't need NDK installed to build apps that depend on the AAR.