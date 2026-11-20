// Lucian UX/UI Prompt #040 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#040
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/app_version_provider.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/focus_ring.dart';

/// One entry of the [SettingsSidebar].
typedef SidebarItem = ({IconData icon, String label, int? badge});

/// Settings menu: one entry per group, a highlight that glides to the
/// chosen one, and the server's status at the bottom. When [compact] it
/// narrows to an icon rail. ↑ / ↓ move between entries.
class SettingsSidebar extends StatefulWidget {
  final List<SidebarItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final bool compact;
  final bool running;
  final int port;
  final int devices;

  const SettingsSidebar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
    required this.compact,
    required this.running,
    required this.port,
    required this.devices,
  });

  @override
  State<SettingsSidebar> createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<SettingsSidebar> {
  static const _spring = Cubic(0.34, 1.45, 0.64, 1);
  static const _itemHeight = 44.0;
  static const _gap = 4.0;

  late List<FocusNode> _nodes = _makeNodes();

  List<FocusNode> _makeNodes() => [
    for (var i = 0; i < widget.items.length; i++) FocusNode(),
  ];

  @override
  void didUpdateWidget(SettingsSidebar old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length) {
      for (final n in _nodes) {
        n.dispose();
      }
      _nodes = _makeNodes();
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _moveFocus(int d) {
    final n = _nodes.length;
    final current = _nodes.indexWhere((f) => f.hasFocus);
    _nodes[((current < 0 ? widget.index : current) + d + n) % n].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final s = S.of(context);
    final compact = widget.compact;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;

    return AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
      curve: _spring,
      width: compact ? 72 : 236,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: p.isDark ? ColorTokens.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: p.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.6 : 0.14),
            offset: const Offset(0, 30),
            blurRadius: 60,
            spreadRadius: -36,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: _FullWidth(
              child: Row(
                children: [
                  const SizedBox(width: 7),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [ColorTokens.primaryLight, ColorTokens.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorTokens.primary.withValues(alpha: 0.45),
                          offset: const Offset(0, 6),
                          blurRadius: 14,
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.settings,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Reveal(
                      shown: !compact,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.settings,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: p.text,
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final version = ref
                                  .watch(appVersionProvider)
                                  .value;
                              return Text(
                                version == null ? '' : 'v$version',
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  _moveFocus(1),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                  _moveFocus(-1),
            },
            child: SizedBox(
              height: widget.items.length * (_itemHeight + _gap) - _gap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: reduce
                        ? Duration.zero
                        : const Duration(milliseconds: 500),
                    curve: _spring,
                    left: 0,
                    right: 0,
                    top: widget.index * (_itemHeight + _gap),
                    height: _itemHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                alpha: p.isDark ? 0.16 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: -10,
                          top: 12,
                          bottom: 12,
                          width: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(4),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  ColorTokens.primaryLight,
                                  ColorTokens.primary,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      for (var i = 0; i < widget.items.length; i++) ...[
                        if (i > 0) const SizedBox(height: _gap),
                        _Entry(
                          item: widget.items[i],
                          selected: i == widget.index,
                          compact: compact,
                          focusNode: _nodes[i],
                          height: _itemHeight,
                          onTap: () => widget.onSelect(i),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _ServerStatus(
            running: widget.running,
            port: widget.port,
            devices: widget.devices,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

/// Fades and slides its child in when [shown]; used for the labels that
/// the compact rail hides.
class _Reveal extends StatelessWidget {
  final bool shown;
  final Widget child;

  const _Reveal({required this.shown, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(-0.06, 0),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 500),
        curve: const Cubic(0.34, 1.45, 0.64, 1),
        child: child,
      ),
    );
  }
}

/// One menu entry: dim until hovered or chosen.
class _Entry extends StatefulWidget {
  final SidebarItem item;
  final bool selected;
  final bool compact;
  final FocusNode focusNode;
  final double height;
  final VoidCallback onTap;

  const _Entry({
    required this.item,
    required this.selected,
    required this.compact,
    required this.focusNode,
    required this.height,
    required this.onTap,
  });

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final item = widget.item;
    final badge = item.badge;
    final strong = widget.selected || _hover;
    final accent = p.isDark ? ColorTokens.primaryLight : ColorTokens.primary;

    final entry = FocusRing(
      focusNode: widget.focusNode,
      onTap: widget.onTap,
      radius: 14,
      offset: 0,
      selected: widget.selected,
      label: item.label,
      onHover: (v) => setState(() => _hover = v),
      child: SizedBox(
        height: widget.height,
        child: AnimatedOpacity(
          opacity: strong ? 1 : 0.62,
          duration: const Duration(milliseconds: 250),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _FullWidth(
                child: Row(
                  children: [
                    const SizedBox(width: 15),
                    Icon(
                      item.icon,
                      size: 19,
                      color: widget.selected ? accent : p.text,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Reveal(
                        shown: !widget.compact,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: widget.selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: p.text,
                          ),
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      _Badge(count: badge),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              if (badge != null && widget.compact)
                Positioned(left: 27, top: 6, child: _Badge(count: badge)),
            ],
          ),
        ),
      ),
    );

    return widget.compact ? Tooltip(message: item.label, child: entry) : entry;
  }
}

/// Small count pill on a menu entry.
class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ColorTokens.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// The card at the bottom of the menu: server state, port and devices.
class _ServerStatus extends StatelessWidget {
  final bool running;
  final int port;
  final int devices;
  final bool compact;

  const _ServerStatus({
    required this.running,
    required this.port,
    required this.devices,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final s = S.of(context);
    final color = running ? ColorTokens.success : ColorTokens.error;
    final dot = Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
          ],
        ),
      ),
    );

    return Semantics(
      label: running ? '${s.serverRunning} :$port' : s.serverStopped,
      excludeSemantics: true,
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: p.text.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _FullWidth(
          child: Row(
            children: [
              dot,
              const SizedBox(width: 10),
              Expanded(
                child: _Reveal(
                  shown: !compact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        running ? s.serverRunning : s.serverStopped,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.text,
                        ),
                      ),
                      Text(
                        running
                            ? ':$port · ${s.deviceCount(devices)}'
                            : s.deviceCount(devices),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: TextStyle(fontSize: 11.5, color: p.textMuted),
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

/// Lays [child] out at the full menu width and clips it to the space there
/// is, so the compact rail hides the labels instead of squeezing them.
class _FullWidth extends StatelessWidget {
  static const width = 214.0;

  final Widget child;

  const _FullWidth({required this.child});

  @override
  Widget build(BuildContext context) => ClipRect(
    child: OverflowBox(
      alignment: Alignment.centerLeft,
      minWidth: width,
      maxWidth: width,
      child: child,
    ),
  );
}
