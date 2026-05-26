/**
 * DevConnect Error Monitor Plugin
 *
 * Captures and reports errors from:
 * - JavaScript errors (unhandled exceptions, promise rejections)
 * - Native crashes (iOS/Android)
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
  DevConnect.safeSend('client:error', {
    platform: opts.platform,
    severity: opts.severity,
    message: opts.message,
    ...(opts.stackTrace ? { stackTrace: opts.stackTrace } : {}),
    ...(opts.source ? { source: opts.source } : {}),
    ...(opts.metadata ? { metadata: opts.metadata } : {}),
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

// ---- JS Error Handler (ErrorUtils + unhandledrejection) ----

export function startJSErrorMonitor(): void {
  // Capture console.error that isn't our own to catch JS errors
  const originalError = console.error.bind(console);

  console.error = function(...args: any[]) {
    originalError(...args);

    // Skip internal DevConnect errors
    const msg = String(args[0] ?? '');
    if (msg.includes('DevConnect') || msg.includes('[DC_')) return;

    // Parse error from console.error arguments
    const errorMsg = args.map((a) => {
      if (a instanceof Error) return a.message;
      if (typeof a === 'string') return a;
      try { return JSON.stringify(a); } catch (_) { return String(a); }
    }).join(' ');

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
      let message = String(reason instanceof Error ? reason.message : (reason as { message?: string })?.message ?? reason ?? 'Unhandled Promise Rejection');
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

  // Global error handler for React Native
  // ErrorUtils is React Native's global error handler
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
          try { originalHandler(error, isFatal); } catch (_) {}
        }
      });
    }
  } catch (_) {}
}

// ---- Native Error Handler ----

interface NativeErrorModule {
  setJSExceptionHandler: (handler: (error: string, isFatal: boolean) => void, forceAppQuit: boolean) => void;
  setNativeExceptionHandler: (handler: (exceptionString: string) => void) => void;
}

// Start error monitoring for React Native
export function startErrorMonitor(): void {
  startJSErrorMonitor();

  const os = Platform.OS;

  // Capture JS errors via native module if available
  try {
    const RNErrorHandler = NativeModules.RNErrorHandler as NativeErrorModule | undefined;
    if (RNErrorHandler?.setJSExceptionHandler) {
      RNErrorHandler.setJSExceptionHandler((errorMessage: string, isFatal: boolean) => {
        sendError({
          platform: os as 'android' | 'ios',
          severity: isFatal ? 'fatal' : 'error',
          message: errorMessage,
          source: 'native.js_exception',
        });
      }, false);
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
    // Intercept common Android crash patterns
    const originalConsoleError = console.error.bind(console);
    console.error = function(...args: any[]) {
      const msg = String(args[0] ?? '');
      // Detect Android native errors
      if (msg.includes('java.lang.') || msg.includes('android.runtime') ||
          msg.includes('Native崩溃') || msg.includes('FATAL EXCEPTION')) {
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
    // Intercept iOS crash patterns
    const originalConsoleError = console.error.bind(console);
    console.error = function(...args: any[]) {
      const msg = String(args[0] ?? '');
      // Detect iOS native errors
      if (msg.includes('*** NSException ***') || msg.includes('__NSCRASH') ||
          msg.includes('Thread <') && msg.includes('crashed')) {
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