import type { DevConnect } from '../client';
import { generateId, safeString } from '../core/util';
import { MAX_IMAGE_SIZE, MAX_READ_SIZE, capBody, dataUrl, isTextType, parseBody } from './bodies';
import { classifyUrl, readFinalHeaders, wrapFetchInit } from './requestInfo';

  // ---- Fetch interceptor ----

export function patchFetch(dc: DevConnect): void {
  const originalFetch = (globalThis as any).fetch;
  dc.originalFetch = originalFetch;

  (globalThis as any).fetch = async function (input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
    const requestId = generateId();
    const startTime = Date.now();

    let method: string;
    if (init?.method) {
      method = init.method.toUpperCase();
    } else if (typeof Request !== 'undefined' && input instanceof Request) {
      method = (input as Request).method.toUpperCase();
    } else {
      method = 'GET';
    }

    let url: string;
    if (typeof input === 'string') {
      url = input;
    } else if (input instanceof URL) {
      url = input.toString();
    } else if (typeof Request !== 'undefined' && input instanceof Request) {
      url = input.url;
    } else {
      url = (input as any)?.url ?? String(input);
    }

    // AWS SDK v3 (@aws-sdk/fetch-http-handler) calls `fetch(request)` where
    // `request` is a fully-built Request object — init is undefined in that
    // case. All headers (including X-Amz-Date, Authorization added by the
    // signer middleware) are inside request.headers by the time fetch is
    // invoked. We must read from request, not init.
    const isRequestInput =
      typeof Request !== 'undefined' && input instanceof Request;
    // `unknown` (not `string`) because user-supplied fetch headers can
    // be arrays/objects (e.g. `headers: { map: { apiKey: 'x' } }`).
    // We pass them through verbatim so the desktop inspector can
    // JSON-render them instead of seeing the literal `[object Object]`.
    let reqHeaders: Record<string, unknown>;
    let finalBody: any;

    if (isRequestInput) {
      const r = input as Request;
      reqHeaders = {};
      r.headers.forEach((v: string, k: string) => (reqHeaders[k.toLowerCase()] = v));
      try {
        finalBody = await r.clone().text();
      } catch (_) {
        finalBody = undefined;
      }
    } else {
      const tracker: { headers?: any; body?: any } = {};
      const trackedInit = wrapFetchInit(init, tracker);
      (init as any) = trackedInit;
      reqHeaders = readFinalHeaders(tracker, trackedInit);
      finalBody = tracker.body !== undefined ? tracker.body : trackedInit?.body;
    }

    let requestBody: any;
    if (finalBody) {
      if (finalBody instanceof FormData) {
        const fields: Record<string, any> = {};
        const files: any[] = [];
        for (const [key, value] of (finalBody as any).entries()) {
          if (value instanceof Blob || (value && typeof value === 'object' && value.uri)) {
            files.push({ key, filename: value.name ?? value.filename ?? 'unknown', type: value.type ?? value.contentType ?? 'unknown', size: value.size ?? value.length });
          } else {
            fields[key] = value;
          }
        }
        requestBody = { ...fields, ...(files.length ? { _files: files, _contentType: 'multipart/form-data' } : {}) };
      } else {
        requestBody = parseBody(safeString(capBody(finalBody)));
      }
    }

    const source = classifyUrl(url);
    // Track this fetch so the XHR interceptor (which fires on RN's
    // internal XHR transport for the same call) can dedup against us.
    const fetchKey = `${method}\0${url}`;
    dc.fetchInFlight.set(fetchKey, (dc.fetchInFlight.get(fetchKey) ?? 0) + 1);
    dc.send('client:network:request_start', { requestId, method, url, startTime, requestHeaders: reqHeaders, requestBody, source, via: 'fetch' });

    // A desktop mock rule answers instead of the network (lazy require: that module
    // imports this one). A broken rule must never break the app's request.
    const mockServer = require('../interceptors/network/mockServerInterceptor');
    let mockRule: any = null;
    try { mockRule = mockServer.findMockMatch(method, url, reqHeaders, { currentDeviceId: dc.deviceId }); } catch (_) {}

    let responsePromise: Promise<Response>;
    dc.fetchStackCount++;
    try {
      responsePromise = mockRule
        ? mockServer.buildMockResponse(mockRule, requestId, { url, method })
        : originalFetch(input, init);
    } catch (err: any) {
      dc.send('client:network:request_complete', {
        requestId,
        method,
        url,
        statusCode: 0,
        startTime,
        endTime: Date.now(),
        duration: Date.now() - startTime,
        requestHeaders: reqHeaders,
        requestBody,
        error: err?.message ?? String(err),
        source,
        via: 'fetch',
      });
      const currentCount = dc.fetchInFlight.get(fetchKey) ?? 0;
      if (currentCount <= 1) {
        dc.fetchInFlight.delete(fetchKey);
      } else {
        dc.fetchInFlight.set(fetchKey, currentCount - 1);
      }
      throw err;
    } finally {
      dc.fetchStackCount--;
    }

    try {
      const response = await responsePromise;
      const resHeaders: Record<string, string> = {};
      response.headers.forEach((v: string, k: string) => (resHeaders[k] = v));

      const report = (responseBody?: any) => dc.send('client:network:request_complete', {
        requestId, method, url, statusCode: response.status, startTime,
        endTime: Date.now(), duration: Date.now() - startTime,
        requestHeaders: reqHeaders, responseHeaders: resHeaders, requestBody, responseBody, source,
        via: 'fetch',
      });
      const type = (response.headers.get('content-type') ?? '').toLowerCase();
      const size = Number(response.headers.get('content-length'));
      if (type.includes('event-stream')) {
        report('<stream>');
      } else if (isTextType(type) || (!type && !(size > MAX_READ_SIZE))) {
        response.clone().text().then((text) => report(parseBody(text)), () => report());
      } else if (!type) {
        report(`<${size} bytes>`);
      } else {
        const mime = type.split(';')[0].trim();
        response.clone().blob().then(async (blob: any) => report(mime.startsWith('image/') && blob.size <= MAX_IMAGE_SIZE
          ? await dataUrl(blob, mime)
          : `<${blob.size} bytes>`)).catch(() => report());
      }
      const currentCount = dc.fetchInFlight.get(fetchKey) ?? 0;
      if (currentCount <= 1) {
        dc.fetchInFlight.delete(fetchKey);
      } else {
        dc.fetchInFlight.set(fetchKey, currentCount - 1);
      }
      return response;
    } catch (error: any) {
      dc.send('client:network:request_complete', {
        requestId, method, url, statusCode: 0, startTime,
        endTime: Date.now(), duration: Date.now() - startTime,
        requestHeaders: reqHeaders, requestBody, error: error?.message ?? String(error), source,
        via: 'fetch',
      });
      const currentCount = dc.fetchInFlight.get(fetchKey) ?? 0;
      if (currentCount <= 1) {
        dc.fetchInFlight.delete(fetchKey);
      } else {
        dc.fetchInFlight.set(fetchKey, currentCount - 1);
      }
      throw error;
    }
  };
}
