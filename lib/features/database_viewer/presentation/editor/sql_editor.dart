import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/shared/focus_ring.dart';

/// The SQL editor: line numbers beside the text, and Run with its shortcut,
/// ⌘↵ (Ctrl+Enter off macOS). Enter starts a new line.
class SqlEditor extends StatefulWidget {
  final TextEditingController controller;
  final bool running;
  final VoidCallback onRun;

  const SqlEditor({
    super.key,
    required this.controller,
    required this.running,
    required this.onRun,
  });

  @override
  State<SqlEditor> createState() => _SqlEditorState();
}

class _SqlEditorState extends State<SqlEditor> {
  final _text = ScrollController();
  final _gutter = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _text.addListener(_follow);
  }

  @override
  void didUpdateWidget(SqlEditor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _text.dispose();
    _gutter.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  /// Keeps the line numbers level with the text as it scrolls.
  void _follow() {
    if (!_gutter.hasClients) return;
    _gutter.jumpTo(_text.offset.clamp(0.0, _gutter.position.maxScrollExtent));
  }

  void _run() {
    if (!widget.running) widget.onRun();
  }

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final style = chromeMono(
      context,
      size: 12.5,
      color: p.text,
    ).copyWith(height: 1.5);
    final lines = '\n'.allMatches(widget.controller.text).length + 1;
    final shown = lines.clamp(3, 8);
    return Container(
      color: p.isDark ? ColorTokens.darkBackground : Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            height: shown * style.fontSize! * style.height!,
            child: SingleChildScrollView(
              controller: _gutter,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 1; i <= lines; i++)
                    Text(
                      '$i',
                      style: style.copyWith(
                        color: p.textMuted.withValues(alpha: 0.7),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter, meta: true):
                    _run,
                const SingleActivator(LogicalKeyboardKey.enter, control: true):
                    _run,
              },
              child: TextField(
                controller: widget.controller,
                scrollController: _text,
                minLines: 3,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                style: style,
                cursorColor: p.text,
                decoration: InputDecoration.collapsed(
                  hintText: 'SELECT * FROM table_name LIMIT 100',
                  hintStyle: style.copyWith(
                    color: p.textMuted.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RunButton(running: widget.running, onRun: _run),
        ],
      ),
    );
  }
}

/// Run as a plain bordered button with its shortcut beside the label.
class _RunButton extends StatefulWidget {
  final bool running;
  final VoidCallback onRun;

  const _RunButton({required this.running, required this.onRun});

  @override
  State<_RunButton> createState() => _RunButtonState();
}

class _RunButtonState extends State<_RunButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final loc = S.of(context);
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    final fill = p.isDark
        ? Colors.white.withValues(alpha: _hover ? 0.10 : 0.06)
        : Colors.black.withValues(alpha: _hover ? 0.07 : 0.04);
    return FocusRing(
      onTap: widget.onRun,
      radius: 7,
      label: loc.dbRun,
      onHover: (v) => setState(() => _hover = v),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.running)
              SizedBox.square(
                dimension: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: p.textMuted,
                ),
              )
            else
              Icon(LucideIcons.play, size: 12, color: p.text),
            const SizedBox(width: 6),
            Text(
              loc.dbRun,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.running ? p.textMuted : p.text,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              mac ? '⌘↵' : 'Ctrl ↵',
              style: chromeMono(context, size: 11, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
