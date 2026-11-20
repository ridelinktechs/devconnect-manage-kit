import type { DevConnect } from '../client';
import { generateId } from '../core/util';
import { MAX_IMAGE_SIZE, capBody, dataUrl, parseBody } from './bodies';
import { classifyUrl } from './requestInfo';

  // ---- XHR interceptor ----

export function patchXHR(dc: DevConnect): void {
  const OriginalXHR = (globalThis as any).XMLHttpRequest;
  dc.originalXHR = OriginalXHR;

  function PatchedXHR(this: any) {
    const xhr = new OriginalXHR();
    const isFetchXhr = dc.fetchStackCount > 0;
    const requestId = generateId();
    let method = 'GET', url = '', startTime = 0;
    const reqHeaders: Record<string, string> = {};
    let requestBody: any;

    const origOpen = xhr.open.bind(xhr);
    let openedOffline = false;
    xhr.open = (m: string, u: string | URL, ...args: any[]) => {
      method = m.toUpperCase();
      // Coerce URL/Request to a string in case a polyfill accepts them
      url = typeof u === 'string' ? u : (u as any)?.url ?? String(u);
      // Offline throttle: refused right away, like a dead network.
      openedOffline = dc._throttle.offline;
      return origOpen(m, openedOffline ? 'http://127.0.0.1:9' : u as string, ...args);
    };

    const origSetHeader = xhr.setRequestHeader.bind(xhr);
    xhr.setRequestHeader = (n: string, v: string) => { reqHeaders[n] = v; return origSetHeader(n, v); };

    const origSend = xhr.send.bind(xhr);
    xhr.send = (body?: any) => {
      startTime = Date.now();
      if (body) {
        if (body instanceof FormData) {
          const fields: Record<string, any> = {};
          const files: any[] = [];
          for (const [key, value] of (body as any).entries()) {
            if (value instanceof Blob || (value && typeof value === 'object' && value.uri)) {
              files.push({ key, filename: value.name ?? value.filename ?? 'unknown', type: value.type ?? value.contentType ?? 'unknown', size: value.size ?? value.length });
            } else {
              fields[key] = value;
            }
          }
          requestBody = { ...fields, ...(files.length ? { _files: files, _contentType: 'multipart/form-data' } : {}) };
        } else {
          const data = capBody(body);
          requestBody = typeof data === 'string' ? parseBody(data) : data;
        }
      }
      // Skip the start report if the fetch interceptor already
      // covers this call (see handleLoadEnd for the matching skip).
      const xhrKey = `${method}\0${url}`;
      const isFetchRequest = isFetchXhr || (dc.fetchInFlight.get(xhrKey) ?? 0) > 0;
      if (!isFetchRequest) {
        dc.send('client:network:request_start', { requestId, method, url, startTime, requestHeaders: reqHeaders, requestBody, source: classifyUrl(url), via: 'xhr' });
      }
      if (openedOffline) return origSend();
      const { latencyMs } = dc._throttle;
      if (latencyMs > 0) {
        // shortcut: a fetch() aborted during the delay stays pending (RN fires no abort event for an unsent XHR).
        setTimeout(() => { try { if (xhr.readyState === xhr.OPENED) origSend(body); } catch (_) {} }, latencyMs);
        return;
      }
      return origSend(body);
    };

    const handleLoadEnd = async () => {
      xhr.removeEventListener('loadend', handleLoadEnd);
      // Skip if the fetch interceptor already reported this call —
      // RN 0.85's fetch goes through XHR internally, so without this
      // every fetch would double-fire (once via fetch path, once via
      // XHR path) with different requestIds, which the server
      // cannot merge downstream.
      const xhrKey = `${method}\0${url}`;
      const isFetchRequest = isFetchXhr || (dc.fetchInFlight.get(xhrKey) ?? 0) > 0;
      if (isFetchRequest) {
        return;
      }
      const resHeaders: Record<string, string> = {};
      try { xhr.getAllResponseHeaders().split('\r\n').forEach((l: string) => { const i = l.indexOf(':'); if (i > 0) resHeaders[l.substring(0, i).trim()] = l.substring(i + 1).trim(); }); } catch (_) {}
      let responseBody: any;
      const rt = xhr.responseType;
      if (!rt || rt === 'text' || (rt as string) === '') {
        responseBody = parseBody(xhr.responseText);
      } else if (rt === 'json') {
        responseBody = xhr.response;
      } else {
        // Non-text responseType (blob, arraybuffer, ...). If the
        // server's Content-Type looks like JSON or text, try to read
        // it as text — saves the user from seeing `<blob 2852 bytes>`
        // when the server actually sent JSON. We trust the Content-Type
        // to tell us when the body is genuinely binary (image/*, video/*,
        // audio/*, application/octet-stream, ...).
        const ct = (resHeaders['content-type'] ?? '').toLowerCase();
        const isJsonCt = ct.includes('json') || ct.includes('+json');
        const isTextCt = ct.startsWith('text/') || ct === 'application/javascript' || ct === 'application/x-www-form-urlencoded';
        const blob = xhr.response as any;
        const blobSize = blob?.size ?? blob?.byteLength ?? 0;
        if ((isJsonCt || isTextCt) && blob && typeof blob.text === 'function') {
          try {
            const text = await blob.text();
            responseBody = isJsonCt ? parseBody(text) : text;
          } catch (_) {
            responseBody = `<${rt} ${blobSize || '?'} bytes>`;
          }
        } else if (rt === 'blob' && ct.startsWith('image/') && !ct.includes('svg') && blob && blobSize <= MAX_IMAGE_SIZE) {
          responseBody = await dataUrl(blob, ct.split(';')[0].trim()).catch(() => `<${rt} ${blobSize} bytes>`);
        } else {
          responseBody = `<${rt} ${blobSize || xhr.response?.byteLength || '?'} bytes>`;
        }
      }
      dc.send('client:network:request_complete', {
        requestId, method, url, statusCode: xhr.status, startTime,
        endTime: Date.now(), duration: Date.now() - startTime,
        requestHeaders: reqHeaders, responseHeaders: resHeaders, requestBody, responseBody,
        source: classifyUrl(url),
        via: 'xhr',
        ...(xhr.status === 0 ? { error: 'Network request failed' } : {}),
      });
    };
    xhr.addEventListener('loadend', handleLoadEnd);
    return xhr;
  }
  (globalThis as any).XMLHttpRequest = PatchedXHR;
}
