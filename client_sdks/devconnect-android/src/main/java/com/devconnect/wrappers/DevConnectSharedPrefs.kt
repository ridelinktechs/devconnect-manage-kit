package com.devconnect.wrappers

import android.content.SharedPreferences
import com.devconnect.DevConnect

/**
 * Auto-reporting wrapper for SharedPreferences.
 *
 * ```kotlin
 * val prefs = DevConnectSharedPrefs.wrap(
 *     context.getSharedPreferences("my_prefs", Context.MODE_PRIVATE)
 * )
 * prefs.edit().putString("token", "abc").apply() // auto-reports write
 * prefs.getString("token", null)                  // auto-reports read
 * ```
 */
class DevConnectSharedPrefs private constructor(
    private val inner: SharedPreferences
) : SharedPreferences by inner {

    companion object {
        fun wrap(prefs: SharedPreferences): DevConnectSharedPrefs {
            val wrapped = DevConnectSharedPrefs(prefs)
            // Lets the desktop's Storage tab list and edit it; edits go
            // through the tracked editor so they're reported like the app's.
            DevConnect.registerStorage("shared_preferences", object : DevConnect.StorageAdapter {
                override fun getAll(): Map<String, Any?> = prefs.all

                override fun set(key: String, value: Any?) {
                    val editor = wrapped.edit()
                    when (value) {
                        null -> editor.remove(key)
                        is Boolean -> editor.putBoolean(key, value)
                        // Keep the stored type, or the app's getInt() throws.
                        is Number -> when (prefs.all[key]) {
                            is Int -> editor.putInt(key, value.toInt())
                            is Long -> editor.putLong(key, value.toLong())
                            is Float -> editor.putFloat(key, value.toFloat())
                            else -> when (value) {
                                is Int -> editor.putInt(key, value)
                                is Long -> editor.putLong(key, value)
                                else -> editor.putFloat(key, value.toFloat())
                            }
                        }
                        is Collection<*> -> editor.putStringSet(key, value.map { "$it" }.toSet())
                        else -> editor.putString(key, value.toString())
                    }
                    editor.apply()
                }

                override fun remove(key: String) = wrapped.edit().remove(key).apply()

                override fun clear() = wrapped.edit().clear().apply()
            })
            return wrapped
        }
    }

    override fun getString(key: String?, defValue: String?): String? {
        val value = inner.getString(key, defValue)
        report("read", key ?: "", value)
        return value
    }

    override fun getInt(key: String?, defValue: Int): Int {
        val value = inner.getInt(key, defValue)
        report("read", key ?: "", value)
        return value
    }

    override fun getLong(key: String?, defValue: Long): Long {
        val value = inner.getLong(key, defValue)
        report("read", key ?: "", value)
        return value
    }

    override fun getFloat(key: String?, defValue: Float): Float {
        val value = inner.getFloat(key, defValue)
        report("read", key ?: "", value)
        return value
    }

    override fun getBoolean(key: String?, defValue: Boolean): Boolean {
        val value = inner.getBoolean(key, defValue)
        report("read", key ?: "", value)
        return value
    }

    override fun getStringSet(key: String?, defValues: MutableSet<String>?): MutableSet<String>? {
        val value = inner.getStringSet(key, defValues)
        report("read", key ?: "", value)
        return value
    }

    override fun edit(): SharedPreferences.Editor {
        return TrackedEditor(inner.edit())
    }

    private fun report(operation: String, key: String, value: Any?) {
        DevConnect.sendStorage(
            storageType = "shared_preferences",
            key = key,
            value = value,
            operation = operation,
        )
    }

    inner class TrackedEditor(private val editor: SharedPreferences.Editor) : SharedPreferences.Editor by editor {

        override fun putString(key: String?, value: String?): SharedPreferences.Editor {
            editor.putString(key, value)
            report("write", key ?: "", value)
            return this
        }

        override fun putInt(key: String?, value: Int): SharedPreferences.Editor {
            editor.putInt(key, value)
            report("write", key ?: "", value)
            return this
        }

        override fun putLong(key: String?, value: Long): SharedPreferences.Editor {
            editor.putLong(key, value)
            report("write", key ?: "", value)
            return this
        }

        override fun putFloat(key: String?, value: Float): SharedPreferences.Editor {
            editor.putFloat(key, value)
            report("write", key ?: "", value)
            return this
        }

        override fun putBoolean(key: String?, value: Boolean): SharedPreferences.Editor {
            editor.putBoolean(key, value)
            report("write", key ?: "", value)
            return this
        }

        override fun putStringSet(key: String?, values: MutableSet<String>?): SharedPreferences.Editor {
            editor.putStringSet(key, values)
            report("write", key ?: "", values)
            return this
        }

        override fun remove(key: String?): SharedPreferences.Editor {
            editor.remove(key)
            report("delete", key ?: "", null)
            return this
        }

        override fun clear(): SharedPreferences.Editor {
            editor.clear()
            report("clear", "*", null)
            return this
        }
    }
}
