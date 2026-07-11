import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_entry.freezed.dart';
part 'network_entry.g.dart';

/// Possible values for [NetworkEntry.via] — which interceptor path on
/// the SDK side reported this entry. The raw string also flows through
/// from the SDK payload, so any unknown value is preserved as
/// [NetworkVia.unknown] on the next rebuild.
class NetworkVia {
  const NetworkVia._();

  static const String fetch = 'fetch';
  static const String xhr = 'xhr';
  static const String unknown = 'unknown';

  /// True when [via] should render a visible tag in the UI.
  static bool isKnown(String via) => via == fetch || via == xhr;
}

@freezed
abstract class NetworkEntry with _$NetworkEntry {
  const factory NetworkEntry({
    required String id,
    required String deviceId,
    required String method,
    required String url,
    @Default(0) int statusCode,
    @Default({}) Map<String, String> requestHeaders,
    @Default({}) Map<String, String> responseHeaders,
    dynamic requestBody,
    dynamic responseBody,
    required int startTime,
    int? endTime,
    int? duration,
    String? error,
    @Default(false) bool isComplete,
    @Default('app') String source,
    String? serviceName,
    String? serviceAction,
    @Default(NetworkVia.unknown) String via,
  }) = _NetworkEntry;

  factory NetworkEntry.fromJson(Map<String, dynamic> json) =>
      _$NetworkEntryFromJson(json);
}
