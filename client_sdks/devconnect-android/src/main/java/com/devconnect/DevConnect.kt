package com.devconnect

import com.devconnect.client.WebSocketClient
import com.devconnect.interceptors.DevConnectKermitWriter
import com.devconnect.interceptors.DevConnectKtorPlugin
import com.devconnect.interceptors.DevConnectNapierAntilog
import com.devconnect.interceptors.OkHttpInterceptor
import com.devconnect.reporters.DataStoreReporter
import com.devconnect.reporters.LogReporter
import com.devconnect.reporters.MmkvReporter
import com.devconnect.reporters.RoomReporter
import com.devconnect.reporters.DevConnectStateObserver
import com.devconnect.reporters.SharedPrefsReporter
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
    private var client: WebSocketClient? = null
    private var enabled = true
    private var deviceId = ""

    /** Pre-init queue: messages sent before init() completes */
    private val preInitQueue = mutableListOf<Pair<String, JSONObject>>()

    /**
     * Initialize DevConnect.
     *
     * @param context Android Context (Application preferred)
     * @param appName Your app's name
     * @param appVersion Your app's version
     * @param host Desktop IP. null or "auto" for auto-detection.
     * @param port WebSocket port (default: 9091)
     * @param auto Auto-detect host if not specified (default: true)
     * @param enabled Pass BuildConfig.DEBUG to disable in production (default: true)
     *
     * Production usage:
     * ```kotlin
     * DevConnect.init(context = this, appName = "MyApp", enabled = BuildConfig.DEBUG)
     * ```
     * When enabled=false: zero overhead — no WebSocket, no timers, no monitoring.
     *
     * Auto-detection tries: 10.0.2.2 (emulator) -> 10.0.3.2 (Genymotion) -> localhost -> 127.0.0.1
     */
    private var appContext: android.content.Context? = null
    private const val CACHE_KEY = "DcN3t\$ecR7!"

    private fun getPrefs(): android.content.SharedPreferences? {
        return appContext?.getSharedPreferences("dc_session", android.content.Context.MODE_PRIVATE)
    }

    private fun xorCipher(input: String, key: String): String {
        val sb = StringBuilder()
        for (i in input.indices) {
            sb.append((input[i].code xor key[i % key.length].code).toChar())
        }
        return sb.toString()
    }

    @android.annotation.SuppressLint("HardwareIds")
    private fun generateStableDeviceId(appName: String): String {
        val ctx = appContext
        val seed = if (ctx != null) {
            val androidId = android.provider.Settings.Secure.getString(
                ctx.contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            ) ?: ""
            "$androidId:${ctx.packageName}"
        } else {
            "$appName:${android.os.Build.BRAND}:${android.os.Build.MODEL}:${android.os.Build.FINGERPRINT}"
        }
        return UUID.nameUUIDFromBytes(seed.toByteArray()).toString()
    }

    private fun saveHostCache(host: String, port: Int) {
        try {
            val plain = """{"h":"$host","p":$port,"t":${System.currentTimeMillis()}}"""
            val encrypted = android.util.Base64.encodeToString(
                xorCipher(plain, CACHE_KEY).toByteArray(Charsets.ISO_8859_1),
                android.util.Base64.NO_WRAP
            )
            getPrefs()?.edit()?.putString("dc_s", encrypted)?.apply()
        } catch (_: Exception) {}
    }

    private fun readHostCache(port: Int): String? {
        try {
            val encrypted = getPrefs()?.getString("dc_s", null) ?: return null
            val decoded = android.util.Base64.decode(encrypted, android.util.Base64.NO_WRAP)
            val decrypted = xorCipher(String(decoded, Charsets.ISO_8859_1), CACHE_KEY)
            val json = JSONObject(decrypted)
            val cachedTime = json.optLong("t", 0)
            if (System.currentTimeMillis() - cachedTime > 24 * 60 * 60 * 1000) return null
            if (json.optInt("p") != port) return null
            return json.optString("h", null)
        } catch (_: Exception) {}
        return null
    }

    fun init(
        context: Any,
        appName: String,
        appVersion: String = "1.0.0",
        host: String? = null,
        port: Int = 9091,
        auto: Boolean = true,
        enabled: Boolean = true,
        versionCode: String? = null,
        autoInterceptLogs: Boolean = false,
        /** Auto-start performance monitoring (default: true) */
        autoPerformance: Boolean = true,
        /** Auto-start memory leak detection (default: true) */
        autoMemoryLeak: Boolean = true,
        /** Auto-start app benchmark (default: true) */
        autoBenchmark: Boolean = true
    ) {
        this.enabled = enabled
        if (!enabled) return

        // Save context for SharedPreferences
        if (context is android.content.Context) {
            appContext = context.applicationContext
        }

        // Generate stable deviceId from app + device info (prevents duplicates on reconnect/hot-reload)
        deviceId = generateStableDeviceId(appName)

        val resolvedHost = if (host == null || host == "auto") {
            if (auto) autoDetectHost(port) else "10.0.2.2"
        } else {
            host
        }

        client = WebSocketClient(
            host = resolvedHost,
            port = port,
            deviceId = deviceId,
            appName = appName,
            appVersion = appVersion,
            versionCode = versionCode
        ).also { ws ->
            ws.onServerMessage = { type, json ->
                val payload = json.optJSONObject("payload") ?: JSONObject()
                when (type) {
                    "server:state:restore" -> {
                        val state = payload.optJSONObject("state")
                        if (state != null) {
                            val map = jsonObjectToMap(state)
                            onStateRestore?.invoke(map)
                        }
                    }
                    "server:redux:dispatch" -> {
                        val action = payload.optJSONObject("action")
                        if (action != null) {
                            val map = jsonObjectToMap(action)
                            onReduxDispatch?.invoke(map)
                        }
                    }
                    "server:custom:command" -> {
                        val cmd = payload.optString("command", "")
                        val handler = commandHandlers[cmd]
                        if (handler != null) {
                            val args = payload.optJSONObject("args")
                            val argsMap = if (args != null) jsonObjectToMap(args) else null
                            val result = handler(argsMap)
                            val correlationId = json.optString("correlationId", null)
                            val resultPayload = buildPayload {
                                put("command", cmd)
                                if (result != null) put("result", result)
                            }
                            send("client:custom:command_result", resultPayload)
                        }
                    }
                }
            }
        }
        client?.connect()

        // Auto-intercept System.out (println) if enabled
        if (autoInterceptLogs) {
            com.devconnect.interceptors.DevConnectLogInterceptor.interceptSystemOut()
        }

        // Flush pre-init queue (messages from interceptors before init)
        if (preInitQueue.isNotEmpty()) {
            for ((type, payload) in preInitQueue) {
                send(type, payload)
            }
            preInitQueue.clear()
        }

        // Auto-start monitoring plugins (run in both dev and production)
        if (autoPerformance) {
            com.devconnect.plugins.startPerformanceMonitor(context)
        }
        if (autoMemoryLeak) {
            com.devconnect.plugins.startMemoryLeakDetector(context)
        }
        if (autoBenchmark) {
            com.devconnect.plugins.setupAppBenchmark(context)
        }
    }

    /** UDP discovery port — server broadcasts beacons here */
    private const val DISCOVERY_PORT = 41234

    private fun autoDetectHost(port: Int): String {
        // 0. Try cached host from previous session (instant reconnect)
        val cached = readHostCache(port)
        if (cached != null && tryHost(cached, port, 500)) return cached

        // 1. Race: UDP beacon + known hosts in parallel
        //    USB (adb reverse) → localhost/10.0.2.2 responds fast
        //    WiFi → UDP beacon responds fast
        val executor = java.util.concurrent.Executors.newFixedThreadPool(6)
        try {
            val futures = mutableListOf<java.util.concurrent.Future<String?>>()

            // UDP beacon
            futures.add(executor.submit(java.util.concurrent.Callable { listenForBeacon(port) }))

            // Known emulator/USB hosts
            for (candidate in listOf("10.0.2.2", "10.0.3.2", "localhost", "127.0.0.1")) {
                futures.add(executor.submit(java.util.concurrent.Callable {
                    if (tryHost(candidate, port, 800)) candidate else null
                }))
            }

            // Wait up to 3.5s for first result
            val deadline = System.currentTimeMillis() + 3500
            for (future in futures) {
                try {
                    val remaining = deadline - System.currentTimeMillis()
                    if (remaining <= 0) break
                    val result = future.get(remaining, java.util.concurrent.TimeUnit.MILLISECONDS)
                    if (result != null) {
                        saveHostCache(result, port)
                        return result
                    }
                } catch (_: Exception) {}
            }
        } finally {
            executor.shutdownNow()
        }

        // 2. Get device's own subnet and scan it (real device on same WiFi)
        try {
            val interfaces = java.net.NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val iface = interfaces.nextElement()
                val addrs = iface.inetAddresses
                while (addrs.hasMoreElements()) {
                    val addr = addrs.nextElement()
                    if (!addr.isLoopbackAddress && addr is java.net.Inet4Address) {
                        val parts = addr.hostAddress?.split(".") ?: continue
                        if (parts.size == 4) {
                            val subnet = "${parts[0]}.${parts[1]}.${parts[2]}"
                            val found = scanSubnet(subnet, port)
                            if (found != null) { saveHostCache(found, port); return found }
                        }
                    }
                }
            }
        } catch (_: Exception) {}

        // 4. Scan common subnets as fallback
        val commonSubnets = listOf("192.168.1", "192.168.0", "192.168.2", "10.0.0", "10.0.1", "172.16.0")
        for (subnet in commonSubnets) {
            val found = scanSubnet(subnet, port)
            if (found != null) { saveHostCache(found, port); return found }
        }

        return "10.0.2.2" // fallback for emulator
    }

    /**
     * Listen for UDP beacon from DevConnect server.
     * Server broadcasts {"type":"devconnect_beacon","port":9090,...}
     * every 2 seconds. We listen for up to 3 seconds.
     */
    private fun listenForBeacon(expectedPort: Int): String? {
        var socket: java.net.DatagramSocket? = null
        try {
            socket = java.net.DatagramSocket(null)
            socket.reuseAddress = true
            socket.bind(java.net.InetSocketAddress(DISCOVERY_PORT))
            socket.soTimeout = 3000 // 3 second timeout

            val buf = ByteArray(1024)
            val packet = java.net.DatagramPacket(buf, buf.size)
            socket.receive(packet)

            val data = String(packet.data, 0, packet.length)
            val json = org.json.JSONObject(data)
            if (json.optString("type") == "devconnect_beacon" &&
                json.optInt("port") == expectedPort) {
                return packet.address.hostAddress
            }
        } catch (_: Exception) {
            // Timeout or error — fall through to other methods
        } finally {
            socket?.close()
        }
        return null
    }

    private fun tryHost(host: String, port: Int, timeoutMs: Int): Boolean {
        return try {
            val socket = java.net.Socket()
            socket.connect(java.net.InetSocketAddress(host, port), timeoutMs)
            socket.close()
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Scan a subnet (x.x.x.1 through x.x.x.30) in parallel.
     * Returns first host that responds, or null.
     */
    private fun scanSubnet(subnet: String, port: Int): String? {
        val executor = java.util.concurrent.Executors.newFixedThreadPool(15)
        val futures = (1..30).map { i ->
            executor.submit(java.util.concurrent.Callable {
                val host = "$subnet.$i"
                if (tryHost(host, port, 400)) host else null
            })
        }
        try {
            for (future in futures) {
                try {
                    val result = future.get(500, java.util.concurrent.TimeUnit.MILLISECONDS)
                    if (result != null) {
                        executor.shutdownNow()
                        return result
                    }
                } catch (_: Exception) {}
            }
        } finally {
            executor.shutdownNow()
        }
        return null
    }

    fun isConnected(): Boolean = client?.isConnected == true

    /**
     * Disconnect from DevConnect desktop.
     */
    fun disconnect() {
        client?.disconnect()
        client = null
    }

    // ---- State Restore ----

    /** Handler called when desktop restores a state snapshot */
    var onStateRestore: ((Map<String, Any>) -> Unit)? = null

    /** Handler called when desktop dispatches a Redux/ViewModel action */
    var onReduxDispatch: ((Map<String, Any>) -> Unit)? = null

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
        previousState: Map<String, Any>? = null,
        nextState: Map<String, Any>? = null
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
            value?.let { put("value", it) }
            put("operation", operation)
        })
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
    ) {
        send("client:performance:metric", buildPayload {
            put("metricType", metricType)
            put("value", value)
            label?.let { put("label", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

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
    ) {
        send("client:memory:leak", buildPayload {
            put("leakType", leakType)
            put("severity", severity)
            put("objectName", objectName)
            detail?.let { put("detail", it) }
            retainedSizeBytes?.let { put("retainedSizeBytes", it) }
            stackTrace?.let { put("stackTrace", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    // ---- Network (internal) ----

    fun reportNetworkStart(
        requestId: String,
        method: String,
        url: String,
        headers: Map<String, String>? = null,
        body: Any? = null
    ) {
        send("client:network:request_start", buildPayload {
            put("requestId", requestId)
            put("method", method)
            put("url", url)
            put("startTime", System.currentTimeMillis())
            headers?.let { put("requestHeaders", JSONObject(it as Map<*, *>)) }
            body?.let { put("requestBody", it) }
        })
    }

    fun reportNetworkComplete(
        requestId: String,
        method: String,
        url: String,
        statusCode: Int,
        startTime: Long,
        requestHeaders: Map<String, String>? = null,
        responseHeaders: Map<String, String>? = null,
        requestBody: Any? = null,
        responseBody: Any? = null,
        error: String? = null
    ) {
        val now = System.currentTimeMillis()
        send("client:network:request_complete", buildPayload {
            put("requestId", requestId)
            put("method", method)
            put("url", url)
            put("statusCode", statusCode)
            put("startTime", startTime)
            put("endTime", now)
            put("duration", now - startTime)
            requestHeaders?.let { put("requestHeaders", JSONObject(it as Map<*, *>)) }
            responseHeaders?.let { put("responseHeaders", JSONObject(it as Map<*, *>)) }
            requestBody?.let { put("requestBody", it) }
            responseBody?.let { put("responseBody", it) }
            error?.let { put("error", it) }
        })
    }

    // ---- Benchmark API ----

    private val benchmarks = mutableMapOf<String, MutableList<Long>>()

    fun benchmarkStart(title: String) {
        benchmarks[title] = mutableListOf(System.currentTimeMillis())
    }

    fun benchmarkStep(title: String) {
        benchmarks[title]?.add(System.currentTimeMillis())
    }

    fun benchmarkStop(title: String) {
        val times = benchmarks.remove(title) ?: return
        val startTime = times.first()
        val endTime = System.currentTimeMillis()

        send("client:benchmark", buildPayload {
            put("title", title)
            put("startTime", startTime)
            put("endTime", endTime)
            put("duration", endTime - startTime)
        })
    }

    // ---- State snapshot ----

    fun sendStateSnapshot(stateManager: String, state: Map<String, Any>) {
        send("client:state:snapshot", buildPayload {
            put("stateManager", stateManager)
            put("state", JSONObject(state))
        })
    }

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
    ) {
        send("client:display", buildPayload {
            put("name", name)
            value?.let { put("value", it) }
            preview?.let { put("preview", it) }
            image?.let { put("image", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

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
    ) {
        send("client:async:operation", buildPayload {
            put("operationType", operationType)
            put("description", description)
            put("status", status)
            duration?.let { put("duration", it) }
            sagaName?.let { put("sagaName", it) }
            error?.let { put("error", it) }
            result?.let { put("result", it) }
            metadata?.let { put("metadata", JSONObject(it)) }
        })
    }

    // ---- Custom commands ----

    private val commandHandlers = mutableMapOf<String, (Map<String, Any>?) -> Any?>()

    fun registerCommand(name: String, handler: (Map<String, Any>?) -> Any?) {
        commandHandlers[name] = handler
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
            // Queue for later if init() hasn't been called yet
            if (preInitQueue.size < 500) {
                preInitQueue.add(Pair(type, payload))
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

        c.send(message.toString())
    }

    private fun buildPayload(block: JSONObject.() -> Unit): JSONObject {
        return JSONObject().apply(block)
    }

    private fun jsonObjectToMap(json: JSONObject): Map<String, Any> {
        val map = mutableMapOf<String, Any>()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = json.get(key)
            map[key] = when (value) {
                is JSONObject -> jsonObjectToMap(value)
                is org.json.JSONArray -> {
                    val list = mutableListOf<Any>()
                    for (i in 0 until value.length()) {
                        val item = value.get(i)
                        list.add(if (item is JSONObject) jsonObjectToMap(item) else item)
                    }
                    list
                }
                else -> value
            }
        }
        return map
    }
}
