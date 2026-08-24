"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.devConnectApolloLink = devConnectApolloLink;
const client_1 = require("../../client");
/**
 * Apollo Client `ApolloLink` middleware that emits `client:graphql_*`
 * events to the DevConnect desktop on every operation.
 *
 * Wire it in front of the HTTP link:
 * ```typescript
 * import { ApolloClient, InMemoryCache, ApolloLink } from '@apollo/client';
 * import { devConnectApolloLink } from 'devconnect-react-native';
 *
 * const httpLink = new HttpLink({ uri: 'https://api.example.com/graphql' });
 * const client = new ApolloClient({
 *   cache: new InMemoryCache(),
 *   link: ApolloLink.from([devConnectApolloLink(), httpLink]),
 * });
 * ```
 */
function devConnectApolloLink() {
    const ApolloLink = getApolloLinkClass();
    return new ApolloLink((operation, forward) => {
        const startTime = Date.now();
        const operationName = operation.operationName ||
            (operation.query?.definitions?.find((d) => d.kind === 'OperationDefinition')?.name?.value ?? 'anonymous');
        const operationType = operation.query?.definitions?.find((d) => d.kind === 'OperationDefinition')?.operation ?? 'query';
        const variables = safeSerialize(operation.variables ?? {});
        try {
            client_1.DevConnect.safeSend('client:graphql_operation', {
                operation: operationName,
                type: operationType,
                variables,
            });
        }
        catch (_) { }
        if (!forward) {
            try {
                client_1.DevConnect.safeSend('client:graphql_response', {
                    operation: operationName,
                    type: operationType,
                    error: 'devConnectApolloLink: missing forward (downstream link)',
                });
            }
            catch (_) { }
            return new Observable((sub) => sub.error(new Error('No downstream link')));
        }
        return new Observable((observer) => {
            const subscription = forward(operation).subscribe({
                next: (response) => {
                    try {
                        const latencyMs = Date.now() - startTime;
                        const errors = response?.errors?.map((e) => ({
                            message: e?.message ?? '',
                            locations: e?.locations ?? [],
                        })) ?? [];
                        const cacheHit = Boolean(response?.extensions?.persistedQuery);
                        client_1.DevConnect.safeSend('client:graphql_response', {
                            operation: operationName,
                            type: operationType,
                            latencyMs,
                            cacheHit,
                            data: safeSerialize(response?.data),
                            ...(errors.length ? { errors } : {}),
                        });
                    }
                    catch (_) { }
                    observer.next(response);
                },
                error: (err) => {
                    try {
                        client_1.DevConnect.safeSend('client:graphql_response', {
                            operation: operationName,
                            type: operationType,
                            error: err?.message ?? String(err),
                            stack: err?.stack,
                        });
                    }
                    catch (_) { }
                    observer.error(err);
                },
                complete: () => observer.complete(),
            });
            return () => subscription?.unsubscribe?.();
        });
    });
}
/**
 * Minimal Observable interface — we don't import `zen-observable-ts`
 * directly so this file works in any RN setup. Apollo Client itself
 * always provides a compatible Observable, so users normally don't see
 * this class — it's here for graceful fallback when `forward` is missing.
 */
class Observable {
    constructor(subscribe) {
        this._subscribe = subscribe;
    }
    subscribe(observer) {
        try {
            return this._subscribe(observer);
        }
        catch (_) {
            return { unsubscribe() { } };
        }
    }
}
function safeSerialize(value) {
    try {
        return JSON.parse(JSON.stringify(value));
    }
    catch (_) {
        return { _error: 'Could not serialize' };
    }
}
// Lazy-require ApolloLink so this file doesn't fail to load when
// `@apollo/client` isn't installed — the helper would still be callable
// from user code that imports it directly, just not actually patching Apollo.
let _ApolloLink;
function getApolloLinkClass() {
    if (!_ApolloLink) {
        try {
            _ApolloLink = require('@apollo/client').ApolloLink;
        }
        catch (_) {
            throw new Error('devConnectApolloLink: @apollo/client is not installed. ' +
                'Either install it, or use DevConnectGraphQLHelper.reportOperation() directly.');
        }
    }
    return _ApolloLink;
}
