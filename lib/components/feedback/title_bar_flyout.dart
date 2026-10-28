import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/sdk_versions_provider.dart';
import '../../core/theme/chrome_palette.dart';
import '../../core/utils/sdk_version.dart';
import '../../l10n/app_localizations.dart';

/// A title-bar pill that previews a popover on hover and pins it on click
/// (or Enter/Space); Esc or a click outside closes a pinned one. The
/// popover fades/scales out of the pill instead of resizing it, so the
/// title bar never reflows mid-animation.
class TitleBarFlyout extends StatefulWidget {
  final String semanticLabel;

  /// Line the popover up with the pill's right edge (for a pill at the
  /// right of the title bar) instead of its left.
  final bool alignRight;

  final Widget Function(bool open, bool focusRing) pill;
  final WidgetBuilder popover;

  /// Called each time the popover opens — a chance to refresh its data.
  final VoidCallback? onOpen;

  const TitleBarFlyout({
    super.key,
    required this.semanticLabel,
    required this.pill,
    required this.popover,
    this.alignRight = false,
    this.onOpen,
  });

  @override
  State<TitleBarFlyout> createState() => _TitleBarFlyoutState();
}

class _TitleBarFlyoutState extends State<TitleBarFlyout> {
  final _focusNode = FocusNode(debugLabel: 'TitleBarFlyout');
  Timer? _closeTimer;
  bool _hovered = false;
  bool _pinned = false;
  bool _focusRing = false;

  bool get _open => _hovered || _pinned;

  @override
  void dispose() {
    _closeTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _set({bool? hovered, bool? pinned}) {
    final wasOpen = _open;
    setState(() {
      _hovered = hovered ?? _hovered;
      _pinned = pinned ?? _pinned;
    });
    if (!wasOpen && _open) widget.onOpen?.call();
  }

  void _onEnter() {
    _closeTimer?.cancel();
    if (!_hovered) _set(hovered: true);
  }

  // Grace period so crossing the gap between pill and popover (or a
  // slightly diagonal mouse path) doesn't flicker it shut.
  void _onExit() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) _set(hovered: false);
    });
  }

  void _togglePin() {
    _focusNode.requestFocus(); // so Esc can close it
    _set(pinned: !_pinned);
  }

  void _close() {
    _closeTimer?.cancel();
    _set(hovered: false, pinned: false);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final anchor = widget.alignRight ? Alignment.topRight : Alignment.topLeft;
    return TapRegion(
      onTapOutside: (_) {
        if (_pinned) _set(pinned: false);
      },
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              expanded: _open,
              label: widget.semanticLabel,
              child: FocusableActionDetector(
                focusNode: _focusNode,
                mouseCursor: SystemMouseCursors.click,
                onShowFocusHighlight: (v) => setState(() => _focusRing = v),
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) => _togglePin(),
                  ),
                  DismissIntent: CallbackAction<DismissIntent>(
                    onInvoke: (_) => _close(),
                  ),
                },
                child: GestureDetector(
                  onTap: _togglePin,
                  child: widget.pill(_open, _focusRing),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              reverseDuration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              switchInCurve: Curves.easeOutCubic,
              // Runs backwards on exit, so easeOut reads as accelerate-out.
              switchOutCurve: Curves.easeOutCubic,
              layoutBuilder: (current, previous) =>
                  Stack(alignment: anchor, children: [...previous, ?current]),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.96, end: 1.0).animate(animation),
                  alignment: anchor,
                  child: child,
                ),
              ),
              child: _open
                  ? Padding(
                      key: const ValueKey('popover'),
                      padding: const EdgeInsets.only(top: 8),
                      child: RepaintBoundary(child: widget.popover(context)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The collapsed pill: a leading glyph and a label, plus an amber dot when
/// something needs updating.
class FlyoutPill extends StatelessWidget {
  final ChromePalette palette;
  final Widget leading;
  final String label;

  /// Set the label in the mono face — for version numbers.
  final bool mono;
  final bool active;
  final bool focusRing;
  final bool dot;

  const FlyoutPill({
    super.key,
    required this.palette,
    required this.leading,
    required this.label,
    required this.active,
    required this.focusRing,
    this.mono = false,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? palette.pillActive : palette.pill,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: palette.border),
        // Focus ring as a shadow so it never shifts the pill's bounds.
        boxShadow: focusRing
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: mono
                ? chromeMono(
                    context,
                    size: 11,
                    color: palette.text,
                    weight: FontWeight.w600,
                  )
                : TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: palette.text,
                  ),
          ),
          if (dot) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: palette.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Popover body: a header (glyph, title, optional subtitle and trailing
/// badge) over sections separated by hairlines.
class FlyoutPanel extends StatelessWidget {
  final ChromePalette palette;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> sections;
  final double width;

  const FlyoutPanel({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    required this.sections,
    this.subtitle,
    this.trailing,
    this.width = 380,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      // A Material (not a colored box) so the buttons' ink shows on top.
      child: Material(
        color: palette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 14, color: palette.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.text,
                          ),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  if (subtitle case final subtitle?) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            for (final section in sections) ...[
              Divider(height: 1, thickness: 1, color: palette.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: section,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Installed v1.0.5 → Latest v1.0.6", collapsing to one side when the
/// other is unknown or identical, or to the live-check state.
class FlyoutVersionLine extends StatelessWidget {
  final ChromePalette palette;
  final String? installed;
  final String? latest;
  final SdkVersionFetch fetch;
  final VoidCallback onRetry;

  const FlyoutVersionLine({
    super.key,
    required this.palette,
    required this.installed,
    required this.latest,
    required this.fetch,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final muted = TextStyle(fontSize: 11.5, color: palette.textMuted);
    final installed = this.installed;
    final latest = this.latest;
    final outdated =
        installed != null &&
        latest != null &&
        compareSdkVersions(installed, latest) < 0;
    final upToDate = installed != null && latest != null && !outdated;

    Widget version(String label, String v, Color color) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: muted),
          TextSpan(
            text: loc.sdkTipsVersionLabel(v),
            style: chromeMono(
              context,
              size: 11.5,
              color: color,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (installed != null)
          version(
            loc.sdkTipsInstalled,
            installed,
            outdated ? palette.accent : palette.text,
          ),
        ...switch (fetch) {
          SdkVersionFetch.loaded => [
            if (outdated)
              Icon(LucideIcons.arrowRight, size: 12, color: palette.textMuted),
            if (!upToDate && latest != null)
              version(loc.sdkTipsLatestLabel, latest, palette.text),
          ],
          SdkVersionFetch.loading => [
            SizedBox.square(
              dimension: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: palette.textMuted,
              ),
            ),
            Text(loc.sdkTipsChecking, style: muted),
          ],
          SdkVersionFetch.error => [
            Icon(LucideIcons.cloudOff, size: 12, color: palette.textMuted),
            Text(loc.sdkTipsOffline, style: muted),
            FlyoutButton(
              palette: palette,
              icon: LucideIcons.refreshCw,
              label: loc.sdkTipsRetry,
              onPressed: onRetry,
            ),
          ],
        },
      ],
    );
  }
}

/// Amber "Update" chip — amber is reserved for this state.
class FlyoutUpdateBadge extends StatelessWidget {
  final ChromePalette palette;
  final String label;

  const FlyoutUpdateBadge({
    super.key,
    required this.palette,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: palette.accentBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.arrowUp, size: 11, color: palette.accent),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact button in the body face (the theme's button text style is the
/// mono face). [primary] fills it amber: the one call to action, an update.
class FlyoutButton extends StatelessWidget {
  final ChromePalette palette;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const FlyoutButton({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    );
    final iconWidget = Icon(icon, size: 12);
    final labelWidget = Text(label);
    if (primary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: iconWidget,
        label: labelWidget,
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.isDark
              ? const Color(0xFF1F2328)
              : Colors.white,
          textStyle: textStyle,
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: shape,
        ),
      );
    }
    // Outlined, so its edge — not its label — lines up with the text above.
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: iconWidget,
      label: labelWidget,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        side: BorderSide(color: palette.border),
        textStyle: textStyle,
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: shape,
      ),
    );
  }
}
