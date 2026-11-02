// Lucian UX/UI Prompt #042 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#042
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/focus_ring.dart';
import 'code_snippet.dart';
import 'guide_steps.dart';
import 'guides.dart';

const _ease = Cubic(0.2, 0.8, 0.2, 1);
const _spring = Cubic(0.34, 1.45, 0.64, 1);

/// Opens the detail modal on `guides[index]`; ← / → page through [guides].
/// `{port}` and `{host}` in code snippets become [port] and [host].
Future<void> showGuideDialog(
  BuildContext context, {
  required List<Guide> guides,
  required int index,
  required String tabLabel,
  required int port,
  required String host,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: S.of(context).tipsClose,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.55 : 0.28),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (context, animation, secondary, child) => child,
    pageBuilder: (context, animation, _) => GuideDialog(
      animation: animation,
      guides: guides,
      index: index,
      tabLabel: tabLabel,
      port: port,
      host: host,
    ),
  );
}

/// The guide detail modal: header, steps, code and tip of one guide, with
/// Previous / Next paging through its tab. The page slides toward the side
/// the user moves to; the backdrop blurs in as the card pops up.
class GuideDialog extends StatefulWidget {
  final Animation<double> animation;
  final List<Guide> guides;
  final int index;
  final String tabLabel;
  final int port;
  final String host;

  const GuideDialog({
    super.key,
    required this.animation,
    required this.guides,
    required this.index,
    required this.tabLabel,
    required this.port,
    required this.host,
  });

  @override
  State<GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends State<GuideDialog> {
  late int _index = widget.index;
  int _dir = 1;
  late final CurvedAnimation _fade = CurvedAnimation(
    parent: widget.animation,
    curve: _ease,
    reverseCurve: Curves.easeIn,
  );
  late final CurvedAnimation _pop = CurvedAnimation(
    parent: widget.animation,
    curve: _spring,
    reverseCurve: Curves.easeIn,
  );

  @override
  void dispose() {
    _fade.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _go(int to) {
    if (to < 0 || to >= widget.guides.length || to == _index) return;
    setState(() {
      _dir = to > _index ? 1 : -1;
      _index = to;
    });
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final s = S.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final guide = widget.guides[_index];
    final last = _index == widget.guides.length - 1;
    final router = GoRouter.maybeOf(context);
    final route = guide.route;
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;
    final page = p.isDark ? ColorTokens.darkSurface : Colors.white;

    final card = Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                _go(_index + 1),
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                _go(_index - 1),
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: p.isDark ? 0.6 : 0.18),
                  offset: const Offset(0, 30),
                  blurRadius: 60,
                  spreadRadius: -20,
                ),
              ],
            ),
            child: Material(
              color: p.isDark ? ColorTokens.darkBackground : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: p.border),
              ),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: guide.title,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: _SizeTween(
                        enabled: !reduce,
                        child: AnimatedSwitcher(
                          duration: reduce
                              ? Duration.zero
                              : const Duration(milliseconds: 550),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [...previous, ?current],
                          ),
                          transitionBuilder: (child, animation) {
                            final incoming = child.key == ValueKey(_index);
                            final dx = (incoming ? _dir : -_dir) * 0.4;
                            return FadeTransition(
                              opacity: animation.drive(
                                CurveTween(
                                  curve: incoming
                                      ? const Interval(0, 0.64, curve: _ease)
                                      : const Interval(0.36, 1, curve: _ease),
                                ),
                              ),
                              child: SlideTransition(
                                position: animation.drive(
                                  Tween(
                                    begin: Offset(dx, 0),
                                    end: Offset.zero,
                                  ).chain(CurveTween(curve: _ease)),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: _GuidePage(
                            key: ValueKey(_index),
                            guide: guide,
                            position:
                                '${widget.tabLabel} · ${_index + 1}/${widget.guides.length}',
                            port: widget.port,
                            host: widget.host,
                            onClose: _close,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: p.border)),
                      ),
                      child: Row(
                        children: [
                          _Dots(
                            count: widget.guides.length,
                            index: _index,
                            color: accent,
                            idle: p.border,
                            onTap: _go,
                          ),
                          const Spacer(),
                          if (route != null &&
                              router != null &&
                              router.state.uri.path != route) ...[
                            _FooterButton(
                              label: s.tipsOpenPage,
                              icon: LucideIcons.externalLink,
                              background: Colors.transparent,
                              foreground: p.textMuted,
                              onTap: () {
                                Navigator.of(context).pop();
                                router.go(route);
                              },
                            ),
                            const SizedBox(width: 6),
                          ],
                          _FooterButton(
                            label: s.tipsPrevious,
                            width: 96,
                            background: p.isDark
                                ? const Color(0xFF262C36)
                                : const Color(0xFFEAEEF2),
                            foreground: p.text,
                            onTap: _index > 0 ? () => _go(_index - 1) : null,
                          ),
                          const SizedBox(width: 8),
                          _FooterButton(
                            label: last ? s.tipsDone : s.tipsNext,
                            icon: last
                                ? LucideIcons.check
                                : LucideIcons.arrowRight,
                            iconAfter: true,
                            width: 112,
                            autofocus: true,
                            background: last ? ColorTokens.success : p.text,
                            foreground: last ? ColorTokens.darkSurface : page,
                            onTap: last ? _close : () => _go(_index + 1),
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

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final fade = _fade.value.clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 8 * fade,
                    sigmaY: 8 * fade,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: fade,
                child: Transform.scale(
                  scale: reduce ? 1 : 0.96 + 0.04 * _pop.value,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: card,
    );
  }
}

/// Header and body of one guide inside [GuideDialog].
class _GuidePage extends StatelessWidget {
  final Guide guide;
  final String position;
  final int port;
  final String host;
  final VoidCallback onClose;

  const _GuidePage({
    super.key,
    required this.guide,
    required this.position,
    required this.port,
    required this.host,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final s = S.of(context);
    final tone = guideTone(guide.color, p.isDark);
    final label = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: p.textMuted,
    );
    final steps = guide.steps;
    final tip = guide.tip;
    final keysOnly =
        steps != null && parseSteps(steps).every((l) => l.$1.isNotEmpty);
    final hasBody = steps != null || guide.code.isNotEmpty || tip != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.9, -1.1),
              radius: 1.1,
              colors: [
                guide.color.withValues(alpha: p.isDark ? 0.2 : 0.12),
                guide.color.withValues(alpha: 0),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 14, hasBody ? 18 : 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.lerp(tone, Colors.white, 0.25)!, tone],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: tone.withValues(alpha: 0.35),
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(guide.icon, size: 21, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(position, style: label),
                      const SizedBox(height: 4),
                      Text(
                        guide.title,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        guide.summary,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CloseButton(onTap: onClose),
              ],
            ),
          ),
        ),
        if (hasBody)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (steps != null) ...[
                    Text(keysOnly ? s.tipsKeys : s.tipsSteps, style: label),
                    const SizedBox(height: 10),
                    GuideSteps(steps: steps, color: tone),
                  ],
                  for (final (name, code) in guide.code) ...[
                    const SizedBox(height: 12),
                    CodeSnippet(
                      label: name,
                      code: code
                          .replaceAll('{port}', '$port')
                          .replaceAll('{host}', host),
                    ),
                  ],
                  if (tip != null) ...[
                    const SizedBox(height: 18),
                    _TipCallout(text: tip, color: tone),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// "Pro tip" note with an accent bar down its left edge.
class _TipCallout extends StatelessWidget {
  final String text;
  final Color color;

  const _TipCallout({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: p.isDark ? 0.09 : 0.07),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          LucideIcons.lightbulb,
                          size: 15,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${S.of(context).tipsProTip}  ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                              TextSpan(text: text),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: p.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round × in the corner of the modal; Esc does the same.
class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final s = S.of(context);
    return Tooltip(
      message: '${s.tipsClose} (Esc)',
      child: FocusRing(
        onTap: widget.onTap,
        radius: 9,
        label: s.tipsClose,
        onHover: (v) => setState(() => _hover = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hover ? p.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            LucideIcons.x,
            size: 16,
            color: _hover ? p.text : p.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Footer button of the modal: shrinks a little while pressed and fades
/// when it has no [onTap].
class _FooterButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool iconAfter;

  /// Minimum width; longer labels widen the button.
  final double? width;
  final bool autofocus;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _FooterButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.icon,
    this.iconAfter = false,
    this.width,
    this.autofocus = false,
  });

  @override
  State<_FooterButton> createState() => _FooterButtonState();
}

class _FooterButtonState extends State<_FooterButton> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final hoverTint = widget.background == Colors.transparent
        ? ChromePalette.of(context).hover
        : Color.lerp(widget.background, widget.foreground, 0.1)!;
    final icon = widget.icon == null
        ? null
        : Icon(widget.icon, size: 15, color: widget.foreground);
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: _ease,
      height: 40,
      constraints: BoxConstraints(minWidth: widget.width ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _hover && enabled ? hoverTint : widget.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null && !widget.iconAfter) ...[
            icon,
            const SizedBox(width: 7),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: widget.foreground,
            ),
          ),
          if (icon != null && widget.iconAfter) ...[
            const SizedBox(width: 7),
            icon,
          ],
        ],
      ),
    );

    if (!enabled) {
      return Opacity(opacity: 0.35, child: ExcludeFocus(child: body));
    }
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 350),
        curve: _spring,
        child: FocusRing(
          onTap: widget.onTap!,
          autofocus: widget.autofocus,
          radius: 12,
          label: widget.label,
          onHover: (v) => setState(() => _hover = v),
          child: body,
        ),
      ),
    );
  }
}

/// Page dots under the modal; the current one stretches into a bar.
class _Dots extends StatelessWidget {
  final int count;
  final int index;
  final Color color;
  final Color idle;
  final ValueChanged<int> onTap;

  const _Dots({
    required this.count,
    required this.index,
    required this.color,
    required this.idle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2.5,
                    vertical: 8,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: _ease,
                    width: i == index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == index ? color : idle,
                      borderRadius: BorderRadius.circular(3),
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

/// Eases [child]'s size changes, or follows them at once when [enabled] is
/// off (an [AnimatedSize] with no duration asserts mid-layout).
class _SizeTween extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _SizeTween({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) => enabled
      ? AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: _ease,
          alignment: Alignment.topCenter,
          child: child,
        )
      : child;
}
