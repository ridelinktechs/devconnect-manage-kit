import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect_manage_kit/src/version.dart';

void main() {
  test('devConnectSdkVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
        .firstMatch(pubspec)!
        .group(1);

    expect(devConnectSdkVersion, version);
  });
}
