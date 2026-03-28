/// Format milliseconds to human-readable duration.
/// Examples:
///   120ms → "120ms"
///   1500ms → "1.5s"
///   65000ms → "1m 5s"
///   3661000ms → "1h 1m"
String formatDuration(int ms) {
  if (ms < 1000) return '${ms}ms';
  if (ms < 60000) {
    final seconds = ms / 1000;
    return seconds == seconds.truncateToDouble()
        ? '${seconds.toInt()}s'
        : '${seconds.toStringAsFixed(1)}s';
  }
  final minutes = ms ~/ 60000;
  final seconds = (ms % 60000) ~/ 1000;
  if (minutes < 60) {
    return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
}
