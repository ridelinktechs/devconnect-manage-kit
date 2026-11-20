package com.devconnect.core

import com.devconnect.DevConnect
import com.devconnect.client.WebSocketClient
import com.devconnect.interceptors.DevConnectURLStreamHandlerFactory

/** The steps behind [DevConnect.init] and [DevConnect.installForApp]: attach to the app, then connect. */
internal object Startup {
    fun attach(context: Any) {
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
            DevConnect.appContext = context.applicationContext
            // `context` is smart-cast to non-null inside this branch;
            // pass the applicationContext directly so installActivity-
            // // LifecycleTracker (which expects a non-null Context) doesn't
            // receive the nullable `appContext` field.
            AppLifecycle.installActivityLifecycleTracker(context.applicationContext)
        } else {
            throw IllegalArgumentException(
                "DevConnect.init requires an android.content.Context as the first argument"
            )
        }
    }

    fun connectAfterDiscovery(
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
    ) {
        // Disconnect old client to prevent orphaned connections
        DevConnect.client?.disconnect()

        DevConnect.client = WebSocketClient(
            host = host,
            port = port,
            deviceId = DevConnect.deviceId,
            appName = appName,
            appVersion = appVersion,
            versionCode = versionCode
        ).also { ws ->
            // Capture the server's stable machineId so the next launch can
            // verify the cached host really points at *this* desktop and not
            // some other device that happened to claim the same IP.
            ws.onServerHello = { machineId ->
                if (!machineId.isNullOrEmpty()) {
                    HostDiscovery.saveHostCache(host, port, machineId)
                }
                // The handshake just went out: tell the desktop what it can run.
                DesktopCommands.announceCommands()
            }
            ws.onDisconnected = {
                DevConnect.networkLatencyMs = 0
                DevConnect.networkOffline = false
                com.devconnect.interceptors.MockRuleStore.clearDesktopRules()
            }
            ws.onServerMessage = { type, json -> DesktopCommands.handle(type, json) }
        }
        DevConnect.client?.connect()

        // Auto-intercept System.out (println) if enabled
        if (autoInterceptLogs) {
            com.devconnect.interceptors.DevConnectLogInterceptor.interceptSystemOut()
        }

        if (autoInterceptHttp) {
            DevConnectURLStreamHandlerFactory.install()
        }

        // Flush pre-init queue (messages from interceptors before init).
        // Hold the same lock [send] uses so a late interceptor can't enqueue
        // between our drain and clear — that race was the source of an
        // earlier CME.
        synchronized(DevConnect.preInitQueue) {
            if (DevConnect.preInitQueue.isNotEmpty()) {
                for ((type, payload) in DevConnect.preInitQueue) {
                    DevConnect.send(type, payload)
                }
                DevConnect.preInitQueue.clear()
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
        // ErrorMonitor covers ANR detection. Native crash capture is
        // intentionally out of scope (would require JNI + NDK).
        if (autoAnrWatchdog && context is android.content.Context) {
            com.devconnect.plugins.ErrorMonitor.start(context)
        }
        if (autoViewModelDiscovery) {
            com.devconnect.plugins.ViewModelAutoDiscoverer.start(context)
        }
        // Round 2: Compose state observer (no-op when Compose isn't on the classpath)
        try {
            com.devconnect.plugins.ComposeStateObserver.start(context)
        } catch (_: Exception) {}
    }

    fun installForApp(
        context: Any,
        appName: String,
        appVersion: String,
        host: String?,
        port: Int,
        enabled: Boolean,
        versionCode: String?,
    ) {
        DevConnect.init(
            context = context,
            appName = appName,
            appVersion = appVersion,
            host = host,
            port = port,
            enabled = enabled,
            versionCode = versionCode,
            autoInterceptLogs = true,
            autoInterceptHttp = true,
            autoPerformance = true,
            autoMemoryLeak = true,
            autoBenchmark = true,
            autoAnrWatchdog = true,
            autoViewModelDiscovery = true,
        )

        if (enabled) {
            val cl = context::class.java.classLoader
            val hasOkHttp = try {
                cl.loadClass("okhttp3.OkHttpClient") != null
            } catch (_: ClassNotFoundException) { false }

            val hasTimber = try {
                cl.loadClass("timber.log.Timber") != null
            } catch (_: ClassNotFoundException) { false }

            if (hasOkHttp) {
                android.util.Log.i(
                    "DevConnect",
                    "Detected OkHttp on classpath. To capture network traffic, " +
                        "add `DevConnect.okHttpInterceptor()` to your OkHttpClient.Builder(). " +
                        "See README 'Wiring OkHttp / Retrofit'."
                )
            }
            if (hasTimber) {
                android.util.Log.i(
                    "DevConnect",
                    "Detected Timber on classpath. To capture Timber logs, plant a Tree " +
                        "that calls `DevConnect.sendLog(...)`. See README 'Wiring Timber'."
                )
            }
        }
    }
}
