import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'json_tree.dart' show queryMarkStyle;

/// Start and end of each case-insensitive occurrence of [query] in [text],
/// the first [limit] of them. [lower] is [text] lowercased, if already at
/// hand.
List<(int, int)> findMatches(
  String text,
  String query, {
  String? lower,
  int? limit,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final haystack = lower ?? text.toLowerCase();
  final found = <(int, int)>[];
  for (
    var at = haystack.indexOf(q);
    at >= 0 && (limit == null || found.length < limit);
    at = haystack.indexOf(q, at + q.length)
  ) {
    found.add((at, at + q.length));
  }
  return found;
}

/// [spans] (plain text, no children) with the character ranges [matches]
/// marked as search hits, the one at [current] strongest.
List<TextSpan> markMatches(
  List<TextSpan> spans,
  List<(int, int)> matches,
  int current,
) {
  if (matches.isEmpty) return spans;
  final out = <TextSpan>[];
  var next = 0;
  var offset = 0;
  for (final span in spans) {
    final text = span.text ?? '';
    var from = 0;
    while (next < matches.length && matches[next].$1 < offset + text.length) {
      final (start, end) = matches[next];
      final a = (start - offset).clamp(from, text.length);
      final b = (end - offset).clamp(a, text.length);
      if (a > from) {
        out.add(TextSpan(text: text.substring(from, a), style: span.style));
      }
      out.add(
        TextSpan(
          text: text.substring(a, b),
          style: queryMarkStyle(
            span.style ?? const TextStyle(),
            current: next == current,
          ),
        ),
      );
      from = b;
      if (end > offset + text.length) break;
      next++;
    }
    if (from == 0) {
      out.add(span);
    } else if (from < text.length) {
      out.add(TextSpan(text: text.substring(from), style: span.style));
    }
    offset += text.length;
  }
  return out;
}

/// After this frame, scrolls whatever holds [key]'s text so its character
/// [offset] is in view.
void revealTextOffset(GlobalKey key, int offset) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    RenderParagraph? paragraph;
    void find(RenderObject node) {
      if (node is RenderParagraph) paragraph ??= node;
      if (paragraph == null) node.visitChildren(find);
    }

    final root = key.currentContext?.findRenderObject();
    if (root != null) find(root);
    final text = paragraph;
    if (text == null || !text.attached) return;
    final position = TextPosition(offset: offset);
    final caret = text.getOffsetForCaret(position, Rect.zero);
    final height = text.getFullHeightForCaret(position);
    text.showOnScreen(
      rect: Rect.fromLTWH(caret.dx, caret.dy, 1, height).inflate(48),
    );
  });
}
