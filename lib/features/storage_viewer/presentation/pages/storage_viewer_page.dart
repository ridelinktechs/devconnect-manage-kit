import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../components/text/text_component.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../components/misc/jump_to_latest_fab.dart';
import '../../../../core/utils/position_retained_scroll_physics.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../server/providers/server_providers.dart';
import '../../provider/storage_providers.dart';

class StorageViewerPage extends ConsumerStatefulWidget {
  const StorageViewerPage({super.key});

  @override
  ConsumerState<StorageViewerPage> createState() => _StorageViewerPageState();
}

class _StorageViewerPageState extends ConsumerState<StorageViewerPage> {
  final ScrollController _scrollController = SmoothScrollController();
  final _entryCount = ValueNotifier<int>(0);
  bool _autoScroll = true;
  bool _programmaticScroll = false;
  int _visibleCount = 0;
  int _generation = 0;
  final List<StorageEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual(
      filteredStorageEntriesProvider,
      (previous, next) {
        // Storage has in-place updates (value changes for existing key).
        // Always full sync to ensure tiles reflect latest data.
        final grew = next.length > _entries.length;
        final shrunk = next.length < _entries.length;
        _entries..clear()..addAll(next);
        _entryCount.value = _entries.length;
        if (grew || shrunk || _autoScroll) _visibleCount = _entries.length;
        _generation++;
        setState(() {});
        if (_autoScroll) _autoScrollIfNeeded();
      },
      fireImmediately: true,
    );
    // Selection changes must also bump generation — StableBuilderDelegate
    // short-circuits shouldRebuild when generation is unchanged, which
    // would otherwise leave tile decorations (selected bg, accent border)
    // stuck on the previously-selected item.
    ref.listenManual<String?>(
      selectedStorageIdProvider,
      (_, _) {
        _generation++;
        setState(() {});
      },
      fireImmediately: false,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final reversed = ref.read(scrollDirectionProvider) == ScrollDirection.top;
    final atBottom = reversed
        ? pos.pixels <= pos.minScrollExtent + 2.0
        : pos.pixels >= pos.maxScrollExtent - 2.0;
    final distFromBottom = reversed
        ? pos.pixels - pos.minScrollExtent
        : pos.maxScrollExtent - pos.pixels;

    if (!_autoScroll && atBottom) {
      _autoScroll = true;
      _visibleCount = _entries.length;
      setState(() {});
      return;
    }

    if (_autoScroll && !_programmaticScroll && distFromBottom > 50.0) {
      _autoScroll = false;
      setState(() {});
      return;
    }

    if (!_autoScroll && _visibleCount < _entries.length) {
      if (distFromBottom < pos.viewportDimension * 1.5) {
        _visibleCount = _entries.length;
        setState(() {});
      }
    }
  }

  void _autoScrollIfNeeded() {
    if (!_autoScroll || _programmaticScroll) return;
    _programmaticScroll = true;
    _doAutoScroll();
  }

  void _doAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_autoScroll || !_scrollController.hasClients) {
        _programmaticScroll = false;
        return;
      }
      final reversed = ref.read(scrollDirectionProvider) == ScrollDirection.top;
      final pos = _scrollController.position;
      final target = reversed ? pos.minScrollExtent : pos.maxScrollExtent;
      final atTarget = reversed
          ? pos.pixels <= pos.minScrollExtent + 2.0
          : pos.pixels >= pos.maxScrollExtent - 2.0;
      if (atTarget) {
        _programmaticScroll = false;
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      ).whenComplete(() {
        if (!mounted || !_autoScroll || !_scrollController.hasClients) {
          _programmaticScroll = false;
          return;
        }
        final p = _scrollController.position;
        final done = reversed
            ? p.pixels <= p.minScrollExtent + 2.0
            : p.pixels >= p.maxScrollExtent - 2.0;
        if (!done) {
          _doAutoScroll();
        } else {
          _programmaticScroll = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _entryCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isReversed = scrollDir == ScrollDirection.top;

    return Column(
      children: [
        _Toolbar(
          totalCount: _entryCount,
          autoScroll: _autoScroll,
          onToggleAutoScroll: () {
            if (_autoScroll) {
              _autoScroll = false;
              _programmaticScroll = false;
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(_scrollController.offset);
              }
            } else {
              _autoScroll = true;
              _visibleCount = _entries.length;
              _autoScrollIfNeeded();
            }
            setState(() {});
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: _entries.isEmpty
              ? EmptyState(
                  icon: LucideIcons.database,
                  title: S.of(context).noStorageData,
                  subtitle:
                      S.of(context).storageEntriesAppearHere,
                )
              : Stack(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final selected = ref.watch(selectedStorageEntryProvider);
                        return Row(
                          children: [
                            // Key list
                            Expanded(
                              flex: 2,
                              child: ListView.custom(
                                controller: _scrollController,
                                reverse: isReversed,
                                physics: isReversed ? const PositionRetainedScrollPhysics() : null,
                                itemExtent: 58,
                                childrenDelegate: StableBuilderDelegate(
                                  generation: _generation,
                                  childCount: _visibleCount,
                                  findChildIndexCallback: (key) {
                                    if (key is ValueKey<String>) {
                                      final idx = _entries.indexWhere((e) => e.id == key.value);
                                      return idx == -1 ? null : idx;
                                    }
                                    return null;
                                  },
                                  builder: (context, index) {
                                    final entry = _entries[index];
                                    final isSelected = selected?.id == entry.id;
                                    return RepaintBoundary(
                                      key: ValueKey(entry.id),
                                      child: _StorageEntryTile(
                                        entry: entry,
                                        isSelected: isSelected,
                                        onTap: () {
                                          ref
                                              .read(selectedStorageIdProvider.notifier)
                                              .state = isSelected ? null : entry.id;
                                          if (!isSelected && _autoScroll) {
                                            _autoScroll = false;
                                            _programmaticScroll = false;
                                            if (_scrollController.hasClients) {
                                              _scrollController.jumpTo(_scrollController.offset);
                                            }
                                            setState(() {});
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (selected != null) ...[
                              VerticalDivider(width: 1, color: theme.dividerColor),
                              Expanded(
                                flex: 3,
                                child: _StorageDetailPanel(
                                  // Recycle the panel state when the entry
                                  // changes — without this, Flutter reuses
                                  // the State across entries, which can
                                  // leave the GestureDetector inside the
                                  // JsonPrettyViewer's deferred subtree in
                                  // a state that captures subsequent pointer
                                  // events.
                                  key: ValueKey(selected.id),
                                  entry: selected,
                                  onClose: () => ref
                                      .read(selectedStorageIdProvider.notifier)
                                      .state = null,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    PositionedJumpToLatestFab(
                      scrollController: _scrollController,
                      reversed: isReversed,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Toolbar extends ConsumerWidget {
  final ValueNotifier<int> totalCount;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  const _Toolbar({
    required this.totalCount,
    required this.autoScroll,
    required this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final opFilter = ref.watch(storageOperationFilterProvider);
    final typeFilter = ref.watch(storageTypeFilterProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Title + count pill
          Icon(LucideIcons.database, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('Storage', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: totalCount,
            builder: (_, c, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ColorTokens.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$c',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ColorTokens.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Operation segment group ──
          _SegmentGroup(isDark: isDark, children: [
            _SegmentChip(label: S.of(context).read, isActive: opFilter == 'read', color: ColorTokens.info, isMono: true, onTap: () => ref.read(storageOperationFilterProvider.notifier).state = opFilter == 'read' ? null : 'read'),
            _SegmentChip(label: S.of(context).write, isActive: opFilter == 'write', color: ColorTokens.success, isMono: true, onTap: () => ref.read(storageOperationFilterProvider.notifier).state = opFilter == 'write' ? null : 'write'),
            _SegmentChip(label: S.of(context).delete, isActive: opFilter == 'delete', color: ColorTokens.error, isMono: true, onTap: () => ref.read(storageOperationFilterProvider.notifier).state = opFilter == 'delete' ? null : 'delete'),
          ]),
          const SizedBox(width: 10),

          // ── Type segment group ──
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _SegmentGroup(isDark: isDark, children: [
                _SegmentChip(label: 'AS', isActive: typeFilter.contains(StorageType.asyncStorage), color: const Color(0xFF61DAFB), isMono: true, onTap: () => _toggleType(ref, StorageType.asyncStorage)),
                _SegmentChip(label: 'SP', isActive: typeFilter.contains(StorageType.sharedPreferences), color: const Color(0xFF3DDC84), isMono: true, onTap: () => _toggleType(ref, StorageType.sharedPreferences)),
                _SegmentChip(label: 'HV', isActive: typeFilter.contains(StorageType.hive), color: const Color(0xFFFFC107), isMono: true, onTap: () => _toggleType(ref, StorageType.hive)),
                _SegmentChip(label: 'SQL', isActive: typeFilter.contains(StorageType.sqlite), color: const Color(0xFF003B57), isMono: true, onTap: () => _toggleType(ref, StorageType.sqlite)),
                _SegmentChip(label: 'RLM', isActive: typeFilter.contains(StorageType.realm), color: const Color(0xFF39477F), isMono: true, onTap: () => _toggleType(ref, StorageType.realm)),
                _SegmentChip(label: 'MKV', isActive: typeFilter.contains(StorageType.mmkv), color: const Color(0xFFFF6F00), isMono: true, onTap: () => _toggleType(ref, StorageType.mmkv)),
                _SegmentChip(label: 'OBX', isActive: typeFilter.contains(StorageType.objectbox), color: const Color(0xFF00C853), isMono: true, onTap: () => _toggleType(ref, StorageType.objectbox)),
                _SegmentChip(label: 'SQF', isActive: typeFilter.contains(StorageType.sqflite), color: const Color(0xFF1565C0), isMono: true, onTap: () => _toggleType(ref, StorageType.sqflite)),
                _SegmentChip(label: 'ENC', isActive: typeFilter.contains(StorageType.encryptedStorage), color: const Color(0xFFE91E63), isMono: true, onTap: () => _toggleType(ref, StorageType.encryptedStorage)),
              ]),
            ),
          ),

          const Spacer(),

          // Search field
          SizedBox(
            width: 200,
            child: SearchField(
              hintText: S.of(context).filterKeys,
              onChanged: (v) =>
                  ref.read(storageSearchProvider.notifier).state = v,
            ),
          ),
          const SizedBox(width: 12),

          // Action group
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBtn(
                  icon: LucideIcons.arrowDownToLine,
                  tooltip: S.of(context).autoScroll,
                  isActive: autoScroll,
                  onTap: onToggleAutoScroll,
                ),
                const SizedBox(width: 2),
                Consumer(
                  builder: (context, ref, _) {
                    final dir = ref.watch(scrollDirectionProvider);
                    final isTop = dir == ScrollDirection.top;
                    return _IconBtn(
                      icon: isTop
                          ? LucideIcons.arrowUpNarrowWide
                          : LucideIcons.arrowDownNarrowWide,
                      tooltip: isTop ? S.of(context).newestFirst : S.of(context).oldestFirst,
                      isActive: isTop,
                      onTap: () =>
                          ref.read(scrollDirectionProvider.notifier).state =
                              isTop ? ScrollDirection.bottom : ScrollDirection.top,
                    );
                  },
                ),
                const SizedBox(width: 2),
                Container(
                  width: 1,
                  height: 18,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 2),
                _IconBtn(
                  icon: LucideIcons.trash2,
                  tooltip: S.of(context).clearAll,
                  isDanger: true,
                  onTap: () =>
                      ref.read(storageEntriesProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleType(WidgetRef ref, StorageType type) {
    final current = ref.read(storageTypeFilterProvider);
    if (current.contains(type)) {
      ref.read(storageTypeFilterProvider.notifier).state =
          current.difference({type});
    } else {
      ref.read(storageTypeFilterProvider.notifier).state = {...current, type};
    }
  }
}

class _SegmentGroup extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SegmentGroup({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SegmentChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color color;
  final bool isMono;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.isActive,
    required this.color,
    this.isMono = false,
    required this.onTap,
  });

  @override
  State<_SegmentChip> createState() => _SegmentChipState();
}

class _SegmentChipState extends State<_SegmentChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.color.withValues(alpha: 0.15)
                : _hovered
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: widget.isMono ? AppConstants.monoFontFamily : null,
                fontSize: 10,
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isActive
                    ? widget.color
                    : isDark
                        ? Colors.grey[500]
                        : Colors.grey[600],
                letterSpacing: widget.isMono ? 0.3 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isDanger;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    Color bgColor;

    if (widget.isActive) {
      iconColor = ColorTokens.primary;
      bgColor = ColorTokens.primary.withValues(alpha: 0.15);
    } else if (widget.isDanger && _hovered) {
      iconColor = ColorTokens.error;
      bgColor = ColorTokens.error.withValues(alpha: 0.12);
    } else if (_hovered) {
      iconColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06);
    } else {
      iconColor = Colors.grey[500]!;
      bgColor = Colors.transparent;
    }

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _StorageEntryTile extends StatelessWidget {
  final StorageEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _StorageEntryTile({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  static Color _typeColor(StorageType type) {
    switch (type) {
      case StorageType.asyncStorage: return const Color(0xFF61DAFB);
      case StorageType.sharedPreferences: return const Color(0xFF3DDC84);
      case StorageType.hive: return const Color(0xFFFFC107);
      case StorageType.sqlite: return const Color(0xFF003B57);
      case StorageType.realm: return const Color(0xFF39477F);
      case StorageType.objectbox: return const Color(0xFF00C853);
      case StorageType.floor: return const Color(0xFF607D8B);
      case StorageType.sembast: return const Color(0xFF8D6E63);
      case StorageType.sqflite: return const Color(0xFF1565C0);
      case StorageType.watermelondb: return const Color(0xFF4CAF50);
      case StorageType.encryptedStorage: return const Color(0xFFE91E63);
      case StorageType.sqldelight: return const Color(0xFF0288D1);
      case StorageType.mmkv: return const Color(0xFFFF6F00);
    }
  }

  static String _typeLabel(StorageType type) {
    switch (type) {
      case StorageType.asyncStorage: return 'AS';
      case StorageType.sharedPreferences: return 'SP';
      case StorageType.hive: return 'HV';
      case StorageType.sqlite: return 'SQL';
      case StorageType.realm: return 'RLM';
      case StorageType.objectbox: return 'OBX';
      case StorageType.floor: return 'FLR';
      case StorageType.sembast: return 'SMB';
      case StorageType.sqflite: return 'SQF';
      case StorageType.watermelondb: return 'WDB';
      case StorageType.encryptedStorage: return 'ENC';
      case StorageType.sqldelight: return 'SDL';
      case StorageType.mmkv: return 'MKV';
    }
  }

  static Color _opColor(String op) {
    switch (op.toLowerCase()) {
      case 'write': return ColorTokens.success;
      case 'delete':
      case 'clear': return ColorTokens.error;
      default: return ColorTokens.info;
    }
  }

  String _valuePreview() {
    final v = entry.value;
    if (v == null) return 'null';
    if (v is Map || v is List) {
      final s = jsonEncode(v);
      return s.length > 80 ? '${s.substring(0, 80)}...' : s;
    }
    final s = v.toString();
    return s.length > 80 ? '${s.substring(0, 80)}...' : s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );
    final tColor = _typeColor(entry.storageType);
    final opColor = _opColor(entry.operation);

    return GestureDetector(
      onTap: onTap,
      // Opaque hit-testing so taps land on the tile's full area — without
      // this, an outer MouseRegion can swallow the hit for hover handling
      // before the GestureDetector sees it, breaking subsequent taps after
      // a rebuild.
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 58,
          padding: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorTokens.selectedBg(isDark)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              left: BorderSide(
                color: isSelected ? ColorTokens.selectedAccent : tColor,
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              // Timestamp
              SizedBox(
                width: 84,
                child: Text(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 10,
                    color: Colors.grey[500],
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              // Operation badge
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: opColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    entry.operation.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: opColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Storage type badge
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: tColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    _typeLabel(entry.storageType),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: tColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Key + value preview
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : ColorTokens.darkNeutral,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _valuePreview(),
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageDetailPanel extends ConsumerStatefulWidget {
  final StorageEntry entry;
  final VoidCallback onClose;

  const _StorageDetailPanel({
    super.key,
    required this.entry,
    required this.onClose,
  });

  @override
  ConsumerState<_StorageDetailPanel> createState() => _StorageDetailPanelState();
}

class _StorageDetailPanelState extends ConsumerState<_StorageDetailPanel> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  StorageEntry get entry => widget.entry;

  /// Stats used by the metadata footer + the JSON-mode empty state.
  String _valueStats() {
    final v = entry.value;
    if (v == null) return 'null';
    if (v is Map) {
      final n = v.length;
      return '$n ${n == 1 ? 'key' : 'keys'} · ${v.values.length} values';
    }
    if (v is List) return '${v.length} items';
    final s = v.toString();
    if (s.length > 24) return '${s.length} chars';
    return s;
  }

  String _sizeLabel() {
    final v = entry.value;
    if (v == null) return '0 B';
    final raw = v is String ? v : jsonEncode(v);
    return AppConstants.formatBytes(raw.length);
  }

  void _takeScreenshot(BuildContext context, bool isDark) {
    final mode = ref.read(bodyViewModeProvider);
    final isAlreadyJson = entry.value is Map || entry.value is List;
    dynamic parsedJson;
    if (!isAlreadyJson && entry.value is String) {
      try {
        parsedJson = jsonDecode(entry.value as String);
        if (parsedJson is! Map && parsedJson is! List) parsedJson = null;
      } catch (_) {}
    }

    final displayValue = isAlreadyJson
        ? entry.value
        : (parsedJson ?? entry.value);
    final usePrettyJson = mode == BodyViewMode.json;
    final useTree = mode == BodyViewMode.tree;

    final screenshotWidget = Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextComponent(S.of(context).key,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 4),
          TextComponent(entry.key,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorTokens.primary,
              )),
          const SizedBox(height: 16),
          TextComponent(S.of(context).value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 4),
          if (usePrettyJson)
            JsonPrettyViewer(data: displayValue)
          else if (useTree)
            JsonViewer(data: displayValue, initiallyExpanded: true)
          else
            _screenshotCodeView(displayValue),
          const SizedBox(height: 16),
          TextComponent(S.of(context).metadata,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 4),
          TextComponent(
              'Type: ${entry.storageType.name}  |  Operation: ${entry.operation}',
              style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
    captureWidgetAsImage(context, screenshotWidget);
  }

  Widget _screenshotCodeView(dynamic displayValue) {
    final devices = ref.read(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final lang = CodeGenerator.langForPlatform(platform);
    final generated =
        CodeGenerator.generate(displayValue, lang);
    return CodeViewer(
      generated: generated,
      lang: lang,
      languageLabel: CodeGenerator.labelFor(lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );
    final mode = ref.watch(bodyViewModeProvider);

    final devices = ref.watch(connectedDevicesProvider);
    final platform = devices
            .where((d) => d.deviceId == entry.deviceId)
            .map((d) => d.platform)
            .firstOrNull ??
        'react_native';
    final codeLang = CodeGenerator.langForPlatform(platform);
    final codeLabel = CodeGenerator.labelFor(codeLang);

    final opColor = _StorageEntryTile._opColor(entry.operation);
    final tColor = _StorageEntryTile._typeColor(entry.storageType);

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: isDark ? ColorTokens.darkBackground : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.database, size: 14, color: ColorTokens.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextComponent(
                        entry.key,
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _DetailIconBtn(
                      icon: LucideIcons.camera,
                      tooltip: S.of(context).captureAsImage,
                      isDark: isDark,
                      onTap: () => _takeScreenshot(context, isDark),
                    ),
                    const SizedBox(width: 4),
                    _DetailIconBtn(
                      icon: LucideIcons.x,
                      tooltip: S.of(context).close,
                      isDark: isDark,
                      onTap: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MetaChip(
                      icon: _opIcon(entry.operation),
                      label: entry.operation.toUpperCase(),
                      color: opColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _MetaChip(
                      icon: LucideIcons.database,
                      label: entry.storageType.name,
                      color: tColor,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _MetaChip(
                      icon: LucideIcons.clock,
                      label: time,
                      color: Colors.grey,
                      isDark: isDark,
                      isMono: true,
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: AsyncJsonParser(
              rawData: entry.value,
              builder: (context, parsedJson, isJson) {
                final isAlreadyJson =
                    entry.value is Map || entry.value is List;
                // For Tree/JSON: prefer the parsed JSON when available so
                // string-encoded JSON renders correctly in both modes.
                final displayValue = isAlreadyJson
                    ? entry.value
                    : (parsedJson ?? entry.value);

                // Plain text payload: skip the 3-mode toggle entirely and
                // show the raw value as a single styled block. Users can
                // still copy via the icon-button in the header.
                if (!isJson) {
                  return SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextComponent(
                              'Value',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MetaChip(
                              icon: LucideIcons.hardDrive,
                              label: _sizeLabel(),
                              color: Colors.grey,
                              isDark: isDark,
                              isMono: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: SelectableText(
                            entry.value?.toString() ?? 'null',
                            style: TextStyle(
                              fontFamily: AppConstants.monoFontFamily,
                              fontSize: 12,
                              height: 1.6,
                              color: isDark
                                  ? const Color(0xFFD4D4D4)
                                  : const Color(0xFF1F2328),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _MetaDivider(),
                        const SizedBox(height: 12),
                        _MetadataFooter(
                        entry: entry,
                        isDark: isDark,
                        stats: _valueStats(),
                      ),
                    ],
                  ),
                );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          TextComponent(
                            'Value',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _MetaChip(
                            icon: LucideIcons.hardDrive,
                            label: _sizeLabel(),
                            color: Colors.grey,
                            isDark: isDark,
                            isMono: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // View switcher (own row so its inner Expanded row gets
                      // a real width — placing it inside a parent Row collapsed
                      // the Container's intrinsic width to ~0, hiding it).
                      SizedBox(
                        width: double.infinity,
                        child: ViewModeSwitcher(
                          current: mode,
                          codeLabel: codeLabel,
                          onChanged: (BodyViewMode m) =>
                              ref.read(bodyViewModeProvider.notifier).set(m),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DeferredBuilder(
                        key: ValueKey(mode),
                        builder: (_) {
                          switch (mode) {
                            case BodyViewMode.tree:
                              return JsonViewer(
                                data: displayValue,
                                initiallyExpanded: true,
                              );
                            case BodyViewMode.json:
                              return JsonPrettyViewer(data: displayValue);
                            case BodyViewMode.code:
                              return CodeViewer(
                                generated: CodeGenerator.generate(
                                  displayValue,
                                  codeLang,
                                ),
                                lang: codeLang,
                                languageLabel: codeLabel,
                              );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      const _MetaDivider(),
                      const SizedBox(height: 12),
                      _MetadataFooter(
                        entry: entry,
                        isDark: isDark,
                        stats: _valueStats(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _opIcon(String op) {
    switch (op.toLowerCase()) {
      case 'write':
        return LucideIcons.pencilLine;
      case 'delete':
      case 'clear':
        return LucideIcons.trash2;
      default:
        return LucideIcons.eye;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isMono;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color == Colors.grey
            ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04))
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color == Colors.grey ? Colors.grey[500] : color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: isMono ? AppConstants.monoFontFamily : null,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color == Colors.grey ? Colors.grey[500] : color,
              letterSpacing: isMono ? -0.1 : 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        TextComponent(
          'Metadata',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _MetadataFooter extends StatelessWidget {
  final StorageEntry entry;
  final bool isDark;
  final String stats;

  const _MetadataFooter({
    required this.entry,
    required this.isDark,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final valueColor = isDark ? Colors.white70 : Colors.black87;
    final monoStyle = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      color: valueColor,
    );

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: monoStyle,
                  softWrap: true,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Type', entry.storageType.name),
        row('Operation', entry.operation),
        row('Shape', stats),
        row('Device', entry.deviceId),
      ],
    );
  }
}

class _DetailIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _DetailIconBtn({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 13, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}
