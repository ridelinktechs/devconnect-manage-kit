import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/color_tokens.dart';

/// Popup menu button for picking the app locale. Renders the currently
/// selected language as a chevron row; tapping reveals the full
/// `supportedLocales` list with a check next to the active one.
///
/// Local copy — the popup pattern is similar to other features but
/// the locale lookup (`localeDisplayNames`) is unique to settings.
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({
    super.key,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  final Locale selected;
  final bool isDark;
  final ValueChanged<Locale> onSelect;

  String _selectedLabel() {
    final key = selected.countryCode != null
        ? '${selected.languageCode}_${selected.countryCode}'
        : selected.languageCode;
    return localeDisplayNames[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<Locale>(
        onSelected: onSelect,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        itemBuilder: (context) => supportedLocales.map((locale) {
          final key = locale.countryCode != null
              ? '${locale.languageCode}_${locale.countryCode}'
              : locale.languageCode;
          final label = localeDisplayNames[key] ?? key;
          final isSelected = locale == selected;
          return PopupMenuItem<Locale>(
            value: locale,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                if (isSelected)
                  Icon(LucideIcons.check, size: 14, color: ColorTokens.primary)
                else
                  const SizedBox(width: 14),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? ColorTokens.primary
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(LucideIcons.languages, size: 15, color: Colors.grey[500]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
              ),
              Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}