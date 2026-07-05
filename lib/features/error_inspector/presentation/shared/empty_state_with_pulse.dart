import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';

/// Rich empty state with a breathing shield icon and a one-shot
/// fade+slide entrance for the title.
///
/// Replaces the bland `EmptyState(icon: checkCircle, …)` from
/// `lib/components/feedback/empty_state.dart` with a layout that has
/// actual motion: a stacked shield with two concentric breathing rings
/// that perpetually expand + fade, plus a title that fades + slides in
/// when the widget mounts.
class EmptyStateWithPulse extends StatefulWidget {
  final String title;
  final String subtitle;

  const EmptyStateWithPulse({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<EmptyStateWithPulse> createState() => _EmptyStateWithPulseState();
}

class _EmptyStateWithPulseState extends State<EmptyStateWithPulse>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryOpacity;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    // Slow breathing loop for the rings (perpetual motion, no user trigger)
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    // One-shot entrance animation for the title + icon
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    ));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: FadeTransition(
        opacity: _entryOpacity,
        child: SlideTransition(
          position: _entrySlide,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated shield with breathing rings (perpetual motion)
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _breathCtrl,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Transform.scale(
                          scale: 0.85 + 0.15 * _breathCtrl.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorTokens.logError
                                    .withValues(alpha: 0.12 + 0.08 * _breathCtrl.value),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Inner ring
                        Transform.scale(
                          scale: 0.55 + 0.10 * (1 - _breathCtrl.value),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorTokens.logError
                                    .withValues(alpha: 0.20 + 0.10 * (1 - _breathCtrl.value)),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Shield icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorTokens.logError.withValues(alpha: 0.10),
                            border: Border.all(
                              color: ColorTokens.logError.withValues(alpha: 0.30),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.shieldCheck,
                            size: 28,
                            color: ColorTokens.logError,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark
                      ? ColorTokens.lightBackground
                      : ColorTokens.darkNeutral,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}