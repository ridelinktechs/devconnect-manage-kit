/// Format a byte-rate value with an auto-picked unit (MB/s / KB/s / B/s).
String formatSpeed(double bytesPerSec) {
  if (bytesPerSec >= 1024 * 1024) return '${(bytesPerSec / 1024 / 1024).toStringAsFixed(1)} MB/s';
  if (bytesPerSec >= 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
  if (bytesPerSec > 0) return '${bytesPerSec.toStringAsFixed(0)} B/s';
  return '0';
}