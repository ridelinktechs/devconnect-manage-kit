package com.devconnect.reporters

import com.devconnect.DevConnect

/**
 * MMKV storage reporter for DevConnect.
 *
 * Reports MMKV (https://github.com/Tencent/MMKV) read/write/delete operations
 * to the DevConnect desktop app for debugging.
 *
 * Usage:
 * ```kotlin
 * val reporter = DevConnect.mmkvReporter()
 *
 * // After writing to MMKV
 * mmkv.encode("token", "abc123")
 * reporter.reportWrite("token", "abc123")
 *
 * // After reading from MMKV
 * val token = mmkv.decodeString("token")
 * reporter.reportRead("token", token)
 *
 * // After deleting from MMKV
 * mmkv.removeValueForKey("token")
 * reporter.reportDelete("token")
 * ```
 *
 * Since MMKV is not a hard dependency, this reporter uses manual reporting.
 * Call the appropriate method after your MMKV operations.
 *
 * Pass the MMKV instance label (e.g. `"user_session"`, `"cache"`) to the
 * constructor so the desktop UI can keep separate MMKV buckets distinct.
 * The previous implementation always reported `storageType = "mmkv"`, which
 * forced every wrapped MMKV to share the same filter bucket — see the
 * matching fix in [com.devconnect.wrappers.DevConnectMMKV].
 */
class MmkvReporter(private val label: String = "default") {

    /**
     * Report an MMKV read operation.
     *
     * @param key The MMKV key name
     * @param value The value that was read
     */
    fun reportRead(key: String, value: Any?) {
        DevConnect.reportStorageOperation(
            storageType = "mmkv:$label",
            key = key,
            value = value,
            operation = "read"
        )
    }

    /**
     * Report an MMKV write operation.
     *
     * @param key The MMKV key name
     * @param value The value that was written
     */
    fun reportWrite(key: String, value: Any?) {
        DevConnect.reportStorageOperation(
            storageType = "mmkv:$label",
            key = key,
            value = value,
            operation = "write"
        )
    }

    /**
     * Report an MMKV key deletion.
     *
     * @param key The MMKV key that was removed
     */
    fun reportDelete(key: String) {
        DevConnect.reportStorageOperation(
            storageType = "mmkv:$label",
            key = key,
            operation = "delete"
        )
    }

    /**
     * Report an MMKV clear operation (all keys removed).
     */
    fun reportClear() {
        DevConnect.reportStorageOperation(
            storageType = "mmkv:$label",
            key = "*",
            operation = "clear"
        )
    }

    /**
     * Report a batch of MMKV writes at once.
     *
     * ```kotlin
     * reporter.reportBatchWrite(mapOf(
     *     "token" to "abc123",
     *     "userId" to 42,
     *     "isLoggedIn" to true
     * ))
     * ```
     *
     * @param entries Map of key-value pairs that were written
     */
    fun reportBatchWrite(entries: Map<String, Any?>) {
        for ((key, value) in entries) {
            reportWrite(key, value)
        }
    }

    /**
     * Report reading all keys from MMKV.
     *
     * ```kotlin
     * val allKeys = mmkv.allKeys()
     * reporter.reportAllKeys(allKeys?.toList() ?: emptyList())
     * ```
     *
     * @param keys List of all keys currently in MMKV
     */
    fun reportAllKeys(keys: List<String>) {
        DevConnect.reportStorageOperation(
            storageType = "mmkv:$label",
            key = "*",
            value = keys,
            operation = "read"
        )
    }

    /**
     * Report MMKV storage size info.
     *
     * ```kotlin
     * reporter.reportStorageInfo(
     *     totalSize = mmkv.totalSize(),
     *     actualSize = mmkv.actualSize()
     * )
     * ```
     *
     * @param totalSize Total allocated size in bytes
     * @param actualSize Actual used size in bytes
     */
    fun reportStorageInfo(totalSize: Long, actualSize: Long) {
        DevConnect.reportStorageOperation(
            storageType = "mmkv:$label",
            key = "__storage_info__",
            value = mapOf(
                "totalSize" to totalSize,
                "actualSize" to actualSize,
                "utilizationPercent" to if (totalSize > 0) (actualSize * 100 / totalSize) else 0
            ),
            operation = "read"
        )
    }
}
