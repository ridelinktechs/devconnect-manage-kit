import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression test for `devconnect_bloc_observer.dart:33-61`.
///
/// The `BlocObserverBase` duck-typed base class is a no-op. Consumers
/// who subclass `DevConnectBlocObserver` and write `super.onCreate(bloc)`
/// might assume this chains to the real `flutter_bloc` BlocObserver.
/// It doesn't — there is no super-chain.
///
/// The chosen fix is option (b): clearly document the limitation so
/// consumers don't get surprised. This test asserts the docstring
/// states the limitation explicitly.
void main() {
  test('BlocObserverBase class comment documents the no-super-chain limit',
      () {
    final src = File(
      '/Users/phibui/Documents/ridelink-techs/connect-totron/client_sdks/'
      'devconnect_flutter/lib/src/interceptors/bloc/devconnect_bloc_observer.dart',
    ).readAsStringSync();

    // Find the BlocObserverBase class block. The doc comment sits
    // immediately above the declaration — capture from the start of
    // the `///` block.
    final classIdx = src.indexOf('abstract class BlocObserverBase');
    expect(classIdx, isNonNegative, reason: 'BlocObserverBase must exist');

    // Step 1: walk back past any whitespace/newlines to the end of the
    // preceding line. `classIdx` points at the 'a' of `abstract`; the
    // '\n' immediately before it terminates the line above.
    var cursor = classIdx - 1;
    while (cursor > 0 && (src[cursor] == ' ' || src[cursor] == '\t')) {
      cursor--;
    }
    expect(src[cursor], '\n',
        reason: 'Expected the line above `abstract class` to end with \\n');
    // `cursor` now points to the '\n' that ends the preceding line.
    final lineEnd = cursor;

    // Step 2: walk backward through consecutive `///` lines.
    // `docStart` is the start of the current line; the line ends at the
    // `\n` immediately before it (position docStart - 1). Search for
    // the *previous* '\n' before that — i.e. start from docStart - 2.
    var docStart = lineEnd;
    while (docStart > 0) {
      final prevNl = src.lastIndexOf('\n', docStart - 2);
      if (prevNl < 0) break;
      final prevLineStart = prevNl + 1;
      final prevLine = src.substring(prevLineStart, docStart);
      if (prevLine.trimLeft().startsWith('///')) {
        docStart = prevLineStart;
      } else {
        break;
      }
    }
    expect(docStart, lessThan(classIdx),
        reason: 'BlocObserverBase must have a preceding /// doc comment');

    // Walk to the matching closing brace (naively count depth — fine
    // for a tiny class with no nested braces).
    var depth = 0;
    var end = classIdx;
    for (var i = classIdx; i < src.length; i++) {
      final ch = src[i];
      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    expect(end, greaterThan(classIdx));
    final block = src.substring(docStart, end + 1);

    // The docstring must warn consumers that:
    //  1. This is NOT flutter_bloc's real BlocObserver/BlocObserverBase.
    //  2. `super.onCreate` does NOT chain to the real BlocObserver.
    expect(block, contains('super'),
        reason:
            'Doc must mention that super.* does not chain to flutter_bloc.');
    // A more semantic check: the comment must contain a phrase that
    // warns about the no-super-chain behavior.
    final lc = block.toLowerCase();
    expect(
      lc.contains('does not chain') ||
          lc.contains('no super') ||
          lc.contains('no chain') ||
          lc.contains('doesn\'t chain') ||
          lc.contains('not chain'),
      isTrue,
      reason:
          'BlocObserverBase doc must explicitly warn that super.* does not '
          'chain to the real flutter_bloc BlocObserver.',
    );
  });
}
