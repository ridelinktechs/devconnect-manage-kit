import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/code/code_generator.dart';
import '../../../core/utils/code/code_highlighter.dart';
import '../../../core/utils/ui/toast_utils.dart';
import 'json_mini_button.dart';
import 'json_search_field.dart';
import 'text_search.dart';

/// Generated code for a JSON value: its types and the code building it,
/// searched together (⌘F; Enter / ⇧Enter step through the matches).
class CodeViewer extends StatefulWidget {
  final GeneratedCode generated;
  final CodeLang lang;
  final String languageLabel;

  const CodeViewer({
    super.key,
    required this.generated,
    required this.lang,
    required this.languageLabel,
  });

  @override
  State<CodeViewer> createState() => _CodeViewerState();
}

class _CodeViewerState extends State<CodeViewer> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _typesKey = GlobalKey();
  final _codeKey = GlobalKey();

  /// Search hits in the types, then in the code.
  List<(int, int)> _typeMatches = const [];
  List<(int, int)> _codeMatches = const [];
  int _current = 0;

  int get _matchCount => _typeMatches.length + _codeMatches.length;

  @override
  void didUpdateWidget(CodeViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.generated, widget.generated)) _find();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _find() {
    _typeMatches = findMatches(widget.generated.types ?? '', _search.text);
    _codeMatches = findMatches(widget.generated.code, _search.text);
    if (_current >= _matchCount) _current = 0;
  }

  void _onQuery(String query) {
    setState(() {
      _current = 0;
      _find();
    });
    _reveal();
  }

  void _step(int delta) {
    final n = _matchCount;
    if (n == 0) return;
    setState(() => _current = ((_current + delta) % n + n) % n);
    _reveal();
  }

  void _reveal() {
    if (_matchCount == 0) return;
    final types = _typeMatches.length;
    if (_current < types) {
      revealTextOffset(_typesKey, _typeMatches[_current].$1);
    } else {
      revealTextOffset(_codeKey, _codeMatches[_current - types].$1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final generated = widget.generated;
    final hasTypes = generated.types != null && generated.types!.isNotEmpty;
    final types = _typeMatches.length;
    final panels = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTypes) ...[
          _CodePanel(
            isDark: isDark,
            icon: LucideIcons.fileCode,
            title: 'Types',
            subtitle: widget.languageLabel,
            code: generated.types!,
            lang: widget.lang,
            copyLabel: 'Type definition copied',
            textKey: _typesKey,
            matches: _typeMatches,
            current: _current,
          ),
          const SizedBox(height: 12),
        ],
        _CodePanel(
          isDark: isDark,
          icon: LucideIcons.code,
          title: 'Code',
          subtitle: widget.languageLabel,
          code: generated.code,
          lang: widget.lang,
          copyLabel: '${widget.languageLabel} code copied',
          textKey: _codeKey,
          matches: _codeMatches,
          current: _current - types,
        ),
      ],
    );
    final searchBar = Container(
      height: 32,
      padding: const EdgeInsets.only(left: 8, right: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252526) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          JsonSearchField(
            search: _search,
            searchFocus: _searchFocus,
            onQuery: _onQuery,
            matchCount: _matchCount,
            current: _current,
            onStep: _step,
            isDark: isDark,
          ),
        ],
      ),
    );

    return CallbackShortcuts(
      bindings: {
        SingleActivator(
          LogicalKeyboardKey.keyF,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): () =>
            _searchFocus.requestFocus(),
      },
      child: Focus(
        // With a bounded height the code scrolls under the search bar, which
        // stays put; inside a caller's scroll view both scroll together.
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchBar,
              const SizedBox(height: 6),
              if (constraints.hasBoundedHeight)
                Flexible(child: SingleChildScrollView(child: panels))
              else
                panels,
            ],
          ),
        ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final String code;
  final CodeLang lang;
  final String copyLabel;
  final GlobalKey textKey;

  /// Search hits in [code], and which of them is current (if any).
  final List<(int, int)> matches;
  final int current;

  const _CodePanel({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.lang,
    required this.copyLabel,
    required this.textKey,
    required this.matches,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(code).length + 1;
    final spans = markMatches(
      CodeHighlighter.highlight(code, lang, isDark),
      matches,
      current,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252526) : const Color(0xFFF0F0F0),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
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
                Icon(
                  icon,
                  size: 12,
                  color: isDark
                      ? const Color(0xFF7FD4E4)
                      : const Color(0xFF0451A5),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppConstants.monoFontFamily,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· $subtitle',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppConstants.monoFontFamily,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$lineCount lines',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppConstants.monoFontFamily,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                JsonMiniButton(
                  icon: LucideIcons.copy,
                  tooltip: 'Copy',
                  isDark: isDark,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    showCopiedToast(context, label: copyLabel);
                  },
                ),
              ],
            ),
          ),
          // Content — syntax-highlighted, selectable
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectionArea(
              child: Text.rich(
                key: textKey,
                TextSpan(
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  children: spans,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
