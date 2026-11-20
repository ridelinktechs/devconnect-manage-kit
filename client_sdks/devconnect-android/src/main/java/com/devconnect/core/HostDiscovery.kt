package com.devconnect.core

import com.devconnect.DevConnect
import org.json.JSONObject
import java.util.UUID

/** This device's stable id, plus finding the desktop on the network and caching its address. */
internal object HostDiscovery {
    private fun getPrefs(): android.content.SharedPreferences? {
        return DevConnect.appContext?.getSharedPreferences("dc_session", android.content.Context.MODE_PRIVATE)
    }

    @android.annotation.SuppressLint("HardwareIds")
    fun generateStableDeviceId(appName: String): String {
        // deviceId is only derived from appContext — calling [init] without
        // a Context is now a programmer error (was previously a silent
        // privacy leak via Build.FINGERPRINT).
        val ctx = DevConnect.appContext
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
    fun saveHostCache(host: String, port: Int, machineId: String?) {
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

    /** UDP discovery port — server broadcasts beacons here */
    private const val DISCOVERY_PORT = 41234

    fun autoDetectHost(port: Int): String {
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
}
