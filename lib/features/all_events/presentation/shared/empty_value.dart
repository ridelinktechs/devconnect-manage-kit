import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Empty-state placeholder used by storage / state detail panels when the
/// underlying value was deleted or never set. Communicates "no value" with
/// a database icon and a muted label — never a blank column.
class EmptyValue extends StatelessWidget {
  final bool isDark;
  const EmptyValue({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            LucideIcons.database,
            size: 24,
            color: isDark ? const Color(0xFF4A4A4A) : const Color(0xFFB0B0B0),
          ),
          const SizedBox(height: 10),
          Text(
            'No value stored',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF8B8B8B) : const Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }
}
