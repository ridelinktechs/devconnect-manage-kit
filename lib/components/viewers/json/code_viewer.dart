import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/code_generator.dart';
import '../../../core/utils/code_highlighter.dart';
import '../../../core/utils/toast_utils.dart';
import 'json_mini_button.dart';

class CodeViewer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTypes = generated.types != null && generated.types!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTypes) ...[
          _CodePanel(
            isDark: isDark,
            icon: LucideIcons.fileCode,
            title: 'Types',
            subtitle: languageLabel,
            code: generated.types!,
            lang: lang,
            copyLabel: 'Type definition copied',
          ),
          const SizedBox(height: 12),
        ],
        _CodePanel(
          isDark: isDark,
          icon: LucideIcons.code,
          title: 'Code',
          subtitle: languageLabel,
          code: generated.code,
          lang: lang,
          copyLabel: '$languageLabel code copied',
        ),
      ],
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

  const _CodePanel({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.lang,
    required this.copyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(code).length + 1;
    final spans = CodeHighlighter.highlight(code, lang, isDark);

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
