import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../components/feedback/empty_state.dart';
import '../../../../components/inputs/search_field.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/screenshot_utils.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../models/storage/storage_entry.dart';
import '../../../../components/lists/stable_list_view.dart';
import '../../../../core/utils/position_retained_scroll_physics.dart';
import '../../provider/storage_providers.dart';

class StorageViewerPage extends ConsumerStatefulWidget {
  const StorageViewerPage({super.key});

  @override
  ConsumerState<StorageViewerPage> createState() => _StorageViewerPageState();
}

class _StorageViewerPageState extends ConsumerState<StorageViewerPage> {
  final ScrollController _scrollController = ScrollController();
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
        _entries..clear()..addAll(next);
        _entryCount.value = _entries.length;
        if (grew) _visibleCount = _entries.length;
        _generation++;
        setState(() {});
        if (_autoScroll) _autoScrollIfNeeded();
      },
      fireImmediately: true,
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
              ? const EmptyState(
                  icon: LucideIcons.database,
                  title: 'No storage data',
                  subtitle:
                      'SharedPreferences, AsyncStorage, and Hive entries appear here',
                )
              : Consumer(
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
                            itemExtent: 44,
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

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.database, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text('Storage', style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: totalCount,
            builder: (_, c, __) => Text('$c keys', style: theme.textTheme.bodySmall),
          ),
          const Spacer(),
          SizedBox(
            width: 200,
            child: SearchField(
              hintText: 'Filter keys...',
              onChanged: (v) =>
                  ref.read(storageSearchProvider.notifier).state = v,
            ),
          ),
          const SizedBox(width: 12),
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
                  tooltip: 'Auto-scroll',
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
                      tooltip: isTop ? 'Newest first' : 'Oldest first',
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
                  tooltip: 'Clear all',
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
    }
  }

  static String _typeLabel(StorageType type) {
    switch (type) {
      case StorageType.asyncStorage: return 'AS';
      case StorageType.sharedPreferences: return 'SP';
      case StorageType.hive: return 'HV';
      case StorageType.sqlite: return 'SQL';
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 44,
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
              // Key name
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    color: isDark
                        ? ColorTokens.lightBackground
                        : ColorTokens.darkNeutral,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageDetailPanel extends StatefulWidget {
  final StorageEntry entry;
  final VoidCallback onClose;

  const _StorageDetailPanel({required this.entry, required this.onClose});

  @override
  State<_StorageDetailPanel> createState() => _StorageDetailPanelState();
}

class _StorageDetailPanelState extends State<_StorageDetailPanel> {
  bool _formatted = false;
  bool _jsonMode = false;
  bool _jsonEverOpened = false;

  StorageEntry get entry => widget.entry;

  void _takeScreenshot(BuildContext context, bool isDark) {
    final isAlreadyJson = entry.value is Map || entry.value is List;
    final parsedJson = isAlreadyJson ? null : _tryParseJson(entry.value);

    final screenshotWidget = Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(entry.key,
              style: TextStyle(
                fontFamily: AppConstants.monoFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorTokens.primary,
              )),
          if (entry.value != null) ...[
            const SizedBox(height: 16),
            Text('Value',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500])),
            const SizedBox(height: 4),
            if (isAlreadyJson)
              JsonViewer(data: entry.value, initiallyExpanded: true)
            else if (_formatted && parsedJson != null)
              JsonViewer(data: parsedJson, initiallyExpanded: true)
            else
              JsonViewer(data: entry.value, initiallyExpanded: false),
          ],
          const SizedBox(height: 16),
          Text('Metadata',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(
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

  dynamic _tryParseJson(dynamic value) {
    if (value is! String) return null;
    try {
      final parsed = jsonDecode(value);
      if (parsed is Map || parsed is List) return parsed;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );

    final isAlreadyJson = entry.value is Map || entry.value is List;
    final parsedJson = isAlreadyJson ? null : _tryParseJson(entry.value);
    final canFormat = parsedJson != null;

    final opColor = _StorageEntryTile._opColor(entry.operation);
    final tColor = _StorageEntryTile._typeColor(entry.storageType);

    return Container(
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Column(
        children: [
          // Header
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                Icon(LucideIcons.database, size: 14, color: ColorTokens.primary),
                const SizedBox(width: 8),
                // Operation badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: opColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.operation.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: opColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: tColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.storageType.name,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: tColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 10),
                _DetailIconBtn(
                  icon: LucideIcons.camera,
                  tooltip: 'Capture',
                  isDark: isDark,
                  onTap: () => _takeScreenshot(context, isDark),
                ),
                const SizedBox(width: 4),
                _DetailIconBtn(
                  icon: LucideIcons.x,
                  tooltip: 'Close',
                  isDark: isDark,
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Value section
                  Row(
                    children: [
                      Text('Value', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      if (isAlreadyJson || (canFormat && _formatted && parsedJson != null)) ...[
                        _ViewModeToggle(
                          isJsonMode: _jsonMode,
                          onToggle: () => setState(() {
                            _jsonMode = !_jsonMode;
                            if (_jsonMode) _jsonEverOpened = true;
                          }),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (canFormat && !isAlreadyJson)
                        _FormatToggle(
                          isFormatted: _formatted,
                          onToggle: () =>
                              setState(() => _formatted = !_formatted),
                          isDark: isDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_jsonMode && (isAlreadyJson || (_formatted && parsedJson != null))) ...[
                    if (_jsonEverOpened)
                      JsonPrettyViewer(data: isAlreadyJson ? entry.value : parsedJson),
                  ] else ...[
                    if (isAlreadyJson)
                      JsonViewer(data: entry.value, initiallyExpanded: true)
                    else if (_formatted && parsedJson != null)
                      JsonViewer(data: parsedJson, initiallyExpanded: true)
                    else
                      JsonViewer(data: entry.value, initiallyExpanded: false),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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

class _ViewModeToggle extends StatelessWidget {
  final bool isJsonMode;
  final VoidCallback onToggle;
  final bool isDark;

  const _ViewModeToggle({
    required this.isJsonMode,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isJsonMode
                ? ColorTokens.primary.withValues(alpha: 0.15)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isJsonMode ? LucideIcons.braces : LucideIcons.list,
                size: 12,
                color: isJsonMode ? ColorTokens.primary : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                isJsonMode ? 'JSON' : 'Tree',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isJsonMode ? ColorTokens.primary : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatToggle extends StatelessWidget {
  final bool isFormatted;
  final VoidCallback onToggle;
  final bool isDark;

  const _FormatToggle({
    required this.isFormatted,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isFormatted
                ? ColorTokens.primary.withValues(alpha: 0.15)
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.braces,
                size: 12,
                color: isFormatted ? ColorTokens.primary : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                isFormatted ? 'Raw' : 'Format',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isFormatted ? ColorTokens.primary : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
