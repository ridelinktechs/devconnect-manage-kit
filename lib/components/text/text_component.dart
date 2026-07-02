import 'package:flutter/material.dart';

/// Drop-in replacement for [Text] and [SelectableText].
///
/// Supports ALL parameters from both widgets:
/// - [selectable] = true (default) → [SelectableText]
/// - [selectable] = false → [Text]
///
/// Overflow handling with selectable text:
/// - No overflow → normal [SelectableText]
/// - Overflow + ellipsis → clips to [maxLines] + overlays "…" indicator
///
/// Usage:
/// ```dart
/// // Same API as Text:
/// TextComponent('hello', maxLines: 1, overflow: TextOverflow.ellipsis)
///
/// // Non-selectable:
/// TextComponent('hello', selectable: false, overflow: TextOverflow.ellipsis)
/// ```
class TextComponent extends StatelessWidget {
  final String data;
  final bool selectable;

  // Common
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final String? semanticsLabel;

  // Text-only
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;

  // SelectableText-only
  final Color? selectionColor;
  final FocusNode? focusNode;

  const TextComponent(
    this.data, {
    super.key,
    this.selectable = true,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.semanticsLabel,
    this.locale,
    this.softWrap,
    this.overflow,
    this.selectionColor,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    // Non-selectable → plain Text, full param support.
    if (!selectable) {
      return Text(
        data,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        maxLines: maxLines,
        overflow: overflow,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        semanticsLabel: semanticsLabel,
      );
    }

    // Selectable + overflow ellipsis → clip + overlay.
    if (maxLines != null && overflow == TextOverflow.ellipsis) {
      return _SelectableEllipsis(
        data: data,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines!,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        semanticsLabel: semanticsLabel,
        selectionColor: selectionColor,
        focusNode: focusNode,
      );
    }

    // Selectable, no overflow → simple.
    return SelectableText(
      data,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      semanticsLabel: semanticsLabel,
      selectionColor: selectionColor,
      focusNode: focusNode,
    );
  }
}

class _SelectableEllipsis extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int maxLines;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final String? semanticsLabel;
  final Color? selectionColor;
  final FocusNode? focusNode;

  const _SelectableEllipsis({
    required this.data,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    required this.maxLines,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.semanticsLabel,
    this.selectionColor,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: data, style: style),
        maxLines: maxLines,
        textDirection: textDirection ?? TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      final didOverflow = painter.didExceedMaxLines;
      painter.dispose();

      if (!didOverflow) {
        return SelectableText(data,
            style: style,
            strutStyle: strutStyle,
            textAlign: textAlign,
            textDirection: textDirection,
            maxLines: null,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
            semanticsLabel: semanticsLabel,
            selectionColor: selectionColor,
            focusNode: focusNode);
      }

      final ds = DefaultTextStyle.of(context).style.merge(style);
      final lh = (ds.fontSize ?? 14) * (ds.height ?? 1.2);
      final bg = Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A2E)
          : Colors.white;

      return SizedBox(
        height: lh * maxLines,
        child: ClipRect(
          child: Stack(children: [
            Positioned.fill(
              child: SelectableText(data,
                  style: style,
                  strutStyle: strutStyle,
                  textAlign: textAlign,
                  textDirection: textDirection,
                  textWidthBasis: textWidthBasis,
                  textHeightBehavior: textHeightBehavior,
                  semanticsLabel: semanticsLabel,
                  selectionColor: selectionColor,
                  focusNode: focusNode),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, bg],
                  ),
                ),
                child: Text('…', style: ds),
              ),
            ),
          ]),
        ),
      );
    });
  }
}
