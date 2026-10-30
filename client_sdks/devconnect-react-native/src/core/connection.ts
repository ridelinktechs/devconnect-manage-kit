import { Linking, NativeModules } from 'react-native';
import type { DevConnect } from '../client';
import { NativeWebSocket, autoDetectHost, saveHostCache } from './hostDiscovery';
import {
  _databaseSchemas,
  _handleStorageCommand,
  _layoutSnapshot,
  _reloadApp,
  _replayRequest,
  _runDatabaseQuery,
  sendHandshake,
} from './serverCommands';
import { generateId } from './util';

/**
 * Messages longer than this go out in chunks of this many characters, one
 * at a time: OkHttp (RN's WebSocket on Android) drops the connection once
 * 16 MB wait to be sent.
 */
const CHUNK_SIZE = 1_000_000;

/** A chunk the desktop hasn't acked after this long gives up the rest of its message. */
const CHUNK_ACK_TIMEOUT = 15_000;

export function connect(dc: DevConnect): void {
  // Close existing socket before creating a new one to prevent duplicates
  if (dc.ws) {
    try { dc.ws.onclose = null; dc.ws.onerror = null; dc.ws.close(); } catch (_) {}
    dc.ws = null;
  }
  _stopChunks(dc);
  try {
    dc.ws = new NativeWebSocket(`ws://${dc.config.host}:${dc.config.port}`);

    let handshakeSent = false;
    dc.ws.onopen = () => {
      dc.connected = true;
      dc.messageQueue.forEach((msg) => _wsSend(dc, msg));
      dc.messageQueue = [];
      _sendChunk(dc);
    };

    dc.ws.onmessage = (event: WebSocketMessageEvent) => {
      try {
        const msg = JSON.parse(event.data as string);
        if (msg.type === 'server:hello' && !handshakeSent) {
          handshakeSent = true;
          // Capture the server's stable machineId so the next launch can
          // verify the cached host really points at *this* desktop and not
          // some other device that happened to claim the same IP.
          const serverMachineId = msg.payload && msg.payload.machineId;
          if (typeof serverMachineId === 'string' && serverMachineId.length > 0) {
            saveHostCache(dc.config.host, serverMachineId).catch(() => {});
          }
          sendHandshake(dc);
        } else if (msg.type === 'server:chunk_ack') {
          if (msg.payload?.id === dc._bigId) _chunkAcked(dc);
        } else if (msg.type === 'server:redux:dispatch') {
          // Desktop dispatching a Redux action into the app
          if (dc._reduxStore && msg.payload?.action) {
            dc._reduxStore.dispatch(msg.payload.action);
          }
        } else if (msg.type === 'server:state:restore') {
          // Desktop restoring a state snapshot
          if (dc._stateRestoreHandler && msg.payload?.state) {
            dc._stateRestoreHandler(msg.payload.state);
          }
        } else if (msg.type === 'server:custom:command') {
          // Desktop sending a custom command
          const cmd = msg.payload?.command;
          const handler = dc._customCommandHandlers.get(cmd);
          if (handler) {
            // Async handlers resolve before the result goes back; a throw
            // (sync or async) is reported as the error.
            Promise.resolve()
              .then(() => handler(msg.payload?.args))
              .then(
                (result) => dc.send('client:custom:command_result', {
                  command: cmd,
                  result,
                }, msg.correlationId),
                (cmdErr: any) => dc.send('client:custom:command_result', {
                  command: cmd,
                  error: cmdErr?.message ?? String(cmdErr),
                }, msg.correlationId),
              );
          }
        } else if (typeof msg.type === 'string' && msg.type.startsWith('server:storage:')) {
          _handleStorageCommand(dc, msg.type, msg.payload ?? {});
        } else if (msg.type === 'server:layout:capture') {
          _layoutSnapshot(dc).then(
            (snapshot) => dc.send('client:layout:snapshot', snapshot, msg.correlationId),
            (e: any) => dc.send('client:layout:snapshot', {
              error: String(e?.message ?? e),
            }, msg.correlationId),
          );
        } else if (msg.type === 'server:open_url') {
          // Deep link: the app's own Linking handlers route it.
          if (msg.payload?.url) Linking.openURL(msg.payload.url).catch(() => {});
        } else if (msg.type === 'server:dev_menu') {
          NativeModules.DevMenu?.show?.();
        } else if (msg.type === 'server:network:throttle') {
          dc._throttle = {
            latencyMs: Math.max(0, Number(msg.payload?.latencyMs) || 0),
            offline: msg.payload?.offline === true,
          };
        } else if (msg.type === 'server:network:replay') {
          _replayRequest(msg.payload ?? {});
        } else if (msg.type === 'server:mock_rules_update') {
          // Always the full rule list (empty clears). Lazy require: that module imports this one.
          const rules = msg.payload?.rules;
          if (Array.isArray(rules)) require('../interceptors/network/mockServerInterceptor').setMockRules(rules);
        } else if (msg.type === 'server:database:request_schema') {
          _databaseSchemas(dc).then((databases) =>
            dc.send('client:database:schema', { databases }, msg.correlationId));
        } else if (msg.type === 'server:database:query') {
          _runDatabaseQuery(dc, msg.payload?.database, msg.payload?.sql ?? '').then((result) =>
            dc.send('client:database:query_result', result, msg.correlationId));
        } else if (msg.type === 'server:reload') {
          // Desktop asking the app to reload itself. Triggers Metro reload
          // via the official DevSettings module (the same path the RN
          // dev menu's "Reload" option uses). Works in dev builds only.
          _reloadApp(dc);
        } else if (msg.type === 'server:hot_restart') {
          // Heavier counterpart — same observable effect as `server:reload`
          // because RN has no lighter-vs-heavier distinction (DevSettings
          // already tears down the bridge and reloads the bundle from
          // Metro, which IS the "restart" semantic). We accept the message
          // anyway so mixed-platform setups (e.g. Flutter + RN) don't
          // silently drop the hot_restart signal on RN devices.
          _reloadApp(dc);
        }

        // Dispatch to any internal plugin subscribers. Handlers are
        // invoked in registration order; errors are swallowed so one
        // bad plugin can't break the receive loop.
        for (const handler of dc._serverMessageHandlers) {
          try { handler(msg); } catch (e) { /* eslint-disable-next-line no-console */ console.warn('[DevConnect] handler err', e); }
        }
      } catch (_) {}
    };

    dc.ws.onclose = () => { dc.connected = false; _stopChunks(dc); scheduleReconnect(dc); };
    dc.ws.onerror = () => { dc.connected = false; _stopChunks(dc); scheduleReconnect(dc); };
  } catch (_) {
    scheduleReconnect(dc);
  }
}

function scheduleReconnect(dc: DevConnect): void {
  if (!dc.config.enabled) return;
  if (dc.reconnectTimer) clearTimeout(dc.reconnectTimer);
  dc.reconnectTimer = setTimeout(async () => {
    if (!dc.connected) {
      if (dc.config.auto) {
        dc.config.host = await autoDetectHost(dc.config.port);
      }
      connect(dc);
    }
  }, 3000);
}

/** Sends [json] now, or in chunks by [_sendChunk] when it's longer than CHUNK_SIZE. */
export function _wsSend(dc: DevConnect, json: string): void {
  if (json.length <= CHUNK_SIZE) {
    dc.ws?.send(json);
    return;
  }
  dc._bigMessages.push(json);
  _sendChunk(dc);
}

/** Sends the next chunk of the first big message, unless one still waits for its ack. */
function _sendChunk(dc: DevConnect): void {
  const json = dc._bigMessages[0];
  if (json === undefined || dc._chunkTimer || !dc.connected || !dc.ws) return;
  if (dc._bigSent === 0) dc._bigId = generateId();
  let end = Math.min(dc._bigSent + CHUNK_SIZE, json.length);
  const code = json.charCodeAt(end - 1);
  // A surrogate pair stays in one chunk.
  if (end < json.length && code >= 0xd800 && code < 0xdc00) end--;
  const data = json.slice(dc._bigSent, end);
  dc._bigSent = end;
  dc._chunkTimer = setTimeout(() => _chunkAcked(dc, true), CHUNK_ACK_TIMEOUT);
  dc.ws.send(JSON.stringify({ type: 'client:chunk', payload: { id: dc._bigId, data, last: end === json.length } }));
}

/** The chunk in flight was acked, or [timedOut], which gives up its message: on to the next one. */
function _chunkAcked(dc: DevConnect, timedOut = false): void {
  if (dc._chunkTimer) clearTimeout(dc._chunkTimer);
  dc._chunkTimer = null;
  if (timedOut || dc._bigSent >= (dc._bigMessages[0]?.length ?? 0)) {
    dc._bigMessages.shift();
    dc._bigSent = 0;
  }
  _sendChunk(dc);
}

/** The socket is gone, and the desktop's half of a big message with it: it goes again whole. */
function _stopChunks(dc: DevConnect): void {
  if (dc._chunkTimer) clearTimeout(dc._chunkTimer);
  dc._chunkTimer = null;
  dc._bigSent = 0;
}
