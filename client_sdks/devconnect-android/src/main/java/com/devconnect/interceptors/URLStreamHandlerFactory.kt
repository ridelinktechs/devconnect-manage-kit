package com.devconnect.interceptors

import com.devconnect.DevConnect

/**
 * HttpURLConnection can't be auto-captured on Android: the platform's
 * default handler is hidden API. [install] only logs how to capture it.
 */
object DevConnectURLStreamHandlerFactory {

    private const val TAG = "URLStreamHandlerFactory"

    private var logged = false

    fun install() {
        if (logged) return
        logged = true
        DevConnect.sendLog(
            "info",
            "HttpURLConnection traffic isn't captured automatically on Android. " +
                "Add DevConnect.okHttpInterceptor() to your OkHttpClient, or wrap " +
                "connections with DevConnectHttpURLConnection.wrap().",
            TAG
        )
    }
}
