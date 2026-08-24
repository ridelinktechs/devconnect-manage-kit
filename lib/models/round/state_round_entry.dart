/// Round 2: extended state-manager entry for BLoC, Provider, React Query,
/// Apollo. Kept as a single shape because all four share the same field
/// surface (manager type + change payload) — the difference is purely the
/// [manager] discriminator, which the desktop already filters on.
class StateRoundEntry {
  final String id;
  final String deviceId;
  final String manager; // bloc | provider | react_query | apollo
  final String action;
  final Map<String, dynamic> previousState;
  final Map<String, dynamic> nextState;
  final int timestamp;
  final Map<String, dynamic>? metadata;

  const StateRoundEntry({
    required this.id,
    required this.deviceId,
    required this.manager,
    required this.action,
    required this.previousState,
    required this.nextState,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'manager': manager,
        'action': action,
        'previousState': previousState,
        'nextState': nextState,
        'timestamp': timestamp,
        if (metadata != null) 'metadata': metadata,
      };

  factory StateRoundEntry.fromJson(Map<String, dynamic> json) =>
      StateRoundEntry(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        manager: json['manager'] as String,
        action: json['action'] as String? ?? '',
        previousState: (json['previousState'] as Map?)?.cast<String, dynamic>() ?? const {},
        nextState: (json['nextState'] as Map?)?.cast<String, dynamic>() ?? const {},
        timestamp: json['timestamp'] as int? ?? 0,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      );
}
