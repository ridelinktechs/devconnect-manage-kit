import { DevConnect, safeString } from '../client';

/** A logged value as text: JSON, or `safeString` when JSON can't encode it (cycle, BigInt). */
function argText(a: any): string {
  if (typeof a === 'string') return a;
  try { return JSON.stringify(a); } catch (_) { return safeString(a); }
}

/**
 * Integration for `react-native-logs` package.
 *
 * ```typescript
 * import { logger, consoleTransport } from 'react-native-logs';
 * import { devConnectTransport } from 'devconnect-react-native';
 *
 * const log = logger.createLogger({
 *   transport: [consoleTransport, devConnectTransport],
 * });
 *
 * log.info('Hello');  // -> appears in DevConnect!
 * log.warn('Uh oh');
 * log.error('Crash');
 * ```
 */
export const devConnectTransport = (props: {
  msg: any;
  rawMsg: any;
  level: { severity: number; text: string };
  extension?: string | null;
  options?: any;
}) => {
  const levelMap: Record<string, string> = {
    debug: 'debug',
    info: 'info',
    warn: 'warn',
    error: 'error',
    trace: 'debug',
  };

  const level = levelMap[props.level.text.toLowerCase()] ?? 'debug';
  const tag = props.extension ? `rn-logs:${props.extension}` : 'react-native-logs';

  const message = argText(props.msg);

  try {
    DevConnect.safeSend('client:log', {
      level,
      message,
      tag,
      ...(typeof props.rawMsg === 'object' ? { metadata: props.rawMsg } : {}),
    });
  } catch (_) {}
};

/**
 * Integration for `loglevel` package.
 *
 * ```typescript
 * import log from 'loglevel';
 * import { patchLoglevel } from 'devconnect-react-native';
 *
 * patchLoglevel(log);
 *
 * log.info('Hello');  // -> appears in DevConnect!
 * ```
 */
export function patchLoglevel(loglevelInstance: any): void {
  const originalFactory = loglevelInstance.methodFactory;

  loglevelInstance.methodFactory = function (
    methodName: string,
    logLevel: number,
    loggerName: string
  ) {
    const rawMethod = originalFactory(methodName, logLevel, loggerName);

    return function (...args: any[]) {
      const message = args.map(argText).join(' ');

      const levelMap: Record<string, string> = {
        trace: 'debug',
        debug: 'debug',
        info: 'info',
        warn: 'warn',
        error: 'error',
      };

      try {
        DevConnect.safeSend('client:log', {
          level: levelMap[methodName] ?? 'debug',
          message,
          tag: loggerName ? `loglevel:${loggerName}` : 'loglevel',
        });
      } catch (_) {}

      rawMethod(...args);
    };
  };

  // Rebuild methods with the new factory
  loglevelInstance.setLevel(loglevelInstance.getLevel());
}

/**
 * Integration for `winston` (used in some RN projects via polyfills).
 *
 * ```typescript
 * import winston from 'winston';
 * import { winstonDevConnectTransport } from 'devconnect-react-native';
 *
 * const logger = winston.createLogger({
 *   transports: [winstonDevConnectTransport],
 * });
 * ```
 */
export const winstonDevConnectTransport = {
  log: (info: any, callback: () => void) => {
    try {
      const level = info.level ?? 'info';
      const message = info.message ?? JSON.stringify(info);

      const levelMap: Record<string, string> = {
        silly: 'debug',
        debug: 'debug',
        verbose: 'debug',
        info: 'info',
        warn: 'warn',
        error: 'error',
      };

      DevConnect.safeSend('client:log', {
        level: levelMap[level] ?? 'debug',
        message,
        tag: 'winston',
        ...(info.metadata ? { metadata: info.metadata } : {}),
      });
    } catch (_) {}

    if (callback) callback();
  },
};

/**
 * Integration for `pino` logger.
 *
 * ```typescript
 * import pino from 'pino';
 * import { pinoDevConnectTransport } from 'devconnect-react-native';
 *
 * const logger = pino({ }, pinoDevConnectTransport());
 * logger.info('Hello');
 * ```
 */
export function pinoDevConnectTransport() {
  return {
    write(msg: string) {
      try {
        const parsed = JSON.parse(msg);
        const pinoLevels: Record<number, string> = {
          10: 'debug', // trace
          20: 'debug', // debug
          30: 'info',  // info
          40: 'warn',  // warn
          50: 'error', // error
          60: 'error', // fatal
        };

        DevConnect.safeSend('client:log', {
          level: pinoLevels[parsed.level] ?? 'debug',
          message: parsed.msg ?? msg,
          tag: parsed.name ? `pino:${parsed.name}` : 'pino',
          metadata: parsed,
        });
      } catch (_) {
        DevConnect.safeSend('client:log', {
          level: 'debug',
          message: msg,
          tag: 'pino',
        });
      }
    },
  };
}

/**
 * Integration for `bunyan` logger.
 *
 * ```typescript
 * import bunyan from 'bunyan';
 * import { bunyanDevConnectStream } from 'devconnect-react-native';
 *
 * const logger = bunyan.createLogger({
 *   name: 'myapp',
 *   streams: [{ stream: bunyanDevConnectStream() }],
 * });
 * ```
 */
export function bunyanDevConnectStream() {
  return {
    write(record: any) {
      try {
        const parsed = typeof record === 'string' ? JSON.parse(record) : record;
        const bunyanLevels: Record<number, string> = {
          10: 'debug', // trace
          20: 'debug', // debug
          30: 'info',  // info
          40: 'warn',  // warn
          50: 'error', // error
          60: 'error', // fatal
        };

        DevConnect.safeSend('client:log', {
          level: bunyanLevels[parsed.level] ?? 'debug',
          message: parsed.msg ?? JSON.stringify(parsed),
          tag: parsed.name ? `bunyan:${parsed.name}` : 'bunyan',
          metadata: parsed,
        });
      } catch (_) {}
    },
  };
}

/**
 * Generic wrapper for ANY logging library.
 *
 * ```typescript
 * import { wrapLogger } from 'devconnect-react-native';
 *
 * const myLogger = { log: ..., warn: ..., error: ... };
 * const wrapped = wrapLogger(myLogger, 'myLogger');
 * wrapped.log('Hello'); // -> goes to both original logger AND DevConnect
 * ```
 */
export function wrapLogger(
  loggerInstance: Record<string, (...args: any[]) => void>,
  name = 'custom'
): Record<string, (...args: any[]) => void> {
  const methodLevelMap: Record<string, string> = {
    trace: 'debug',
    debug: 'debug',
    verbose: 'debug',
    log: 'debug',
    info: 'info',
    warn: 'warn',
    warning: 'warn',
    error: 'error',
    fatal: 'error',
    critical: 'error',
  };

  const wrapped: Record<string, (...args: any[]) => void> = {};

  for (const [method, fn] of Object.entries(loggerInstance)) {
    if (typeof fn === 'function' && method in methodLevelMap) {
      wrapped[method] = (...args: any[]) => {
        // Call original
        fn.call(loggerInstance, ...args);

        // Send to DevConnect
        const message = args.map(argText).join(' ');

        try {
          DevConnect.safeSend('client:log', {
            level: methodLevelMap[method] ?? 'debug',
            message,
            tag: name,
          });
        } catch (_) {}
      };
    } else {
      wrapped[method] = fn;
    }
  }

  return wrapped;
}
