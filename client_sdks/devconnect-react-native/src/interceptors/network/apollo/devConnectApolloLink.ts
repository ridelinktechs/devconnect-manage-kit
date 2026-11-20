import { DevConnect, generateId } from '../../../client';

/**
 * Apollo Client `ApolloLink` middleware that emits `client:graphql_operation`
 * and `client:graphql_response` (paired by `operationId`) to the DevConnect
 * desktop on every operation.
 *
 * Wire it in front of the HTTP link:
 * ```typescript
 * import { ApolloClient, InMemoryCache, ApolloLink } from '@apollo/client';
 * import { devConnectApolloLink } from 'devconnect-manage-kit';
 *
 * const httpLink = new HttpLink({ uri: 'https://api.example.com/graphql' });
 * const client = new ApolloClient({
 *   cache: new InMemoryCache(),
 *   link: ApolloLink.from([devConnectApolloLink(), httpLink]),
 * });
 * ```
 */
export function devConnectApolloLink() {
  // Apollo's own Observable (zen-observable in v3, RxJS in v4): Apollo calls
  // `unsubscribe()` on what a link returns.
  const { ApolloLink, Observable } = getApollo();
  return new ApolloLink((operation: any, forward: any) => {
    const startTime = Date.now();
    const operationId = generateId();
    const operationName: string =
      operation.operationName ||
      (operation.query?.definitions?.find((d: any) => d.kind === 'OperationDefinition')?.name?.value ?? 'anonymous');
    const operationType: string =
      operation.query?.definitions?.find((d: any) => d.kind === 'OperationDefinition')?.operation ?? 'query';
    const variables = safeSerialize(operation.variables ?? {});

    try {
      DevConnect.safeSend('client:graphql_operation', {
        operationId,
        operation: operationName,
        type: operationType,
        variables,
      });
    } catch (_) {}

    const respond = (result: Record<string, any>) => {
      try {
        DevConnect.safeSend('client:graphql_response', {
          operationId,
          operation: operationName,
          type: operationType,
          latencyMs: Date.now() - startTime,
          ...result,
        });
      } catch (_) {}
    };

    if (!forward) {
      respond({ error: 'devConnectApolloLink: missing forward (downstream link)' });
      return new Observable((observer: any) => observer.error(new Error('No downstream link')));
    }

    return new Observable((observer: any) => {
      const subscription = forward(operation).subscribe({
        next: (response: any) => {
          try {
            const errors = response?.errors?.map((e: any) => ({
              message: e?.message ?? '',
              locations: e?.locations ?? [],
            })) ?? [];
            respond({
              cacheHit: Boolean(response?.extensions?.persistedQuery),
              // An errors-only response has no data.
              ...(response?.data !== undefined ? { data: safeSerialize(response.data) } : {}),
              ...(errors.length ? { errors } : {}),
            });
          } catch (_) {}
          observer.next(response);
        },
        error: (err: any) => {
          respond({ error: err?.message ?? String(err) });
          observer.error(err);
        },
        complete: () => observer.complete(),
      });
      return () => subscription?.unsubscribe?.();
    });
  });
}

function safeSerialize(value: any): any {
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (_) {
    return { _error: 'Could not serialize' };
  }
}

// Lazy-require `@apollo/client` so this file doesn't fail to load when it
// isn't installed — only calling devConnectApolloLink() needs it.
let _apollo: any;
function getApollo() {
  if (!_apollo) {
    try {
      _apollo = require('@apollo/client');
    } catch (_) {
      throw new Error(
        'devConnectApolloLink: @apollo/client is not installed. ' +
        'Either install it, or use DevConnectGraphQLHelper.reportOperation() directly.',
      );
    }
  }
  return _apollo;
}
