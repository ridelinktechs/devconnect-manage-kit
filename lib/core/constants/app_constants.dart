class AppConstants {
  static const String appName = 'DevConnect Manage Tool';
  static const String appVersion = '1.0.3';
  static const String monoFontFamily = 'JetBrains Mono';
  static const int defaultPort = 9090;
  static const int heartbeatIntervalMs = 5000;
  static const int heartbeatTimeoutMs = 10000;
  static const int maxLogEntries = 10000;
  static const int maxNetworkEntries = 5000;

  /// Binary base for byte-size formatting. 1024 = KiB convention used by most
  /// dev tools (KB label intentionally — matches what users expect to see).
  static const int bytesPerKb = 1024;

  /// Formats [bytes] as a human-readable string with binary suffix:
  /// "523 B" / "4.2 KB" / "8.1 MB" / "1.5 GB".
  ///
  /// Uses [bytesPerKb] as the base so the whole app stays consistent if the
  /// base is ever swapped (e.g. for true KiB labels).
  static String formatBytes(int bytes) {
    if (bytes < bytesPerKb) return '$bytes B';
    final kb = bytes / bytesPerKb;
    if (kb < bytesPerKb) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / bytesPerKb;
    if (mb < bytesPerKb) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / bytesPerKb;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
