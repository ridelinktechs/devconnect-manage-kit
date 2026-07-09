import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

/// Preset values for the data-retention dropdown. `null` = unlimited (no
/// cap, the historical default). Stored as a `String` in the dropdown so
/// we can render human-friendly labels (`1K`, `10K`) without losing
/// precision (`5000` vs `5K`).
enum RetentionPreset { unlimited, p100, p500, p1k, p5k, p10k }

extension RetentionPresetX on RetentionPreset {
  /// `null` = no cap. Any integer = drop entries older than `state.length
  /// > limit` (per-list FIFO trim).
  int? get limit => switch (this) {
        RetentionPreset.unlimited => null,
        RetentionPreset.p100 => 100,
        RetentionPreset.p500 => 500,
        RetentionPreset.p1k => 1000,
        RetentionPreset.p5k => 5000,
        RetentionPreset.p10k => 10000,
      };

  String get label => switch (this) {
        RetentionPreset.unlimited => 'Unlimited',
        RetentionPreset.p100 => '100',
        RetentionPreset.p500 => '500',
        RetentionPreset.p1k => '1K',
        RetentionPreset.p5k => '5K',
        RetentionPreset.p10k => '10K',
      };
}

/// Hard cap applied by each per-feature StateNotifier. When the cap is
/// exceeded, the oldest entries are dropped FIFO. Defaults to `Unlimited`
/// so existing behavior is preserved.
///
/// Persisted to disk via [AppPreferences] under the key
/// `retention_limit`. Survives app restarts.
final retentionLimitProvider =
    StateNotifierProvider<RetentionLimitNotifier, RetentionPreset>(
  (ref) => RetentionLimitNotifier(),
);

class RetentionLimitNotifier extends StateNotifier<RetentionPreset> {
  RetentionLimitNotifier() : super(_load());

  static const _key = 'retention_limit';

  static RetentionPreset _load() {
    final raw = AppPreferences().get<String>(_key);
    for (final v in RetentionPreset.values) {
      if (v.name == raw) return v;
    }
    return RetentionPreset.unlimited;
  }

  void set(RetentionPreset v) {
    state = v;
    AppPreferences().set(_key, v.name);
  }
}

/// View-only filter for the All Events page. Caps the rendered list to
/// the N most-recent entries but does NOT mutate the source providers —
/// flipping the value back to `Unlimited` brings every entry back.
/// Separate from [retentionLimitProvider] because the user may want a
/// strict hard cap on the underlying logs but a different (looser)
/// display ceiling on the aggregate view.
///
/// Persisted to disk via [AppPreferences] under `all_events_display_limit`.
final allEventsDisplayLimitProvider = StateNotifierProvider<
    AllEventsDisplayLimitNotifier, RetentionPreset>(
  (ref) => AllEventsDisplayLimitNotifier(),
);

class AllEventsDisplayLimitNotifier extends StateNotifier<RetentionPreset> {
  AllEventsDisplayLimitNotifier() : super(_load());

  static const _key = 'all_events_display_limit';

  static RetentionPreset _load() {
    final raw = AppPreferences().get<String>(_key);
    for (final v in RetentionPreset.values) {
      if (v.name == raw) return v;
    }
    return RetentionPreset.unlimited;
  }

  void set(RetentionPreset v) {
    state = v;
    AppPreferences().set(_key, v.name);
  }
}