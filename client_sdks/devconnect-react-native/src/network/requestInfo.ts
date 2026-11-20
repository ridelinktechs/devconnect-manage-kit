// ---- URL classification (app vs library) ----

const libraryDomains = [
  'firebaseio.com', 'googleapis.com', 'firebase.google.com',
  'firebaseinstallations.googleapis.com', 'fcmregistrations.googleapis.com',
  'crashlyticsreports-pa.googleapis.com', 'firebaseremoteconfig.googleapis.com',
  'google-analytics.com', 'analytics.google.com', 'googletagmanager.com',
  'app-measurement.com', 'doubleclick.net',
  'facebook.com', 'graph.facebook.com', 'fbcdn.net',
  'sentry.io', 'bugsnag.com', 'instabug.com',
  'segment.io', 'segment.com', 'mixpanel.com', 'amplitude.com',
  'appsflyer.com', 'adjust.com', 'branch.io',
  'codepush.appcenter.ms', 'appcenter.ms',
  'clients3.google.com', 'clients4.google.com',
  'connectivitycheck', 'generate_204',
];

export function classifyUrl(url: string): string {
  try {
    const lower = url.toLowerCase();
    for (const domain of libraryDomains) {
      if (lower.includes(domain)) return 'library';
    }
    if (lower.includes('/generate_204') || lower.includes('connectivitycheck')) return 'system';
  } catch (_) {}
  return 'app';
}

export function wrapFetchInit(
  init: RequestInit | undefined,
  tracker: { headers?: any; body?: any },
): RequestInit | undefined {
  if (!init) return init;

  const headers = init.headers;
  if (headers && typeof headers === 'object' && !(headers instanceof Headers)) {
    const proxy = new Proxy(headers as Record<string, string>, {
      set(target, key, value) {
        (target as any)[key] = value;
        tracker.headers = { ...target };
        return true;
      },
      deleteProperty(target, key) {
        delete (target as any)[key];
        tracker.headers = { ...target };
        return true;
      },
    });
    (init as any).headers = proxy;
    tracker.headers = { ...(headers as Record<string, string>) };
  } else if (headers instanceof Headers) {
    const origAppend = headers.append.bind(headers);
    const origSet = headers.set.bind(headers);
    const origDelete = headers.delete.bind(headers);
    headers.append = function (name: string, value: string) {
      const r = origAppend(name, value);
      const snap: Record<string, string> = {};
      headers.forEach((v: string, k: string) => (snap[k.toLowerCase()] = v));
      tracker.headers = snap;
      return r;
    };
    headers.set = function (name: string, value: string) {
      const r = origSet(name, value);
      const snap: Record<string, string> = {};
      headers.forEach((v: string, k: string) => (snap[k.toLowerCase()] = v));
      tracker.headers = snap;
      return r;
    };
    headers.delete = function (name: string) {
      const r = origDelete(name);
      const snap: Record<string, string> = {};
      headers.forEach((v: string, k: string) => (snap[k.toLowerCase()] = v));
      tracker.headers = snap;
      return r;
    };
    const snap: Record<string, string> = {};
    headers.forEach((v: string, k: string) => (snap[k.toLowerCase()] = v));
    tracker.headers = snap;
  } else {
    tracker.headers = headers;
  }

  if ('body' in init) tracker.body = init.body;
  (init as any)['__dcBodyGet'] = () => tracker.body;

  return init;
}

/**
 * Read the final request headers from a fetch call, returning them as a
 * plain object. Nested Map/List values are preserved verbatim — the
 * desktop inspector JSON-encodes them for display. Calling `String(v)`
 * on a `{ apiKey: 'xxx' }` value would produce the literal
 * `[object Object]`, which is unrecoverable downstream.
 */
export function readFinalHeaders(
  tracker: { headers?: any },
  init: RequestInit | undefined,
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  const src = tracker.headers ?? init?.headers;
  if (!src) return out;
  if (typeof Headers !== 'undefined' && src instanceof Headers) {
    src.forEach((v: string, k: string) => (out[k.toLowerCase()] = v));
  } else if (Array.isArray(src)) {
    for (const [k, v] of src) out[String(k).toLowerCase()] = v;
  } else if (typeof src === 'object') {
    for (const [k, v] of Object.entries(src)) out[k.toLowerCase()] = v;
  }
  return out;
}
