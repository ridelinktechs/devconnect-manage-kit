"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setMockRules = setMockRules;
exports.installMockServerInterceptor = installMockServerInterceptor;
exports.findMockMatch = findMockMatch;
exports.buildMockResponse = buildMockResponse;
const client_1 = require("../client");
/** Marker used to cache invalid-regex results so we don't re-throw on every call. */
const INVALID_URL_REGEX = null;
class MockRuleStore {
    constructor() {
        this.rules = [];
        this.compiledUrlRegexes = new Map();
        this.compiledHeaderRegexes = new Map();
    }
    setRules(rules) {
        this.rules = rules.filter(r => r.enabled);
        this.compiledUrlRegexes.clear();
        this.compiledHeaderRegexes.clear();
    }
    /**
     * Find the first matching rule for a request. Returns null when no
     * match — caller falls through to the real network.
     *
     * `options.currentDeviceId` is checked against `rule.scope.deviceIds` when
     * present; if the device doesn't match, the rule is skipped. Expired
     * rules (per `rule.expiresAt`) are skipped.
     */
    findMatch(method, url, headers, options = {}) {
        const now = Date.now();
        for (const rule of this.rules) {
            if (!rule.enabled)
                continue;
            // Expiration check — skip rules past their TTL.
            if (rule.expiresAt) {
                const ts = Date.parse(rule.expiresAt);
                if (Number.isFinite(ts) && ts <= now)
                    continue;
            }
            // Device-scope check — empty list = applies to all devices.
            if (rule.scope?.deviceIds && rule.scope.deviceIds.length > 0) {
                if (!options.currentDeviceId)
                    continue;
                if (!rule.scope.deviceIds.includes(options.currentDeviceId))
                    continue;
            }
            if (rule.match.method.toUpperCase() !== method.toUpperCase())
                continue;
            // URL regex (cached, including negative results).
            let regex = this.compiledUrlRegexes.get(rule.id);
            if (regex === undefined) {
                try {
                    regex = new RegExp(rule.match.url);
                }
                catch (_) {
                    regex = INVALID_URL_REGEX;
                }
                this.compiledUrlRegexes.set(rule.id, regex);
            }
            if (!regex)
                continue;
            if (!regex.test(url))
                continue;
            // Optional header constraints — normalize request keys to lowercase
            // so rule matchers (whose keys may be any case) line up reliably.
            if (rule.match.headers) {
                const reqHeaders = {};
                for (const [k, v] of Object.entries(headers ?? {})) {
                    reqHeaders[k.toLowerCase()] = v;
                }
                let perRule = this.compiledHeaderRegexes.get(rule.id);
                if (!perRule) {
                    perRule = new Map();
                    this.compiledHeaderRegexes.set(rule.id, perRule);
                }
                let ok = true;
                for (const [k, v] of Object.entries(rule.match.headers)) {
                    let re = perRule.get(k);
                    if (!re) {
                        try {
                            re = new RegExp(v);
                        }
                        catch (_) {
                            re = INVALID_URL_REGEX;
                        }
                        perRule.set(k, re);
                    }
                    if (!re) {
                        ok = false;
                        break;
                    }
                    const actual = reqHeaders[k.toLowerCase()] ?? '';
                    if (!re.test(actual)) {
                        ok = false;
                        break;
                    }
                }
                if (!ok)
                    continue;
            }
            return rule;
        }
        return null;
    }
}
const store = new MockRuleStore();
/**
 * Replace the entire rule list. Called from `server:mock_rules_update`
 * handlers and from `setupMockServerInterceptor`'s initial sync.
 */
function setMockRules(rules) {
    store.setRules(rules);
}
let serverHandlerInstalled = false;
let installedHandlerRef = null;
/**
 * Wire the mock server interceptor to the DevConnect message loop so
 * that `server:mock_rules_update` automatically updates the rule list.
 * Idempotent — repeated calls are no-ops.
 */
function installMockServerInterceptor() {
    if (serverHandlerInstalled)
        return;
    try {
        const client = require('../client').DevConnect;
        const prev = typeof client.onMessage === 'function' ? client.onMessage.bind(client) : null;
        installedHandlerRef = (msg) => {
            try {
                if (msg?.type === 'server:mock_rules_update') {
                    const rules = msg?.payload?.rules ?? msg?.rules;
                    if (Array.isArray(rules))
                        setMockRules(rules);
                }
            }
            catch (_) { }
            if (prev)
                prev(msg);
        };
        client.onMessage = installedHandlerRef;
        // Only mark installed after the handler was successfully assigned.
        serverHandlerInstalled = true;
    }
    catch (_) { }
}
/**
 * Look up a matching rule for a request, given what the fetch
 * interceptor knows about it.
 */
function findMockMatch(method, url, headers, options = {}) {
    return store.findMatch(method, url, headers, options);
}
/**
 * Build a synthetic `Response` from a rule. Mirrors the spec:
 * "short-circuit with the mock response (delay → emit response with
 * synthetic latency)".
 */
async function buildMockResponse(rule, requestId) {
    if (rule.response.delayMs && rule.response.delayMs > 0) {
        await new Promise(resolve => setTimeout(resolve, rule.response.delayMs));
    }
    // Emit `client:mocked_request` so the user knows the response was synthetic.
    client_1.DevConnect.safeSend('client:mocked_request', {
        ruleId: rule.id,
        status: rule.response.status,
        requestId,
        timestamp: Date.now(),
    });
    const headers = new Headers();
    // Copy headers but exclude `statusText` (it's not a real header — it
    // belongs on the Response init object).
    for (const [k, v] of Object.entries(rule.response.headers ?? {})) {
        if (k.toLowerCase() === 'statustext')
            continue;
        headers.set(k, v);
    }
    return new Response(rule.response.body, {
        status: rule.response.status,
        statusText: 'OK',
        headers,
    });
}
