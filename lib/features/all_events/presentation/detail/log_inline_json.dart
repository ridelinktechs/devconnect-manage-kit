import 'package:flutter/material.dart';

import '../../../../components/viewers/json_viewer.dart';

/// Inline JSON viewer used inside [LogDetail] (and elsewhere) to render a
/// pretty-printed tree of an embedded payload under the message.
class LogInlineJson extends StatelessWidget {
  final dynamic data;
  final String label;

  const LogInlineJson({super.key, required this.data, required this.label});

  @override
  Widget build(BuildContext context) {
    return JsonViewer(data: data, initiallyExpanded: true);
  }
}