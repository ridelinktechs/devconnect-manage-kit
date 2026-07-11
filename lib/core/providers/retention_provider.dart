import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';

/// User-facing retention caps surfaced in the Settings dropdown.
///
/// The matching `RetentionPreset.pXXX` enum values map directly to these
/// numbers via [RetentionPresetX.limit]. Keeping them as named constants
/// means a future bump (say `kRetentionSafetyCap` 5000 → 8000) only has to
/// be done in one place — both the dropdown choice and the safety-net
/// fallback pick up the new value automatically.
const int kRetentionCap100 = 100;
const int kRetentionCap500 = 500;
const int kRetentionCap1k = 1000;

/// Safety-net cap applied when the user picks `RetentionPreset.unlimited`.
/// The preset exposes `limit == null` (= no user cap), but a totally
/// unbounded list is a memory-leak hazard: each event source appends on
/// every WebSocket frame for the lifetime of the app. We fall back to a
/// conservative upper bound so the desktop client doesn't OOM when the
/// user opts out of explicit capping.
const int kRetentionSafetyCap = 5000;

/// Looser cap for high-frequency, low-size streams (console logs,
/// performance samples). Each entry is small so a higher ceiling is
/// affordable, and these streams are the first thing the user notices
/// when truncated.
const int kRetentionHighVolumeCap = 10000;

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
        RetentionPreset.p100 => kRetentionCap100,
        RetentionPreset.p500 => kRetentionCap500,
        RetentionPreset.p1k => kRetentionCap1k,
        RetentionPreset.p5k => kRetentionSafetyCap,
        RetentionPreset.p10k => kRetentionHighVolumeCap,
      };

  String get label => switch (this) {
        RetentionPreset.unlimited => 'Unlimited',
        RetentionPreset.p100 => '$kRetentionCap100',
        RetentionPreset.p500 => '$kRetentionCap500',
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