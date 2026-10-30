export function generateId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/** `String(v)` that never throws: a null-prototype object (query-string's `parse` result) has no `toString`. */
export function safeString(v: unknown): string {
  try { return String(v); } catch (_) { return '[object Object]'; }
}
