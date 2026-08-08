package com.devconnect

import com.devconnect.client.WebSocketClient
import com.devconnect.interceptors.DevConnectKermitWriter
import com.devconnect.interceptors.DevConnectKtorPlugin
import com.devconnect.interceptors.DevConnectNapierAntilog
import com.devconnect.interceptors.DevConnectURLStreamHandlerFactory
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
    private var client: WebSocketClient? = null

    /**
     * Default `false` — opt-in only. The SDK captures network requests,
     * auth headers, and request bodies that may include OAuth tokens.
     * Production builds MUST pass `enabled = BuildConfig.DEBUG` explicitly.
     */
    private var enabled = false
    @Volatile private var deviceId = ""

    /** Pre-init queue: messages sent before init() completes. Synchronized
     *  because [send] is called from any thread (interceptor callbacks,
     *  OkHttp dispatchers, etc.) while [init] drains it on the calling
     *  thread. */
    private val preInitQueue: MutableList<Pair<String, JSONObject>> =
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
    private var appContext: android.content.Context? = null

    /** Coroutine scope for the asynchronous portion of [init] — host
     *  discovery + WebSocket client construction. Kept as a separate
     *  scope so init() returns quickly and the caller's
     *  `Application.onCreate()` doesn't block. */
    private val initScope = kotlinx.coroutines.CoroutineScope(
        kotlinx.coroutines.SupervisorJob() + kotlinx.coroutines.Dispatchers.IO
    )

    /**
     * Tracks the topmost (or last-resumed) Activity in this process. Set
     * automatically via [android.app.Application.ActivityLifecycleCallbacks]
     * installed during [init]. Used by the `server:reload` handler to call
     * [android.app.Activity.recreate] on the current activity.
     *
     * Activities are weakly referenced so a recreated activity doesn't
     * leak through this field after [recreate] runs.
     */
    private var trackedActivityRef: java.lang.ref.WeakReference<android.app.Activity>? = null
    private var lifecycleCallbacks: android.app.Application.ActivityLifecycleCallbacks? = null

    /** Monotonic timestamp of the last server:reload/server:hot_restart
     *  we dispatched. Used to debounce — a malicious or buggy desktop
     *  could otherwise recreate the Activity every frame. */
    @Volatile private var lastReloadDispatchMs = 0L
    private val reloadDebounceMs = 1_000L

    /**
     * Installs an [android.app.Application.ActivityLifecycleCallbacks] that
     * keeps [trackedActivityRef] pointed at the topmost resumed Activity.
     * The callback is installed once per process — repeat calls are no-ops —
     * and uninstalled automatically when the tracked activity is destroyed.
     */
    private fun installActivityLifecycleTracker(app: android.content.Context) {
        if (lifecycleCallbacks != null) return
        val appCtx = app.applicationContext as? android.app.Application ?: return

        val callbacks = object : android.app.Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(a: android.app.Activity, b: android.os.Bundle?) {
                trackedActivityRef = java.lang.ref.WeakReference(a)
            }
            override fun onActivityStarted(a: android.app.Activity) {}
            override fun onActivityResumed(a: android.app.Activity) {
                trackedActivityRef = java.lang.ref.WeakReference(a)
            }
            override fun onActivityPaused(a: android.app.Activity) {}
            override fun onActivityStopped(a: android.app.Activity) {}
            override fun onActivitySaveInstanceState(a: android.app.Activity, b: android.os.Bundle) {}
            override fun onActivityDestroyed(a: android.app.Activity) {
                val current = trackedActivityRef?.get()
                if (current === a) trackedActivityRef = null
            }
        }
        lifecycleCallbacks = callbacks
        appCtx.registerActivityLifecycleCallbacks(callbacks)
    }

    /**
     * Dispatch a reload/hot_restart request to the host activity, with a
     * 1-second debounce so a misbehaving desktop cannot thrash the
     * activity through onCreate/onDestroy at 10Hz. Shared between
     * `server:reload` and `server:hot_restart` because they trigger the
     * same code path on Android (Activity.recreate is the strongest
     * "reset" Android exposes).
     *
     * Main-thread dispatch is required — the WebSocket listener fires on
     * a background thread and Activity.recreate() MUST run on the UI
     * thread or ActivityManager throws CalledFromWrongThreadException.
     */
    private fun handleReloadRequest(messageType: String) {
        val now = System.currentTimeMillis()
        if (now - lastReloadDispatchMs < reloadDebounceMs) {
            // Drop the request — the previous one is still in flight or
            // just completed. Log at info level so the dev can see the
            // desktop is spamming.
            android.util.Log.i(
                "DevConnect",
                "Ignored $messageType (debounced — last dispatch $now - $lastReloadDispatchMs ms ago)"
            )
            return
        }
        lastReloadDispatchMs = now

        android.os.Handler(android.os.Looper.getMainLooper()).post {
            if (reloadHandler != null) {
                try { reloadHandler?.invoke() } catch (e: Exception) {
                    android.util.Log.w(
                        "DevConnect",
                        "reloadHandler threw: ${e.message}",
                        e
                    )
                }
            } else {
                try {
                    val act = trackedActivityRef?.get()
                    if (act != null && !act.isFinishing) act.recreate()
                } catch (e: Exception) {
                    android.util.Log.w(
                        "DevConnect",
                        "Activity.recreate failed: ${e.message}",
                        e
                    )
                }
            }
        }
    }

    private fun getPrefs(): android.content.SharedPreferences? {
        return appContext?.getSharedPreferences("dc_session", android.content.Context.MODE_PRIVATE)
    }

    @android.annotation.SuppressLint("HardwareIds")
    private fun generateStableDeviceId(appName: String): String {
        // deviceId is only derived from appContext — calling [init] without
        // a Context is now a programmer error (was previously a silent
        // privacy leak via Build.FINGERPRINT).
        val ctx = appContext
            ?: throw IllegalStateException(
                "DevConnect.init must be called with a Context before deviceId is used"
            )
        val androidId = android.provider.Settings.Secure.getString(
            ctx.contentResolver,
            android.provider.Settings.Secure.ANDROID_ID
        ) ?: ""
        val seed = "$androidId:${ctx.packageName}"
        return UUID.nameUUIDFromBytes(seed.toByteArray()).toString()
    }

    /** Cached host + server's stable machineId for identity verification. */
    private data class CachedHost(val host: String, val machineId: String)

    /**
     * Cache the discovered host. Stored as plain JSON in
     * `dc_session` SharedPreferences (MODE_PRIVATE). The previous
     * implementation claimed "encryption" via XOR with a hardcoded key —
     * XOR with a static key is not encryption, and the misleading framing
     * raised the security review bar without delivering it. The cache
     * holds dev-only connection metadata (IP + machineId), so plain JSON
     * is honest and appropriate.
     */
    private fun saveHostCache(host: String, port: Int, machineId: String?) {
        try {
            val plain = JSONObject().apply {
                put("h", host)
                put("p", port)
                put("t", System.currentTimeMillis())
                if (machineId != null) put("m", machineId)
            }.toString()
            getPrefs()?.edit()?.putString("dc_s", plain)?.apply()
        } catch (_: Exception) {}
    }

    /** Invalidate the cached host. Used when verification fails. */
    private fun clearHostCache() {
        try {
            getPrefs()?.edit()?.remove("dc_s")?.apply()
        } catch (_: Exception) {}
    }

    private fun readHostCache(port: Int): CachedHost? {
        try {
            val plain = getPrefs()?.getString("dc_s", null) ?: return null
            val json = JSONObject(plain)
            val cachedTime = json.optLong("t", 0)
            if (System.currentTimeMillis() - cachedTime > 24 * 60 * 60 * 1000) return null
            if (json.optInt("p") != port) return null
            val host = json.optString("h", null) ?: return null
            val machineId = json.optString("m", null)
            // Legacy caches without machineId cannot be verified and would
            // re-trigger the simulator/device-swap bug we are fixing —
            // treat them as absent.
            if (machineId.isNullOrEmpty()) return null
            return CachedHost(host, machineId)
        } catch (_: Exception) {}
        return null
    }

    /**
     * Probe a host via plain HTTP GET / and check that it returns the
     * expected `machineId` in the JSON response. Cheap and reliable — no
     * WebSocket frame parsing required.
     *
     * Prevents connecting to the wrong machine when the cached IP now points
     * at a different device (e.g. switched between iOS Simulator and a real
     * iPhone, or back, after the desktop's address changed).
     */
    private fun verifyCachedHost(host: String, port: Int, expectedId: String): Boolean {
        var connection: java.net.HttpURLConnection? = null
        return try {
            val url = java.net.URL("http://$host:$port/")
            connection = url.openConnection() as java.net.HttpURLConnection
            connection.connectTimeout = 1500
            connection.readTimeout = 1500
            connection.requestMethod = "GET"
            connection.doInput = true
            val code = connection.responseCode
            if (code !in 200..299) {
                return false
            }
            val body = connection.inputStream.bufferedReader().use { it.readText() }
            val announced = extractMachineId(body)
            announced == expectedId
        } catch (_: Exception) {
            false
        } finally {
            connection?.disconnect()
        }
    }

    /** Parse machineId from the server's plain HTTP identify response. */
    private fun extractMachineId(jsonText: String): String? {
        return try {
            val json = JSONObject(jsonText)
            json.optString("machineId", null)
        } catch (_: Exception) {
            null
        }
    }

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
        /** Auto-intercept HttpURLConnection (Volley, native HTTP). Default: true */
        autoInterceptHttp: Boolean = true,
        /** Auto-start performance monitoring (default: true) */
        autoPerformance: Boolean = true,
        /** Auto-start memory leak detection (default: true) */
        autoMemoryLeak: Boolean = true,
        /** Auto-start app benchmark (default: true) */
        autoBenchmark: Boolean = true
    ) {
        this.enabled = enabled
        if (!enabled) return

        // Defence-in-depth: warn (not abort) when DevConnect is enabled in
        // a non-debuggable build. The SDK captures network requests,
        // headers (incl. Authorization), and request bodies that may
        // contain OAuth tokens — production releases should pass
        // `enabled = BuildConfig.DEBUG`.
        try {
            // `context` is typed `Any` so cross-platform call sites can
            // pass a non-Android context. Smart-cast to a real Context
            // before accessing platform-specific members.
            val ctx = context as? android.content.Context
            val app = ctx?.applicationContext as? android.app.Application
            if (app != null &&
                (app.getApplicationInfo().flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) == 0
            ) {
                android.util.Log.w(
                    "DevConnect",
                    "DevConnect.init called with enabled=true in a non-debuggable build. " +
                        "Captured traffic (incl. Authorization headers) will be sent in cleartext " +
                        "to the LAN-connected desktop. Pass `enabled = BuildConfig.DEBUG` in release."
                )
            }
        } catch (_: Exception) {}

        // Save context for SharedPreferences. We require a real Context so
        // deviceId derivation never falls through to the Build.FINGERPRINT
        // privacy leak (M4).
        if (context is android.content.Context) {
            appContext = context.applicationContext
            // `context` is smart-cast to non-null inside this branch;
            // pass the applicationContext directly so installActivity-
            // // LifecycleTracker (which expects a non-null Context) doesn't
            // receive the nullable `appContext` field.
            installActivityLifecycleTracker(context.applicationContext)
        } else {
            throw IllegalArgumentException(
                "DevConnect.init requires an android.content.Context as the first argument"
            )
        }

        // Generate stable deviceId from app + device info (prevents duplicates on reconnect/hot-reload)
        deviceId = generateStableDeviceId(appName)

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
                auto -> autoDetectHost(port)
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
                autoBenchmark = autoBenchmark
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
        autoBenchmark: Boolean
    ) {
        // Disconnect old client to prevent orphaned connections
        client?.disconnect()

        client = WebSocketClient(
            host = host,
            port = port,
            deviceId = deviceId,
            appName = appName,
            appVersion = appVersion,
            versionCode = versionCode
        ).also { ws ->
            // Capture the server's stable machineId so the next launch can
            // verify the cached host really points at *this* desktop and not
            // some other device that happened to claim the same IP.
            ws.onServerHello = { machineId ->
                if (!machineId.isNullOrEmpty()) {
                    saveHostCache(host, port, machineId)
                }
            }
            ws.onServerMessage = { type, json ->
                val payload = json.optJSONObject("payload") ?: JSONObject()
                when (type) {
                    "server:state:restore" -> {
                        val state = payload.optJSONObject("state")
                        if (state != null) {
                            val map = jsonObjectToMap(state)
                            // Guard the user-supplied lambda — a throw
                            // here used to escape into the WebSocket
                            // coroutine scope and silently fail the
                            // whole restore. Log to the desktop so the
                            // dev can see which handler broke.
                            try {
                                onStateRestore?.invoke(map)
                            } catch (e: Exception) {
                                sendLog("error", "onStateRestore threw: ${e.message}", "DevConnect", e.stackTraceToString())
                            }
                        }
                    }
                    "server:redux:dispatch" -> {
                        val action = payload.optJSONObject("action")
                        if (action != null) {
                            val map = jsonObjectToMap(action)
                            try {
                                onReduxDispatch?.invoke(map)
                            } catch (e: Exception) {
                                sendLog("error", "onReduxDispatch threw: ${e.message}", "DevConnect", e.stackTraceToString())
                            }
                        }
                    }
                    "server:custom:command" -> {
                        val cmd = payload.optString("command", "")
                        val handler = commandHandlers[cmd]
                        if (handler != null) {
                            val args = payload.optJSONObject("args")
                            val argsMap = if (args != null) jsonObjectToMap(args) else null
                            try {
                                val result = handler(argsMap)
                                send("client:custom:command_result", buildPayload {
                                    put("command", cmd)
                                    put("status", "ok")
                                    if (result != null) put("result", result)
                                })
                            } catch (e: Exception) {
                                // Surface the failure to the desktop so it
                                // can show the user that the handler
                                // crashed — the previous "swallow + send
                                // empty result" payload made every failure
                                // look like success.
                                send("client:custom:command_result", buildPayload {
                                    put("command", cmd)
                                    put("status", "error")
                                    put("error", e.message ?: e.javaClass.simpleName)
                                })
                            }
                        }
                    }
                    "server:reload" -> handleReloadRequest(json.optString("type"))
                    "server:hot_restart" -> handleReloadRequest(json.optString("type"))
                }
            }
        }
        client?.connect()

        // Auto-intercept System.out (println) if enabled
        if (autoInterceptLogs) {
            com.devconnect.interceptors.DevConnectLogInterceptor.interceptSystemOut()
        }

        // Auto-intercept HttpURLConnection (catches Volley, native HTTP, etc.)
        if (autoInterceptHttp) {
            DevConnectURLStreamHandlerFactory.install()
        }

        // Flush pre-init queue (messages from interceptors before init).
        // Hold the same lock [send] uses so a late interceptor can't enqueue
        // between our drain and clear — that race was the source of an
        // earlier CME.
        synchronized(preInitQueue) {
            if (preInitQueue.isNotEmpty()) {
                for ((type, payload) in preInitQueue) {
                    send(type, payload)
                }
                preInitQueue.clear()
            }
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
        // 0. Try cached host from previous session (instant reconnect).
        //    Verify the server's machineId matches what we cached — this
        //    catches the case where the cached IP now points at a different
        //    device (e.g. iOS Simulator ↔ real iPhone swap on the same network).
        val cached = readHostCache(port)
        if (cached != null) {
            if (verifyCachedHost(cached.host, port, cached.machineId)) {
                return cached.host
            }
            // Stale or wrong machine — invalidate so the next discovery wins.
            clearHostCache()
        }

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
                        saveHostCache(result, port, null)
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
                            if (found != null) { saveHostCache(found, port, null); return found }
                        }
                    }
                }
            }
        } catch (_: Exception) {}

        // 4. Scan common subnets as fallback
        val commonSubnets = listOf("192.168.1", "192.168.0", "192.168.2", "10.0.0", "10.0.1", "172.16.0")
        for (subnet in commonSubnets) {
            val found = scanSubnet(subnet, port)
            if (found != null) { saveHostCache(found, port, null); return found }
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

    private val reloadHandler: (() -> Unit)?
        get() = onReloadRequest

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
            value?.let { put("value", redactSensitiveValue(key, it)) }
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
            for ((k, v) in payload) {
                if (v == null) {
                    json.put(k, JSONObject.NULL)
                } else {
                    json.put(k, v)
                }
            }
            send(type, json)
        } catch (_: Exception) {
            // The process is dying — swallow everything.
        }
    }

    /** Keys whose values must be redacted before they leave the device.
     *  Matches `Authorization`, `Cookie`, `password`, `token`, `secret`,
     *  etc. by substring (case-insensitive) — same heuristic the desktop
     *  side uses. */
    private val sensitiveKeyPatterns = listOf(
        "token", "password", "secret", "apikey", "api_key",
        "authorization", "cookie", "set-cookie", "credential"
    )

    private fun redactSensitiveValue(key: String, value: Any?): Any? {
        if (value == null) return null
        val lower = key.lowercase()
        if (sensitiveKeyPatterns.any { lower.contains(it) }) {
            return "[REDACTED]"
        }
        return value
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

    private val benchmarks = java.util.concurrent.ConcurrentHashMap<String, MutableList<Long>>()

    fun benchmarkStart(title: String) {
        benchmarks[title] = mutableListOf(System.currentTimeMillis())
    }

    fun benchmarkStep(title: String) {
        // Synchronize the inner list — ConcurrentHashMap only guards the
        // map access, not the underlying list's mutation.
        synchronized(benchmarks) {
            benchmarks[title]?.add(System.currentTimeMillis())
        }
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

    private val commandHandlers = java.util.concurrent.ConcurrentHashMap<String, (Map<String, Any>?) -> Any?>()

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
