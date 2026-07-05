import 'package:flutter/material.dart';

import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../provider/all_events_provider.dart';
import '../shared/code_block.dart';
import '../shared/section_label.dart';

/// Default detail view used when an event has no dedicated panel (display,
/// async, generic error). Renders title, subtitle, and — when present —
/// the raw `event.rawData` payload as a JSON tree.
class FallbackDetail extends StatefulWidget {
  final UnifiedEvent event;

  const FallbackDetail({super.key, required this.event});

  @override
  State<FallbackDetail> createState() => _FallbackDetailState();
}

class _FallbackDetailState extends State<FallbackDetail> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Title'),
          const SizedBox(height: 6),
          CodeBlock(text: event.title, isDark: isDark),
          const SizedBox(height: 16),
          const SectionLabel('Details'),
          const SizedBox(height: 6),
          CodeBlock(text: event.subtitle, isDark: isDark),
          if (event.rawData != null) ...[
            const SizedBox(height: 16),
            const SectionLabel('Raw Data'),
            const SizedBox(height: 6),
            if (event.rawData is Map || event.rawData is List)
              JsonViewer(data: event.rawData, initiallyExpanded: true)
            else
              CodeBlock(text: '${event.rawData}', isDark: isDark),
          ],
        ],
      ),
    );
  }
}