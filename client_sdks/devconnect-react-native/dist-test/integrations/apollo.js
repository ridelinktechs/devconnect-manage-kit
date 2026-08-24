"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupApolloDevConnect = setupApolloDevConnect;
const client_1 = require("../client");
/**
 * Build a snapshot payload from raw cache data, capped at `maxBytes`
 * UTF-8 bytes. Returns the payload plus a flag indicating whether the
 * data was truncated and the original UTF-8 byte size.
 */
function buildCappedSnapshot(raw, maxBytes) {
    const serialized = safeSerialize(raw);
    // Serialize to JSON, then re-encode as UTF-8 to measure bytes.
    const json = JSON.stringify(serialized);
    const bytes = new TextEncoder().encode(json);
    if (bytes.byteLength <= maxBytes) {
        return { state: serialized, truncated: false, originalSize: bytes.byteLength };
    }
    // Truncate at a valid code-point boundary, keeping `…` suffix budget.
    const suffix = '…';
    const budget = Math.max(0, maxBytes - new TextEncoder().encode(suffix).byteLength);
    // Walk byte array, stop when crossing budget at a code-point boundary.
    // TextEncoder always emits complete code points, so a simple prefix works.
    const decoder = new TextDecoder('utf-8', { fatal: false });
    let lo = 0;
    let hi = bytes.byteLength;
    while (lo < hi) {
        const mid = (lo + hi + 1) >>> 1;
        const slice = bytes.subarray(0, mid);
        const decoded = decoder.decode(slice);
        const reencoded = new TextEncoder().encode(decoded);
        if (reencoded.byteLength <= budget)
            lo = mid;
        else
            hi = mid - 1;
    }
    const truncatedBytes = bytes.subarray(0, lo);
    const truncatedStr = decoder.decode(truncatedBytes) + suffix;
    return {
        state: truncatedStr,
        truncated: true,
        originalSize: bytes.byteLength,
    };
}
function setupApolloDevConnect(apolloClient, options = {}) {
    if (!apolloClient || typeof apolloClient.cache?.watch !== 'function') {
        // Not a real Apollo client — silently no-op.
        return () => { };
    }
    const cache = apolloClient.cache;
    const snapshotIntervalMs = options.snapshotIntervalMs ?? 1000;
    const maxSnapshotBytes = options.maxSnapshotBytes ?? 1048576;
    const emitInitial = options.emitInitialSnapshot ?? true;
    // 1. Watch the entire cache for writes. Apollo's `cache.watch(opts)`
    // returns an Observable; we must subscribe to it to actually receive
    // diffs.
    let unsubscribe = null;
    try {
        const observable = cache.watch({});
        if (observable && typeof observable.subscribe === 'function') {
            const sub = observable.subscribe({
                next: (diff) => {
                    try {
                        const fieldName = diff?.fieldName ?? diff?.incompleteFromListLikeUpdate?.fieldName ?? '<root>';
                        const broadcast = typeof diff?.broadcast === 'function' ? diff.broadcast() : {};
                        const affected = diff?.affected ?? broadcast?.affected ?? {};
                        const queryKeys = Array.isArray(diff?.query?.selectionSet?.selections)
                            ? extractOperationName(diff.query.selectionSet.selections)
                            : null;
                        client_1.DevConnect.reportStateChange({
                            stateManager: 'Apollo',
                            action: `cache:${fieldName} updated`,
                            nextState: {
                                fieldName,
                                ...(queryKeys ? { operation: queryKeys } : {}),
                                result: safeSerialize(broadcast?.result ?? affected),
                            },
                        });
                    }
                    catch (_) { }
                },
                error: (_err) => { },
                complete: () => { },
            });
            // Subscription may be a function (Apollo 3) or { unsubscribe() }.
            if (typeof sub === 'function')
                unsubscribe = sub;
            else if (sub && typeof sub.unsubscribe === 'function')
                unsubscribe = () => sub.unsubscribe();
        }
    }
    catch (_) {
        // Watch not available — fall through silently.
    }
    // 2. Periodic `cache.extract()` snapshot.
    let intervalHandle = null;
    if (snapshotIntervalMs > 0) {
        intervalHandle = setInterval(() => {
            try {
                const raw = cache.extract?.();
                if (!raw)
                    return;
                const { state, truncated, originalSize } = buildCappedSnapshot(raw, maxSnapshotBytes);
                client_1.DevConnect.safeSend('client:state:snapshot', {
                    stateManager: 'Apollo',
                    state,
                    ...(truncated ? { metadata: { truncated: true, originalSize } } : {}),
                });
            }
            catch (_) { }
        }, snapshotIntervalMs);
    }
    // 3. Initial snapshot — also capped.
    if (emitInitial) {
        try {
            const raw = cache.extract?.();
            if (raw) {
                const { state, truncated, originalSize } = buildCappedSnapshot(raw, maxSnapshotBytes);
                client_1.DevConnect.safeSend('client:state:snapshot', {
                    stateManager: 'Apollo',
                    state,
                    ...(truncated ? { metadata: { truncated: true, originalSize } } : {}),
                });
            }
        }
        catch (_) { }
    }
    return () => {
        try {
            unsubscribe?.();
        }
        catch (_) { }
        if (intervalHandle) {
            clearInterval(intervalHandle);
            intervalHandle = null;
        }
    };
}
/** Try to find a `name` (`GetUser(...)`) inside Apollo's selection set. */
function extractOperationName(selections) {
    try {
        for (const sel of selections) {
            if (!sel)
                continue;
            if (sel.name && sel.name.value)
                return sel.name.value;
            if (sel.selectionSet?.selections) {
                const nested = extractOperationName(sel.selectionSet.selections);
                if (nested)
                    return nested;
            }
        }
    }
    catch (_) { }
    return null;
}
function safeSerialize(value) {
    try {
        return JSON.parse(JSON.stringify(value));
    }
    catch (_) {
        return { _error: 'Could not serialize value' };
    }
}
