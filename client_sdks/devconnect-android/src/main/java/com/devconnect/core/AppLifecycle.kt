package com.devconnect.core

import com.devconnect.DevConnect

/** Tracks the app's current Activity and recreates it when the desktop asks for a reload. */
internal object AppLifecycle {
    /**
     * Tracks the topmost (or last-resumed) Activity in this process. Set
     * automatically via [android.app.Application.ActivityLifecycleCallbacks]
     * installed during [init]. Used by the `server:reload` handler to call
     * [android.app.Activity.recreate] on the current activity.
     *
     * Activities are weakly referenced so a recreated activity doesn't
     * leak through this field after [recreate] runs.
     */
    var trackedActivityRef: java.lang.ref.WeakReference<android.app.Activity>? = null
    private var lifecycleCallbacks: android.app.Application.ActivityLifecycleCallbacks? = null

    /** Monotonic timestamp of the last server:reload/server:hot_restart
     *  we dispatched. Used to debounce — a malicious or buggy desktop
     *  could otherwise recreate the Activity every frame. */
    @Volatile private var lastReloadDispatchMs = 0L
    private val reloadDebounceMs = 1_000L

    private val reloadHandler: (() -> Unit)?
        get() = DevConnect.onReloadRequest

    /**
     * Installs an [android.app.Application.ActivityLifecycleCallbacks] that
     * keeps [trackedActivityRef] pointed at the topmost resumed Activity.
     * The callback is installed once per process — repeat calls are no-ops —
     * and uninstalled automatically when the tracked activity is destroyed.
     */
    fun installActivityLifecycleTracker(app: android.content.Context) {
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
    fun handleReloadRequest(messageType: String) {
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
}
