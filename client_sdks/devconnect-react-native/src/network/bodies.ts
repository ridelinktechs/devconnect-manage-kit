/** Text bodies longer than this are sent unparsed: the desktop parses them off its UI thread. */
const MAX_PARSE_SIZE = 1_048_576;

/** Response bodies of no stated type bigger than this aren't read: only their size is reported. */
export const MAX_READ_SIZE = 10 * MAX_PARSE_SIZE;

/** Images up to this many bytes are sent for the desktop to show; bigger ones by their size. */
export const MAX_IMAGE_SIZE = 10 * MAX_PARSE_SIZE;

/** Binary bodies as `<N bytes>`; anything else unchanged. */
export function capBody(body: any): any {
  return body instanceof ArrayBuffer || ArrayBuffer.isView(body) ? `<${body.byteLength} bytes>` : body;
}

/** [text] parsed when it's JSON, unless it's longer than MAX_PARSE_SIZE. */
export function parseBody(text: string): any {
  if (text.length > MAX_PARSE_SIZE) return text;
  try { return JSON.parse(text); } catch (_) { return text; }
}

/** Whether a body of this (lowercase) content type is text, which is sent whole. */
export function isTextType(type: string): boolean {
  return /json|xml|javascript|x-www-form-urlencoded|graphql|^text\//.test(type);
}

/** [blob] as a `data:` URL of type [mime], for the desktop to show. */
export function dataUrl(blob: any, mime: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new (globalThis as any).FileReader();
    reader.onload = () => {
      const url = String(reader.result);
      resolve(`data:${mime};base64,${url.slice(url.indexOf(',') + 1)}`);
    };
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(blob);
  });
}
