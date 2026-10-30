import { Platform, NativeModules } from 'react-native';

/**
 * Convert a seed string to a UUID v5-like format (deterministic).
 * Uses FNV-1a to produce 128 bits, then formats as UUID with version=5, variant=a.
 */
function seedToUUID(seed: string): string {
  // Generate 4 x 32-bit hashes for 128 bits total
  const hashes: number[] = [];
  for (let round = 0; round < 4; round++) {
    let h = 0x811c9dc5 ^ (round * 0x01000193);
    for (let i = 0; i < seed.length; i++) {
      h ^= seed.charCodeAt(i);
      h = Math.imul(h, 0x01000193);
    }
    hashes.push(h >>> 0);
  }
  const hex = hashes.map(h => h.toString(16).padStart(8, '0')).join('');
  // Format as UUID: 8-4-4-4-12, set version=5 and variant=a
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-5${hex.slice(13, 16)}-a${hex.slice(17, 20)}-${hex.slice(20, 32)}`;
}

/**
 * Generate a stable deviceId in UUID format using native platform identifiers.
 * Same app on same device always produces the same UUID.
 */
export function generateStableDeviceId(appName: string): string {
  const os = Platform.OS;
  const version = String(Platform.Version);
  let seed = `${appName}:react_native:${os}:${version}`;
  try {
    const constants = (Platform.constants || NativeModules.PlatformConstants) as Record<string, any> | undefined;
    if (os === 'android' && constants) {
      const pkg = constants.Package?.packageName || '';
      const fingerprint = constants.Fingerprint || constants.Serial || '';
      const model = constants.Model || constants.Brand || '';
      seed = `${pkg}:${model}:${fingerprint}:${appName}`;
    } else if (os === 'ios' && constants) {
      const idiom = constants.interfaceIdiom || '';
      const systemName = constants.systemName || '';
      const osVersion = constants.osVersion || version;
      seed = `${idiom}:${systemName}:${osVersion}:${appName}`;
    }
  } catch (_) {}
  return seedToUUID(seed);
}
