package com.devconnect.core

import com.devconnect.DevConnect
import kotlinx.coroutines.launch
import org.json.JSONObject

/** Handles the `server:*` messages the desktop sends. */
internal object DesktopCommands {
    fun handle(type: String, json: JSONObject) {
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
                    onMainThread {
                        try {
                            DevConnect.onStateRestore?.invoke(map)
                        } catch (e: Exception) {
                            DevConnect.sendLog("error", "onStateRestore threw: ${e.message}", "DevConnect", e.stackTraceToString())
                        }
                    }
                }
            }
            "server:redux:dispatch" -> {
                val action = payload.optJSONObject("action")
                if (action != null) {
                    val map = jsonObjectToMap(action)
                    onMainThread {
                        try {
                            DevConnect.onReduxDispatch?.invoke(map)
                        } catch (e: Exception) {
                            DevConnect.sendLog("error", "onReduxDispatch threw: ${e.message}", "DevConnect", e.stackTraceToString())
                        }
                    }
                }
            }
            "server:custom:command" -> {
                val cmd = payload.optString("command", "")
                val handler = DevConnect.commandHandlers[cmd]
                if (handler != null) {
                    val args = payload.optJSONObject("args")
                    val argsMap = if (args != null) jsonObjectToMap(args) else null
                    try {
                        val result = handler(argsMap)
                        DevConnect.send("client:custom:command_result", buildPayload {
                            put("command", cmd)
                            put("status", "ok")
                            if (result != null) put("result", jsonValue(result))
                        })
                    } catch (e: Exception) {
                        // Surface the failure to the desktop so it
                        // can show the user that the handler
                        // crashed — the previous "swallow + send
                        // empty result" payload made every failure
                        // look like success.
                        DevConnect.send("client:custom:command_result", buildPayload {
                            put("command", cmd)
                            put("status", "error")
                            put("error", e.message ?: e.javaClass.simpleName)
                        })
                    }
                }
            }
            "server:reload" -> AppLifecycle.handleReloadRequest(json.optString("type"))
            "server:hot_restart" -> AppLifecycle.handleReloadRequest(json.optString("type"))
            "server:storage:request_all", "server:storage:write",
            "server:storage:delete", "server:storage:clear" ->
                DevConnect.initScope.launch { handleStorageCommand(type, payload) }
            "server:open_url" -> openUrl(payload.optString("url"))
            "server:layout:capture" -> DevConnect.initScope.launch {
                val activity = AppLifecycle.trackedActivityRef?.get() ?: return@launch
                val snapshot = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                    com.devconnect.plugins.LayoutInspector.capture(activity)
                }
                DevConnect.send("client:layout:snapshot", snapshot)
            }
            "server:network:throttle" -> {
                DevConnect.networkLatencyMs = payload.optLong("latencyMs", 0).coerceAtLeast(0)
                DevConnect.networkOffline = payload.optBoolean("offline", false)
            }
            "server:network:replay" -> DevConnect.initScope.launch { replayRequest(payload) }
            // Off the socket's reader: a big table can take a while.
            "server:database:request_schema" -> DevConnect.initScope.launch {
                DevConnect.send("client:database:schema", JSONObject().put("databases", databaseSchemas()))
            }
            "server:database:query" -> DevConnect.initScope.launch {
                DevConnect.send(
                    "client:database:query_result",
                    runDatabaseQuery(payload.optString("database"), payload.optString("sql")),
                )
            }
            "server:mock_rules_update" ->
                com.devconnect.interceptors.MockRuleStore.loadFromPayload(payload)
        }
    }

    /** Reads / writes / deletes / clears a registered store, then sends its contents. */
    private fun handleStorageCommand(type: String, p: JSONObject) {
        val only = p.optString("storageType").ifEmpty { null }
        val targets = if (only == null) DevConnect.storages.toList()
        else listOfNotNull(DevConnect.storages[only]?.let { only to it })
        for ((name, adapter) in targets) {
            val result = JSONObject().put("storageType", name)
            try {
                val key = p.optString("key")
                when (type) {
                    "server:storage:write" -> adapter.set(key, jsonToKotlin(p.opt("value")))
                    "server:storage:delete" -> adapter.remove(key)
                    "server:storage:clear" -> adapter.clear()
                }
                result.put("entries", JSONObject(adapter.getAll()))
            } catch (e: Exception) {
                result.put("entries", JSONObject()).put("error", e.message ?: e.javaClass.simpleName)
            }
            DevConnect.send("client:storage:all_data", result)
        }
    }

    /**
     * Runs [block] on the main thread, so a handler can touch views and
     * `LiveData.setValue`; inline when already there, or when there is no
     * Android main looper (JVM tests).
     */
    private fun onMainThread(block: () -> Unit) {
        val main = try {
            android.os.Looper.getMainLooper()
        } catch (_: RuntimeException) {
            null
        }
        if (main == null || main.thread == Thread.currentThread()) block()
        else android.os.Handler(main).post(block)
    }

    /**
     * Sends a captured request again: as a clone of the app's own OkHttp
     * call when it's remembered (real headers, same interceptors), else over
     * HttpURLConnection with the captured method, URL, headers and body.
     */
    private fun replayRequest(p: JSONObject) {
        val requestId = p.optString("requestId")
        val viaOkHttp = try {
            requestId.isNotEmpty() && com.devconnect.interceptors.OkHttpCalls.replay(requestId)
        } catch (_: LinkageError) {
            false // the app doesn't ship OkHttp
        }
        if (viaOkHttp) return
        val url = p.optString("url").ifEmpty { return }
        val method = p.optString("method", "GET").uppercase()
        try {
            val conn = java.net.URL(url).openConnection() as java.net.HttpURLConnection
            conn.requestMethod = method
            p.optJSONObject("headers")?.let { headers ->
                for (name in headers.keys()) {
                    if (!name.equals("content-length", ignoreCase = true)) {
                        conn.setRequestProperty(name, headers.optString(name))
                    }
                }
            }
            val body = p.opt("body")
            if (body != null && body != JSONObject.NULL && method != "GET" && method != "HEAD") {
                conn.doOutput = true
                conn.outputStream.use { it.write(body.toString().toByteArray()) }
            }
            (if (conn.responseCode >= 400) conn.errorStream else conn.inputStream)?.use { it.readBytes() }
        } catch (_: Exception) {
            // Reported like any other failed request.
        }
    }

    /** Opens [url] in this app, the way a tap on one of its links does. */
    private fun openUrl(url: String) {
        val ctx = DevConnect.appContext ?: return
        if (url.isEmpty()) return
        try {
            ctx.startActivity(
                android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url))
                    .setPackage(ctx.packageName)
                    .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (_: Exception) {
            DevConnect.sendLog("warn", "No activity of this app handles $url", "DevConnect", null)
        }
    }

    /** Rows past this are left out of a query result, which says `truncated`. */
    private const val MAX_QUERY_ROWS = 1000

    private fun databaseSchemas() = org.json.JSONArray().apply {
        for ((name, query) in DevConnect.databases) {
            val tables = org.json.JSONArray()
            try {
                val names = query(
                    "SELECT name FROM sqlite_master WHERE type = 'table' " +
                        "AND name NOT LIKE 'sqlite_%' AND name <> 'android_metadata' ORDER BY name"
                ).use { c -> buildList { while (c.moveToNext()) add(c.getString(0)) } }
                for (table in names) {
                    val quoted = "\"" + table.replace("\"", "\"\"") + "\""
                    val columns = query("PRAGMA table_info($quoted)").use { c ->
                        org.json.JSONArray().apply {
                            while (c.moveToNext()) put(
                                JSONObject()
                                    .put("name", c.getString(c.getColumnIndexOrThrow("name")))
                                    .put("type", c.getString(c.getColumnIndexOrThrow("type")) ?: "")
                                    .put("isPrimaryKey", c.getInt(c.getColumnIndexOrThrow("pk")) > 0)
                                    .put("isNullable", c.getInt(c.getColumnIndexOrThrow("notnull")) == 0)
                            )
                        }
                    }
                    val rowCount = query("SELECT COUNT(*) FROM $quoted")
                        .use { c -> if (c.moveToFirst()) c.getLong(0) else 0L }
                    tables.put(
                        JSONObject().put("name", table).put("columns", columns).put("rowCount", rowCount)
                    )
                }
            } catch (_: Exception) {
                // Unreadable database: listed without tables.
            }
            put(JSONObject().put("name", name).put("tables", tables))
        }
    }

    private fun runDatabaseQuery(database: String, sql: String): JSONObject {
        val start = System.currentTimeMillis()
        val result = JSONObject().put("database", database)
        try {
            val query = DevConnect.databases[database] ?: DevConnect.databases.values.firstOrNull()
                ?: throw IllegalStateException("No database registered with DevConnect.registerDatabase")
            query(sql).use { c ->
                val columns = c.columnNames.toList()
                val rows = org.json.JSONArray()
                while (rows.length() < MAX_QUERY_ROWS && c.moveToNext()) {
                    rows.put(JSONObject().apply {
                        for (i in columns.indices) put(columns[i], when (c.getType(i)) {
                            android.database.Cursor.FIELD_TYPE_NULL -> JSONObject.NULL
                            android.database.Cursor.FIELD_TYPE_INTEGER -> c.getLong(i)
                            android.database.Cursor.FIELD_TYPE_FLOAT -> c.getDouble(i)
                            android.database.Cursor.FIELD_TYPE_BLOB -> "<blob ${c.getBlob(i).size} bytes>"
                            else -> c.getString(i)
                        })
                    })
                }
                result.put("columns", org.json.JSONArray(columns))
                    .put("rows", rows)
                    .put("truncated", c.moveToNext())
            }
        } catch (e: Exception) {
            result.put("columns", org.json.JSONArray())
                .put("rows", org.json.JSONArray())
                .put("error", e.message ?: e.javaClass.simpleName)
        }
        return result.put("executionTimeMs", System.currentTimeMillis() - start)
    }

    /** Tells the desktop which custom commands it can run (Commands panel). */
    fun announceCommands() {
        DevConnect.send(
            "client:custom:commands",
            JSONObject().put("commands", org.json.JSONArray(DevConnect.commandHandlers.keys.toList())),
        )
    }
}
