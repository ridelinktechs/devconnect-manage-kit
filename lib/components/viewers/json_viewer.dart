import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/color_tokens.dart';

class JsonViewer extends StatelessWidget {
  final dynamic data;
  final bool initiallyExpanded;

  const JsonViewer({
    super.key,
    required this.data,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Text('null', style: Theme.of(context).textTheme.labelMedium);
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _JsonNode(
            keyName: null,
            value: data,
            depth: 0,
            initiallyExpanded: initiallyExpanded,
          ),
        ],
      ),
    );
  }
}

class _JsonNode extends StatefulWidget {
  final String? keyName;
  final dynamic value;
  final int depth;
  final bool initiallyExpanded;

  const _JsonNode({
    required this.keyName,
    required this.value,
    required this.depth,
    this.initiallyExpanded = false,
  });

  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
  late bool _expanded;
  List<_JsonNode>? _cachedChildren;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded && widget.depth < 2;
  }

  @override
  void didUpdateWidget(_JsonNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate cache if value identity changes
    if (!identical(oldWidget.value, widget.value)) {
      _cachedChildren = null;
    }
  }

  List<_JsonNode> _buildChildren() {
    if (_cachedChildren != null) return _cachedChildren!;

    if (widget.value is Map) {
      _cachedChildren = (widget.value as Map).entries.map((e) {
        return _JsonNode(
          keyName: e.key.toString(),
          value: e.value,
          depth: widget.depth + 1,
        );
      }).toList();
    } else if (widget.value is List) {
      _cachedChildren = (widget.value as List).asMap().entries.map((e) {
        return _JsonNode(
          keyName: '${e.key}',
          value: e.value,
          depth: widget.depth + 1,
        );
      }).toList();
    } else {
      _cachedChildren = [];
    }
    return _cachedChildren!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indent = widget.depth * 16.0;

    if (widget.value is Map) {
      return _buildExpandable(
        '{${(widget.value as Map).length}}',
        indent,
        isDark,
      );
    }

    if (widget.value is List) {
      return _buildExpandable(
        '[${(widget.value as List).length}]',
        indent,
        isDark,
      );
    }

    // Primitive value
    Color valueColor;
    String displayValue;

    if (widget.value is String) {
      valueColor = isDark ? const Color(0xFF98C379) : const Color(0xFF50A14F);
      displayValue = '"${widget.value}"';
    } else if (widget.value is num) {
      valueColor = isDark ? const Color(0xFFD19A66) : const Color(0xFF986801);
      displayValue = '${widget.value}';
    } else if (widget.value is bool) {
      valueColor = isDark ? const Color(0xFF56B6C2) : const Color(0xFF0184BC);
      displayValue = '${widget.value}';
    } else {
      valueColor = Colors.grey;
      displayValue = 'null';
    }

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: GestureDetector(
        onDoubleTap: () {
          Clipboard.setData(
            ClipboardData(text: widget.value?.toString() ?? 'null'),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.keyName != null) ...[
                Text(
                  '${widget.keyName}: ',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFFE06C75)
                        : ColorTokens.primary,
                  ),
                ),
              ],
              Flexible(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandable(String badge, double indent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: Colors.grey,
                    ),
                    if (widget.keyName != null) ...[
                      Text(
                        '${widget.keyName}: ',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFE06C75)
                              : ColorTokens.primary,
                        ),
                      ),
                    ],
                    Text(
                      badge,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded) ..._buildChildren(),
      ],
    );
  }
}

class JsonPrettyViewer extends StatelessWidget {
  final dynamic data;

  const JsonPrettyViewer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String formatted;
    try {
      formatted = const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      formatted = data?.toString() ?? 'null';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        children: [
          SelectableText(
            formatted,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328),
              height: 1.5,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(
                Icons.copy,
                size: 14,
                color: Colors.grey[500],
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: formatted));
              },
              tooltip: 'Copy',
              splashRadius: 14,
            ),
          ),
        ],
      ),
    );
  }
}
