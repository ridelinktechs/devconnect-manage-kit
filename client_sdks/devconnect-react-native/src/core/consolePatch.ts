import type { DevConnect } from '../client';
import { safeString } from './util';

  // ---- Console interceptor ----

export function patchConsole(dc: DevConnect): void {
  const orig = {
    log: console.log.bind(console), warn: console.warn.bind(console),
    error: console.error.bind(console), debug: console.debug.bind(console),
    info: console.info.bind(console), trace: console.trace?.bind(console),
  };
  dc.originalConsole = orig;

  const systemPrefixes = [
    'Running "', 'BUNDLE ', 'nativeRequire ', 'Require cycle:', 'Remote debugger',
    'Debugger and device', 'Download the React DevTools', 'New NativeEventEmitter',
    'Sending `', 'ViewManager:', 'Unbalanced calls', 'componentWillReceiveProps',
    'componentWillMount', 'Each child in a list', 'VirtualizedList:', 'LogBox',
    'DevConnect', '[DevConnect]',
  ];

  const isEmptyObj = (args: any[]) => {
    if (args.length === 1 && typeof args[0] === 'object' && args[0] !== null) {
      try { if (Object.keys(args[0]).length === 0) return true; } catch (_) {}
    }
    return false;
  };

  const isInternalError = (args: any[]) => {
    const s = safeString(args[0] ?? '');
    return s.includes("'responseText'") || s.includes('responseType') || s.includes('DevConnect');
  };

  const isSys = (args: any[]) => args.length === 0 || isEmptyObj(args) || isInternalError(args) || systemPrefixes.some((p) => safeString(args[0]).startsWith(p));
  const toStr = (args: any[]) => args.map((a) => typeof a === 'string' ? a : (() => { try { return JSON.stringify(a, null, 2); } catch (_) { return safeString(a); } })()).join(' ');
  const toMeta = (args: any[]): Record<string, any> | undefined => {
    if (args.length === 1 && typeof args[0] === 'object' && args[0] !== null) { try { return JSON.parse(JSON.stringify(args[0])); } catch (_) {} }
    return undefined;
  };

  const patch = (method: string, level: string, origFn: Function) => (...args: any[]) => {
    origFn(...args);
    try {
      if (!isSys(args)) dc.send('client:log', { level, message: toStr(args), tag: `console.${method}`, ...(toMeta(args) ? { metadata: toMeta(args) } : {}) });
    } catch (_) {}
  };

  console.log = patch('log', 'debug', orig.log);
  console.debug = patch('debug', 'debug', orig.debug);
  console.info = patch('info', 'info', orig.info);
  console.warn = patch('warn', 'warn', orig.warn);
  console.error = patch('error', 'error', orig.error);
  if (console.trace) console.trace = patch('trace', 'debug', orig.trace!);
}
