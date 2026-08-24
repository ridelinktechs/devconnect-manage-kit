import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';

/// Query-parameter tab used inside the all-events detail view. Same
/// shape as the inspector variant: one bordered card with a title bar
/// (icon + count badge) and a list of [ParamRow] rows underneath.
///
/// Per-key values: `?a=1&a=2` arrives as `["1","2"]` from
/// `Uri.queryParametersAll`. Joining with `", "` would conflate a
/// comma inside a value with the value boundary, so each value
/// renders on its own line with a `#N` chip.
class ParamsTab extends StatefulWidget {
  final Uri uri;

  const ParamsTab({super.key, required this.uri});

  @override
  State<ParamsTab> createState() => _ParamsTabState();
}

class _ParamsTabState extends State<ParamsTab> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = widget.uri.queryParametersAll.entries.toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: ParamsSection(
        icon: LucideIcons.arrowDownRight,
        iconColor: ColorTokens.primary,
        title: 'Query Parameters',
        count: entries.length,
        entries: entries,
        isDark: isDark,
      ),
    );
  }
}

/// Section card: title bar with icon + count, list of [ParamRow] rows.
class ParamsSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final List<MapEntry<String, List<String>>> entries;
  final bool isDark;

  const ParamsSection({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.entries,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? ColorTokens.darkBackground : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: EmptyState(
              icon: LucideIcons.list,
              title: 'No params',
            ),
          ),
        ),
      );
    }

    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2128) : ColorTokens.lightSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
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
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 8),
                TextComponent(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextComponent(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...entries.asMap().entries.map((item) {
            final e = item.value;
            final isLast = item.key == entries.length - 1;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
              child: ParamRow(
                keyName: e.key,
                values: e.value,
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// One param row. Fixed-width key column, expanded values column,
/// reserved copy slot. Multi-value rows render values stacked
/// vertically with `#N` chips.
class ParamRow extends StatefulWidget {
  final String keyName;
  final List<String> values;
  final bool isDark;

  const ParamRow({
    super.key,
    required this.keyName,
    required this.values,
    required this.isDark,
  });

  @override
  State<ParamRow> createState() => _ParamRowState();
}

class _ParamRowState extends State<ParamRow> {
  bool _rowHovered = false;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 12,
      color: widget.isDark
          ? const Color(0xFFCE9178)
          : const Color(0xFFA31515),
      height: 1.4,
    );

    final single = widget.values.length == 1;
    final autoSplit =
        single ? _splitIfList(widget.values.first) : <String>[];
    final copyPayload = single
        ? '${widget.keyName}=${widget.values.first}'
        : '${widget.keyName}=${widget.values.join('&${widget.keyName}=')}';

    return MouseRegion(
      onEnter: (_) => setState(() => _rowHovered = true),
      onExit: (_) => setState(() {
        _rowHovered = false;
        _copied = false;
      }),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                widget.keyName,
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? const Color(0xFF9CDCFE)
                      : const Color(0xFF0451A5),
                ),
              ),
            ),
          ),
          Expanded(
            child: single && autoSplit.isEmpty
                ? SelectableText(widget.values.first, style: valueStyle)
                : _ChipsList(
                    items: autoSplit.isNotEmpty
                        ? autoSplit
                        : widget.values,
                    valueStyle: valueStyle,
                  ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: _rowHovered ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_rowHovered,
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: copyPayload));
                  setState(() => _copied = true);
                  showCopiedToast(context, label: 'Param copied');
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, top: 1),
                    child: Icon(
                      _copied ? LucideIcons.check : LucideIcons.copy,
                      size: 12,
                      color: _copied
                          ? ColorTokens.success
                          : (widget.isDark ? Colors.white38 : Colors.black26),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Treat a single value as a CSV-like list when it has ≥4 comma
  /// tokens and none of them contain whitespace. Lets a value like
  /// `"id,document_key,document_type,..."` render as one token per
  /// row (each selectable) instead of one tall wrapped block.
  static List<String> _splitIfList(String value) {
    if (!value.contains(',')) return const [];
    final parts = value
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 4) return const [];
    final hasInternalSpace = parts.any((p) => p.contains(RegExp(r'\s')));
    if (hasInternalSpace) return const [];
    return parts;
  }
}

/// Numbered list rendering shared by the `?a=1&a=2` multi-value
/// case and the auto-split single-value CSV case.
class _ChipsList extends StatelessWidget {
  final List<String> items;
  final TextStyle valueStyle;

  const _ChipsList({
    required this.items,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 3, right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: ColorTokens.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '#${i + 1}',
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.primary,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(items[i], style: valueStyle),
              ),
            ],
          ),
        ],
      ],
    );
  }
}