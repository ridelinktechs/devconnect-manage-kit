import { DevConnect } from '../../client';

/**
 * MobX spy integration that auto-reports observable changes.
 *
 * Usage:
 * ```typescript
 * import { spy } from 'mobx';
 * import { setupMobxSpy } from 'devconnect-react-native';
 *
 * setupMobxSpy(spy);
 * ```
 *
 * This automatically captures:
 * - Action calls
 * - Observable updates
 * - Computed value changes
 * - Reaction triggers
 */
export function setupMobxSpy(spyFn: (listener: (event: any) => void) => any): any {
  return spyFn((event: any) => {
    try {
      switch (event.type) {
        case 'action':
          DevConnect.reportStateChange({
            stateManager: 'mobx',
            action: `@action ${event.name ?? 'anonymous'}`,
            nextState: {
              object: event.object?.constructor?.name ?? 'unknown',
              arguments: safeArgs(event.arguments),
            },
          });
          break;

        case 'update':
          if (event.observableKind === 'object') {
            DevConnect.reportStateChange({
              stateManager: 'mobx',
              action: `@observable ${event.debugObjectName ?? ''}.${event.name ?? 'unknown'} updated`,
              previousState: { [event.name ?? 'value']: event.oldValue },
              nextState: { [event.name ?? 'value']: event.newValue },
              diff: [
                {
                  path: event.name ?? 'value',
                  operation: 'replace',
                  oldValue: event.oldValue,
                  newValue: event.newValue,
                },
              ],
            });
          } else if (event.observableKind === 'array') {
            DevConnect.reportStateChange({
              stateManager: 'mobx',
              action: `@observable array ${event.debugObjectName ?? ''} updated`,
              nextState: { type: event.observableKind },
            });
          } else if (event.observableKind === 'map') {
            DevConnect.reportStateChange({
              stateManager: 'mobx',
              action: `@observable map ${event.debugObjectName ?? ''} updated`,
              previousState: { [event.name ?? 'key']: event.oldValue },
              nextState: { [event.name ?? 'key']: event.newValue },
            });
          }
          break;

        case 'add':
          DevConnect.reportStateChange({
            stateManager: 'mobx',
            action: `@observable ${event.debugObjectName ?? ''}.${event.name ?? 'unknown'} added`,
            nextState: { [event.name ?? 'value']: event.newValue },
            diff: [
              {
                path: event.name ?? 'value',
                operation: 'add',
                newValue: event.newValue,
              },
            ],
          });
          break;

        case 'delete':
          DevConnect.reportStateChange({
            stateManager: 'mobx',
            action: `@observable ${event.debugObjectName ?? ''}.${event.name ?? 'unknown'} deleted`,
            previousState: { [event.name ?? 'value']: event.oldValue },
            diff: [
              {
                path: event.name ?? 'value',
                operation: 'remove',
                oldValue: event.oldValue,
              },
            ],
          });
          break;
      }
    } catch (_) {}
  });
}

function safeArgs(args: any): any {
  if (!args) return undefined;
  try {
    return JSON.parse(JSON.stringify(Array.from(args)));
  } catch (_) {
    return undefined;
  }
}
