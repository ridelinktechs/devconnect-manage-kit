import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';

class ScrollDirectionButton extends ConsumerWidget {
  const ScrollDirectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(scrollDirectionProvider);
    final isTop = dir == ScrollDirection.top;

    return GestureDetector(
      onTap: () {
        ref.read(scrollDirectionProvider.notifier).set(
            isTop ? ScrollDirection.bottom : ScrollDirection.top);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: isTop ? 'Scroll to top (newest)' : 'Scroll to bottom (newest)',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTop ? LucideIcons.arrowUpToLine : LucideIcons.arrowDownToLine,
                  size: 14,
                  color: ColorTokens.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  isTop ? 'TOP' : 'BTM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ColorTokens.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
