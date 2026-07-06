import 'package:flutter/material.dart';

/// Small uppercase section label used in detail panels (e.g. "MESSAGE",
/// "REQUEST HEADERS"). Color is muted so it sits visually behind the body
/// content.
class Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const Label({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF8B8B8B),
      ),
    );
  }
}
