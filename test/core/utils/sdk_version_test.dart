import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/core/utils/app/sdk_version.dart';

void main() {
  test('the 1.0.0 that older SDKs hardcode reads as unknown', () {
    expect(reportedSdkVersion('1.0.0'), isNull);
    expect(reportedSdkVersion(null), isNull);
    expect(reportedSdkVersion('1.0.10'), '1.0.10');
  });
}
