import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/storage_snapshot_providers.dart';

/// The current contents of an app's key-value stores (AsyncStorage, MMKV,
/// SharedPreferences, …), editable from here: add, edit or delete a key,
/// or clear a whole store. Each edit comes back as the store's new
/// contents.
class StorageKeyValuePanel extends ConsumerStatefulWidget {
  const StorageKeyValuePanel({super.key});

  @override
  ConsumerState<StorageKeyValuePanel> createState() =>
      _StorageKeyValuePanelState();
}

class _StorageKeyValuePanelState extends ConsumerState<StorageKeyValuePanel> {
  /// Devices already asked for their stores, so rebuilds don't re-ask.
  final _asked = <String>{};
  String? _storageType;
  String _filter = '';

  void _request(String deviceId) =>
      ref.read(wsMessageHandlerProvider).requestStorage(deviceId);

  Future<void> _edit(
    DeviceInfo device,
    String storageType, {
    String? key,
    Object? original,
  }) async {
    final loc = S.of(context);
    final mono = chromeMono(
      context,
      size: 12.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final keyField = TextEditingController(text: key ?? '');
    final valueField = TextEditingController(
      text: key == null ? '' : storageValueText(original),
    );
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(key == null ? loc.storageKvAdd : loc.storageKvEdit),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyField,
                enabled: key == null,
                autofocus: key == null,
                style: mono,
                decoration: InputDecoration(labelText: loc.storageKvKey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueField,
                autofocus: key != null,
                minLines: 3,
                maxLines: 12,
                style: mono,
                decoration: InputDecoration(
                  labelText: loc.storageKvValue,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (keyField.text.trim(), valueField.text)),
            child: Text(loc.storageKvSave),
          ),
        ],
      ),
    );
    keyField.dispose();
    valueField.dispose();
    if (result == null || result.$1.isEmpty) return;
    ref
        .read(wsMessageHandlerProvider)
        .writeStorage(
          device.deviceId,
          storageType,
          result.$1,
          parseStorageEdit(result.$2, original),
        );
  }

  Future<void> _clear(DeviceInfo device, String storageType) async {
    final loc = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.storageKvClear),
        content: Text(loc.storageKvClearConfirm(storageType)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.storageKvClear),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref
          .read(wsMessageHandlerProvider)
          .clearStorage(device.deviceId, storageType);
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
        icon: LucideIcons.database,
        title: loc.storageTabKeyValue,
        subtitle: loc.storageKvNoDevice,
      );
    }
    if (_asked.add(target.deviceId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _request(target.deviceId);
      });
    }
    final stores =
        ref.watch(storageSnapshotsProvider)[target.deviceId] ?? const {};
    final storageType = stores.containsKey(_storageType)
        ? _storageType!
        : stores.keys.firstOrNull;
    final snapshot = storageType == null ? null : stores[storageType];
    final filter = _filter.toLowerCase();
    final entries =
        (snapshot?.entries.entries ?? const <MapEntry<String, Object?>>[])
            .where((e) => e.key.toLowerCase().contains(filter))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(bottom: BorderSide(color: divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final type in stores.keys)
                        _StoreChip(
                          label: type,
                          count: stores[type]!.entries.length,
                          selected: type == storageType,
                          isDark: isDark,
                          onTap: () => setState(() => _storageType = type),
                        ),
                    ],
                  ),
                ),
              ),
              if (storageType != null) ...[
                SizedBox(
                  width: 180,
                  child: TextField(
                    onChanged: (v) => setState(() => _filter = v),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: loc.storageKvFilter,
                      prefixIcon: const Icon(LucideIcons.search, size: 14),
                      prefixIconConstraints: const BoxConstraints(minWidth: 30),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 15),
                  tooltip: loc.storageKvAdd,
                  onPressed: () => _edit(target, storageType),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 14),
                  color: ColorTokens.error,
                  tooltip: loc.storageKvClear,
                  onPressed: () => _clear(target, storageType),
                ),
              ],
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                tooltip: loc.storageKvRefresh,
                onPressed: () => _request(target.deviceId),
              ),
            ],
          ),
        ),
        if (snapshot?.error case final error?)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: ColorTokens.error.withValues(alpha: 0.1),
            child: Text(
              error,
              style: TextStyle(fontSize: 12, color: ColorTokens.error),
            ),
          ),
        Expanded(
          child: storageType == null
              ? EmptyState(
                  icon: LucideIcons.database,
                  title: loc.storageTabKeyValue,
                  subtitle: loc.storageKvEmpty,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: divider),
                  itemBuilder: (context, i) {
                    final MapEntry(:key, :value) = entries[i];
                    return _KeyValueRow(
                      entryKey: key,
                      value: value,
                      isDark: isDark,
                      onEdit: () =>
                          _edit(target, storageType, key: key, original: value),
                      onDelete: () => ref
                          .read(wsMessageHandlerProvider)
                          .deleteStorage(target.deviceId, storageType, key),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StoreChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _StoreChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? ColorTokens.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? ColorTokens.primary.withValues(alpha: 0.5)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1)),
            ),
          ),
          child: Text(
            '$label  $count',
            style: chromeMono(
              context,
              size: 11.5,
              color: selected
                  ? ColorTokens.primary
                  : (isDark ? Colors.white70 : Colors.black87),
              weight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String entryKey;
  final Object? value;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KeyValueRow({
    required this.entryKey,
    required this.value,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final text = storageValueText(value);
    final type = switch (value) {
      String() => 'string',
      num() => 'number',
      bool() => 'bool',
      null => 'null',
      _ => 'json',
    };
    return InkWell(
      onDoubleTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        child: Row(
          children: [
            SizedBox(
              width: 240,
              child: Text(
                entryKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: chromeMono(
                  context,
                  size: 12,
                  color: isDark ? const Color(0xFFE06C75) : ColorTokens.primary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Tooltip(
                message: text.length > 80 ? text : '',
                waitDuration: const Duration(milliseconds: 500),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: chromeMono(
                    context,
                    size: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
            ),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 13),
              tooltip: loc.storageKvEdit,
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 13),
              tooltip: loc.storageKvDelete,
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
