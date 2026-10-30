import { StyleSheet, UIManager } from 'react-native';

/** One component on screen, as the desktop's Layout tab draws it. */
export interface LayoutNode {
  id: string;
  name: string;
  x: number;
  y: number;
  w: number;
  h: number;
  /** [left, top, right, bottom], when a host view sets any. */
  padding?: number[];
  margin?: number[];
  /** A native view (`RCTView`…) rather than a component. */
  host?: boolean;
  props: Record<string, string>;
  /** A class component's state, or a function component's useState values. */
  state?: Record<string, string>;
  children: LayoutNode[];
}

/** What a capture found: the roots, and whether MAX_NODES cut it short. */
export interface ComponentTree {
  roots: LayoutNode[];
  truncated: boolean;
}

// React fiber tags.
const FUNCTION = 0;
const CLASS = 1;
const HOST = 5;
const FORWARD_REF = 11;
const MEMO = 14;
const SIMPLE_MEMO = 15;

/** Past this many components the tree is cut short. */
const MAX_NODES = 4000;

function fiberName(fiber: any): string | null {
  const t = fiber.type;
  switch (fiber.tag) {
    case HOST:
      return typeof t === 'string' ? t : null;
    case FUNCTION:
    case CLASS:
    case SIMPLE_MEMO:
      return t?.displayName ?? t?.name ?? null;
    case FORWARD_REF:
      return t?.displayName ?? t?.render?.displayName ?? t?.render?.name ?? null;
    case MEMO:
      return t?.displayName ?? t?.type?.displayName ?? t?.type?.name ?? null;
    default:
      return null; // fragments, providers, text nodes…
  }
}

/**
 * [value] as short text (functions as `ƒ`, objects as JSON), or undefined
 * when there is nothing to show. Past [limit] it's cut with `…`.
 */
function short(value: any, limit = 300): string | undefined {
  let text: string | undefined;
  try {
    if (typeof value === 'function') text = 'ƒ';
    else if (value !== null && typeof value === 'object') text = JSON.stringify(value);
    else text = String(value);
  } catch (_) {
    text = '[object]'; // circular
  }
  if (text === undefined) return undefined;
  return text.length > limit ? `${text.slice(0, limit)}…` : text;
}

/** A fiber's props as short strings, `children` and `ref` left out. */
function fiberProps(fiber: any): Record<string, string> {
  const out: Record<string, string> = {};
  const props = fiber.memoizedProps;
  if (!props || typeof props !== 'object') return out;
  for (const [key, value] of Object.entries(props)) {
    if (key === 'children' || key === 'ref' || value === undefined) continue;
    if (Object.keys(out).length >= 12) break;
    // A style is shown whole, flattened: cut short it's no longer JSON.
    const text = key === 'style'
      ? short(StyleSheet.flatten(value as any), 2000)
      : short(value);
    if (text !== undefined) out[key] = text;
  }
  return out;
}

/**
 * A component's state as short strings: a class component's `state`, or a
 * function component's useState / useReducer values (`#1`, `#2`…, in
 * call order — hooks have no names at runtime).
 */
function fiberState(fiber: any): Record<string, string> | undefined {
  const out: Record<string, string> = {};
  if (fiber.tag === CLASS) {
    const state = fiber.stateNode?.state;
    if (state && typeof state === 'object') {
      for (const [key, value] of Object.entries(state).slice(0, 12)) {
        const text = short(value);
        if (text !== undefined) out[key] = text;
      }
    }
  } else if (fiber.tag === FUNCTION || fiber.tag === FORWARD_REF || fiber.tag === SIMPLE_MEMO) {
    let n = 0;
    for (let hook = fiber.memoizedState; hook && n < 12; hook = hook.next) {
      // Only state hooks have an update queue with a dispatcher.
      if (typeof hook.queue?.dispatch !== 'function') continue;
      out[`#${++n}`] = short(hook.memoizedState) ?? 'undefined';
    }
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

/** [left, top, right, bottom] of a style's numeric padding or margin, if any. */
function insets(style: any, kind: 'padding' | 'margin'): number[] | undefined {
  if (!style || typeof style !== 'object') return undefined;
  const pick = (...sides: string[]): number => {
    for (const side of sides) {
      const value = style[kind + side];
      if (typeof value === 'number') return value;
    }
    return 0;
  };
  const edges = [
    pick('Left', 'Start', 'Horizontal', ''),
    pick('Top', 'Vertical', ''),
    pick('Right', 'End', 'Horizontal', ''),
    pick('Bottom', 'Vertical', ''),
  ];
  return edges.some((v) => v !== 0) ? edges : undefined;
}

/**
 * [x, y, w, h] from a measureInWindow-style call, or null — including when
 * the callback comes back empty, which is what Android does for views it
 * flattened away (layout-only `View`s with no native counterpart).
 */
function measureWith(
  call: (cb: (...box: number[]) => void) => void,
): Promise<[number, number, number, number] | null> {
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(null), 2000);
    try {
      call((x, y, w, h) => {
        clearTimeout(timer);
        resolve([x, y, w, h].every(Number.isFinite) ? [x, y, w, h] : null);
      });
    } catch (_) {
      clearTimeout(timer);
      resolve(null);
    }
  });
}

/** On-screen box of a host fiber (old architecture or Fabric), or null. */
function measure(fiber: any): Promise<[number, number, number, number] | null> {
  const instance = fiber.stateNode?.canonical?.publicInstance ?? fiber.stateNode;
  if (typeof instance?.measureInWindow !== 'function') return Promise.resolve(null);
  return measureWith((cb) => instance.measureInWindow(cb));
}

/**
 * Where a React root's view sits in measureInWindow's coordinates; boxes are
 * reported relative to it, the screenshot's origin. Android subtracts the
 * status bar from measureInWindow even when the app draws under it
 * (translucent / edge-to-edge), which put every box one status bar too high.
 */
async function rootOrigin(root: any): Promise<[number, number]> {
  const info = root?.containerInfo;
  const tag = typeof info === 'number' ? info : info?.containerTag;
  const ui: any = UIManager;
  if (typeof tag !== 'number' || typeof ui?.measureInWindow !== 'function') return [0, 0];
  const box = await measureWith((cb) => ui.measureInWindow(tag, cb));
  return box ? [box[0], box[1]] : [0, 0];
}

/** A named fiber kept for the tree; `out` is what it adds to its parent. */
interface Kept {
  fiber: any;
  name: string;
  /** Index of its React root in the roots list. */
  root: number;
  box: [number, number, number, number] | null;
  kids: Kept[];
  out?: LayoutNode[];
}

/**
 * The component tree with each component's on-screen bounds, read from the
 * fiber roots React DevTools' hook keeps (present in dev builds). A
 * component spans its children; private names (`_Foo`) are skipped.
 *
 * No recursion: real fiber trees run hundreds of levels deep, and recursing
 * (worse, through async functions) overflows Hermes' stack.
 */
export async function captureComponentTree(): Promise<ComponentTree> {
  const hook = (globalThis as any).__REACT_DEVTOOLS_GLOBAL_HOOK__;
  if (!hook?.getFiberRoots || !hook.renderers) {
    throw new Error('React DevTools hook not found (dev builds only)');
  }

  // 1. Every named fiber, hung off its nearest named ancestor, in document
  //    order (children are pushed last-first so they come off in order).
  const top: Kept = { fiber: null, name: '', root: -1, box: null, kids: [] };
  const order: Kept[] = [];
  const roots: any[] = [];
  const stack: Array<[any, Kept, number]> = [];
  for (const rendererId of hook.renderers.keys()) {
    for (const root of hook.getFiberRoots(rendererId) ?? []) {
      if (!root?.current) continue;
      stack.unshift([root.current, top, roots.length]);
      roots.push(root);
    }
  }
  while (stack.length > 0 && order.length < MAX_NODES) {
    const [fiber, parent, rootIndex] = stack.pop()!;
    // A screen react-native-screens has put away (behind the current one):
    // not on screen, and in the way of picking what is.
    if (fiber.tag === HOST && fiber.type === 'RNSScreen' && fiber.memoizedProps?.activityState === 0) {
      continue;
    }
    const name = fiberName(fiber);
    let owner = parent;
    if (name && !name.startsWith('_')) {
      owner = { fiber, name, root: rootIndex, box: null, kids: [] };
      parent.kids.push(owner);
      order.push(owner);
    }
    const children: any[] = [];
    for (let child = fiber.child; child; child = child.sibling) children.push(child);
    for (let i = children.length - 1; i >= 0; i--) stack.push([children[i], owner, rootIndex]);
  }

  // 2. Every host view measured at once, relative to its root.
  const origins = await Promise.all(roots.map(rootOrigin));
  await Promise.all(
    order
      .filter((k) => k.fiber.tag === HOST)
      .map(async (k) => {
        const box = await measure(k.fiber);
        const [ox, oy] = origins[k.root];
        k.box = box && [box[0] - ox, box[1] - oy, box[2], box[3]];
      }),
  );

  // 3. Bottom-up (children come after their parent in `order`): a component
  //    spans its children; one without a box hands its children up.
  let count = 0;
  const outOf = (kids: Kept[]): LayoutNode[] => {
    const nodes: LayoutNode[] = [];
    for (const kid of kids) for (const node of kid.out ?? []) nodes.push(node);
    return nodes;
  };
  for (let i = order.length - 1; i >= 0; i--) {
    const k = order[i];
    const children = outOf(k.kids);
    const box = k.box ?? spanOf(children);
    if (!box) {
      k.out = children;
      continue;
    }
    let style: any = null;
    try {
      if (k.fiber.tag === HOST) style = StyleSheet.flatten(k.fiber.memoizedProps?.style);
    } catch (_) {
      // Unreadable style: no box model for this view.
    }
    // A component drawing a single view shares that view's box model.
    const only = k.fiber.tag !== HOST && children.length === 1 ? children[0] : null;
    const padding = only ? only.padding : insets(style, 'padding');
    const margin = only ? only.margin : insets(style, 'margin');
    const state = fiberState(k.fiber);
    k.out = [
      {
        id: String(++count),
        name: k.name,
        x: box[0],
        y: box[1],
        w: box[2],
        h: box[3],
        ...(padding && { padding }),
        ...(margin && { margin }),
        ...(k.fiber.tag === HOST && { host: true }),
        props: fiberProps(k.fiber),
        ...(state && { state }),
        children,
      },
    ];
  }
  return { roots: outOf(top.kids), truncated: stack.length > 0 };
}

/** The box around [nodes], or null when there are none. */
function spanOf(nodes: LayoutNode[]): [number, number, number, number] | null {
  if (nodes.length === 0) return null;
  let left = Infinity;
  let top = Infinity;
  let right = -Infinity;
  let bottom = -Infinity;
  for (const n of nodes) {
    left = Math.min(left, n.x);
    top = Math.min(top, n.y);
    right = Math.max(right, n.x + n.w);
    bottom = Math.max(bottom, n.y + n.h);
  }
  return [left, top, right - left, bottom - top];
}
