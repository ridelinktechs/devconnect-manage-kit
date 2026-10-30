import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/format/duration_format.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/custom_commands_providers.dart';

/// Custom commands (Reactotron-style): the commands each app registered
/// with `DevConnect.registerCommand`, run from here with optional JSON
/// args. A name can also be typed by hand — SDKs that predate the
/// `client:custom:commands` announcement still run it.
class CustomCommandsPage extends ConsumerStatefulWidget {
  const CustomCommandsPage({super.key});

  @override
  ConsumerState<CustomCommandsPage> createState() => _CustomCommandsPageState();
}

class _CustomCommandsPageState extends ConsumerState<CustomCommandsPage> {
  final _command = TextEditingController();
  final _args = TextEditingController();

  /// Device of the command last picked from the list.
  String? _pickedDeviceId;
  String? _argsError;

  @override
  void dispose() {
    _command.dispose();
    _args.dispose();
    super.dispose();
  }

  /// Where a run goes: the picked command's device, else the selected one,
  /// else the only one connected.
  DeviceInfo? _target(List<DeviceInfo> devices, String? selectedId) =>
      devices.where((d) => d.deviceId == _pickedDeviceId).firstOrNull ??
      devices.where((d) => d.deviceId == selectedId).firstOrNull ??
      (devices.length == 1 ? devices.single : null);

  void _run(DeviceInfo device) {
    final name = _command.text.trim();
    if (name.isEmpty) return;
    Map<String, dynamic>? args;
    final raw = _args.text.trim();
    if (raw.isNotEmpty) {
      final decoded = _tryDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        setState(() => _argsError = S.of(context).commandsArgsInvalid);
        return;
      }
      args = decoded;
    }
    setState(() => _argsError = null);
    ref.read(commandRunsProvider.notifier).run(device.deviceId, name, args);
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
    final commands = ref.watch(customCommandsProvider);
    final runs = ref.watch(commandRunsProvider);
    final selected = devices.where((d) => d.deviceId == selectedId).toList();
    final listed = selected.isNotEmpty ? selected : devices;
    final target = _target(devices, selectedId);
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      children: [
        _Toolbar(
          isDark: isDark,
          divider: divider,
          title: loc.commandsTitle,
          onClear: runs.isEmpty
              ? null
              : () => ref.read(commandRunsProvider.notifier).clear(),
        ),
        Expanded(
          child: devices.isEmpty
              ? EmptyState(
                  icon: LucideIcons.squareTerminal,
                  title: loc.commandsTitle,
                  subtitle: loc.commandsNoDevice,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _CommandList(
                        devices: listed,
                        commands: commands,
                        showDevice: listed.length > 1,
                        picked: (_pickedDeviceId, _command.text.trim()),
                        isDark: isDark,
                        onPick: (deviceId, command) => setState(() {
                          _pickedDeviceId = deviceId;
                          _command.text = command;
                        }),
                      ),
                    ),
                    VerticalDivider(width: 1, color: divider),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Editor(
                            command: _command,
                            args: _args,
                            argsError: _argsError,
                            target: target,
                            isDark: isDark,
                            onRun: target == null ? null : () => _run(target),
                            onChanged: () => setState(() {}),
                          ),
                          Divider(height: 1, color: divider),
                          Expanded(
                            child: _History(
                              runs: runs,
                              devices: devices,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  final bool isDark;
  final Color divider;
  final String title;
  final VoidCallback? onClear;

  const _Toolbar({
    required this.isDark,
    required this.divider,
    required this.title,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.squareTerminal,
            size: 15,
            color: ColorTokens.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 14),
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            tooltip: S.of(context).clear,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _CommandList extends StatelessWidget {
  final List<DeviceInfo> devices;
  final Map<String, List<String>> commands;
  final bool showDevice;
  final (String?, String) picked;
  final bool isDark;
  final void Function(String deviceId, String command) onPick;

  const _CommandList({
    required this.devices,
    required this.commands,
    required this.showDevice,
    required this.picked,
    required this.isDark,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? Colors.grey[500] : Colors.grey[600];
    final any = devices.any((d) => commands[d.deviceId]?.isNotEmpty ?? false);
    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: !any
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                S.of(context).commandsEmptyHint,
                style: TextStyle(fontSize: 12, height: 1.5, color: muted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final d in devices) ...[
                  if (showDevice && (commands[d.deviceId]?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: Text(
                        '${d.appName} · ${d.deviceName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                    ),
                  for (final c in commands[d.deviceId] ?? const <String>[])
                    _CommandTile(
                      name: c,
                      selected: picked == (d.deviceId, c),
                      isDark: isDark,
                      onTap: () => onPick(d.deviceId, c),
                    ),
                ],
              ],
            ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  final String name;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _CommandTile({
    required this.name,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: selected ? ColorTokens.selectedBg(isDark) : null,
        child: Row(
          children: [
            Icon(
              LucideIcons.command,
              size: 13,
              color: selected ? ColorTokens.selectedAccent : Colors.grey[500],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: chromeMono(
                  context,
                  size: 12,
                  color: selected
                      ? ColorTokens.selectedAccent
                      : (isDark ? Colors.white70 : Colors.black87),
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  final TextEditingController command;
  final TextEditingController args;
  final String? argsError;
  final DeviceInfo? target;
  final bool isDark;
  final VoidCallback? onRun;
  final VoidCallback onChanged;

  const _Editor({
    required this.command,
    required this.args,
    required this.argsError,
    required this.target,
    required this.isDark,
    required this.onRun,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final mono = chromeMono(
      context,
      size: 12.5,
      color: isDark ? Colors.white : Colors.black87,
    );
    InputDecoration decoration(String label, {String? hint, String? error}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: error,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        );
    final canRun = onRun != null && command.text.trim().isNotEmpty;
    return Container(
      color: isDark ? ColorTokens.darkBackground : Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: command,
                  style: mono,
                  decoration: decoration(loc.commandsName, hint: 'clearCache'),
                  onChanged: (_) => onChanged(),
                  onSubmitted: canRun ? (_) => onRun!() : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: canRun ? onRun : null,
                  icon: const Icon(LucideIcons.play, size: 14),
                  label: Text(loc.commandsRun),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorTokens.primary,
                    foregroundColor: Colors.white,
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: args,
            style: mono,
            minLines: 2,
            maxLines: 6,
            decoration: decoration(
              loc.commandsArgs,
              hint: '{"userId": 42}',
              error: argsError,
            ),
          ),
          if (target case final target?) ...[
            const SizedBox(height: 8),
            Text(
              loc.commandsTarget('${target.appName} · ${target.deviceName}'),
              style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  final List<CommandRun> runs;
  final List<DeviceInfo> devices;
  final bool isDark;

  const _History({
    required this.runs,
    required this.devices,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    if (runs.isEmpty) {
      return EmptyState(
        icon: LucideIcons.history,
        title: loc.history,
        subtitle: loc.commandsHistoryEmpty,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: runs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _RunTile(
        run: runs[i],
        device: devices
            .where((d) => d.deviceId == runs[i].deviceId)
            .firstOrNull,
        isDark: isDark,
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  final CommandRun run;
  final DeviceInfo? device;
  final bool isDark;

  const _RunTile({
    required this.run,
    required this.device,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final muted = TextStyle(fontSize: 11, color: Colors.grey[500]);
    final (Widget icon, String? body, Color bodyColor) = switch (run.status) {
      CommandRunStatus.pending => (
        const SizedBox.square(
          dimension: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
        null,
        Colors.transparent,
      ),
      CommandRunStatus.ok => (
        Icon(LucideIcons.circleCheck, size: 14, color: ColorTokens.success),
        run.result == null
            ? null
            : const JsonEncoder.withIndent('  ').convert(run.result),
        isDark ? Colors.white70 : Colors.black87,
      ),
      CommandRunStatus.error => (
        Icon(LucideIcons.circleX, size: 14, color: ColorTokens.error),
        run.error,
        ColorTokens.error,
      ),
      CommandRunStatus.noResponse => (
        Icon(LucideIcons.clock, size: 14, color: Colors.grey[500]),
        loc.commandsNoResponse,
        Colors.grey[500]!,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              run.command,
              style: chromeMono(
                context,
                size: 12.5,
                color: isDark ? Colors.white : Colors.black87,
                weight: FontWeight.w600,
              ),
            ),
            if (device case final device?) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  device.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
            ],
            const Spacer(),
            Text(DateFormat.Hms().format(run.sentAt), style: muted),
            if (run.took case final took?) ...[
              const SizedBox(width: 8),
              Text(formatDuration(took.inMilliseconds), style: muted),
            ],
          ],
        ),
        if (body != null)
          Container(
            margin: const EdgeInsets.only(left: 22, top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? ColorTokens.darkBackground
                  : ColorTokens.lightSurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              body,
              style: chromeMono(
                context,
                size: 11.5,
                color: bodyColor,
              ).copyWith(height: 1.45),
            ),
          ),
      ],
    );
  }
}
