import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/state_tools_providers.dart';

/// Reactotron-style state controls for one device: pinned paths with their
/// live values, snapshots to restore, and a Redux action composer.
class StateToolsPanel extends ConsumerStatefulWidget {
  const StateToolsPanel({super.key});

  @override
  ConsumerState<StateToolsPanel> createState() => _StateToolsPanelState();
}

class _StateToolsPanelState extends ConsumerState<StateToolsPanel> {
  final _path = TextEditingController();
  final _action = TextEditingController();
  String? _actionError;

  @override
  void dispose() {
    _path.dispose();
    _action.dispose();
    super.dispose();
  }

  void _pin() {
    ref.read(stateSubscriptionsProvider.notifier).add(_path.text);
    _path.clear();
  }

  void _dispatch(DeviceInfo target) {
    final loc = S.of(context);
    final action = _tryDecode(_action.text.trim());
    if (action is! Map<String, dynamic>) {
      setState(() => _actionError = loc.stateActionInvalid);
      return;
    }
    setState(() => _actionError = null);
    ref
        .read(wsMessageHandlerProvider)
        .dispatchReduxAction(target.deviceId, action);
    ref.read(dispatchHistoryProvider.notifier).add(jsonEncode(action));
    showSuccessToast(context, message: loc.stateDispatchSent);
  }

  static Object? _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devices = ref.watch(connectedDevicesProvider);
    final selectedId = ref.watch(selectedDeviceProvider);
    final target =
        devices.where((d) => d.deviceId == selectedId).firstOrNull ??
        (devices.length == 1 ? devices.single : null);
    if (target == null) {
      return EmptyState(
        icon: LucideIcons.slidersHorizontal,
        title: loc.stateToolsTab,
        subtitle: loc.stateNoDevice,
      );
    }
    final state = ref.watch(latestStateProvider(target.deviceId));
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);
    final muted = TextStyle(
      fontSize: 11.5,
      height: 1.45,
      color: Colors.grey[500],
    );
    final mono = chromeMono(
      context,
      size: 12,
      color: isDark ? Colors.white : Colors.black87,
    );
    InputDecoration field(String hint, {String? error, Widget? suffix}) =>
        InputDecoration(
          hintText: hint,
          hintStyle: mono.copyWith(color: Colors.grey[600]),
          errorText: error,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        );

    final paths = ref.watch(stateSubscriptionsProvider);
    final snapshots = ref.watch(stateSnapshotsProvider);
    final history = ref.watch(dispatchHistoryProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _Section(
            icon: LucideIcons.pin,
            title: loc.stateSubscriptions,
            hint: loc.stateSubscriptionsHint,
            isDark: isDark,
            children: [
              TextField(
                controller: _path,
                style: mono,
                decoration: field(
                  'auth.user.name',
                  suffix: IconButton(
                    icon: const Icon(LucideIcons.plus, size: 14),
                    tooltip: loc.statePinPath,
                    onPressed: _pin,
                  ),
                ),
                onSubmitted: (_) => _pin(),
              ),
              if (state == null) ...[
                const SizedBox(height: 10),
                Text(loc.stateNoState, style: muted),
              ],
              for (final p in paths)
                _PinnedPath(
                  path: p,
                  value: state == null ? stateMissing : valueAtPath(state, p),
                  isDark: isDark,
                  onRemove: () =>
                      ref.read(stateSubscriptionsProvider.notifier).remove(p),
                ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: divider),
        Expanded(
          child: _Section(
            icon: LucideIcons.camera,
            title: loc.stateSnapshots,
            hint: loc.stateSnapshotsHint,
            isDark: isDark,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: state == null
                      ? null
                      : () => ref
                            .read(stateSnapshotsProvider.notifier)
                            .add(
                              'Snapshot ${DateFormat.Hms().format(DateTime.now())}',
                              target.deviceId,
                              state,
                            ),
                  icon: const Icon(LucideIcons.camera, size: 14),
                  label: Text(loc.stateTakeSnapshot),
                  style: _filled(context),
                ),
              ),
              for (final s in snapshots)
                _SnapshotTile(
                  snapshot: s,
                  source: devices
                      .where((d) => d.deviceId == s.deviceId)
                      .firstOrNull,
                  isDark: isDark,
                  onRestore: () =>
                      restoreAppState(context, ref, target.deviceId, s.state),
                  onDelete: () =>
                      ref.read(stateSnapshotsProvider.notifier).remove(s.id),
                ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: divider),
        Expanded(
          child: _Section(
            icon: LucideIcons.send,
            title: loc.stateDispatch,
            hint: loc.stateDispatchHint,
            isDark: isDark,
            children: [
              TextField(
                controller: _action,
                style: mono,
                minLines: 4,
                maxLines: 10,
                decoration: field('{"type": "LOGOUT"}', error: _actionError),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _dispatch(target),
                  icon: const Icon(LucideIcons.send, size: 14),
                  label: Text(loc.stateDispatchButton),
                  style: _filled(context),
                ),
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(loc.stateRecentActions.toUpperCase(), style: _label),
                const SizedBox(height: 4),
                for (final a in history)
                  InkWell(
                    onTap: () => setState(() {
                      _action.text = const JsonEncoder.withIndent(
                        '  ',
                      ).convert(jsonDecode(a));
                      _actionError = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        a,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mono.copyWith(color: Colors.grey[500]),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

const _label = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1,
  color: Color(0xFF8B949E),
);

ButtonStyle _filled(BuildContext context) => FilledButton.styleFrom(
  backgroundColor: ColorTokens.primary,
  foregroundColor: Colors.white,
  textStyle: Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
);

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final bool isDark;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.hint,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: ColorTokens.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          hint,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.45,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

class _PinnedPath extends StatelessWidget {
  final String path;
  final Object? value;
  final bool isDark;
  final VoidCallback onRemove;

  const _PinnedPath({
    required this.path,
    required this.value,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final missing = identical(value, stateMissing);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: chromeMono(
                    context,
                    size: 12,
                    color: ColorTokens.primary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 13),
                color: Colors.grey[500],
                tooltip: S.of(context).stateRemove,
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? ColorTokens.darkBackground
                  : ColorTokens.lightSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              missing
                  ? S.of(context).statePathMissing
                  : const JsonEncoder.withIndent('  ').convert(value),
              style: chromeMono(
                context,
                size: 11.5,
                color: missing
                    ? Colors.grey[500]!
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  final StateSnapshot snapshot;
  final DeviceInfo? source;
  final bool isDark;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _SnapshotTile({
    required this.snapshot,
    required this.source,
    required this.isDark,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  [
                    ?source?.appName,
                    loc.stateKeys(snapshot.state.length),
                  ].join(' · '),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRestore,
            icon: const Icon(LucideIcons.rotateCcw, size: 13),
            label: Text(loc.stateRestore),
            style: TextButton.styleFrom(
              foregroundColor: ColorTokens.primary,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 13),
            color: Colors.grey[500],
            tooltip: loc.stateRemove,
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
