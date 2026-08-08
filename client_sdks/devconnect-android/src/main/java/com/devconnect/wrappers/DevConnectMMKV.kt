package com.devconnect.wrappers

import com.devconnect.DevConnect

/**
 * Auto-reporting wrapper for MMKV (Android).
 *
 * ```kotlin
 * val mmkv = DevConnectMMKV.wrap(MMKV.defaultMMKV())
 * mmkv.encode("token", "abc")  // auto-reports write
 * mmkv.decodeString("token")    // auto-reports read
 * mmkv.removeValueForKey("token") // auto-reports delete
 * ```
 *
 * Uses dynamic dispatch since MMKV is not a compile-time dependency.
 */
class DevConnectMMKV private constructor(
    private val inner: Any,
    private val label: String,
) {
    companion object {
        fun wrap(mmkv: Any, label: String = "mmkv"): DevConnectMMKV {
            return DevConnectMMKV(mmkv, label)
        }
    }

    fun encode(key: String, value: Any?): Boolean {
        // MMKV v1 has separate typed `encode*` methods — there is no
        // polymorphic `encode(key, Any)` overload. Dispatch on runtime
        // type and use the matching MMKV API name.
        val result: Boolean = when (value) {
            null -> invokeEncode("encodeString", key, null as String?)
            is Boolean -> invokeEncode("encodeBool", key, value)
            is Int -> invokeEncode("encodeInt", key, value)
            is Long -> invokeEncode("encodeLong", key, value)
            is Float -> invokeEncode("encodeFloat", key, value)
            is Double -> invokeEncode("encodeDouble", key, value)
            is ByteArray -> invokeEncode("encodeBytes", key, value)
            is String -> invokeEncode("encodeString", key, value)
            else -> throw IllegalArgumentException(
                "DevConnectMMKV.encode does not support value of type ${value.javaClass.name}"
            )
        }
        report("write", key, value)
        return result
    }

    private fun invokeEncode(methodName: String, key: String, value: Any?): Boolean {
        // MMKV's primitive `encode*` methods take JVM primitive types
        // (`int`, `boolean`, ...), so the reflection lookup must pass
        // `Int::class.javaPrimitiveType` / `Boolean::class.javaPrimitiveType`
        // rather than the boxed `Integer` / `Boolean` class.
        val paramTypes = when (value) {
            null -> arrayOf(String::class.java, String::class.java)
            is Boolean -> arrayOf(String::class.java, Boolean::class.javaPrimitiveType)
            is Int -> arrayOf(String::class.java, Int::class.javaPrimitiveType)
            is Long -> arrayOf(String::class.java, Long::class.javaPrimitiveType)
            is Float -> arrayOf(String::class.java, Float::class.javaPrimitiveType)
            is Double -> arrayOf(String::class.java, Double::class.javaPrimitiveType)
            is ByteArray -> arrayOf(String::class.java, ByteArray::class.java)
            is String -> arrayOf(String::class.java, String::class.java)
            else -> throw IllegalArgumentException("unsupported type")
        }
        val method = inner.javaClass.getMethod(methodName, *paramTypes)
        return method.invoke(inner, key, value) as Boolean
    }

    fun decodeString(key: String, defaultValue: String? = null): String? {
        val method = inner.javaClass.getMethod(
            "decodeString",
            String::class.java,
            String::class.java
        )
        val value = method.invoke(inner, key, defaultValue) as? String
        report("read", key, value)
        return value
    }

    fun decodeInt(key: String, defaultValue: Int = 0): Int {
        // `decodeInt(String, int)` — use the primitive `int.class`
        // (`Int::class.javaPrimitiveType`). Passing `Int::class.java`
        // (boxed Integer) would never match and the lookup would throw.
        val method = inner.javaClass.getMethod(
            "decodeInt",
            String::class.java,
            Int::class.javaPrimitiveType
        )
        val value = method.invoke(inner, key, defaultValue) as Int
        report("read", key, value)
        return value
    }

    fun decodeBool(key: String, defaultValue: Boolean = false): Boolean {
        val method = inner.javaClass.getMethod(
            "decodeBool",
            String::class.java,
            Boolean::class.javaPrimitiveType
        )
        val value = method.invoke(inner, key, defaultValue) as Boolean
        report("read", key, value)
        return value
    }

    fun decodeLong(key: String, defaultValue: Long = 0L): Long {
        val method = inner.javaClass.getMethod(
            "decodeLong",
            String::class.java,
            Long::class.javaPrimitiveType
        )
        val value = method.invoke(inner, key, defaultValue) as Long
        report("read", key, value)
        return value
    }

    fun decodeFloat(key: String, defaultValue: Float = 0f): Float {
        val method = inner.javaClass.getMethod(
            "decodeFloat",
            String::class.java,
            Float::class.javaPrimitiveType
        )
        val value = method.invoke(inner, key, defaultValue) as Float
        report("read", key, value)
        return value
    }

    fun decodeDouble(key: String, defaultValue: Double = 0.0): Double {
        val method = inner.javaClass.getMethod(
            "decodeDouble",
            String::class.java,
            Double::class.javaPrimitiveType
        )
        val value = method.invoke(inner, key, defaultValue) as Double
        report("read", key, value)
        return value
    }

    fun decodeBytes(key: String): ByteArray? {
        val method = inner.javaClass.getMethod("decodeBytes", String::class.java)
        val value = method.invoke(inner, key) as? ByteArray
        report("read", key, value?.size)
        return value
    }

    fun removeValueForKey(key: String) {
        val method = inner.javaClass.getMethod("removeValueForKey", String::class.java)
        method.invoke(inner, key)
        report("delete", key, null)
    }

    fun clearAll() {
        val method = inner.javaClass.getMethod("clearAll")
        method.invoke(inner)
        report("clear", "*", null)
    }

    private fun report(operation: String, key: String, value: Any?) {
        // Parity with the React Native fix: MMKV wrappers embed the
        // label in `storageType` so the desktop UI can keep two MMKV
        // instances (`user_session`, `cache`, ...) separate. Previously
        // the Android wrapper folded the label into the key, which
        // forced every wrapped MMKV to share the same `storageType`
        // bucket — breaking the "Filter by storage type" dropdown.
        DevConnect.sendStorage(
            storageType = "mmkv:$label",
            key = key,
            value = value,
            operation = operation,
        )
    }
}
