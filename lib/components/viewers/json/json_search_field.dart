import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/chrome_palette.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'json_mini_button.dart';

/// A JSON viewer's search box, for its toolbar row, where it takes the free
/// space: Enter / ⇧Enter step through the matches, Esc clears. While there's
/// a query it shows [summary] if given, else which match is current, with
/// previous / next.
class JsonSearchField extends StatelessWidget {
  final TextEditingController search;
  final FocusNode searchFocus;
  final ValueChanged<String> onQuery;
  final int matchCount;
  final int current;
  final ValueChanged<int> onStep;
  final String? summary;

  /// The count stopped at [matchCount]: there may be more.
  final bool capped;
  final bool isDark;

  const JsonSearchField({
    super.key,
    required this.search,
    required this.searchFocus,
    required this.onQuery,
    required this.matchCount,
    required this.current,
    required this.onStep,
    this.summary,
    this.capped = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final muted = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final hasQuery = search.text.trim().isNotEmpty;
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    shift: true,
                  ): () =>
                      onStep(-1),
                  const SingleActivator(LogicalKeyboardKey.escape): () {
                    search.clear();
                    onQuery('');
                  },
                },
                child: TextField(
                  controller: search,
                  focusNode: searchFocus,
                  onChanged: onQuery,
                  onSubmitted: (_) {
                    onStep(1);
                    searchFocus.requestFocus();
                  },
                  style: chromeMono(
                    context,
                    size: 11,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: loc.jsonSearchHint,
                    hintStyle: TextStyle(fontSize: 11, color: muted),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 12,
                      color: muted,
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 24),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ),
          ),
          // Room for the count and buttons is kept while there's no query,
          // and the count has a fixed width: typing doesn't shift the row.
          Visibility(
            visible: hasQuery,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 52,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      summary ??
                          (matchCount == 0
                              ? '0'
                              : '${current + 1}/$matchCount${capped ? '+' : ''}'),
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                  ),
                ),
                if (summary == null) ...[
                  JsonMiniButton(
                    icon: LucideIcons.chevronUp,
                    tooltip: '${loc.jsonPrevMatch} (⇧↵)',
                    isDark: isDark,
                    onTap: () => onStep(-1),
                  ),
                  JsonMiniButton(
                    icon: LucideIcons.chevronDown,
                    tooltip: '${loc.jsonNextMatch} (↵)',
                    isDark: isDark,
                    onTap: () => onStep(1),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
