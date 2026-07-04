/// Detects the backend service behind a network request and, where possible,
/// extracts a human-readable action name (e.g. AWS Cognito's
/// `AWSCognitoIdentityProviderService.GetUser`).
library;

class DetectedService {
  final String name;
  final String? action;
  const DetectedService(this.name, {this.action});
}

const _services = <_ServiceRule>[
  _ServiceRule('Google Maps', ['maps.googleapis.com', 'maps.google.com']),
  _ServiceRule('Firebase', [
    'firebaseio.com',
    'firebasestorage.googleapis.com',
    'identitytoolkit.googleapis.com',
    'fcm.googleapis.com',
  ]),
  _ServiceRule('AWS Cognito', [
    'cognito-idp.',
    'cognito-identity.',
    'cognito-sync.',
  ]),
  _ServiceRule('AWS', ['amazonaws.com']),
  _ServiceRule('Stripe', ['stripe.com', 'stripe.network']),
  _ServiceRule('GitHub', ['api.github.com']),
  _ServiceRule('Sentry', ['sentry.io', 'ingest.sentry.io']),
  _ServiceRule('Mixpanel', ['mixpanel.com']),
  _ServiceRule('Segment', ['segment.io', 'segment.com']),
  _ServiceRule('Amplitude', ['amplitude.com', 'api.amplitude.com']),
];

class _ServiceRule {
  final String name;
  final List<String> patterns;
  const _ServiceRule(this.name, this.patterns);
}

DetectedService? detectService(String url, {Map<String, String>? headers, dynamic body}) {
  final lower = url.toLowerCase();
  for (final s in _services) {
    if (s.patterns.any((p) => lower.contains(p))) {
      final action = _extractAction(s.name, url, headers, body);
      return DetectedService(s.name, action: action);
    }
  }
  return null;
}

String? _extractAction(String service, String url, Map<String, String>? headers, dynamic body) {
  final h = _normalizeHeaders(headers);
  final amzTarget = h['x-amz-target'] ?? h['amz-target'];
  if (amzTarget != null && amzTarget.isNotEmpty) return amzTarget;

  if (service == 'AWS Cognito' && body is String) {
    final match = RegExp(r'<Action>\s*([^<]+)\s*</Action>', caseSensitive: false)
        .firstMatch(body);
    if (match != null) return match.group(1)?.trim();
  }
  if (body is String) {
    final sigMatch = RegExp(r'"Action"\s*:\s*"([^"]+)"').firstMatch(body);
    if (sigMatch != null) return sigMatch.group(1);
  }
  return null;
}

Map<String, String> _normalizeHeaders(Map<String, String>? h) {
  if (h == null) return const {};
  return {for (final e in h.entries) e.key.toLowerCase(): e.value};
}
