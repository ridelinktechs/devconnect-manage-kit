import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_event.freezed.dart';
part 'error_event.g.dart';

/// Platform source of the error
enum ErrorPlatform { js, native, android, ios }

/// Severity level for errors
enum ErrorSeverity { fatal, crash, error, warning, info }

@freezed
abstract class ErrorEvent with _$ErrorEvent {
  const factory ErrorEvent({
    required String id,
    required String deviceId,
    required ErrorPlatform platform,
    required ErrorSeverity severity,
    required String message,
    required int timestamp,
    String? stackTrace,
    String? source,
    String? deviceInfo,
    Map<String, dynamic>? metadata,
  }) = _ErrorEvent;

  factory ErrorEvent.fromJson(Map<String, dynamic> json) =>
      _$ErrorEventFromJson(json);
}