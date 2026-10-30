import { DevConnect } from '../../client';

/**
 * XState machine inspector that reports state transitions to DevConnect.
 *
 * Usage with XState v4:
 * ```typescript
 * import { interpret } from 'xstate';
 * import { devConnectXStateInspector } from 'devconnect-react-native';
 *
 * const service = interpret(machine)
 *   .onTransition(devConnectXStateInspector('MyMachine'))
 *   .start();
 * ```
 *
 * Usage with XState v5 (actor.subscribe):
 * ```typescript
 * import { createActor } from 'xstate';
 * import { devConnectXStateInspector } from 'devconnect-react-native';
 *
 * const actor = createActor(machine);
 * actor.subscribe(devConnectXStateInspector('MyMachine'));
 * actor.start();
 * ```
 *
 * With full service tracking:
 * ```typescript
 * import { devConnectXStateService } from 'devconnect-react-native';
 *
 * // Automatically hooks into onTransition + reports start/stop
 * devConnectXStateService(service, 'MyMachine');
 * service.start();
 * ```
 */

/**
 * Returns a callback for onTransition / subscribe that reports state changes.
 *
 * @param machineLabel A label to identify this machine in DevConnect
 */
export function devConnectXStateInspector(
  machineLabel: string,
): (state: any, event?: any) => void {
  let previousStateValue: any = undefined;
  let previousContext: any = undefined;

  return (state: any, event?: any) => {
    try {
      // XState v4: state.value, state.context, state.event
      // XState v5: state.value, state.context, event passed separately or state.event
      const currentValue = resolveStateValue(state);
      if (!DevConnect.isListening()) {
        previousStateValue = currentValue;
        previousContext = undefined;
        return;
      }
      const currentContext = safeSerialize(state.context);
      const eventObj = event ?? state.event ?? state._event?.data;
      const eventType = resolveEventType(eventObj);

      const fromState = previousStateValue ?? '(initial)';
      const toState = currentValue;

      const diff: Array<Record<string, any>> = [];

      // Diff the state value
      if (previousStateValue !== undefined && JSON.stringify(previousStateValue) !== JSON.stringify(currentValue)) {
        diff.push({
          path: 'state',
          operation: 'replace',
          oldValue: previousStateValue,
          newValue: currentValue,
        });
      }

      // Diff the context
      if (previousContext !== undefined) {
        diff.push(...calculateContextDiff(previousContext, currentContext));
      }

      DevConnect.reportStateChange({
        stateManager: `xstate:${machineLabel}`,
        action: `${eventType} (${formatStateValue(fromState)} -> ${formatStateValue(toState)})`,
        previousState: {
          value: previousStateValue,
          context: previousContext,
        },
        nextState: {
          value: currentValue,
          context: currentContext,
        },
        diff,
      });

      previousStateValue = currentValue;
      previousContext = currentContext;
    } catch (_) {}
  };
}

/**
 * Attaches DevConnect inspection to an XState service (interpret() result).
 * Reports transitions, start, and stop events.
 *
 * @param service The XState interpreted service
 * @param machineLabel A label to identify this machine in DevConnect
 * @returns The service (for chaining)
 */
export function devConnectXStateService(
  service: any,
  machineLabel: string,
): any {
  const inspector = devConnectXStateInspector(machineLabel);

  // Attach transition listener
  if (typeof service.onTransition === 'function') {
    service.onTransition(inspector);
  } else if (typeof service.subscribe === 'function') {
    service.subscribe(inspector);
  }

  // Report start/stop
  if (typeof service.onStart === 'function') {
    service.onStart(() => {
      try {
        DevConnect.reportStateChange({
          stateManager: `xstate:${machineLabel}`,
          action: 'service started',
          nextState: {
            status: 'running',
            value: resolveStateValue(service.state ?? service.getSnapshot?.()),
          },
        });
      } catch (_) {}
    });
  }

  if (typeof service.onStop === 'function') {
    service.onStop(() => {
      try {
        DevConnect.reportStateChange({
          stateManager: `xstate:${machineLabel}`,
          action: 'service stopped',
          nextState: { status: 'stopped' },
        });
      } catch (_) {}
    });
  }

  return service;
}

function resolveStateValue(state: any): any {
  if (!state) return 'unknown';
  // state.value can be a string or nested object (parallel/hierarchical states)
  if (state.value !== undefined) return state.value;
  if (state.status !== undefined) return state.status;
  return 'unknown';
}

function resolveEventType(event: any): string {
  if (!event) return 'unknown';
  if (typeof event === 'string') return event;
  if (typeof event === 'object' && event.type) return String(event.type);
  return 'unknown';
}

function formatStateValue(value: any): string {
  if (typeof value === 'string') return value;
  if (typeof value === 'object' && value !== null) {
    try {
      // For nested state values like { active: 'editing' }
      return JSON.stringify(value);
    } catch (_) {
      return 'complex';
    }
  }
  return String(value);
}

function calculateContextDiff(
  prev: Record<string, any>,
  next: Record<string, any>,
  path = 'context',
  diffs: Array<Record<string, any>> = [],
  depth = 0,
): Array<Record<string, any>> {
  if (prev === next) return diffs;

  if (typeof prev !== 'object' || typeof next !== 'object' || prev === null || next === null) {
    diffs.push({
      path,
      operation: 'replace',
      oldValue: prev,
      newValue: next,
    });
    return diffs;
  }

  const allKeys = new Set([...Object.keys(prev), ...Object.keys(next)]);
  for (const key of allKeys) {
    if (diffs.length >= 50) break;
    const currentPath = `${path}.${key}`;
    const prevVal = prev[key];
    const nextVal = next[key];

    if (!(key in prev)) {
      diffs.push({ path: currentPath, operation: 'add', newValue: nextVal });
    } else if (!(key in next)) {
      diffs.push({ path: currentPath, operation: 'remove', oldValue: prevVal });
    } else if (prevVal !== nextVal) {
      if (
        typeof prevVal === 'object' &&
        typeof nextVal === 'object' &&
        prevVal !== null &&
        nextVal !== null &&
        depth < 10
      ) {
        calculateContextDiff(prevVal, nextVal, currentPath, diffs, depth + 1);
      } else {
        diffs.push({
          path: currentPath,
          operation: 'replace',
          oldValue: prevVal,
          newValue: nextVal,
        });
      }
    }
  }

  return diffs;
}

function safeSerialize(obj: any): Record<string, any> {
  try {
    return JSON.parse(JSON.stringify(obj));
  } catch (_) {
    return { _error: 'Could not serialize state' };
  }
}
