import 'package:flutter/material.dart';

import '../../../../components/text/text_component.dart';

/// Small uppercase "section header" used inside the detail panel
/// ("Tag" / "Message" / "Metadata" / "Stack trace"). 11pt w600,
/// letter-spacing 0.5, muted grey — keeps each block visually
/// separated without adding a divider line.
class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextComponent(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.grey[500],
      ),
    );
  }
}