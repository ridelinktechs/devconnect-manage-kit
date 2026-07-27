import WebSocket from 'ws';
import { randomUUID } from 'node:crypto';
import { McpCommand, McpCommandResult } from './types.js';

/**
 * Thin WebSocket client that talks to a running DevConnect desktop app on
 * localhost:9090 (default). The MCP server registers as a "control
 * client" — same handshake shape as a mobile device, just with a
 * different appName so the desktop knows we're a tool driver and not a
 * debuggable app.
 *
 * Wire protocol (mirror of lib/server/protocol/dc_message.dart):
 *   send: { id, type: 'client:handshake', deviceId, timestamp, payload }
 *   send: { id, type: 'mcp:command', deviceId: 'mcp', timestamp, payload,
 *           correlationId }
 *   recv: { id, type: 'mcp:response', deviceId: 'server', timestamp,
 *           payload, correlationId }
 */
export class DesktopClient {
  private ws: WebSocket | null = null;
  private host: string;
  private port: number;
  private deviceId: string;
  private readonly pending = new Map<
    string,
    { resolve: (v: McpCommandResult) => void; reject: (e: Error) => void; timer: NodeJS.Timeout }
  >();
  private connected = false;
  private connectPromise: Promise<void> | null = null;

  constructor(opts: { host?: string; port?: number } = {}) {
    this.host = opts.host ?? '127.0.0.1';
    this.port = opts.port ?? 9090;
    this.deviceId = `mcp-${randomUUID().slice(0, 8)}`;
  }

  async connect(): Promise<void> {
    if (this.connected) return;
    if (this.connectPromise) return this.connectPromise;

    this.connectPromise = new Promise<void>((resolve, reject) => {
      const url = `ws://${this.host}:${this.port}`;
      const ws = new WebSocket(url, { handshakeTimeout: 5000 });
      this.ws = ws;

      const fail = (e: Error) => {
        this.connectPromise = null;
        reject(e);
      };

      ws.once('open', () => {
        // Send handshake identifying us as the MCP control client.
        this.send({
          id: randomUUID(),
          type: 'client:handshake',
          deviceId: this.deviceId,
          timestamp: Date.now(),
          payload: {
            deviceInfo: {
              deviceId: this.deviceId,
              deviceName: 'DevConnect MCP',
              platform: 'desktop',
              osVersion: process.platform,
              appName: 'devconnect-manage',
              appVersion: '0.1.0',
            },
          },
        });
      });

      ws.on('message', (data) => {
        try {
          const msg = JSON.parse(data.toString());
          if (msg.type === 'server:handshake_ack') {
            this.connected = true;
            this.connectPromise = null;
            resolve();
            return;
          }
          if (msg.type === 'mcp:response' && msg.correlationId) {
            const p = this.pending.get(msg.correlationId);
            if (p) {
              this.pending.delete(msg.correlationId);
              clearTimeout(p.timer);
              p.resolve(msg.payload);
            }
          }
        } catch {
          // ignore malformed
        }
      });

      ws.on('error', fail);
      ws.on('close', () => {
        this.connected = false;
        this.ws = null;
        // Reject all pending
        for (const p of this.pending.values()) {
          clearTimeout(p.timer);
          p.reject(new Error('Desktop disconnected'));
        }
        this.pending.clear();
      });
    });

    return this.connectPromise;
  }

  /**
   * Send a command and await the response. Throws on timeout.
   */
  async sendCommand<T = unknown>(
    command: McpCommand,
    opts: { timeoutMs?: number } = {}
  ): Promise<McpCommandResult<T>> {
    if (!this.connected || !this.ws) {
      throw new Error('DesktopClient not connected');
    }
    const correlationId = randomUUID();
    const timeoutMs = opts.timeoutMs ?? 30_000;

    return new Promise<McpCommandResult<T>>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(correlationId);
        reject(new Error(`MCP command ${command.kind} timed out after ${timeoutMs}ms`));
      }, timeoutMs);

      this.pending.set(correlationId, {
        resolve: (v) => resolve(v as McpCommandResult<T>),
        reject,
        timer,
      });

      this.send({
        id: randomUUID(),
        type: 'mcp:command',
        deviceId: this.deviceId,
        timestamp: Date.now(),
        payload: command,
        correlationId,
      });
    });
  }

  private send(message: unknown): void {
    if (!this.ws) return;
    this.ws.send(JSON.stringify(message));
  }

  async close(): Promise<void> {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    this.connected = false;
  }
}