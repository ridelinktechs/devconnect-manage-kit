import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state_with_pulse.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/layout/segmented_tab_bar.dart';
import '../../../../core/routes/listen_while_shown.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/device_info.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../../server/ws_message_handler.dart';
import '../../provider/storage_snapshot_providers.dart';
import '../header/icon_btn.dart';
import '../shared/storage_tokens.dart';
import 'edit_key_dialog.dart';
import 'key_value_row.dart';

/// A store as people read it — `async_storage` is AsyncStorage,
/// `mmkv:settings` is MMKV · settings — or as the SDK sent it when the app
/// doesn't know the storage.
String _storeName(String raw) {
  final (:storageType, :storeId) = parseStorageTypeAndStoreId(raw);
  final base = raw.split(':').first.toLowerCase().replaceAll('_', '');
  return storageType != StorageType.sharedPreferences ||
          base == 'sharedpreferences'
      ? storageLabel(storageType, storeId)
      : raw;
}

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

class _StorageKeyValuePanelState extends ConsumerState<StorageKeyValuePanel>
    with ListenWhileShown {
  /// Devices asked for their stores since the panel was last shown, so
  /// rebuilds don't re-ask.
  final _asked = <String>{};
  String? _storageType;
  String _filter = '';

  @override
  void onShownAgain() => _asked.clear();

  void _request(String deviceId) =>
      ref.read(wsMessageHandlerProvider).requestStorage(deviceId);

  Future<void> _edit(
    DeviceInfo device,
    String storageType, {
    String? key,
    Object? original,
  }) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => EditKeyDialog(
        entryKey: key,
        value: key == null ? '' : storageValueText(original),
      ),
    );
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
    final p = ChromePalette.of(context);
    final target = ref.watch(storageTargetDeviceProvider);
    if (target == null) {
      return EmptyStateWithPulse(
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
    final names = stores.keys.toList();
    final storageType = stores.containsKey(_storageType)
        ? _storageType!
        : names.firstOrNull;
    final snapshot = storageType == null ? null : stores[storageType];
    final filter = _filter.toLowerCase();
    final entries =
        (snapshot?.entries.entries ?? const <MapEntry<String, Object?>>[])
            .where((e) => e.key.toLowerCase().contains(filter))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final head = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: p.textMuted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: storageType == null
                        ? const SizedBox.shrink()
                        : SegmentedTabs(
                            tabs: [
                              for (final name in names)
                                SegmentedTab(
                                  icon: LucideIcons.database,
                                  label: _storeName(name),
                                  count: stores[name]!.entries.length,
                                ),
                            ],
                            index: names.indexOf(storageType),
                            animate: !MediaQuery.disableAnimationsOf(context),
                            onSelect: (i) =>
                                setState(() => _storageType = names[i]),
                          ),
                  ),
                ),
              ),
              if (storageType != null) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: SearchField(
                    hintText: loc.storageKvFilter,
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: p.isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (storageType != null) ...[
                      IconBtn(
                        icon: LucideIcons.plus,
                        tooltip: loc.storageKvAdd,
                        onTap: () => _edit(target, storageType),
                      ),
                      const SizedBox(width: 2),
                    ],
                    IconBtn(
                      icon: LucideIcons.refreshCw,
                      tooltip: loc.storageKvRefresh,
                      onTap: () => _request(target.deviceId),
                    ),
                    if (storageType != null) ...[
                      const SizedBox(width: 2),
                      Container(width: 1, height: 18, color: p.border),
                      const SizedBox(width: 2),
                      IconBtn(
                        icon: LucideIcons.trash2,
                        tooltip: loc.storageKvClear,
                        isDanger: true,
                        onTap: () => _clear(target, storageType),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (snapshot?.error case final error?)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                ColorTokens.error.withValues(alpha: 0.10),
                p.surface,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorTokens.error.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.circleAlert,
                  size: 14,
                  color: ColorTokens.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    error,
                    style: TextStyle(fontSize: 12, height: 1.4, color: p.text),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: storageType == null
              ? EmptyStateWithPulse(
                  icon: LucideIcons.database,
                  title: loc.storageTabKeyValue,
                  subtitle: loc.storageKvEmpty,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 16, 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 240,
                            child: Text(
                              loc.storageKvKey.toUpperCase(),
                              style: head,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(loc.storageKvValue.toUpperCase(), style: head),
                        ],
                      ),
                    ),
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text(
                                filter.isNotEmpty
                                    ? loc.storageKvNoMatch
                                    : (snapshot?.error == null
                                          ? loc.noData
                                          : ''),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: p.textMuted,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                              itemCount: entries.length,
                              itemBuilder: (context, i) {
                                final MapEntry(:key, :value) = entries[i];
                                return KeyValueRow(
                                  key: ValueKey(key),
                                  entryKey: key,
                                  value: value,
                                  onEdit: () => _edit(
                                    target,
                                    storageType,
                                    key: key,
                                    original: value,
                                  ),
                                  onDelete: () => ref
                                      .read(wsMessageHandlerProvider)
                                      .deleteStorage(
                                        target.deviceId,
                                        storageType,
                                        key,
                                      ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
