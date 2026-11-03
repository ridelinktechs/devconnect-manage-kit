import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/theme_provider.dart';

enum ViewSegmentPosition { start, middle, end }

class ViewModeSegment extends StatelessWidget {
  final String label;
  final bool active;
  final ViewSegmentPosition position;
  final VoidCallback onTap;

  const ViewModeSegment({
    super.key,
    required this.label,
    required this.active,
    required this.position,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius radius;
    switch (position) {
      case ViewSegmentPosition.start:
        radius = const BorderRadius.only(
          topLeft: Radius.circular(5),
          bottomLeft: Radius.circular(5),
        );
        break;
      case ViewSegmentPosition.end:
        radius = const BorderRadius.only(
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(5),
        );
        break;
      case ViewSegmentPosition.middle:
        radius = BorderRadius.zero;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: active
                ? ColorTokens.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: active
                  ? ColorTokens.primary.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? ColorTokens.primary : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium 3-mode toggle (Tree / JSON / Code).
class ViewModeSwitcher extends ConsumerWidget {
  final BodyViewMode current;
  final String codeLabel;
  final ValueChanged<BodyViewMode> onChanged;

  const ViewModeSwitcher({
    super.key,
    required this.current,
    required this.codeLabel,
    required this.onChanged,
  });

  Alignment _alignmentFor(BodyViewMode mode) {
    switch (mode) {
      case BodyViewMode.tree:
        return Alignment.centerLeft;
      case BodyViewMode.json:
        return Alignment.center;
      case BodyViewMode.code:
        return Alignment.centerRight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF1C2128).withValues(alpha: 0.6)
        : const Color(0xFFEEF0F2);
    final trackBorder = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final thumbColor = isDark ? const Color(0xFF30363D) : Colors.white;
    final thumbShadow = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: trackBorder, width: 1),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _alignmentFor(current),
            duration: ref.watch(tabAnimationProvider),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: thumbShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _Segment(
                mode: BodyViewMode.tree,
                current: current,
                icon: LucideIcons.gitBranch,
                label: 'Tree',
                onTap: onChanged,
              ),
              _Segment(
                mode: BodyViewMode.json,
                current: current,
                icon: LucideIcons.braces,
                label: 'JSON',
                onTap: onChanged,
              ),
              _Segment(
                mode: BodyViewMode.code,
                current: current,
                icon: LucideIcons.code,
                label: codeLabel,
                onTap: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  final BodyViewMode mode;
  final BodyViewMode current;
  final IconData icon;
  final String label;
  final ValueChanged<BodyViewMode> onTap;

  const _Segment({
    required this.mode,
    required this.current,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.mode == widget.current;
    final color = isActive
        ? ColorTokens.primary
        : (isDark ? Colors.white60 : Colors.black54);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(widget.mode),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _hovered && !isActive
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 11, color: color),
                  const SizedBox(width: 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                      fontFamily: AppConstants.monoFontFamily,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Code viewer — renders the generator's output as two stacked panels:
//   1. "Types" — a define-file-style block of named type declarations
//      (TypeScript `interface`, Dart `class`, Kotlin `data class`).
//   2. "Code"  — the typed initializer for a `body` variable.
// Both panels share a VSCode-style syntax highlighter and have their
// own Copy button.
// ═══════════════════════════════════════════════════════════════════
