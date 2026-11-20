import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// For pages the router keeps alive behind the one on screen: listens to
/// providers only while the page is shown, as `ref.watch` already does, and
/// catches up when it's shown again.
mixin ListenWhileShown<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final _listens = <ProviderSubscription<Object?> Function()>[];

  /// The open subscriptions; null while the page is hidden.
  List<ProviderSubscription<Object?>>? _subs = [];

  /// Calls [listener] with [provider]'s value now and on each change while
  /// the page is shown, and with its current value, and no previous one,
  /// each time the page is shown again.
  void listenWhileShown<V>(
    ProviderListenable<V> provider,
    void Function(V? previous, V next) listener,
  ) {
    ProviderSubscription<Object?> listen() =>
        ref.listenManual<V>(provider, listener, fireImmediately: true);
    _listens.add(listen);
    _subs?.add(listen());
  }

  /// Called when the page is shown again after being hidden.
  void onShownAgain() {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.valuesOf(context).enabled;
    if (shown == (_subs != null)) return;
    if (shown) {
      _subs = [for (final listen in _listens) listen()];
      onShownAgain();
    } else {
      for (final sub in _subs!) {
        sub.close();
      }
      _subs = null;
    }
  }
}
