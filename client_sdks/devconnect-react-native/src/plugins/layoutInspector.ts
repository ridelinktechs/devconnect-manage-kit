import { StyleSheet } from 'react-native';

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
  props: Record<string, string>;
  children: LayoutNode[];
}

// React fiber tags.
const FUNCTION = 0;
const CLASS = 1;
const HOST = 5;
const FORWARD_REF = 11;
const MEMO = 14;
const SIMPLE_MEMO = 15;

/** Past this many components the tree is cut short. */
const MAX_NODES = 1500;

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

/** A fiber's props as short strings; functions show as `ƒ`. */
function fiberProps(fiber: any): Record<string, string> {
  const out: Record<string, string> = {};
  const props = fiber.memoizedProps;
  if (!props || typeof props !== 'object') return out;
  for (const [key, value] of Object.entries(props)) {
    if (key === 'children' || Object.keys(out).length >= 12) continue;
    let text: string;
    try {
      if (typeof value === 'function') text = 'ƒ';
      else if (key === 'style') text = JSON.stringify(StyleSheet.flatten(value as any));
      else if (value !== null && typeof value === 'object') text = JSON.stringify(value);
      else text = String(value);
    } catch (_) {
      text = '[object]';
    }
    out[key] = text.length > 200 ? `${text.slice(0, 200)}…` : text;
  }
  return out;
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

/** On-screen box of a host fiber (old architecture or Fabric), or null. */
function measure(fiber: any): Promise<[number, number, number, number] | null> {
  const instance = fiber.stateNode?.canonical?.publicInstance ?? fiber.stateNode;
  if (typeof instance?.measureInWindow !== 'function') return Promise.resolve(null);
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(null), 1000);
    try {
      instance.measureInWindow((x: number, y: number, w: number, h: number) => {
        clearTimeout(timer);
        resolve([x, y, w, h]);
      });
    } catch (_) {
      clearTimeout(timer);
      resolve(null);
    }
  });
}

/**
 * The component tree with each component's on-screen bounds, read from the
 * fiber roots React DevTools' hook keeps (present in dev builds). A
 * component spans its children; private names (`_Foo`) are skipped.
 */
export async function captureComponentTree(): Promise<LayoutNode[]> {
  const hook = (globalThis as any).__REACT_DEVTOOLS_GLOBAL_HOOK__;
  if (!hook?.getFiberRoots || !hook.renderers) return [];
  let count = 0;

  const visit = async (fiber: any): Promise<LayoutNode[]> => {
    const pending: Array<Promise<LayoutNode[]>> = [];
    for (let child = fiber.child; child; child = child.sibling) pending.push(visit(child));
    const children = (await Promise.all(pending)).flat();
    const name = fiberName(fiber);
    if (!name || name.startsWith('_') || count >= MAX_NODES) return children;
    let box = fiber.tag === HOST ? await measure(fiber) : null;
    if (!box && children.length > 0) {
      const left = Math.min(...children.map((c) => c.x));
      const top = Math.min(...children.map((c) => c.y));
      const right = Math.max(...children.map((c) => c.x + c.w));
      const bottom = Math.max(...children.map((c) => c.y + c.h));
      box = [left, top, right - left, bottom - top];
    }
    if (!box) return children;
    count++;
    let style: any = null;
    try {
      if (fiber.tag === HOST) style = StyleSheet.flatten(fiber.memoizedProps?.style);
    } catch (_) {
      // Unreadable style: no box model for this view.
    }
    // A component drawing a single view shares that view's box model.
    const only = fiber.tag !== HOST && children.length === 1 ? children[0] : null;
    const padding = only ? only.padding : insets(style, 'padding');
    const margin = only ? only.margin : insets(style, 'margin');
    return [
      {
        id: String(count),
        name,
        x: box[0],
        y: box[1],
        w: box[2],
        h: box[3],
        ...(padding && { padding }),
        ...(margin && { margin }),
        props: fiberProps(fiber),
        children,
      },
    ];
  };

  const roots: LayoutNode[] = [];
  for (const rendererId of hook.renderers.keys()) {
    for (const root of hook.getFiberRoots(rendererId) ?? []) {
      roots.push(...(await visit(root.current)));
    }
  }
  return roots;
}
