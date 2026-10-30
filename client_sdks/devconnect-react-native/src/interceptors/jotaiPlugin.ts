import { DevConnect } from '../client';

/**
 * Jotai atom observer that reports atom value changes to DevConnect.
 *
 * Usage with atomEffect (recommended):
 * ```typescript
 * import { atom } from 'jotai';
 * import { devConnectAtomEffect } from 'devconnect-react-native';
 *
 * const countAtom = atom(0);
 * countAtom.debugLabel = 'count';
 *
 * // Option 1: Observe a single atom
 * const countEffect = devConnectAtomEffect(countAtom);
 * // Use in a component: useAtom(countEffect);
 *
 * // Option 2: Observe via onMount
 * const trackedAtom = atom(0);
 * trackedAtom.onMount = devConnectAtomOnMount(trackedAtom, 'myAtom');
 * ```
 *
 * Usage with store.sub (outside React):
 * ```typescript
 * import { createStore } from 'jotai';
 * import { watchAtom } from 'devconnect-react-native';
 *
 * const store = createStore();
 * const countAtom = atom(0);
 *
 * watchAtom(store, countAtom, 'count');
 * ```
 */

/**
 * Creates a derived atom that observes another atom and reports changes.
 * Returns an atom you can use alongside the original in your component.
 *
 * @param targetAtom The Jotai atom to observe
 * @param label Optional label for the atom (defaults to atom.debugLabel or 'unknown')
 */
export function devConnectAtomEffect(
  targetAtom: any,
  label?: string,
): any {
  const atomLabel = label ?? targetAtom.debugLabel ?? 'unknown';
  let previousValue: any = undefined;
  let previousJson = '';
  let initialized = false;

  // Create a read-only derived atom that reports when the target atom changes
  const effectAtom = {
    read(get: (atom: any) => any) {
      const currentValue = get(targetAtom);

      if (!DevConnect.isListening()) {
        initialized = false;
        return currentValue;
      }

      try {
        if (!initialized) {
          initialized = true;
          previousJson = safeJson(currentValue);
          previousValue = JSON.parse(previousJson);
          DevConnect.reportStateChange({
            stateManager: 'jotai',
            action: `atom:${atomLabel} initialized`,
            nextState: { [atomLabel]: previousValue },
          });
        } else {
          const json = safeJson(currentValue);
          if (json !== previousJson) {
            const serializedCurrent = JSON.parse(json);
            DevConnect.reportStateChange({
              stateManager: 'jotai',
              action: `atom:${atomLabel} changed`,
              previousState: { [atomLabel]: previousValue },
              nextState: { [atomLabel]: serializedCurrent },
              diff: [{
                path: atomLabel,
                operation: 'replace',
                oldValue: previousValue,
                newValue: serializedCurrent,
              }],
            });
            previousValue = serializedCurrent;
            previousJson = json;
          }
        }
      } catch (_) {}

      return currentValue;
    },
    debugLabel: `devConnect:${atomLabel}`,
  };

  return effectAtom;
}

/**
 * Returns an onMount callback for a Jotai atom that reports changes.
 *
 * ```typescript
 * const myAtom = atom(0);
 * myAtom.onMount = devConnectAtomOnMount(myAtom, 'myAtom');
 * ```
 *
 * @param targetAtom The atom being mounted
 * @param label Label for this atom in DevConnect
 */
export function devConnectAtomOnMount(
  targetAtom: any,
  label: string,
): (setAtom: (update: any) => void) => (() => void) | void {
  return (setAtom: (update: any) => void) => {
    try {
      DevConnect.reportStateChange({
        stateManager: 'jotai',
        action: `atom:${label} mounted`,
        nextState: { status: 'mounted' },
      });
    } catch (_) {}

    return () => {
      try {
        DevConnect.reportStateChange({
          stateManager: 'jotai',
          action: `atom:${label} unmounted`,
          nextState: { status: 'unmounted' },
        });
      } catch (_) {}
    };
  };
}

/**
 * Watches a Jotai atom via a store's `sub` method (works outside React).
 *
 * ```typescript
 * import { createStore, atom } from 'jotai';
 * const store = createStore();
 * const countAtom = atom(0);
 * const unsub = watchAtom(store, countAtom, 'count');
 * ```
 *
 * @param store Jotai store (from createStore())
 * @param targetAtom The atom to watch
 * @param label Label for this atom in DevConnect
 * @returns Unsubscribe function
 */
export function watchAtom(
  store: any,
  targetAtom: any,
  label: string,
): () => void {
  let previousValue: any = safeSerialize(store.get(targetAtom));

  return store.sub(targetAtom, () => {
    if (!DevConnect.isListening()) {
      previousValue = undefined;
      return;
    }
    try {
      const currentValue = safeSerialize(store.get(targetAtom));
      DevConnect.reportStateChange({
        stateManager: 'jotai',
        action: `atom:${label} changed`,
        previousState: { [label]: previousValue },
        nextState: { [label]: currentValue },
        diff: [{
          path: label,
          operation: 'replace',
          oldValue: previousValue,
          newValue: currentValue,
        }],
      });
      previousValue = currentValue;
    } catch (_) {}
  });
}

function safeSerialize(value: any): any {
  return JSON.parse(safeJson(value));
}

/** JSON for `value`, or for an `_error` placeholder when JSON can't encode it. */
function safeJson(value: any): string {
  try {
    const json = JSON.stringify(value);
    if (json !== undefined) return json;
  } catch (_) {}
  return '{"_error":"Could not serialize value"}';
}
