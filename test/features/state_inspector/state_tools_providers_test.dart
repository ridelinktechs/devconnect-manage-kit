import 'package:flutter_test/flutter_test.dart';

import 'package:devconnect_manage_tool/features/state_inspector/provider/state_tools_providers.dart';
import 'package:devconnect_manage_tool/models/state/state_change.dart';

void main() {
  const state = {
    'auth': {
      'user': {'name': 'An', 'nickname': null},
    },
    'cart': {
      'items': [
        {'price': 12},
        {'price': 30},
      ],
    },
  };

  test('reads dotted and indexed paths', () {
    expect(valueAtPath(state, 'auth.user.name'), 'An');
    expect(valueAtPath(state, 'cart.items[1].price'), 30);
    expect(valueAtPath(state, 'cart.items.0.price'), 12);
    expect(valueAtPath(state, 'cart.items'), hasLength(2));
    expect(valueAtPath(state, ''), state);
  });

  test('tells a missing path from a null value', () {
    expect(valueAtPath(state, 'auth.user.nickname'), isNull);
    expect(valueAtPath(state, 'auth.user.email'), same(stateMissing));
    expect(valueAtPath(state, 'cart.items[5]'), same(stateMissing));
    expect(valueAtPath(state, 'auth.user.name.first'), same(stateMissing));
  });

  test('the live state is the latest change of that device', () {
    StateChange change(String device, int v) => StateChange(
      id: '$device$v',
      deviceId: device,
      stateManagerType: 'redux',
      actionName: 'A',
      nextState: {'v': v},
      timestamp: v,
    );
    final changes = [change('a', 1), change('b', 2), change('a', 3)];
    expect(latestStateOf(changes, 'a'), {'v': 3});
    expect(latestStateOf(changes, 'b'), {'v': 2});
    expect(latestStateOf(changes, 'c'), isNull);
  });
}
