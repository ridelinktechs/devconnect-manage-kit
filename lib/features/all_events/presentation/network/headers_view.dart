import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/text/text_component.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/network/network_entry.dart';

/// Full network headers view: two sections (request / response) rendered
/// as bordered cards with a count badge and a list of [HeaderRowCopy] rows
/// underneath each.
class HeadersView extends StatefulWidget {
  final NetworkEntry entry;

  const HeadersView({super.key, required this.entry});

  @override
  State<HeadersView> createState() => _HeadersViewState();
}

class _HeadersViewState extends State<HeadersView> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderSection(
            icon: LucideIcons.arrowUpRight,
            iconColor: ColorTokens.primary,
            title: 'Request Headers',
            count: entry.requestHeaders.length,
            headers: entry.requestHeaders,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          HeaderSection(
            icon: LucideIcons.arrowDownLeft,
            iconColor: ColorTokens.success,
            title: 'Response Headers',
            count: entry.responseHeaders.length,
            headers: entry.responseHeaders,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// One request/response section card: title row with icon + count badge,
/// followed by a list of [HeaderRowCopy] rows.
class HeaderSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final Map<String, String> headers;
  final bool isDark;

  const HeaderSection({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.headers,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
          // Section header
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
          // Header rows
          if (headers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextComponent('No headers',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            )
          else
            ...headers.entries.toList().asMap().entries.map((entry) {
              final e = entry.value;
              final isLast = entry.key == headers.length - 1;
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
                child: HeaderRowCopy(
                  headerKey: e.key,
                  headerValue: e.value,
                  isDark: isDark,
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Flattened header list used inside screenshots (no per-row hover
/// controls, just key/value lines with VSCode-syntax colors).
class HeaderTable extends StatelessWidget {
  final Map<String, String> headers;
  final bool isScreenshot;

  const HeaderTable({super.key, required this.headers, this.isScreenshot = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (headers.isEmpty) {
      return TextComponent('No headers',
          style: TextStyle(color: Colors.grey[500], fontSize: 12));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: headers.entries.map((e) {
        if (isScreenshot) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 170,
                  child: TextComponent(e.key,
                      style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF9CDCFE)
                              : const Color(0xFF0451A5))),
                ),
                Expanded(
                  child: TextComponent(e.value,
                      style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFCE9178)
                              : const Color(0xFFA31515))),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: HeaderRowCopy(
            headerKey: e.key,
            headerValue: e.value,
            isDark: isDark,
          ),
        );
      }).toList(),
    );
  }
}

/// One header row with VSCode-syntax colors. Long values collapse to 4
/// lines with a fade gradient hint + a "Show more" pill button
/// underneath. The button has its own hover state and chevron icon.
/// On hover over the row, a copy icon fades in at the end of the row.
class HeaderRowCopy extends StatefulWidget {
  final String headerKey;
  final String headerValue;
  final bool isDark;

  const HeaderRowCopy({
    super.key,
    required this.headerKey,
    required this.headerValue,
    required this.isDark,
  });

  @override
  State<HeaderRowCopy> createState() => _HeaderRowCopyState();
}

class _HeaderRowCopyState extends State<HeaderRowCopy> {
  bool _rowHovered = false;
  bool _copied = false;
  bool _expanded = false;

  static const _maxCollapsedLines = 4;

  bool get _isLong => '\n'.allMatches(widget.headerValue).length >= 3 ||
      widget.headerValue.length > 120;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      color: widget.isDark
          ? const Color(0xFFCE9178)
          : const Color(0xFFA31515),
    );

    final bg = widget.isDark ? ColorTokens.darkBackground : Colors.white;

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
            child: TextComponent(
              widget.headerKey,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_expanded)
                  TextComponent(widget.headerValue, style: valueStyle)
                else
                  Stack(
                    children: [
                      TextComponent(
                        widget.headerValue,
                        style: valueStyle,
                        maxLines: _maxCollapsedLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isLong)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    bg.withValues(alpha: 0),
                                    bg,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                if (_isLong) ...[
                  const SizedBox(height: 6),
                  _ExpandToggleButton(
                    expanded: _expanded,
                    isDark: widget.isDark,
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ],
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: _rowHovered ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_rowHovered,
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '${widget.headerKey}: ${widget.headerValue}'));
                  setState(() => _copied = true);
                  showCopiedToast(context);
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
}

/// Pill-shaped toggle that says "Show more" / "Show less" with a
/// chevron icon. Isolated widget so its hover state doesn't bleed
/// into the row's copy-icon hover (and vice versa).
class _ExpandToggleButton extends StatefulWidget {
  final bool expanded;
  final bool isDark;
  final VoidCallback onTap;

  const _ExpandToggleButton({
    required this.expanded,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ExpandToggleButton> createState() => _ExpandToggleButtonState();
}

class _ExpandToggleButtonState extends State<_ExpandToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovered
        ? ColorTokens.primary.withValues(alpha: 0.14)
        : ColorTokens.primary.withValues(alpha: 0.07);
    final border = _hovered
        ? ColorTokens.primary.withValues(alpha: 0.45)
        : ColorTokens.primary.withValues(alpha: 0.22);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.expanded
                    ? S.of(context).collapse
                    : S.of(context).showMore,
                style: TextStyle(
                  fontSize: 10,
                  color: ColorTokens.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                widget.expanded
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                size: 10,
                color: ColorTokens.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}