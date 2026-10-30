import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/color_sample.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/utils/ui/toast_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../provider/layout_providers.dart';
import '../shared/layout_style.dart';
import '../shared/mini_button.dart';
import '../shared/section_label.dart';
import '../shared/tag_chip.dart';
import 'box_model.dart';

/// A value's text and color as the JSON viewer shows them: strings green,
/// numbers orange, booleans cyan, the rest grey.
(String, Color) _typed(Object? value, bool isDark) => switch (value) {
  String() when value == 'ƒ' => ('ƒ', const Color(0xFF8B949E)),
  String() => (
    value,
    isDark ? const Color(0xFF98C379) : const Color(0xFF50A14F),
  ),
  num() => (
    '$value',
    isDark ? const Color(0xFFD19A66) : const Color(0xFF986801),
  ),
  bool() => (
    '$value',
    isDark ? const Color(0xFF56B6C2) : const Color(0xFF0184BC),
  ),
  _ => ('$value', const Color(0xFF8B949E)),
};

/// A prop as the SDK sent it (always text) back to what it holds: JSON for
/// objects / arrays, numbers and booleans as such.
Object? _propValue(String text) {
  final t = text.trimLeft();
  if (t.startsWith('{') || t.startsWith('[')) {
    try {
      return jsonDecode(text);
    } catch (_) {}
  }
  if (text == 'true' || text == 'false') return text == 'true';
  if (text == 'null' || text == 'undefined') return null;
  return num.tryParse(text) ?? text;
}

void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  showCopiedToast(context);
}

class PropertiesPanel extends StatelessWidget {
  final LayoutNode? node;
  final ScrollController scroll;

  const PropertiesPanel({super.key, required this.node, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final palette = ChromePalette.of(context);
    final node = this.node;
    if (node == null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(loc.layoutProperties),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.mousePointerClick,
                  size: 16,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.layoutPickElement,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final chain = layoutChainOf(node);
    final r = node.rect;
    final caption = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: palette.textMuted,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keys get a share of the panel: widening it shows long ones whole.
        final keyWidth = clampDouble(constraints.maxWidth * 0.4, 120, 360);
        return SelectionArea(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 16),
            children: [
              SectionLabel(
                loc.layoutProperties,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiniButton(
                      icon: LucideIcons.copy,
                      tooltip: loc.layoutCopyName,
                      onTap: () => _copy(context, node.name),
                    ),
                    MiniButton(
                      icon: LucideIcons.braces,
                      tooltip: loc.layoutCopyJson,
                      onTap: () =>
                          _copy(context, prettyJson.convert(node.toJson())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                node.name,
                style: chromeMono(
                  context,
                  size: 14,
                  color: LayoutColors.accent(palette.isDark),
                  weight: FontWeight.w700,
                ),
              ),
              // The rest of the row's chain: what this element renders.
              if (chain.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final member in chain.skip(1)) ...[
                        Icon(
                          LucideIcons.cornerDownRight,
                          size: 12,
                          color: palette.textMuted,
                        ),
                        TagChip(member.name),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: BoxModel(
                    rect: r,
                    padding: chain.map((c) => c.padding).nonNulls.firstOrNull,
                    margin: chain.map((c) => c.margin).nonNulls.firstOrNull,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (label, value) in [
                    ('X', r.left),
                    ('Y', r.top),
                    ('W', r.width),
                    ('H', r.height),
                  ])
                    Expanded(
                      child: _Stat(label: label, value: formatDp(value)),
                    ),
                ],
              ),
              // Each element of the chain has its own props and state.
              for (final member in chain)
                if (member.props.isNotEmpty || member.state.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: chromeMono(
                          context,
                          size: 12,
                          color: palette.text,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${member.props.length}',
                        style: chromeMono(
                          context,
                          size: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Divider(height: 1, color: palette.border),
                  ),
                  for (final MapEntry(:key, :value) in member.props.entries)
                    ..._PropRows.of(
                      context,
                      key,
                      _propValue(value),
                      keyWidth: keyWidth,
                    ),
                  if (member.state.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 2),
                      child: Text(
                        loc.layoutState.toUpperCase(),
                        style: caption,
                      ),
                    ),
                    for (final MapEntry(:key, :value) in member.state.entries)
                      ..._PropRows.of(
                        context,
                        key,
                        _propValue(value),
                        keyWidth: keyWidth,
                      ),
                  ],
                ],
            ],
          ),
        );
      },
    );
  }
}

/// A geometry figure: a small caption over its value.
class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: chromeMono(context, size: 12, color: palette.text)),
      ],
    );
  }
}

/// A prop as rows: one for a plain value, or a heading row plus a row per
/// entry, a level deeper, for an object or array (a `style`, a `source`).
abstract final class _PropRows {
  static const _indent = 14.0;

  static List<Widget> of(
    BuildContext context,
    String name,
    Object? value, {
    required double keyWidth,
    int depth = 0,
  }) {
    final palette = ChromePalette.of(context);
    Widget row(String text, Color color) => Padding(
      padding: EdgeInsets.only(left: depth * _indent, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: math.max(48, keyWidth - depth * _indent),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: chromeMono(
                context,
                size: 12,
                color: palette.textMuted,
              ).copyWith(height: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Value(
              // Another value starts folded.
              key: ValueKey(text),
              text: text,
              samples: colorSamplesIn(text, key: name),
              style: chromeMono(
                context,
                size: 12,
                color: color,
              ).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
    // Deeper than this an object stays one line of JSON.
    if ((value is Map || value is List) && depth < 3) {
      final entries = value is Map
          ? [for (final e in value.entries) ('${e.key}', e.value)]
          : [for (final (i, v) in (value as List).indexed) ('$i', v)];
      if (entries.isNotEmpty) {
        return [
          row(
            value is Map ? '{${entries.length}}' : '[${entries.length}]',
            palette.textMuted,
          ),
          for (final (key, child) in entries)
            ...of(context, key, child, keyWidth: keyWidth, depth: depth + 1),
        ];
      }
    }
    final (text, color) = value is Map || value is List
        ? (jsonEncode(value), palette.textMuted)
        : _typed(value, palette.isDark);
    return [row(text, color)];
  }
}

/// A value, folded to three lines when longer, with a toggle to see it all.
class _Value extends StatefulWidget {
  final String text;
  final List<(int, Color)> samples;
  final TextStyle style;

  const _Value({
    super.key,
    required this.text,
    required this.samples,
    required this.style,
  });

  @override
  State<_Value> createState() => _ValueState();
}

class _ValueState extends State<_Value> {
  static const _lines = 3;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final palette = ChromePalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measured without the color samples: when that's a little short,
        // the value just isn't folded — nothing gets hidden.
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: _lines,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final long = painter.didExceedMaxLines;
        painter.dispose();
        final folded = long && !_open;
        final value = Text.rich(
          TextSpan(
            style: widget.style,
            children: withColorSamples(
              widget.text,
              widget.samples,
              (piece) => TextSpan(text: piece),
            ),
          ),
          maxLines: folded ? _lines : null,
          overflow: folded ? TextOverflow.ellipsis : null,
        );
        if (!long) return value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            value,
            SelectionContainer.disabled(
              child: TextButton(
                onPressed: () => setState(() => _open = !_open),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  foregroundColor: LayoutColors.accent(palette.isDark),
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(_open ? loc.collapse : loc.showMore),
              ),
            ),
          ],
        );
      },
    );
  }
}
