package com.devconnect

import com.devconnect.client.WebSocketClient
import com.devconnect.core.DesktopCommands
import com.devconnect.core.HostDiscovery
import com.devconnect.core.Reports
import com.devconnect.core.Startup
import com.devconnect.core.buildPayload
import com.devconnect.core.jsonValue
import com.devconnect.core.redactSensitiveValue
import com.devconnect.interceptors.DevConnectKermitWriter
import com.devconnect.interceptors.DevConnectKtorPlugin
import com.devconnect.interceptors.DevConnectNapierAntilog
import com.devconnect.interceptors.OkHttpInterceptor
import com.devconnect.reporters.DataStoreReporter
import com.devconnect.reporters.LogReporter
import com.devconnect.reporters.MmkvReporter
import com.devconnect.reporters.ObjectBoxReporter
import com.devconnect.reporters.RealmReporter
import com.devconnect.reporters.RoomReporter
import com.devconnect.reporters.SQLDelightReporter
import com.devconnect.reporters.DevConnectStateObserver
import com.devconnect.reporters.SharedPrefsReporter
import com.devconnect.wrappers.DevConnectRealm
// Round 2-5: new SDK files. We import the top-level helpers below so the
// host file doesn't need to change when consumers add more interceptors.
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.util.UUID

/**
 * DevConnect Android SDK - Main entry point.
 *
 * ## Quick Start:
 * ```kotlin
 * // In Application.onCreate()
 * DevConnect.init(
 *     context = this,
 *     appName = "MyApp",
 *     appVersion = "1.0.0"
 * )
 * ```
 *
 * ## With OkHttp (auto-intercept ALL network requests):
 * ```kotlin
 * val client = OkHttpClient.Builder()
 *     .addInterceptor(DevConnect.okHttpInterceptor())
 *     .build()
 * ```
 *
 * ## With Retrofit (uses OkHttp under the hood):
 * ```kotlin
 * val client = OkHttpClient.Builder()
 *     .addInterceptor(DevConnect.okHttpInterceptor())
 *     .build()
 *
 * val retrofit = Retrofit.Builder()
 *     .client(client)
 *     .baseUrl("https://api.example.com/")
 *     .build()
 * ```
 *
 * ## With Ktor:
 * ```kotlin
 * val client = HttpClient {
 *     install(DevConnectKtorPlugin)
 * }
 * ```
 *
 * ## With Kermit (KMP logger):
 * ```kotlin
 * Logger.addLogWriter(DevConnectKermitWriter())
 * ```
 *
 * ## With Napier (KMP logger):
 * ```kotlin
 * Napier.base(DevConnectNapierAntilog())
 * ```
 *
 * ## Firebase / OAuth2:
 * Firebase and OAuth2 use OkHttp internally on Android.
 * If you set DevConnect's interceptor on your OkHttpClient,
 * all Firebase REST and OAuth2 token calls will be captured automatically.
 */
object DevConnect {
    internal var client: WebSocketClient? = null

    /**
     * Default `false` — opt-in only. The SDK captures network requests,
     * auth headers, and request bodies that may include OAuth tokens.
     * Production builds MUST pass `enabled = BuildConfig.DEBUG` explicitly.
     */
    private var enabled = false
    @Volatile internal var deviceId = ""
        private set

    /** Pre-init queue: messages sent before init() completes. Synchronized
     *  because [send] is called from any thread (interceptor callbacks,
     *  OkHttp dispatchers, etc.) while [init] drains it on the calling
     *  thread. */
    internal val preInitQueue: MutableList<Pair<String, JSONObject>> =
        java.util.Collections.synchronizedList(mutableListOf())

    /**
     * Initialize DevConnect.
     *
     * @param context Android Context (Application preferred)
     * @param appName Your app's name
     * @param appVersion Your app's version
     * @param host Desktop IP. null or "auto" for auto-detection.
     * @param port WebSocket port (default: 9090)
     * @param auto Auto-detect host if not specified (default: true)
     * @param enabled Pass BuildConfig.DEBUG to disable in production (default: false)
     *
     * Production usage:
     * ```kotlin
     * DevConnect.init(context = this, appName = "MyApp", enabled = BuildConfig.DEBUG)
     * ```
     * When enabled=false: zero overhead — no WebSocket, no timers, no monitoring.
     *
     * Auto-detection tries: 10.0.2.2 (emulator) -> 10.0.3.2 (Genymotion) -> localhost -> 127.0.0.1
     */
    internal var appContext: android.content.Context? = null

    /** Coroutine scope for the asynchronous portion of [init] — host
     *  discovery + WebSocket client construction. Kept as a separate
     *  scope so init() returns quickly and the caller's
     *  `Application.onCreate()` doesn't block. */
    internal val initScope = kotlinx.coroutines.CoroutineScope(
        kotlinx.coroutines.SupervisorJob() + kotlinx.coroutines.Dispatchers.IO
    )

    fun init(
        context: Any,
        appName: String,
        appVersion: String = "1.0.0",
        host: String? = null,
        port: Int = 9090,
        auto: Boolean = true,
        enabled: Boolean = false,
        versionCode: String? = null,
        autoInterceptLogs: Boolean = false,
        /** Only logs once now: HttpURLConnection can't be auto-captured; use [okHttpInterceptor]. */
        autoInterceptHttp: Boolean = true,
        /** Auto-start performance monitoring (default: true) */
        autoPerformance: Boolean = true,
        /** Auto-start memory leak detection (default: true) */
        autoMemoryLeak: Boolean = true,
        /** Auto-start app benchmark (default: true) */
        autoBenchmark: Boolean = true,
        /** Auto-start the ANR watchdog (main-thread ping). Default: true */
        autoAnrWatchdog: Boolean = true,
        /** Auto-discover StateFlow/LiveData on ViewModels via reflection. Default: true */
        autoViewModelDiscovery: Boolean = true,
    ) {
        this.enabled = enabled
        if (!enabled) return

        Startup.attach(context)

        // Generate stable deviceId from app + device info (prevents duplicates on reconnect/hot-reload)
        deviceId = HostDiscovery.generateStableDeviceId(appName)

        // Resolve the host off the main thread. The previous implementation
        // called `autoDetectHost()` synchronously inside init(), which is
        // typically invoked from `Application.onCreate()` on the main
        // thread. Discovery waits up to 3.5 s on a cache miss and the
        // subnet scan can run for tens of seconds — a hard ANR during app
        // startup.
        val explicitHost = host
        initScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val resolvedHost = when {
                explicitHost != null && explicitHost != "auto" -> explicitHost
                auto -> HostDiscovery.autoDetectHost(port)
                else -> "10.0.2.2"
            }
            connectAfterDiscovery(
                host = resolvedHost,
                context = context,
                appName = appName,
                appVersion = appVersion,
                versionCode = versionCode,
                port = port,
                autoInterceptLogs = autoInterceptLogs,
                autoInterceptHttp = autoInterceptHttp,
                autoPerformance = autoPerformance,
                autoMemoryLeak = autoMemoryLeak,
                autoBenchmark = autoBenchmark,
                autoAnrWatchdog = autoAnrWatchdog,
                autoViewModelDiscovery = autoViewModelDiscovery,
            )
        }
    }

    private fun connectAfterDiscovery(
        host: String,
        context: Any,
        appName: String,
        appVersion: String,
        versionCode: String?,
        port: Int,
        autoInterceptLogs: Boolean,
        autoInterceptHttp: Boolean,
        autoPerformance: Boolean,
        autoMemoryLeak: Boolean,
        autoBenchmark: Boolean,
        autoAnrWatchdog: Boolean,
        autoViewModelDiscovery: Boolean,
    ) = Startup.connectAfterDiscovery(
        host, context, appName, appVersion, versionCode, port, autoInterceptLogs, autoInterceptHttp,
        autoPerformance, autoMemoryLeak, autoBenchmark, autoAnrWatchdog, autoViewModelDiscovery,
    )

    fun isConnected(): Boolean = client?.isConnected == true

    /**
     * Disconnect from DevConnect desktop.
     */
    fun disconnect() {
        client?.disconnect()
        client = null
    }

    // ---- State Restore ----

    /** Handler called, on the main thread, when desktop restores a state snapshot */
    var onStateRestore: ((Map<String, Any>) -> Unit)? = null

    /** Handler called, on the main thread, when desktop dispatches a Redux/ViewModel action */
    var onReduxDispatch: ((Map<String, Any>) -> Unit)? = null

    // ---- Reload ----

    /**
     * Custom handler for `server:reload` requests from the desktop.
     *
     * By default, the SDK calls [Activity.recreate] on the host activity —
     * the closest thing to "rebuild the app" Android has natively. Override
     * when you need to wipe in-memory state first (e.g. ViewModel caches,
     * in-memory databases). If you set a custom handler you are responsible
     * for actually reloading — the default [Activity.recreate] call will not
     * run.
     */
    var onReloadRequest: (() -> Unit)? = null

    // ---- OkHttp Interceptor ----

    /**
     * Returns an OkHttp Interceptor that captures all HTTP requests.
     *
     * Works with OkHttp, Retrofit, Firebase, OAuth2, Glide, Coil, etc.
     *
     * ```kotlin
     * val client = OkHttpClient.Builder()
     *     .addInterceptor(DevConnect.okHttpInterceptor())
     *     .build()
     * ```
     */
    fun okHttpInterceptor(): OkHttpInterceptor = OkHttpInterceptor()

    // ---- Ktor Plugin ----

    /**
     * Returns the Ktor HttpClient plugin for capturing network requests.
     *
     * ```kotlin
     * val client = HttpClient {
     *     install(DevConnect.ktorPlugin())
     * }
     * ```
     *
     * Or use the plugin object directly:
     * ```kotlin
     * val client = HttpClient {
     *     install(DevConnectKtorPlugin)
     * }
     * ```
     */
    fun ktorPlugin(): DevConnectKtorPlugin = DevConnectKtorPlugin

    // ---- Logging ----

    fun logger(tag: String? = null): LogReporter = LogReporter(tag)

    /**
     * Returns a Kermit LogWriter that sends logs to DevConnect.
     *
     * ```kotlin
     * Logger.addLogWriter(DevConnect.kermitWriter())
     * ```
     */
    fun kermitWriter(): DevConnectKermitWriter = DevConnectKermitWriter()

    /**
     * Returns a Napier Antilog that sends logs to DevConnect.
     *
     * ```kotlin
     * Napier.base(DevConnect.napierAntilog())
     * ```
     */
    fun napierAntilog(): DevConnectNapierAntilog = DevConnectNapierAntilog()

    fun log(message: String, tag: String? = null, metadata: Map<String, Any>? = null) {
        send("client:log", buildPayload {
            put("level", "info")
            put("message", message)
            tag?.let { put("tag", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    fun debug(message: String, tag: String? = null, metadata: Map<String, Any>? = null) {
        send("client:log", buildPayload {
            put("level", "debug")
            put("message", message)
            tag?.let { put("tag", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    fun warn(message: String, tag: String? = null, metadata: Map<String, Any>? = null) {
        send("client:log", buildPayload {
            put("level", "warn")
            put("message", message)
            tag?.let { put("tag", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    fun error(
        message: String,
        tag: String? = null,
        stackTrace: String? = null,
        metadata: Map<String, Any>? = null
    ) {
        send("client:log", buildPayload {
            put("level", "error")
            put("message", message)
            tag?.let { put("tag", it) }
            stackTrace?.let { put("stackTrace", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    // ---- State Management ----

    /**
     * Get the StateFlow/LiveData observer for reporting state changes.
     *
     * ```kotlin
     * // StateFlow
     * DevConnect.stateObserver().observe(scope, stateFlow, "UserState")
     *
     * // LiveData
     * DevConnect.stateObserver().observe(lifecycleOwner, liveData, "UserState")
     * ```
     */
    fun stateObserver(): DevConnectStateObserver = DevConnectStateObserver

    fun reportStateChange(
        stateManager: String,
        action: String,
        previousState: Map<String, Any?>? = null,
        nextState: Map<String, Any?>? = null
    ) {
        send("client:state:change", buildPayload {
            put("stateManager", stateManager)
            put("action", action)
            previousState?.let { put("previousState", JSONObject(it)) }
            nextState?.let { put("nextState", JSONObject(it)) }
        })
    }

    // ---- Storage ----

    /**
     * Get a SharedPreferences reporter.
     *
     * ```kotlin
     * val prefsReporter = DevConnect.sharedPrefsReporter()
     * prefsReporter.reportWrite("user_token", "abc123")
     * ```
     */
    fun sharedPrefsReporter(): SharedPrefsReporter = SharedPrefsReporter()

    /**
     * Get a DataStore (Preferences) reporter.
     *
     * ```kotlin
     * val reporter = DevConnect.dataStoreReporter()
     * reporter.reportWrite("darkMode", true)
     * reporter.reportRead("darkMode", true)
     * ```
     */
    fun dataStoreReporter(): DataStoreReporter = DataStoreReporter()

    /**
     * Get a Room database reporter.
     *
     * ```kotlin
     * val reporter = DevConnect.roomReporter()
     * reporter.reportQuery("SELECT * FROM users", results)
     * reporter.reportInsert("users", rowId)
     * ```
     */
    fun roomReporter(): RoomReporter = RoomReporter()

    /**
     * Get a Realm database reporter.
     *
     * ```kotlin
     * val reporter = DevConnect.realmReporter()
     * reporter.reportQuery("User", results.map { mapOf("name" to it.name) })
     * reporter.reportWrite("User", mapOf("name" to user.name))
     * reporter.reportDelete("User", mapOf("id" to user.id))
     * ```
     */
    fun realmReporter(): RealmReporter = RealmReporter()

    /**
     * Get the Realm auto-wrapper for capturing operations without manual reporting.
     *
     * ```kotlin
     * // Wrap write operations
     * DevConnectRealm.wrapWrite("User") {
     *     realm.writeBlocking { copyToRealm(user) }
     * }
     *
     * // Wrap query operations
     * val users = DevConnectRealm.wrapQuery("User") {
     *     realm.query<User>().find().map { mapOf("name" to it.name) }
     * }
     * ```
     */
    fun realmWrapper(): DevConnectRealm = DevConnectRealm()

    fun objectBoxReporter(): ObjectBoxReporter = ObjectBoxReporter()

    fun sqlDelightReporter(): SQLDelightReporter = SQLDelightReporter()

    /**
     * Get an MMKV storage reporter.
     *
     * ```kotlin
     * val reporter = DevConnect.mmkvReporter()
     * reporter.reportWrite("token", "abc123")
     * reporter.reportRead("token", "abc123")
     * reporter.reportDelete("token")
     * ```
     */
    fun mmkvReporter(): MmkvReporter = MmkvReporter()

    fun reportStorageOperation(
        storageType: String,
        key: String,
        value: Any? = null,
        operation: String
    ) {
        send("client:storage:operation", buildPayload {
            put("storageType", storageType)
            put("key", key)
            value?.let { put("value", jsonValue(redactSensitiveValue(key, it))) }
            put("operation", operation)
        })
    }

    /**
     * Short-form storage reporter used by the auto-wrappers
     * ([com.devconnect.wrappers.DevConnectSharedPrefs],
     * [com.devconnect.wrappers.DevConnectMMKV],
     * [com.devconnect.reporters.ObjectBoxReporter],
     * [com.devconnect.reporters.SQLDelightReporter]).
     *
     * Equivalent to [reportStorageOperation] but with a name the wrappers
     * have historically used.
     */
    fun sendStorage(
        storageType: String,
        key: String,
        value: Any? = null,
        operation: String
    ) {
        reportStorageOperation(storageType, key, value, operation)
    }

    /**
     * Best-effort send used by the uncaught-exception handler. Accepts a
     * plain map (instead of a [JSONObject]) because crash payloads are
     * built ad-hoc in [com.devconnect.plugins.ErrorMonitor] before
     * [JSONObject] is touched.
     *
     * Never throws — the previous handler must run even if reporting fails.
     */
    internal fun safeSend(type: String, payload: Map<String, Any?>) {
        try {
            val json = JSONObject()
            for ((k, v) in payload) json.put(k, jsonValue(v))
            send(type, json)
        } catch (_: Exception) {
            // The process is dying — swallow everything.
        }
    }

    // ---- Performance Profiling ----

    /**
     * Report a performance metric (FPS, memory, CPU, jank frame, etc.).
     *
     * ```kotlin
     * // Report FPS
     * DevConnect.reportPerformanceMetric(
     *     metricType = "fps",
     *     value = 58.5,
     *     label = "Main Thread FPS"
     * )
     *
     * // Report memory usage in MB
     * DevConnect.reportPerformanceMetric(
     *     metricType = "memory_usage",
     *     value = 142.3,
     *     label = "Heap Used"
     * )
     *
     * // Report CPU usage percentage
     * DevConnect.reportPerformanceMetric(
     *     metricType = "cpu_usage",
     *     value = 35.2
     * )
     *
     * // Report a jank frame (build time in ms)
     * DevConnect.reportPerformanceMetric(
     *     metricType = "jank_frame",
     *     value = 32.1,
     *     label = "Slow render in RecyclerView"
     * )
     * ```
     *
     * @param metricType One of: fps, frame_build_time, frame_raster_time, memory_usage, memory_peak, cpu_usage, jank_frame
     * @param value The metric value (FPS number, MB, percentage, ms, etc.)
     * @param label Optional human-readable label
     * @param metadata Optional additional key-value data
     */
    fun reportPerformanceMetric(
        metricType: String,
        value: Double,
        label: String? = null,
        metadata: Map<String, Any>? = null
    ) = Reports.reportPerformanceMetric(metricType, value, label, metadata)

    // ---- Memory Leak Detection ----

    /**
     * Report a detected memory leak.
     *
     * ```kotlin
     * // Report an undisposed stream/listener
     * DevConnect.reportMemoryLeak(
     *     leakType = "undisposed_stream",
     *     severity = "warning",
     *     objectName = "LocationListener",
     *     detail = "LocationManager listener not removed in MapsActivity",
     *     retainedSizeBytes = 4096
     * )
     *
     * // Report a growing collection
     * DevConnect.reportMemoryLeak(
     *     leakType = "growing_collection",
     *     severity = "critical",
     *     objectName = "eventCache",
     *     detail = "ArrayList grows unbounded — 15000 items",
     *     retainedSizeBytes = 1200000,
     *     metadata = mapOf("currentSize" to 15000, "maxExpected" to 100)
     * )
     *
     * // Report Activity leak (e.g. from LeakCanary)
     * DevConnect.reportMemoryLeak(
     *     leakType = "widget_leak",
     *     severity = "critical",
     *     objectName = "DetailActivity",
     *     detail = "Activity retained after onDestroy",
     *     stackTrace = leakTrace.toString()
     * )
     * ```
     *
     * @param leakType One of: undisposed_controller, undisposed_stream, undisposed_timer, undisposed_animation_controller, widget_leak, growing_collection, custom
     * @param severity One of: info, warning, critical
     * @param objectName Name of the leaked object/class
     * @param detail Human-readable description
     * @param retainedSizeBytes Estimated retained memory in bytes
     * @param stackTrace Stack trace or leak trace string
     * @param metadata Optional additional key-value data
     */
    fun reportMemoryLeak(
        leakType: String,
        severity: String,
        objectName: String,
        detail: String? = null,
        retainedSizeBytes: Long? = null,
        stackTrace: String? = null,
        metadata: Map<String, Any>? = null
    ) = Reports.reportMemoryLeak(leakType, severity, objectName, detail, retainedSizeBytes, stackTrace, metadata)

    // ---- Network (internal) ----

    fun reportNetworkStart(
        requestId: String,
        method: String,
        url: String,
        headers: Map<String, Any?>? = null,
        body: Any? = null
    ) = Reports.reportNetworkStart(requestId, method, url, headers, body)

    fun reportNetworkComplete(
        requestId: String,
        method: String,
        url: String,
        statusCode: Int,
        startTime: Long,
        requestHeaders: Map<String, Any?>? = null,
        responseHeaders: Map<String, Any?>? = null,
        requestBody: Any? = null,
        responseBody: Any? = null,
        error: String? = null
    ) = Reports.reportNetworkComplete(
        requestId, method, url, statusCode, startTime,
        requestHeaders, responseHeaders, requestBody, responseBody, error,
    )

    // ---- Benchmark API ----

    fun benchmarkStart(title: String) = Reports.benchmarkStart(title)

    fun benchmarkStep(title: String) = Reports.benchmarkStep(title)

    fun benchmarkStop(title: String) = Reports.benchmarkStop(title)

    // ---- State snapshot ----

    fun sendStateSnapshot(stateManager: String, state: Map<String, Any>) = Reports.sendStateSnapshot(stateManager, state)

    // ---- Custom Display ----

    /**
     * Send a custom display value to DevConnect desktop.
     *
     * ```kotlin
     * DevConnect.display("User Profile",
     *     value = mapOf("name" to "John", "age" to 30),
     *     preview = "John, 30"
     * )
     * ```
     */
    fun display(
        name: String,
        value: Any? = null,
        preview: String? = null,
        image: String? = null,
        metadata: Map<String, Any>? = null
    ) = Reports.display(name, value, preview, image, metadata)

    // ---- Async Operations (Saga/Task tracking) ----

    /**
     * Report an async operation (saga step, background task, etc.).
     *
     * ```kotlin
     * // Report saga call start
     * DevConnect.reportAsyncOperation(
     *     operationType = "saga_call",
     *     description = "Fetching user data",
     *     status = "start",
     *     sagaName = "userSaga"
     * )
     *
     * // Report completion
     * DevConnect.reportAsyncOperation(
     *     operationType = "saga_call",
     *     description = "Fetching user data",
     *     status = "resolve",
     *     sagaName = "userSaga",
     *     duration = 350
     * )
     * ```
     *
     * @param operationType One of: saga_take, saga_put, saga_call, saga_fork, saga_all, saga_race, saga_select, saga_delay, async_task, background_job, custom
     * @param description Human-readable description
     * @param status One of: start, resolve, reject
     * @param duration Duration in milliseconds (for resolve/reject)
     * @param sagaName Optional saga name for grouping
     * @param error Error message (for reject)
     * @param result Operation result (for resolve)
     * @param metadata Optional additional key-value data
     */
    fun reportAsyncOperation(
        operationType: String,
        description: String,
        status: String,
        duration: Long? = null,
        sagaName: String? = null,
        error: String? = null,
        result: Any? = null,
        metadata: Map<String, Any>? = null
    ) = Reports.reportAsyncOperation(operationType, description, status, duration, sagaName, error, result, metadata)

    // ---- Custom commands ----

    internal val commandHandlers = java.util.concurrent.ConcurrentHashMap<String, (Map<String, Any>?) -> Any?>()

    fun registerCommand(name: String, handler: (Map<String, Any>?) -> Any?) {
        commandHandlers[name] = handler
        // Before connecting, the handshake announces every command so far.
        if (isConnected()) DesktopCommands.announceCommands()
    }

    // ---- Storage (desktop Storage tab) ----

    /** A key-value store the desktop's Storage tab can list and edit. */
    interface StorageAdapter {
        fun getAll(): Map<String, Any?>
        fun set(key: String, value: Any?)
        fun remove(key: String)
        fun clear()
    }

    internal val storages = java.util.concurrent.ConcurrentHashMap<String, StorageAdapter>()

    /**
     * Lets the desktop's Storage tab list, edit, delete and clear a store.
     * [DevConnectSharedPrefs] and [DevConnectMMKV] register theirs.
     */
    fun registerStorage(storageType: String, adapter: StorageAdapter) {
        storages[storageType] = adapter
    }

    // ---- Network conditions, replay, deep links ----

    @Volatile internal var networkLatencyMs = 0L
    @Volatile internal var networkOffline = false

    /**
     * Applies the desktop-set network conditions to an app request: fails it
     * the way an offline device does, or holds it back. DevConnect's own
     * socket doesn't go through OkHttp, so it's unaffected.
     */
    internal fun applyNetworkConditions() {
        if (networkOffline) {
            throw java.net.UnknownHostException("Network is unreachable (simulated by DevConnect)")
        }
        if (networkLatencyMs > 0) Thread.sleep(networkLatencyMs)
    }

    // ---- Database (desktop Database tab) ----

    internal val databases =
        java.util.concurrent.ConcurrentHashMap<String, (String) -> android.database.Cursor>()

    /**
     * Lets the desktop's Database tab browse and query a SQLite database.
     * [query] runs one SQL statement and returns its cursor, which the SDK
     * reads and closes:
     *
     * ```kotlin
     * DevConnect.registerDatabase("app.db") { sql -> db.rawQuery(sql, null) }
     * DevConnect.registerDatabase("room") { sql -> roomDb.openHelper.readableDatabase.query(sql) }
     * ```
     */
    fun registerDatabase(name: String, query: (String) -> android.database.Cursor) {
        databases[name] = query
    }

    // ---- Log (internal, used by DCLog/Timber/LogInterceptor) ----

    fun sendLog(
        level: String,
        message: String,
        tag: String? = null,
        stackTrace: String? = null,
        metadata: Map<String, Any>? = null
    ) {
        send("client:log", buildPayload {
            put("level", level)
            put("message", message)
            tag?.let { put("tag", it) }
            stackTrace?.let { put("stackTrace", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    // ---- Internal ----

    internal fun send(type: String, payload: JSONObject) {
        if (!enabled) return

        val c = client
        if (c == null) {
            // Queue for later if init() hasn't been called yet. The list
            // is a synchronized wrapper — size + add is one atomic block
            // so we never overshoot the 500 cap.
            synchronized(preInitQueue) {
                if (preInitQueue.size < 500) {
                    preInitQueue.add(Pair(type, payload))
                }
            }
            return
        }

        val message = JSONObject().apply {
            put("id", UUID.randomUUID().toString())
            put("type", type)
            put("deviceId", deviceId)
            put("timestamp", System.currentTimeMillis())
            put("payload", payload)
        }

        // org.json returns null for a value it can't write (a NaN).
        val json = try {
            message.toString()
        } catch (_: Exception) {
            null
        } ?: return
        c.send(json)
    }

    // ---- Round 2: Compose state observer ----

    /**
     * Start the Jetpack Compose state observer. Safe no-op when the
     * app doesn't use Compose or when running on a JVM test runtime.
     *
     * ```kotlin
     * DevConnect.startComposeStateObserver(context)
     * ```
     */
    fun startComposeStateObserver(context: Any) {
        try {
            com.devconnect.plugins.ComposeStateObserver.start(context)
        } catch (_: Exception) {}
    }

    // ---- Round 3: Apollo + gRPC + WebSocket ----

    /**
     * Returns an Apollo Kotlin `ApolloInterceptor` that reports each
     * operation to the desktop. Install it via
     * `ApolloClient.Builder().addInterceptor(...)`.
     */
    fun apolloInterceptor(): com.devconnect.interceptors.graphql.DevConnectApolloInterceptor =
        com.devconnect.interceptors.graphql.DevConnectApolloInterceptor()

    /**
     * Returns a gRPC `io.grpc.ClientInterceptor` that reports each call's
     * start and end. Install it on the channel:
     * `ManagedChannelBuilder.forAddress(host, port).intercept(DevConnect.grpcClientInterceptor())`.
     */
    fun grpcClientInterceptor(): com.devconnect.interceptors.grpc.DevConnectGrpcClientInterceptor =
        com.devconnect.interceptors.grpc.DevConnectGrpcClientInterceptor()

    /**
     * Compose a `WebSocketListener` with DevConnect frame capture. Wrap
     * an existing listener via [devConnectWrap] or install directly.
     */
    fun webSocketListener(): com.devconnect.interceptors.DevConnectWebSocketListener =
        com.devconnect.interceptors.DevConnectWebSocketListener()

    /**
     * Wrap an existing OkHttp `WebSocketListener` so its events are
     * mirrored to the desktop. Frames the app sends aren't seen; use
     * [newWebSocket] for those.
     */
    fun devConnectWrap(delegate: okhttp3.WebSocketListener): okhttp3.WebSocketListener =
        com.devconnect.interceptors.devConnectWrap(delegate)

    /**
     * `client.newWebSocket(request, listener)` that mirrors the socket to
     * the desktop, including the frames the app sends. [listener] gets
     * the same [okhttp3.WebSocket] this returns.
     *
     * ```kotlin
     * val ws = DevConnect.newWebSocket(client, request, listener)
     * ws.send("subscribe")
     * ```
     */
    fun newWebSocket(
        client: okhttp3.OkHttpClient,
        request: okhttp3.Request,
        listener: okhttp3.WebSocketListener,
    ): okhttp3.WebSocket {
        val tracker = com.devconnect.interceptors.DevConnectWebSocketListener(listener, wrapSocket = true)
        return tracker.appSocket(client.newWebSocket(request, tracker))
    }

    // ---- Round 4: Mock server ----

    /**
     * Returns an OkHttp `Interceptor` that short-circuits requests when
     * a matching mock rule has been pushed from the desktop. Add it after
     * [okHttpInterceptor] so mocked responses still show in the HTTP tab:
     * `.addInterceptor(DevConnect.okHttpInterceptor()).addInterceptor(DevConnect.mockServerInterceptor())`.
     */
    fun mockServerInterceptor(): com.devconnect.interceptors.MockServerInterceptor =
        com.devconnect.interceptors.MockServerInterceptor()

    /**
     * Replace the in-memory mock rule list with a JSON array of rules
     * (the `rules` of a `server:mock_rules_update` payload).
     */
    fun installMockRulesFromJson(json: String) {
        com.devconnect.interceptors.installMockRulesFromJson(json)
    }

    /**
     * One-call setup. Wraps [init] with all auto-wiring flags enabled,
     * giving you ANR detection, ViewModel state auto-discovery,
     * auto-intercepted logs, plus the existing performance /
     * memory-leak / benchmark monitors.
     *
     * Consumers who use Retrofit/OkHttp should still add
     * `DevConnect.okHttpInterceptor()` to their `OkHttpClient.Builder`
     * — installForApp detects OkHttp on the classpath and logs a
     * one-time pointer to the README, but does not auto-wire it.
     *
     * Timber consumers should plant a Tree that forwards to
     * `DevConnect.sendLog(...)`. installForApp detects Timber and logs
     * a one-time pointer to the README.
     *
     * For fine-grained control, call [init] directly with the `auto*`
     * flags you want enabled.
     */
    fun installForApp(
        context: Any,
        appName: String,
        appVersion: String = "1.0.0",
        host: String? = null,
        port: Int = 9090,
        enabled: Boolean = false,
        versionCode: String? = null,
    ) = Startup.installForApp(context, appName, appVersion, host, port, enabled, versionCode)
}
