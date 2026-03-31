import { DevConnect } from '../client';

/**
 * Tagged logger for DevConnect.
 *
 * ```typescript
 * const logger = new DevConnectLogger('AuthService');
 * logger.info('User logged in');
 * logger.error('Login failed', 'stack trace here');
 * ```
 */
export class DevConnectLogger {
  constructor(private tag?: string) {}

  debug(message: any, metadata?: Record<string, any>): void {
    DevConnect.debug(message, this.tag, metadata);
  }

  info(message: any, metadata?: Record<string, any>): void {
    DevConnect.log(message, this.tag, metadata);
  }

  warn(message: any, metadata?: Record<string, any>): void {
    DevConnect.warn(message, this.tag, metadata);
  }

  error(message: any, stackTrace?: string, metadata?: Record<string, any>): void {
    DevConnect.error(message, this.tag, stackTrace, metadata);
  }
}
