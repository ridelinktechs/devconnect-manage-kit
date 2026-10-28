import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:devconnect_manage_tool/core/providers/sdk_versions_provider.dart';

/// Fake pub.dev / npm / Maven Central. [mavenStatus] lets a test take
/// one registry down.
MockClient _registries({int mavenStatus = 200}) => MockClient(
      (req) async => switch (req.url.host) {
        'pub.dev' => http.Response('{"latest":{"version":"1.0.6"}}', 200),
        'registry.npmjs.org' => http.Response('{"version":"1.0.9"}', 200),
        _ => http.Response(
            '<metadata><versioning><latest>1.1.0</latest>'
            '<release>1.1.0</release></versioning></metadata>',
            mavenStatus,
          ),
      },
    );

Future<SdkLatestVersions> _firstFetch(MockClient client) =>
    http.runWithClient(() async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(sdkLatestVersionsProvider, (_, _) {});
      await pumpEventQueue();
      return container.read(sdkLatestVersionsProvider);
    }, () => client);

void main() {
  test('first fetch resolves every registry instead of hanging in loading',
      () async {
    final s = await _firstFetch(_registries());

    expect(s.latestFor(SdkPlatform.flutter), '1.0.6');
    expect(s.latestFor(SdkPlatform.reactNative), '1.0.9');
    expect(s.latestFor(SdkPlatform.android), '1.1.0');
  });

  test('a failing registry only marks its own platform as error', () async {
    final s = await _firstFetch(_registries(mavenStatus: 503));

    expect(s.fetchStateFor(SdkPlatform.android), SdkVersionFetch.error);
    expect(s.fetchStateFor(SdkPlatform.flutter), SdkVersionFetch.loaded);
    expect(s.fetchStateFor(SdkPlatform.reactNative), SdkVersionFetch.loaded);
  });
}
