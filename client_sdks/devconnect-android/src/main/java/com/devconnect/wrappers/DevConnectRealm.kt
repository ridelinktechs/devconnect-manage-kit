package com.devconnect.wrappers

import com.devconnect.DevConnect

/**
 * Auto-reporting Realm wrapper for DevConnect.
 *
 * Since Realm is not a hard dependency, this uses duck-typing via reflection
 * to wrap Realm instances and auto-report operations.
 *
 * Usage:
 * ```kotlin
 * // After opening a Realm instance:
 * val realm = Realm.open(config)
 * val wrappedRealm = DevConnectRealm.wrap(realm)
 * // Use wrappedRealm instead of realm — all operations auto-reported
 * ```
 *
 * Or simpler — just wrap individual calls:
 * ```kotlin
 * DevConnectRealm.wrapWrite("User") {
 *     realm.writeBlocking { copyToRealm(user) }
 * }
 * DevConnectRealm.wrapQuery("User") {
 *     realm.query<User>().find()
 * }
 * ```
 */
class DevConnectRealm {

    companion object {
        // `@PublishedApi internal` exposes the constant to the inline
        // functions below without making it part of the public API.
        // A plain `private const val` would cause "Public-API inline
        // function cannot access non-public-API" compile errors; a
        // plain `internal const val` is not enough either — the inline
        // body is compiled into the caller where `internal` is hidden.
        @PublishedApi
        internal const val STORAGE_TYPE = "realm"

        /**
         * Wrap a write/create/update operation for auto-reporting.
         *
         * ```kotlin
         * DevConnectRealm.wrapWrite("User") {
         *     realm.writeBlocking { copyToRealm(user) }
         * }
         * ```
         */
        inline fun <T> wrapWrite(className: String, block: () -> T): T {
            val result = block()
            val data = when (result) {
                is Map<*, *> -> result.mapKeys { it.key.toString() }
                else -> mapOf("result" to (result?.toString() ?: "success"))
            }
            DevConnect.reportStorageOperation(
                storageType = STORAGE_TYPE,
                key = className,
                value = data,
                operation = "write"
            )
            return result
        }

        /**
         * Wrap a query/read operation for auto-reporting.
         *
         * ```kotlin
         * val users = DevConnectRealm.wrapQuery("User") {
         *     realm.query<User>().find().map { mapOf("name" to it.name) }
         * }
         * ```
         */
        inline fun <T> wrapQuery(className: String, block: () -> T): T {
            val result = block()
            val data = when (result) {
                is List<*> -> result
                is Map<*, *> -> result.mapKeys { it.key.toString() }
                else -> mapOf("result" to (result?.toString() ?: "empty"))
            }
            DevConnect.reportStorageOperation(
                storageType = STORAGE_TYPE,
                key = className,
                value = data,
                operation = "read"
            )
            return result
        }

        /**
         * Wrap a delete operation for auto-reporting.
         *
         * ```kotlin
         * DevConnectRealm.wrapDelete("User") {
         *     realm.writeBlocking { delete(user) }
         * }
         * ```
         */
        inline fun <T> wrapDelete(className: String, block: () -> T): T {
            val result = block()
            DevConnect.reportStorageOperation(
                storageType = STORAGE_TYPE,
                key = className,
                operation = "delete"
            )
            return result
        }

        /**
         * Wrap a transaction with count of affected objects.
         *
         * ```kotlin
         * DevConnectRealm.wrapTransaction("Migrate users", 42)
         * ```
         */
        fun wrapTransaction(description: String, affectedObjects: Int) {
            DevConnect.reportStorageOperation(
                storageType = STORAGE_TYPE,
                key = description,
                value = mapOf("affectedObjects" to affectedObjects),
                operation = "write"
            )
        }
    }
}
