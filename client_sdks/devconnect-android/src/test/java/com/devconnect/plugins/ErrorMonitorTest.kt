package com.devconnect.plugins

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.PrintWriter

/**
 * The app's own crash handler (Crashlytics, Sentry, the system one that
 * kills the process) used to be skipped when reporting the crash threw.
 */
class ErrorMonitorTest {

    private val original = Thread.getDefaultUncaughtExceptionHandler()

    @After
    fun restore() {
        ErrorMonitor.stop()
        Thread.setDefaultUncaughtExceptionHandler(original)
    }

    @Test
    fun `the previous handler runs even when reporting the crash fails`() {
        val seen = mutableListOf<Throwable>()
        Thread.setDefaultUncaughtExceptionHandler { _, e -> seen += e }
        ErrorMonitor::class.java.getDeclaredMethod("setupUncaughtExceptionHandler")
            .apply { isAccessible = true }
            .invoke(ErrorMonitor)
        // Building the report's stack trace runs out of memory.
        val crash = object : RuntimeException("boom") {
            override fun printStackTrace(s: PrintWriter): Unit = throw OutOfMemoryError()
        }

        runCatching { Thread.getDefaultUncaughtExceptionHandler()!!.uncaughtException(Thread.currentThread(), crash) }

        assertEquals(listOf<Throwable>(crash), seen)
    }
}
