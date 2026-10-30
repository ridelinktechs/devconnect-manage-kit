import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/features/network_inspector/presentation/detail/blob_info.dart';
import 'package:devconnect_manage_tool/features/network_inspector/presentation/detail/image_body.dart';
import 'package:devconnect_manage_tool/features/network_inspector/presentation/shared/detect_blob_payload.dart';
import 'package:devconnect_manage_tool/l10n/app_localizations.dart';

/// A 1×1 PNG, 70 bytes.
const _png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlE'
    'QVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  test('every SDK size placeholder and image reads as a binary body', () {
    expect(detectBlobPayload('<2097152 bytes>'), ('blob', 2097152));
    expect(detectBlobPayload('<blob 4096 bytes>'), ('blob', 4096));
    expect(detectBlobPayload('<blob: 12 bytes>'), ('blob', 12));
    expect(detectBlobPayload('<binary, 10 bytes>'), ('binary', 10));
    expect(detectBlobPayload('<large, 52428800 bytes>'), ('large', 52428800));
    expect(detectBlobPayload('3 bytes'), ('blob', 3));
    expect(detectBlobPayload('data:image/png;base64,AQID'), ('image/png', 3));
    expect(detectBlobPayload('data:image/gif;base64,AQ=='), ('image/gif', 1));
    expect(detectBlobPayload(_png), ('image/png', 70));

    expect(detectBlobPayload('{"size":"3 bytes"}'), (null, null));
    expect(detectBlobPayload('sent <5 bytes>'), (null, null));
    expect(detectBlobPayload({'a': 1}), (null, null));
  });

  testWidgets('an image body shows the picture with its type and size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ImageBody(dataUrl: _png, label: 'Response', isDark: false)),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('image/png · 70 B'), findsOneWidget);
  });

  testWidgets('a binary body fetched with GET offers to open it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const BlobInfo(
          label: 'Response',
          sizeBytes: 2097152,
          isDark: false,
          openUrl: 'https://cdn.example.com/clip.mp4',
        ),
      ),
    );

    expect(find.text('Open in default app'), findsOneWidget);
    expect(find.text('2.0 MB (2097152 bytes)'), findsOneWidget);

    await tester.pumpWidget(
      _app(const BlobInfo(label: 'Response', sizeBytes: 10, isDark: false)),
    );
    expect(find.text('Open in default app'), findsNothing);
  });
}
