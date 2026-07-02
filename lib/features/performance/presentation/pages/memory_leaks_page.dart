import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/performance/performance_entry.dart';
import '../../provider/performance_providers.dart';

class MemoryLeaksPage extends ConsumerStatefulWidget {
  const MemoryLeaksPage({super.key});

  @override
  ConsumerState<MemoryLeaksPage> createState() => _MemoryLeaksPageState();
}

class _MemoryLeaksPageState extends ConsumerState<MemoryLeaksPage> {
  MemoryLeakEntry? _selectedEntry;
  final _listScrollController = SmoothScrollController();

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = ref.watch(filteredMemoryLeakEntriesProvider);
    final counts = ref.watch(memoryLeakCountsProvider);

    return Column(
      children: [
        // Toolbar
        _Toolbar(
          isDark: isDark,
          counts: counts,
          onClear: () =>
              ref.read(memoryLeakEntriesProvider.notifier).clear(),
        ),
        // Content
        Expanded(
          child: entries.isEmpty
              ? EmptyState(
                  icon: LucideIcons.bug,
                  title: S.of(context).noMemoryLeaksDetected,
                  subtitle:
                      S.of(context).connectAppToMonitorLeaks,
                )
              : Row(
                  children: [
                    // Leak list
                    Expanded(
                      flex: 2,
                      child: _LeakList(
                        entries: entries,
                        selectedEntry: _selectedEntry,
                        isDark: isDark,
                        onSelect: (e) => setState(() => _selectedEntry = e),
                        controller: _listScrollController,
                      ),
                    ),
                    // Detail panel
                    if (_selectedEntry != null)
                      Container(
                        width: 1,
                        color: theme.dividerColor,
                      ),
                    if (_selectedEntry != null)
                      Expanded(
                        flex: 3,
                        child: _LeakDetail(
                          entry: _selectedEntry!,
                          isDark: isDark,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---- Toolbar ----

class _Toolbar extends StatelessWidget {
  final bool isDark;
  final Map<MemoryLeakSeverity, int> counts;
  final VoidCallback onClear;

  const _Toolbar({
    required this.isDark,
    required this.counts,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : ColorTokens.lightSurface,
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
          Icon(LucideIcons.bug, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text(
            S.of(context).memoryLeakDetection,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          _SeverityBadge(
            label: S.of(context).critical,
            count: counts[MemoryLeakSeverity.critical] ?? 0,
            color: ColorTokens.chartRed,
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _SeverityBadge(
            label: S.of(context).warning,
            count: counts[MemoryLeakSeverity.warning] ?? 0,
            color: ColorTokens.chartAmber,
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _SeverityBadge(
            label: S.of(context).info,
            count: counts[MemoryLeakSeverity.info] ?? 0,
            color: ColorTokens.chartBlue,
            isDark: isDark,
          ),
          const Spacer(),
          _MiniButton(
            icon: LucideIcons.trash2,
            tooltip: S.of(context).clear,
            isDark: isDark,
            onTap: onClear,
          ),
        ],
      ),
    );
  }
}

// ---- Severity Badge ----

class _SeverityBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _SeverityBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Leak List ----

class _LeakList extends StatelessWidget {
  final List<MemoryLeakEntry> entries;
  final MemoryLeakEntry? selectedEntry;
  final bool isDark;
  final ValueChanged<MemoryLeakEntry> onSelect;
  final ScrollController? controller;

  const _LeakList({
    required this.entries,
    required this.selectedEntry,
    required this.isDark,
    required this.onSelect,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: entries.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) {
        final entry = entries[entries.length - 1 - index]; // newest first
        final isSelected = selectedEntry?.id == entry.id;

        return GestureDetector(
          onTap: () => onSelect(entry),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : ColorTokens.primary.withValues(alpha: 0.06))
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? ColorTokens.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _severityIcon(entry.severity),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.objectName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.detail,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _leakTypeBadge(context, entry.leakType, isDark),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('HH:mm:ss').format(
                          DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _severityIcon(MemoryLeakSeverity severity) {
    final color = _severityColor(severity);
    final icon = severity == MemoryLeakSeverity.critical
        ? LucideIcons.circleAlert
        : severity == MemoryLeakSeverity.warning
            ? LucideIcons.triangleAlert
            : LucideIcons.info;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _leakTypeBadge(BuildContext context, MemoryLeakType type, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _leakTypeLabel(context, type),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}

// ---- Leak Detail ----

class _LeakDetail extends StatefulWidget {
  final MemoryLeakEntry entry;
  final bool isDark;

  const _LeakDetail({required this.entry, required this.isDark});

  @override
  State<_LeakDetail> createState() => _LeakDetailState();
}

class _LeakDetailState extends State<_LeakDetail> {
  final _contentKey = GlobalKey();
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _takeScreenshot() async {
    try {
      final boundary = _contentKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      final fileName =
          'devconnect_leak_${DateTime.now().millisecondsSinceEpoch}.png';
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG Image', extensions: ['png']),
        ],
      );
      if (location == null) return;
      await File(location.path).writeAsBytes(pngBytes);
      if (mounted) showScreenshotSavedToast(context, filePath: location.path);
    } catch (_) {
      if (mounted) showCopiedToast(context, label: S.of(context).screenshotFailed);
    }
  }


  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = widget.isDark;

    return Column(
      children: [
        // Header with screenshot + close
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.bug, size: 14, color: _severityColor(entry.severity)),
              const SizedBox(width: 8),
              TextComponent(
                entry.objectName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _severityColor(entry.severity),
                ),
              ),
              const Spacer(),
              _severityTag(entry.severity),
              const SizedBox(width: 8),
              Tooltip(
                message: S.of(context).captureAsImage,
                child: IconButton(
                  icon: Icon(LucideIcons.camera,
                      size: 14, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  onPressed: _takeScreenshot,
                  splashRadius: 14,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: RepaintBoundary(
            key: _contentKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _severityColor(entry.severity).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.bug,
                          size: 18,
                          color: _severityColor(entry.severity),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextComponent(
                              entry.objectName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            TextComponent(
                              _leakTypeLabel(context, entry.leakType),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _severityTag(entry.severity),
                    ],
                  ),
                  const SizedBox(height: 16),
          // Info cards
          _DetailSection(
            title: S.of(context).detail,
            icon: LucideIcons.fileText,
            isDark: isDark,
            child: TextComponent(
              entry.detail,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          if (entry.retainedSizeBytes != null) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: S.of(context).retainedSize,
              icon: LucideIcons.hardDrive,
              isDark: isDark,
              child: TextComponent(
                _formatBytes(entry.retainedSizeBytes!),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ColorTokens.chartRed,
                ),
              ),
            ),
          ],
          if (entry.stackTrace != null) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: S.of(context).stackTrace,
              icon: LucideIcons.layers,
              isDark: isDark,
              trailing: GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: entry.stackTrace ?? ''));
                  showCopiedToast(context, label: S.of(context).stackTraceCopied);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    LucideIcons.copy,
                    size: 13,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? ColorTokens.darkSurface
                      : ColorTokens.lightSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextComponent(
                  entry.stackTrace!,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
          if (entry.metadata != null && entry.metadata!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              title: S.of(context).metadata,
              icon: LucideIcons.braces,
              isDark: isDark,
              child: Column(
                children: entry.metadata!.entries.map((kv) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextComponent(
                          kv.key,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextComponent(
                            '${kv.value}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _DetailSection(
            title: S.of(context).timestamp,
            icon: LucideIcons.clock,
            isDark: isDark,
            child: TextComponent(
              DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(
                DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
              ),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _severityTag(MemoryLeakSeverity severity) {
    final color = _severityColor(severity);
    final label = severity.name.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ---- Detail Section ----

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Widget child;
  final Widget? trailing;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: isDark ? Colors.white38 : Colors.black26),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ---- Helpers ----

Color _severityColor(MemoryLeakSeverity severity) {
  switch (severity) {
    case MemoryLeakSeverity.critical:
      return ColorTokens.chartRed;
    case MemoryLeakSeverity.warning:
      return ColorTokens.chartAmber;
    case MemoryLeakSeverity.info:
      return ColorTokens.chartBlue;
  }
}

String _leakTypeLabel(BuildContext context, MemoryLeakType type) {
  switch (type) {
    case MemoryLeakType.undisposedController:
      return S.of(context).undisposedController;
    case MemoryLeakType.undisposedStream:
      return S.of(context).undisposedStream;
    case MemoryLeakType.undisposedTimer:
      return S.of(context).undisposedTimer;
    case MemoryLeakType.undisposedAnimationController:
      return S.of(context).undisposedAnimation;
    case MemoryLeakType.widgetLeak:
      return S.of(context).widgetLeak;
    case MemoryLeakType.growingCollection:
      return S.of(context).growingCollection;
    case MemoryLeakType.custom:
      return S.of(context).custom;
  }
}

// ---- Mini Button ----

class _MiniButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_MiniButton> createState() => _MiniButtonState();
}

class _MiniButtonState extends State<_MiniButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered
                  ? (widget.isDark ? Colors.white70 : Colors.black54)
                  : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}
