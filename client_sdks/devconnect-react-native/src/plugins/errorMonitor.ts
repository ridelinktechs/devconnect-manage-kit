/**
 * DevConnect Error Monitor Plugin
 *
 * Captures and reports errors from:
 * - JavaScript errors (unhandled exceptions, promise rejections)
 * - Native crashes (iOS/Android)
 *
 * Adds:
 * - Stacktrace dedup keyed on the first 4 lines of the trace.
 * - Breadcrumb buffer (30 events) attached to each report.
 * - Public `addBreadcrumb(event)` and `reportCaughtError(err)`.
 */

import { NativeModules, Platform } from 'react-native';
import { DevConnect } from '../client';

function getPlatformTag(): 'android' | 'ios' | 'js' {
  return Platform.OS as 'android' | 'ios';
}

interface ErrorReport {
  platform: 'android' | 'ios' | 'js';
  severity: 'error' | 'fatal' | 'crash' | 'warning' | 'info';
  message: string;
  stackTrace?: string;
  source?: string;
  metadata?: Record<string, any>;
}

function sendError(opts: ErrorReport): void {
  const sig = sha256Short(signature(opts.message, opts.stackTrace));
  const isDup = trackDedup(sig);
  const breadcrumbs = breadcrumbsSnapshot();
  DevConnect.safeSend('client:error', {
    platform: opts.platform,
    severity: opts.severity,
    message: opts.message,
    ...(opts.stackTrace ? { stackTrace: opts.stackTrace } : {}),
    ...(opts.source ? { source: opts.source } : {}),
    signature: sig,
    deduped: isDup,
    metadata: {
      ...(opts.metadata ?? {}),
      breadcrumbs: breadcrumbs.join(' | '),
    },
  });
}

function getDeviceInfo(): string {
  try {
    const os = Platform.OS;
    const version = Platform.Version;
    const constants = (NativeModules.PlatformConstants || Platform.constants) as Record<string, any> | undefined;
    let info = `${os} ${version}`;
    if (os === 'android' && constants) {
      info += ` | ${constants.Model || ''} ${constants.Product || ''}`;
    } else if (os === 'ios' && constants) {
      info += ` | ${constants.systemName || ''} ${constants.osVersion || ''}`;
    }
    return info;
  } catch (_) {
    return `${Platform.OS} ${Platform.Version}`;
  }
}

// ---- Dedup window ----
const dedupSet = new Set<string>();
const dedupOrder: string[] = [];
const MAX_DEDUP = 50;
function trackDedup(sig: string): boolean {
  if (dedupSet.has(sig)) return true;
  dedupSet.add(sig);
  dedupOrder.push(sig);
  if (dedupOrder.length > MAX_DEDUP) {
    const evicted = dedupOrder.shift()!;
    dedupSet.delete(evicted);
  }
  return false;
}

// ---- Breadcrumbs ----
const breadcrumbQueue: string[] = [];
const MAX_BREADCRUMBS = 30;
export function addBreadcrumb(event: string): void {
  if (breadcrumbQueue.length >= MAX_BREADCRUMBS) breadcrumbQueue.shift();
  breadcrumbQueue.push(`${new Date().toISOString()} ${event}`);
}
function breadcrumbsSnapshot(): string[] {
  return [...breadcrumbQueue].reverse();
}

// ---- Stable signature: first 4 lines of stack, or first line of msg
function signature(message: string, stackTrace?: string): string {
  if (!stackTrace || !stackTrace.trim()) {
    return `m:${(message.split('\n')[0] ?? '').trim()}`;
  }
  const head = stackTrace
    .split('\n')
    .filter((l) => l.trim())
    .slice(0, 4)
    .join('|');
  return `s:${head}`;
}

// Tiny non-crypto hash. We only need a stable, low-collision id; SHA-1
// is overkill and crypto.subtle isn't available in RN by default.
function sha256Short(s: string): string {
  let h1 = 0xdeadbeef;
  let h2 = 0x41c6ce57;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    h1 = Math.imul(h1 ^ c, 2654435761);
    h2 = Math.imul(h2 ^ c, 1597334677);
  }
  const hi = ((h1 >>> 0) * 31 + (h2 >>> 0)) >>> 0;
  return hi.toString(16).padStart(8, '0');
}

// ---- JS Error Handler (ErrorUtils + unhandledrejection) ----

export function startJSErrorMonitor(): void {
  // Capture console.error that isn't our own to catch JS errors
  const originalError = console.error.bind(console);

  console.error = function (...args: any[]) {
    originalError(...args);

    // Skip internal DevConnect errors
    const msg = String(args[0] ?? '');
    if (msg.includes('DevConnect') || msg.includes('[DC_')) return;

    // Parse error from console.error arguments
    const errorMsg = args
      .map((a) => {
        if (a instanceof Error) return a.message;
        if (typeof a === 'string') return a;
        try {
          return JSON.stringify(a);
        } catch (_) {
          return String(a);
        }
      })
      .join(' ');

    const stackTrace = args.find((a) => a instanceof Error)?.stack;

    sendError({
      platform: 'js',
      severity: 'error',
      message: errorMsg,
      stackTrace,
      source: 'console.error',
    });
  };

  // Handle unhandled promise rejections (React Native / browser)
  if (typeof window !== 'undefined' && typeof window.addEventListener === 'function') {
    window.addEventListener('unhandledrejection', (event: Event) => {
      const reason = (event as unknown as { reason?: unknown }).reason;
      let message = String(
        reason instanceof Error
          ? reason.message
          : (reason as { message?: string })?.message ?? reason ?? 'Unhandled Promise Rejection',
      );
      let stackTrace = reason instanceof Error ? reason.stack : undefined;

      sendError({
        platform: 'js',
        severity: 'error',
        message,
        stackTrace,
        source: 'unhandledrejection',
        metadata: { type: 'unhandled_promise_rejection' },
      });
    });
  }

  // Global error handler for React Native (ErrorUtils is RN's global
  // error handler — wraps uncaught JS exceptions).
  try {
    const ErrorUtils = (global as any).ErrorUtils;
    if (ErrorUtils && typeof ErrorUtils.setGlobalHandler === 'function') {
      const originalHandler = ErrorUtils.getGlobalHandler?.() || ErrorUtils._globalHandler;
      ErrorUtils.setGlobalHandler((error: any, isFatal: boolean) => {
        const message = error?.message ?? String(error);
        const stackTrace = error?.stack;

        sendError({
          platform: 'js',
          severity: isFatal ? 'fatal' : 'error',
          message,
          stackTrace,
          source: 'ErrorUtils',
          metadata: { isFatal },
        });

        // Call original handler
        if (originalHandler) {
          try {
            originalHandler(error, isFatal);
          } catch (_) {}
        }
      });
    }
  } catch (_) {}
}

// ---- Native Error Handler ----

interface NativeErrorModule {
  setJSExceptionHandler: (
    handler: (error: string, isFatal: boolean) => void,
    forceAppQuit: boolean,
  ) => void;
  setNativeExceptionHandler: (handler: (exceptionString: string) => void) => void;
}

/**
 * Manually report a caught exception. Equivalent to Sentry's
 * `captureException`. Useful in `try { } catch (e) { reportCaughtError(e) }`
 * blocks where you want to surface non-fatal errors.
 */
export function reportCaughtError(err: unknown, source = 'manual'): void {
  if (err instanceof Error) {
    sendError({
      platform: 'js',
      severity: 'error',
      message: err.message,
      stackTrace: err.stack,
      source,
    });
  } else {
    sendError({
      platform: 'js',
      severity: 'error',
      message: String(err),
      source,
    });
  }
}

/**
 * Start error monitoring for the entire app. Call from your root
 * `index.js` BEFORE `AppRegistry.registerComponent` for native errors
 * to be captured from the first launch frame.
 */
export function startErrorMonitor(): void {
  startJSErrorMonitor();

  const os = Platform.OS;

  // Capture JS errors via native module if available
  try {
    const RNErrorHandler = NativeModules.RNErrorHandler as NativeErrorModule | undefined;
    if (RNErrorHandler?.setJSExceptionHandler) {
      RNErrorHandler.setJSExceptionHandler(
        (errorMessage: string, isFatal: boolean) => {
          sendError({
            platform: os as 'android' | 'ios',
            severity: isFatal ? 'fatal' : 'error',
            message: errorMessage,
            source: 'native.js_exception',
          });
        },
        false,
      );
    }
  } catch (_) {}

  // Capture native crashes
  try {
    const RNErrorHandler = NativeModules.RNErrorHandler as NativeErrorModule | undefined;
    if (RNErrorHandler?.setNativeExceptionHandler) {
      RNErrorHandler.setNativeExceptionHandler((exceptionString: string) => {
        sendError({
          platform: os as 'android' | 'ios',
          severity: 'crash',
          message: `Native crash: ${exceptionString.split('\n')[0]}`,
          stackTrace: exceptionString,
          source: 'native.crash',
          metadata: { originalException: exceptionString },
        });
      });
    }
  } catch (_) {}

  // Android-specific: catch Java exceptions via console.error patterns
  // iOS-specific: catch NSException patterns
  if (os === 'android') {
    const originalConsoleError = console.error.bind(console);
    console.error = function (...args: any[]) {
      const msg = String(args[0] ?? '');
      if (
        msg.includes('java.lang.') ||
        msg.includes('android.runtime') ||
        msg.includes('Native崩溃') ||
        msg.includes('FATAL EXCEPTION')
      ) {
        sendError({
          platform: 'android',
          severity: 'crash',
          message: msg.split('\n')[0],
          stackTrace: args.map(String).join('\n'),
          source: 'android.native',
        });
        return;
      }
      originalConsoleError(...args);
    };
  } else if (os === 'ios') {
    const originalConsoleError = console.error.bind(console);
    console.error = function (...args: any[]) {
      const msg = String(args[0] ?? '');
      if (
        msg.includes('*** NSException ***') ||
        msg.includes('__NSCRASH') ||
        (msg.includes('Thread <') && msg.includes('crashed'))
      ) {
        sendError({
          platform: 'ios',
          severity: 'crash',
          message: msg.split('\n')[0],
          stackTrace: args.map(String).join('\n'),
          source: 'ios.native',
        });
        return;
      }
      originalConsoleError(...args);
    };
  }
}
