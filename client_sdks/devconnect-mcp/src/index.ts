#!/usr/bin/env node
/**
 * DevConnect MCP server.
 *
 * Two transports:
 *   - stdio (default, used by `npx -y devconnect-manage` from Claude
 *     Code / Codex). The AI client spawns us as a child process and
 *     reads/writes JSON-RPC over stdin/stdout.
 *   - http (--http --port N, used by localhost install mode). We bind an
 *     HTTP server that speaks MCP Streamable HTTP at `/mcp` and forward
 *     each JSON-RPC message to the desktop app over WebSocket.
 *
 * In both modes the desktop app is the source of truth — it owns the
 * device control plane and our MCP tools just relay tool calls.
 */
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import express from 'express';
import { randomUUID } from 'node:crypto';
import { DesktopClient } from './desktop-client.js';
import { registerTools } from './tools.js';

const DESKTOP_HOST = process.env.DEVCONNECT_HOST ?? '127.0.0.1';
const DESKTOP_PORT = parseInt(process.env.DEVCONNECT_PORT ?? '9090', 10);

interface ParsedArgs {
  http: boolean;
  port: number;
}

function parseArgs(argv: string[]): ParsedArgs {
  let http = false;
  let port = parseInt(process.env.DEVCONNECT_HTTP_PORT ?? '5565', 10);

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--http') {
      http = true;
    } else if (a === '--port' && i + 1 < argv.length) {
      port = parseInt(argv[++i], 10);
    } else if (a.startsWith('--port=')) {
      port = parseInt(a.split('=')[1], 10);
    }
  }
  return { http, port };
}

async function runStdio(desktop: DesktopClient): Promise<void> {
  const server = new Server(
    { name: 'devconnect-manage', version: '0.1.0' },
    { capabilities: { tools: {} } }
  );
  registerTools(server, desktop);
  const transport = new StdioServerTransport();
  await server.connect(transport);
  process.stderr.write(
    `devconnect-manage ready (stdio) — desktop @ ${DESKTOP_HOST}:${DESKTOP_PORT}\n`
  );
}

async function runHttp(desktop: DesktopClient, port: number): Promise<void> {
  // One transport per session — Claude Code / Cursor each get their
  // own session ID and we keep a Map so concurrent clients don't trample
  // each other's initialization state.
  const transports = new Map<string, StreamableHTTPServerTransport>();
  const app = express();
  app.use(express.json({ limit: '4mb' }));

  const handleSessionRequest = async (
    req: express.Request,
    res: express.Response
  ) => {
    const sessionId = req.headers['mcp-session-id'] as string | undefined;
    if (!sessionId || !transports.has(sessionId)) {
      res.status(400).json({
        jsonrpc: '2.0',
        error: { code: -32000, message: 'Invalid or missing MCP session ID' },
        id: req.body?.id ?? null,
      });
      return;
    }
    const transport = transports.get(sessionId)!;
    await transport.handleRequest(req, res, req.body);
  };

  app.post('/mcp', async (req, res) => {
    const sessionId = req.headers['mcp-session-id'] as string | undefined;
    if (sessionId && transports.has(sessionId)) {
      return handleSessionRequest(req, res);
    }

    // New session — spin up a fresh MCP server + transport pair.
    const server = new Server(
      { name: 'devconnect-manage', version: '0.1.0' },
      { capabilities: { tools: {} } }
    );
    registerTools(server, desktop);

    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: () => randomUUID(),
      onsessioninitialized: (sid) => {
        transports.set(sid, transport);
      },
    });
    transport.onclose = () => {
      if (transport.sessionId) transports.delete(transport.sessionId);
    };
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  });

  app.get('/mcp', handleSessionRequest);
  app.delete('/mcp', handleSessionRequest);

  // Health probe so the desktop auto-spawner can confirm it's up.
  app.get('/health', (_req, res) => {
    res.json({ ok: true, desktop: { host: DESKTOP_HOST, port: DESKTOP_PORT } });
  });

  const httpServer = app.listen(port, '127.0.0.1', () => {
    process.stderr.write(
      `devconnect-manage ready (http) — http://127.0.0.1:${port}/mcp — desktop @ ${DESKTOP_HOST}:${DESKTOP_PORT}\n`
    );
  });

  const shutdown = async () => {
    for (const t of transports.values()) {
      try { await t.close(); } catch (_) {}
    }
    httpServer.close();
    try { await desktop.close(); } catch (_) {}
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

async function main() {
  const { http, port } = parseArgs(process.argv.slice(2));

  const desktop = new DesktopClient({ host: DESKTOP_HOST, port: DESKTOP_PORT });
  try {
    await desktop.connect();
  } catch (e) {
    process.stderr.write(
      `Failed to connect to DevConnect desktop at ws://${DESKTOP_HOST}:${DESKTOP_PORT}: ${e}\n` +
      `Make sure DevConnect is running and the MCP server is started (Settings → Server).\n`
    );
    process.exit(1);
  }

  if (http) {
    await runHttp(desktop, port);
  } else {
    await runStdio(desktop);
    const cleanup = async () => {
      try { await desktop.close(); } catch (_) {}
      process.exit(0);
    };
    process.on('SIGINT', cleanup);
    process.on('SIGTERM', cleanup);
  }
}

main().catch((e) => {
  process.stderr.write(`devconnect-manage fatal: ${e}\n`);
  process.exit(1);
});