// Lucian UX/UI Prompt #072 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#072
import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../shared/mock_look.dart';

/// The top of the rule editor as Lucian #072's inline alert, like the
/// Console's detail header: a wash and a 3px bar in the status's color, the
/// status code on a solid tile, then the rule's name, what it matches and,
/// in words, how it answers. It follows the draft as you type.
class RuleHeader extends StatelessWidget {
  final String name;
  final String method;
  final String url;

  /// Null while the status box doesn't hold a valid code.
  final int? status;
  final int? delayMs;
  final int devices;
  final String expires;
  final bool enabled;
  final Widget action;

  const RuleHeader({
    super.key,
    required this.name,
    required this.method,
    required this.url,
    required this.status,
    required this.delayMs,
    required this.devices,
    required this.expires,
    required this.enabled,
    required this.action,
  });

  String get _summary => [
    if (!enabled) 'Paused',
    if (status case final code?)
      'Answers ${'$code ${statusReason(code)}'.trim()}',
    if (delayMs case final ms? when ms > 0) 'after ${formatDelay(ms)}',
    if (devices > 0) 'only on $devices device${devices == 1 ? '' : 's'}',
    if (expires.isNotEmpty) 'until $expires',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final c = status == null ? p.textMuted : statusTint(status!);
    final l = c.computeLuminance();
    final onTile = 1.05 / (l + 0.05) >= (l + 0.05) / 0.067
        ? Colors.white
        : const Color(0xFF1F2328);
    final base = DefaultTextStyle.of(context).style;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(c.withValues(alpha: 0.10), p.surface),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withValues(alpha: 0.22)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -14,
              top: 0,
              bottom: 0,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(3),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    status == null ? '???' : '$status',
                    style: chromeMono(
                      context,
                      size: 12.5,
                      color: onTile,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.trim().isEmpty ? '(unnamed rule)' : name.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: base.copyWith(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.28,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$method  ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: methodInk(method, isDark: p.isDark),
                              ),
                            ),
                            TextSpan(text: url.trim().isEmpty ? '—' : url),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: chromeMono(
                          context,
                          size: 11.5,
                          color: p.textMuted,
                        ),
                      ),
                      if (_summary.isNotEmpty)
                        Text(
                          _summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: base.copyWith(
                            fontSize: 12.5,
                            height: 1.5,
                            color: p.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                action,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
