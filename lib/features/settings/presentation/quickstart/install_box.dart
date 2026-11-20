// Lucian UX/UI Prompt #272 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#272
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../shared/focus_ring.dart';

/// One platform of the quick start: its install line, split so only the
/// start animates when switching, and the code that starts it. [before]
/// holds one start per package manager; its first word names the manager.
typedef InstallTarget = ({
  String name,
  bool prompt,
  List<String> before,
  String package,
  String after,
  List<String> next,
});

/// Dark install box with a tab per platform. Switching slides the
/// underline over and rewrites only the part of the command that changes;
/// copying turns the icon into a check, floats a "Copied" bubble and
/// unfolds the next-step code line by line. A platform with several
/// package managers gets a switch for them on the right. The chosen tab
/// and manager are remembered.
class InstallBox extends StatefulWidget {
  final List<InstallTarget> targets;
  final String nextLabel;
  final String copyLabel;
  final String copiedLabel;

  const InstallBox({
    super.key,
    required this.targets,
    required this.nextLabel,
    required this.copyLabel,
    required this.copiedLabel,
  });

  @override
  State<InstallBox> createState() => _InstallBoxState();
}

class _InstallBoxState extends State<InstallBox>
    with SingleTickerProviderStateMixin {
  static const _prefKey = 'quickStartPlatform';
  static const _managerKey = 'quickStartManager';
  static const _pill = Cubic(0.3, 1.3, 0.5, 1);
  static const _box = Color(0xFF0F1117);
  static const _line = Color(0xFF262A36);

  late int _cur = (AppPreferences().get<int>(_prefKey, 0) ?? 0).clamp(
    0,
    widget.targets.length - 1,
  );
  String? _manager = AppPreferences().get<String>(_managerKey);
  late String _shown = _start;
  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  bool _leaving = false;
  int _swapId = 0;
  bool _copied = false;
  bool _unfolded = false;
  Timer? _reset;
  final _tabKeys = <GlobalKey>[];
  final _tabsKey = GlobalKey();
  (double, double)? _underline;

  @override
  void initState() {
    super.initState();
    _tabKeys.addAll([for (final _ in widget.targets) GlobalKey()]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _reset?.cancel();
    _swap.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final tab = _tabKeys[_cur].currentContext?.findRenderObject() as RenderBox?;
    final row = _tabsKey.currentContext?.findRenderObject() as RenderBox?;
    if (tab == null || row == null || !tab.hasSize) return;
    final x = tab.localToGlobal(Offset.zero, ancestor: row).dx;
    setState(() => _underline = (x, tab.size.width));
  }

  /// Starts of the current platform's install line, one per manager.
  List<String> get _starts => widget.targets[_cur].before;

  /// The start for the chosen manager, else the platform's first one.
  String get _start => _starts.firstWhere(
    (s) => _nameOf(s) == _manager,
    orElse: () => _starts.first,
  );

  static String _nameOf(String start) => start.split(' ').first;

  void _pick(int i) {
    if (i == _cur) return;
    setState(() => _cur = i);
    AppPreferences().set(_prefKey, i);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    _morph();
  }

  void _pickManager(String name) {
    if (name == _nameOf(_start)) return;
    setState(() => _manager = name);
    AppPreferences().set(_managerKey, name);
    _morph();
  }

  /// Fades the shown start of the command out and the chosen one in.
  Future<void> _morph() async {
    final id = ++_swapId;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _shown = _start);
      return;
    }
    setState(() => _leaving = true);
    _swap.duration = const Duration(milliseconds: 200);
    await _swap.forward(from: 0);
    if (!mounted || id != _swapId) return;
    setState(() {
      _shown = _start;
      _leaving = false;
    });
    _swap.duration = const Duration(milliseconds: 300);
    await _swap.forward(from: 0);
  }

  void _step(int d) {
    final n = widget.targets.length;
    _pick((_cur + d + n) % n);
  }

  void _copy() {
    final t = widget.targets[_cur];
    Clipboard.setData(ClipboardData(text: _start + t.package + t.after));
    _reset?.cancel();
    setState(() {
      _copied = true;
      _unfolded = true;
    });
    _reset = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final target = widget.targets[_cur];
    final reduce = MediaQuery.disableAnimationsOf(context);
    final mono = chromeMono(
      context,
      size: 13,
      color: const Color(0xFFE5E7EB),
      weight: FontWeight.w600,
    );
    final underline = _underline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _box,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 18),
                blurRadius: 34,
                spreadRadius: -18,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                key: _tabsKey,
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 10, 0),
                    child: Row(
                      children: [
                        CallbackShortcuts(
                          bindings: {
                            const SingleActivator(
                              LogicalKeyboardKey.arrowRight,
                            ): () =>
                                _step(1),
                            const SingleActivator(
                              LogicalKeyboardKey.arrowLeft,
                            ): () =>
                                _step(-1),
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < widget.targets.length; i++)
                                _Tab(
                                  key: _tabKeys[i],
                                  label: widget.targets[i].name,
                                  selected: i == _cur,
                                  onTap: () => _pick(i),
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: reduce
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          child: target.before.length < 2
                              ? const SizedBox.shrink()
                              : _ManagerSwitch(
                                  key: ValueKey(target.name),
                                  names: [
                                    for (final s in target.before) _nameOf(s),
                                  ],
                                  selected: _nameOf(_start),
                                  onPick: _pickManager,
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (underline != null)
                    AnimatedPositioned(
                      duration: reduce
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      curve: _pill,
                      left: underline.$1,
                      width: underline.$2,
                      bottom: -1,
                      height: 2,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFA78BFA),
                          borderRadius: BorderRadius.all(Radius.circular(1)),
                        ),
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (target.prompt) ...[
                              Text(
                                r'$',
                                style: mono.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            AnimatedBuilder(
                              animation: _swap,
                              builder: (context, child) {
                                final t = Curves.ease.transform(_swap.value);
                                final gone = _leaving ? t : 1 - t;
                                return Opacity(
                                  opacity: 1 - gone,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      (_leaving ? -4 : 4) * gone,
                                    ),
                                    child: gone < 0.01
                                        ? child
                                        : ImageFiltered(
                                            imageFilter: ui.ImageFilter.blur(
                                              sigmaX: 1.5 * gone,
                                              sigmaY: 1.5 * gone,
                                            ),
                                            child: child,
                                          ),
                                  ),
                                );
                              },
                              child: Text(_shown, style: mono),
                            ),
                            Text(
                              target.package,
                              style: mono.copyWith(
                                color: const Color(0xFFC4B5FD),
                              ),
                            ),
                            if (target.after.isNotEmpty)
                              Text(target.after, style: mono),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CopyButton(
                      copied: _copied,
                      copyLabel: widget.copyLabel,
                      copiedLabel: widget.copiedLabel,
                      onTap: _copy,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.nextLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: p.codeBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: p.border.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var k = 0; k < target.next.length; k++)
                _UnfoldLine(
                  key: ValueKey('${target.name}-$k'),
                  text: target.next[k],
                  shown: _unfolded,
                  delay: Duration(milliseconds: 150 + k * 120),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One platform tab of the install box.
class _Tab extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  @override
  Widget build(BuildContext context) {
    return FocusRing(
      onTap: widget.onTap,
      radius: 8,
      offset: -2,
      selected: widget.selected,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: chromeMono(
            context,
            size: 12,
            weight: FontWeight.w700,
            color: widget.selected
                ? const Color(0xFFF3F4F6)
                : const Color(0xFF8B90A3),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

/// Package-manager switch for a platform that installs with several
/// tools; the chosen one sits on a raised chip.
class _ManagerSwitch extends StatelessWidget {
  final List<String> names;
  final String selected;
  final ValueChanged<String> onPick;

  const _ManagerSwitch({
    super.key,
    required this.names,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final name in names)
            FocusRing(
              onTap: () => onPick(name),
              radius: 6,
              offset: -2,
              selected: name == selected,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: name == selected
                      ? const Color(0xFF353B50)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: chromeMono(
                    context,
                    size: 12,
                    weight: FontWeight.w700,
                    color: name == selected
                        ? const Color(0xFFF3F4F6)
                        : const Color(0xFF8B90A3),
                  ),
                  child: Text(name),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Copy button that turns into a check with a "Copied" bubble above it.
class _CopyButton extends StatelessWidget {
  static const _pop = Cubic(0.3, 1.6, 0.5, 1);

  final bool copied;
  final String copyLabel;
  final String copiedLabel;
  final VoidCallback onTap;

  const _CopyButton({
    required this.copied,
    required this.copyLabel,
    required this.copiedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FocusRing(
          onTap: onTap,
          radius: 9,
          label: copyLabel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: copied ? const Color(0xFF064E3B) : const Color(0xFF1E2230),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              copied ? LucideIcons.check : LucideIcons.copy,
              size: 14,
              color: copied ? const Color(0xFF6EE7B7) : const Color(0xFFC7CAD6),
            ),
          ),
        ),
        Positioned(
          right: -6,
          bottom: 38,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: copied ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedSlide(
                offset: copied ? Offset.zero : const Offset(0, 0.2),
                duration: const Duration(milliseconds: 300),
                curve: _pop,
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      copiedLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F1117),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A line of the next-step code: dim until [shown], then it slides in
/// after [delay].
class _UnfoldLine extends StatefulWidget {
  final String text;
  final bool shown;
  final Duration delay;

  const _UnfoldLine({
    super.key,
    required this.text,
    required this.shown,
    required this.delay,
  });

  @override
  State<_UnfoldLine> createState() => _UnfoldLineState();
}

class _UnfoldLineState extends State<_UnfoldLine> {
  static const _pill = Cubic(0.3, 1.3, 0.5, 1);

  late bool _on = widget.shown;
  Timer? _wait;

  @override
  void didUpdateWidget(_UnfoldLine old) {
    super.didUpdateWidget(old);
    if (widget.shown == _on || _wait != null) return;
    if (!widget.shown || MediaQuery.disableAnimationsOf(context)) {
      setState(() => _on = widget.shown);
      return;
    }
    _wait = Timer(widget.delay, () {
      _wait = null;
      if (mounted) setState(() => _on = true);
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    return AnimatedOpacity(
      opacity: _on ? 1 : 0.25,
      duration: const Duration(milliseconds: 350),
      child: AnimatedSlide(
        offset: _on ? Offset.zero : const Offset(-0.012, 0),
        duration: const Duration(milliseconds: 450),
        curve: _pill,
        child: Text.rich(
          TextSpan(children: _highlight(widget.text, p)),
          style: chromeMono(
            context,
            size: 12,
            color: p.text,
          ).copyWith(height: 1.7),
        ),
      ),
    );
  }

  static final _token = RegExp(
    r'''(//.*$)|("[^"]*"|'[^']*')|\b(import|from|await|void|async|const|class|override|fun|this|true|false|return)\b''',
  );

  /// Colors comments, strings and keywords of one line of code.
  static List<TextSpan> _highlight(String line, ChromePalette p) {
    final keyword = p.isDark
        ? const Color(0xFFC4B5FD)
        : const Color(0xFF7C3AED);
    final string = p.isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
    final spans = <TextSpan>[];
    var at = 0;
    for (final m in _token.allMatches(line)) {
      if (m.start > at) spans.add(TextSpan(text: line.substring(at, m.start)));
      final color = m.group(1) != null
          ? p.textMuted
          : (m.group(2) != null ? string : keyword);
      spans.add(
        TextSpan(
          text: m.group(0),
          style: TextStyle(color: color),
        ),
      );
      at = m.end;
    }
    if (at < line.length) spans.add(TextSpan(text: line.substring(at)));
    return spans;
  }
}
