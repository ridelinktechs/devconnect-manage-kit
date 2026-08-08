package com.devconnect;

import android.content.Context;

import com.devconnect.interceptors.DCLog;
import com.devconnect.interceptors.DevConnectKermitWriter;
import com.devconnect.interceptors.DevConnectLogInterceptor;
import com.devconnect.interceptors.DevConnectNapierAntilog;
import com.devconnect.interceptors.DevConnectTimberHelper;
import com.devconnect.interceptors.OkHttpInterceptor;
import com.devconnect.reporters.DataStoreReporter;
import com.devconnect.reporters.DevConnectStateObserver;
import com.devconnect.reporters.LogReporter;
import com.devconnect.reporters.MmkvReporter;
import com.devconnect.reporters.ObjectBoxReporter;
import com.devconnect.reporters.RealmReporter;
import com.devconnect.reporters.RoomReporter;
import com.devconnect.reporters.SQLDelightReporter;
import com.devconnect.reporters.SharedPrefsReporter;
import com.devconnect.wrappers.DevConnectRealm;

import java.util.Map;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;

/**
 * Java-friendly facade for the Kotlin {@link DevConnect} singleton.
 *
 * <p>The Kotlin SDK exposes a single {@code object DevConnect} whose public
 * methods are reachable from Java only via the awkward
 * {@code DevConnect.INSTANCE.method(...)} prefix and a long list of
 * positional parameters (Kotlin default arguments aren't visible from
 * Java). This class mirrors every entry point a Java caller would want,
 * as plain {@code static} methods with overloaded signatures.</p>
 *
 * <p>Lambdas that Kotlin exposes as {@code ((Map) -> Unit)?} properties
 * ({@code onStateRestore}, {@code onReduxDispatch}, {@code onReloadRequest})
 * are wrapped in nested interfaces — see {@link CommandHandler},
 * {@link StateListener}, {@link ActionListener}, {@link ReloadHandler}.</p>
 *
 * <h2>Quick start (Java)</h2>
 * <pre>{@code
 * public class MyApplication extends Application {
 *     @Override public void onCreate() {
 *         super.onCreate();
 *         DevConnectJava.installForApp(this, "MyApp", BuildConfig.DEBUG);
 *     }
 * }
 * }</pre>
 */
public final class DevConnectJava {

    private DevConnectJava() {
        // Static facade — no instances.
    }

    // ───────────────────── Lifecycle ─────────────────────

    /**
     * One-call setup. Equivalent to Kotlin {@code DevConnect.installForApp}.
     *
     * <p>Turns on every auto-* flag (logs, HTTP, performance, memory-leak,
     * benchmark, ANR watchdog, ViewModel auto-discovery). For fine-grained
     * control use {@link #init(Context, String, boolean)}.</p>
     *
     * @param context     your {@link Application}
     * @param appName     your app's display name
     * @param enabled     pass {@code BuildConfig.DEBUG} in debug builds,
     *                    {@code false} in release. When {@code false} the
     *                    SDK is a no-op — zero overhead.
     */
    public static void installForApp(Context context, String appName, boolean enabled) {
        DevConnect.INSTANCE.installForApp(context, appName, "1.0.0", null, 9090, enabled, null);
    }

    /** Convenience overload with explicit app version. */
    public static void installForApp(Context context, String appName, String appVersion, boolean enabled) {
        DevConnect.INSTANCE.installForApp(context, appName, appVersion, null, 9090, enabled, null);
    }

    /** Convenience overload with manual host/port. */
    public static void installForApp(Context context, String appName, String appVersion,
                                     String host, int port, boolean enabled) {
        DevConnect.INSTANCE.installForApp(context, appName, appVersion, host, port, enabled, null);
    }

    /**
     * Fine-grained init. Equivalent to Kotlin {@code DevConnect.init} but
     * with the most useful defaults already set. Use this when you want to
     * disable some auto-* features.
     *
     * <p>Default behaviour: all auto-* flags on, auto host detection on,
     * port 9090, app version {@code "1.0.0"}.</p>
     */
    public static void init(Context context, String appName, boolean enabled) {
        DevConnect.INSTANCE.init(context, appName, "1.0.0", null, 9090, true, enabled,
                null, true, true, true, true, true, true, true);
    }

    /** Full overload — matches every {@code auto*} flag in {@code DevConnect.init}. */
    public static void init(Context context, String appName, String appVersion,
                            String host, int port, boolean enabled,
                            boolean autoInterceptLogs, boolean autoInterceptHttp,
                            boolean autoPerformance, boolean autoMemoryLeak,
                            boolean autoBenchmark, boolean autoAnrWatchdog,
                            boolean autoViewModelDiscovery) {
        DevConnect.INSTANCE.init(context, appName, appVersion, host, port, true, enabled,
                null, autoInterceptLogs, autoInterceptHttp, autoPerformance,
                autoMemoryLeak, autoBenchmark, autoAnrWatchdog, autoViewModelDiscovery);
    }

    /** {@code true} once the WebSocket has connected to the desktop. */
    public static boolean isConnected() {
        return DevConnect.INSTANCE.isConnected();
    }

    /** Tear down the WebSocket. Call before re-init or in tests. */
    public static void disconnect() {
        DevConnect.INSTANCE.disconnect();
    }

    // ───────────────────── Network ─────────────────────

    /**
     * Returns an OkHttp {@link okhttp3.Interceptor} that captures every
     * request the client issues. Add it to your {@code OkHttpClient.Builder}
     * — Retrofit, Glide, Coil, Firebase and OAuth2 calls all flow through
     * the same builder and are captured automatically.
     */
    public static OkHttpInterceptor okHttpInterceptor() {
        return DevConnect.INSTANCE.okHttpInterceptor();
    }

    // ───────────────────── Logs ─────────────────────

    /** Info-level log. */
    public static void log(String message) {
        DevConnect.INSTANCE.log(message, null, null);
    }

    /** Info-level log with tag. */
    public static void log(String message, String tag) {
        DevConnect.INSTANCE.log(message, tag, null);
    }

    /** Debug-level log. */
    public static void debug(String message) {
        DevConnect.INSTANCE.debug(message, null, null);
    }

    public static void debug(String message, String tag) {
        DevConnect.INSTANCE.debug(message, tag, null);
    }

    /** Warning-level log. */
    public static void warn(String message) {
        DevConnect.INSTANCE.warn(message, null, null);
    }

    public static void warn(String message, String tag) {
        DevConnect.INSTANCE.warn(message, tag, null);
    }

    /** Error-level log with optional stack trace. */
    public static void error(String message, String tag, String stackTrace) {
        DevConnect.INSTANCE.error(message, tag, stackTrace, null);
    }

    public static void error(String message, String tag) {
        DevConnect.INSTANCE.error(message, tag, null, null);
    }

    public static void error(String message) {
        DevConnect.INSTANCE.error(message, null, null, null);
    }

    /**
     * Low-level log send — use this when forwarding from Timber /
     * println. Level is one of {@code "debug"}, {@code "info"},
     * {@code "warn"}, {@code "error"}.
     */
    public static void sendLog(String level, String message, String tag, String stackTrace) {
        DevConnect.INSTANCE.sendLog(level, message, tag, stackTrace, null);
    }

    /** Returns a tagged logger that auto-redacts sensitive metadata keys. */
    public static LogReporter logger(String tag) {
        return DevConnect.INSTANCE.logger(tag);
    }

    // ───────────────────── State ─────────────────────

    /**
     * Returns the state-flow observer singleton. Use to observe
     * {@code StateFlow}/{@code LiveData} manually, or rely on the SDK's
     * auto-discovery (default on for {@link #installForApp}).
     */
    public static DevConnectStateObserver stateObserver() {
        return DevConnect.INSTANCE.stateObserver();
    }

    /**
     * Manually report a state change.
     *
     * @param stateManager  a name (e.g. {@code "UserState"})
     * @param action        short verb phrase (e.g. {@code "logged_in"})
     * @param previousState null or a {@code {key -> value}} map
     * @param nextState     null or a {@code {key -> value}} map
     */
    public static void reportStateChange(String stateManager, String action,
                                         Map<String, Object> previousState,
                                         Map<String, Object> nextState) {
        DevConnect.INSTANCE.reportStateChange(stateManager, action, previousState, nextState);
    }

    // ───────────────────── Storage reporters ─────────────────────

    /** SharedPreferences reporter (manual mode). */
    public static SharedPrefsReporter sharedPrefsReporter() {
        return DevConnect.INSTANCE.sharedPrefsReporter();
    }

    /** DataStore (Preferences) reporter. */
    public static DataStoreReporter dataStoreReporter() {
        return DevConnect.INSTANCE.dataStoreReporter();
    }

    /** Room database reporter. */
    public static RoomReporter roomReporter() {
        return DevConnect.INSTANCE.roomReporter();
    }

    /** Realm database reporter. */
    public static RealmReporter realmReporter() {
        return DevConnect.INSTANCE.realmReporter();
    }

    /** Realm auto-wrapper — see {@code DevConnectRealm.wrapWrite/wrapQuery} for usage. */
    public static DevConnectRealm realmWrapper() {
        return DevConnect.INSTANCE.realmWrapper();
    }

    /** ObjectBox reporter. */
    public static ObjectBoxReporter objectBoxReporter() {
        return DevConnect.INSTANCE.objectBoxReporter();
    }

    /** SQLDelight reporter. */
    public static SQLDelightReporter sqlDelightReporter() {
        return DevConnect.INSTANCE.sqlDelightReporter();
    }

    /** MMKV reporter. */
    public static MmkvReporter mmkvReporter() {
        return DevConnect.INSTANCE.mmkvReporter();
    }

    /**
     * Low-level storage event reporter. {@code value} may be {@code null};
     * keys matching {@code token}/{@code password}/{@code authorization}/…
     * are auto-redacted before they leave the device.
     */
    public static void reportStorageOperation(String storageType, String key, Object value, String operation) {
        DevConnect.INSTANCE.reportStorageOperation(storageType, key, value, operation);
    }

    // ───────────────────── Performance / Memory ─────────────────────

    /**
     * Report a single performance metric.
     *
     * @param metricType  one of {@code fps}, {@code memory_usage},
     *                    {@code cpu_usage}, {@code jank_frame}, …
     * @param value       numeric value (FPS, MB, %, ms)
     * @param label       optional human-readable label
     */
    public static void reportPerformanceMetric(String metricType, double value, String label) {
        DevConnect.INSTANCE.reportPerformanceMetric(metricType, value, label, null);
    }

    public static void reportPerformanceMetric(String metricType, double value) {
        DevConnect.INSTANCE.reportPerformanceMetric(metricType, value, null, null);
    }

    /**
     * Report a detected memory leak. See Kotlin doc for full
     * {@code leakType}/{@code severity} value list.
     */
    public static void reportMemoryLeak(String leakType, String severity, String objectName,
                                        String detail, Long retainedSizeBytes, String stackTrace) {
        DevConnect.INSTANCE.reportMemoryLeak(leakType, severity, objectName, detail,
                retainedSizeBytes, stackTrace, null);
    }

    public static void reportMemoryLeak(String leakType, String severity, String objectName) {
        DevConnect.INSTANCE.reportMemoryLeak(leakType, severity, objectName, null, null, null, null);
    }

    // ───────────────────── Benchmark ─────────────────────

    /** Mark the start of a benchmark named {@code title}. */
    public static void benchmarkStart(String title) {
        DevConnect.INSTANCE.benchmarkStart(title);
    }

    /** Add a step (intermediate checkpoint) inside a benchmark. */
    public static void benchmarkStep(String title) {
        DevConnect.INSTANCE.benchmarkStep(title);
    }

    /** Mark the end of a benchmark and emit the elapsed-time payload. */
    public static void benchmarkStop(String title) {
        DevConnect.INSTANCE.benchmarkStop(title);
    }

    // ───────────────────── State snapshot ─────────────────────

    /** Send a full state snapshot (one-shot, not a delta). */
    public static void sendStateSnapshot(String stateManager, Map<String, Object> state) {
        DevConnect.INSTANCE.sendStateSnapshot(stateManager, state);
    }

    // ───────────────────── Custom commands ─────────────────────

    /**
     * Register a handler for a custom desktop-side command. The handler
     * receives an optional args map and may return any object (or null).
     *
     * <p>Java example:</p>
     * <pre>{@code
     * DevConnectJava.registerCommand("clearCache", args -> {
     *     Cache.get().clear();
     *     return java.util.Collections.singletonMap("cleared", true);
     * });
     * }</pre>
     */
    public static void registerCommand(String name, CommandHandler handler) {
        @SuppressWarnings({"rawtypes", "unchecked"})
        Function1 adapter = args -> {
            handler.onCommand((Map<String, Object>) args);
            return Unit.INSTANCE;
        };
        DevConnect.INSTANCE.registerCommand(name, adapter);
    }

    // ───────────────────── Listeners (Java-friendly) ─────────────────────

    /** Called when the desktop restores a state snapshot. */
    public static void setOnStateRestore(StateListener listener) {
        @SuppressWarnings({"rawtypes", "unchecked"})
        Function1 adapter = state -> {
            listener.onState((Map<String, Object>) state);
            return Unit.INSTANCE;
        };
        DevConnect.INSTANCE.setOnStateRestore(adapter);
    }

    /** Clear the state-restore listener. */
    @SuppressWarnings("rawtypes")
    public static void clearOnStateRestore() {
        Function1<Map<String, ? extends Object>, Unit> nullFn = null;
        DevConnect.INSTANCE.setOnStateRestore(nullFn);
    }

    /** Called when the desktop dispatches a Redux/ViewModel action. */
    public static void setOnReduxDispatch(ActionListener listener) {
        @SuppressWarnings({"rawtypes", "unchecked"})
        Function1 adapter = action -> {
            listener.onAction((Map<String, Object>) action);
            return Unit.INSTANCE;
        };
        DevConnect.INSTANCE.setOnReduxDispatch(adapter);
    }

    @SuppressWarnings("rawtypes")
    public static void clearOnReduxDispatch() {
        Function1<Map<String, ? extends Object>, Unit> nullFn = null;
        DevConnect.INSTANCE.setOnReduxDispatch(nullFn);
    }

    /**
     * Override the default reload behaviour (which calls
     * {@code Activity.recreate()}). Useful when you need to wipe
     * in-memory caches before reload — if you set a custom handler the
     * default recreate will NOT run.
     */
    public static void setOnReloadRequest(ReloadHandler handler) {
        @SuppressWarnings("rawtypes")
        kotlin.jvm.functions.Function0<Unit> adapter = () -> {
            handler.onReload();
            return Unit.INSTANCE;
        };
        DevConnect.INSTANCE.setOnReloadRequest(adapter);
    }

    public static void clearOnReloadRequest() {
        DevConnect.INSTANCE.setOnReloadRequest((kotlin.jvm.functions.Function0<Unit>) null);
    }

    // ───────────────────── Interceptor helpers (Java) ─────────────────────

    /**
     * Routes every {@code System.out}/{@code System.err} {@code println}
     * to DevConnect. Idempotent — safe to call multiple times.
     */
    public static void interceptSystemOut() {
        DevConnectLogInterceptor.INSTANCE.interceptSystemOut();
    }

    /** Forward an Android-style Timber log to DevConnect. */
    public static void timberLog(int priority, String tag, String message, Throwable throwable) {
        DevConnectTimberHelper.INSTANCE.log(priority, tag, message, throwable);
    }

    /** Get a Timber helper instance for forwarding {@code Timber.Tree.log}. */
    public static DevConnectTimberHelper timberHelper() {
        return DevConnectTimberHelper.INSTANCE;
    }

    /** Get a Kermit writer instance for forwarding {@code LogWriter.log}. */
    public static DevConnectKermitWriter kermitWriter() {
        return new DevConnectKermitWriter();
    }

    /** Get a Napier antilog instance for forwarding {@code Antilog.performLog}. */
    public static DevConnectNapierAntilog napierAntilog() {
        return new DevConnectNapierAntilog();
    }

    /** Drop-in log facade — mirrors {@code android.util.Log} but also forwards to DevConnect. */
    public static DCLog log() {
        return DCLog.INSTANCE;
    }

    /**
     * Lower-level display: send a custom key/value card to the desktop
     * inspector.
     */
    public static void display(String name, Object value, String preview) {
        DevConnect.INSTANCE.display(name, value, preview, null, null);
    }

    public static void display(String name, Object value) {
        DevConnect.INSTANCE.display(name, value, null, null, null);
    }

    public static void display(String name) {
        DevConnect.INSTANCE.display(name, null, null, null, null);
    }

    // ───────────────────── Async / Saga tracking ─────────────────────

    /**
     * Report an async operation (saga step, background task, …).
     *
     * @param status one of {@code "start"}, {@code "resolve"}, {@code "reject"}
     */
    public static void reportAsyncOperation(String operationType, String description,
                                            String status, Long duration, String sagaName,
                                            String error, Object result) {
        DevConnect.INSTANCE.reportAsyncOperation(operationType, description, status, duration,
                sagaName, error, result, null);
    }

    public static void reportAsyncStart(String operationType, String description, String sagaName) {
        DevConnect.INSTANCE.reportAsyncOperation(operationType, description, "start", null,
                sagaName, null, null, null);
    }

    public static void reportAsyncResolve(String operationType, String description,
                                          String sagaName, long durationMs, Object result) {
        DevConnect.INSTANCE.reportAsyncOperation(operationType, description, "resolve", durationMs,
                sagaName, null, result, null);
    }

    public static void reportAsyncReject(String operationType, String description,
                                         String sagaName, String errorMessage) {
        DevConnect.INSTANCE.reportAsyncOperation(operationType, description, "reject", null,
                sagaName, errorMessage, null, null);
    }

    // ───────────────────── Functional interfaces ─────────────────────

    /**
     * Handler for {@link DevConnectJava#registerCommand(String, CommandHandler)}.
     * Receives the args map (may be null), returns any object (may be null).
     */
    public interface CommandHandler {
        Object onCommand(Map<String, Object> args);
    }

    /** Listener for {@link DevConnectJava#setOnStateRestore(StateListener)}. */
    public interface StateListener {
        void onState(Map<String, Object> state);
    }

    /** Listener for {@link DevConnectJava#setOnReduxDispatch(ActionListener)}. */
    public interface ActionListener {
        void onAction(Map<String, Object> action);
    }

    /** Listener for {@link DevConnectJava#setOnReloadRequest(ReloadHandler)}. */
    public interface ReloadHandler {
        void onReload();
    }
}