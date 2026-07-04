import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_entry.freezed.dart';
part 'network_entry.g.dart';

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
  }) = _NetworkEntry;

  factory NetworkEntry.fromJson(Map<String, dynamic> json) =>
      _$NetworkEntryFromJson(json);
}
