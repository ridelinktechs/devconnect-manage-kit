package com.devconnect.interceptors

import org.junit.Assert.assertTrue
import org.junit.Test
import java.net.HttpURLConnection
import java.net.URL

/**
 * [DevConnectURLStreamHandlerFactory.install] runs by default
 * (`autoInterceptHttp = true`). It used to install a JVM-wide handler that
 * reopened each URL through itself, so every HttpURLConnection in the app
 * died with a StackOverflowError.
 */
class URLStreamHandlerFactoryTest {

    @Test
    fun `install leaves HttpURLConnection working`() {
        DevConnectURLStreamHandlerFactory.install()
        DevConnectURLStreamHandlerFactory.install()

        // openConnection() doesn't touch the network until connect().
        assertTrue(URL("http://example.com/").openConnection() is HttpURLConnection)
    }
}
