import 'dart:io';

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/text/text_component.dart';
import '../constants/app_constants.dart';
import '../theme/color_tokens.dart';

/// Show a screenshot saved toast with "Reveal in Finder" button.
///
/// Matches the fancy format used in Network Inspector detail.
void showScreenshotSavedToast(BuildContext context, {required String filePath}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Transform.scale(
                scale: 0.92 + 0.08 * value,
                child: child,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A24) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: ColorTokens.success.withValues(alpha: 0.08),
                      blurRadius: 40,
                      spreadRadius: -4,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top accent bar
                  Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ColorTokens.success.withValues(alpha: 0.0),
                          ColorTokens.success,
                          ColorTokens.success.withValues(alpha: 0.0),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(
                      children: [
                        // Success icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorTokens.success.withValues(alpha: 0.2),
                                ColorTokens.success.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: ColorTokens.success.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.checkCheck,
                            size: 18,
                            color: ColorTokens.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextComponent(
                                S.of(context).screenshotSaved,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? ColorTokens.lightBackground
                                      : const Color(0xFF1E293B),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextComponent(
                                filePath.split('/').last,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: AppConstants.monoFontFamily,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reveal button
                        GestureDetector(
                          onTap: () {
                            entry.remove();
                            Process.run('open', ['-R', filePath]);
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF1A2332),
                                          const Color(0xFF1E2A3A),
                                        ]
                                      : [
                                          const Color(0xFFF0F4F8),
                                          const Color(0xFFE8EDF2),
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.folderOpen,
                                    size: 13,
                                    color: isDark
                                        ? ColorTokens.lightBackground
                                        : const Color(0xFF374151),
                                  ),
                                  const SizedBox(width: 6),
                                  TextComponent(
                                    S.of(context).reveal,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? ColorTokens.lightBackground
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Close button
                        GestureDetector(
                          onTap: () => entry.remove(),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                              child: Icon(LucideIcons.x,
                                  size: 13,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 4), () {
    if (entry.mounted) entry.remove();
  });
}

/// Show a custom "Copied" toast notification.
///
/// Usage:
/// ```dart
/// showCopiedToast(context, label: 'JSON copied');
/// ```
void showCopiedToast(BuildContext context, {String? label}) {
  _showCustomToast(
    context,
    icon: LucideIcons.checkCheck,
    label: label ?? S.of(context).copied,
    accentColor: ColorTokens.success,
  );
}

/// Internal: show a custom animated toast via Overlay.
void _showCustomToast(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color accentColor,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastWidget(
      icon: icon,
      label: label,
      accentColor: accentColor,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Auto dismiss after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A24) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.06),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top accent bar
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 48),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.accentColor.withValues(alpha: 0.0),
                            widget.accentColor,
                            widget.accentColor.withValues(alpha: 0.0),
                          ],
                        ),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(14)),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.accentColor.withValues(alpha: 0.2),
                                  widget.accentColor.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    widget.accentColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              size: 14,
                              color: widget.accentColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppConstants.monoFontFamily,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
