import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/tab_visibility_provider.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../server/providers/server_providers.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String routePath;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.routePath,
  });
}

final sidebarItems = [
  const SidebarItem(
    label: 'All',
    icon: LucideIcons.layoutDashboard,
    routePath: '/all',
  ),
  const SidebarItem(
    label: 'Console',
    icon: LucideIcons.terminal,
    routePath: '/console',
  ),
  const SidebarItem(
    label: 'Network',
    icon: LucideIcons.globe,
    routePath: '/network',
  ),
  const SidebarItem(
    label: 'State',
    icon: LucideIcons.layers,
    routePath: '/state',
  ),
  const SidebarItem(
    label: 'Storage',
    icon: LucideIcons.database,
    routePath: '/storage',
  ),
  const SidebarItem(
    label: 'Database',
    icon: LucideIcons.hardDrive,
    routePath: '/database',
  ),
  const SidebarItem(
    label: 'Perf',
    icon: LucideIcons.gauge,
    routePath: '/performance',
  ),
  const SidebarItem(
    label: 'Leaks',
    icon: LucideIcons.bug,
    routePath: '/memory-leaks',
  ),
  const SidebarItem(
    label: 'History',
    icon: LucideIcons.history,
    routePath: '/history',
  ),
  const SidebarItem(
    label: 'Settings',
    icon: LucideIcons.settings,
    routePath: '/settings',
  ),
];

class Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final devices = ref.watch(connectedDevicesProvider);
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    if (isCollapsed) {
      return _CollapsedSidebar(
        isDark: isDark,
        onExpand: () =>
            ref.read(sidebarCollapsedProvider.notifier).state = false,
      );
    }

    return Container(
      width: 68,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF),
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 64),
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ColorTokens.primary, ColorTokens.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: ColorTokens.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(22, 22),
                painter: _ConnectionHubPainter(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Connection indicator
          _ConnectionBadge(deviceCount: devices.length),
          const SizedBox(height: 16),
          const Divider(height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 8),
          // Navigation items
          Expanded(
            child: Builder(builder: (context) {
              final enabledTabs = ref.watch(tabVisibilityProvider);
              return ListView.builder(
                itemCount: sidebarItems.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final item = sidebarItems[index];
                  final isSelected = index == selectedIndex;
                  final isLocked =
                      !isTabEnabled(enabledTabs, item.routePath);
                  return _SidebarButton(
                    icon: item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    isLocked: isLocked,
                    onTap: () => onItemSelected(index),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 4),
          // Theme toggle
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _SidebarButton(
              icon: isDark ? LucideIcons.sun : LucideIcons.moon,
              label: isDark ? 'Light' : 'Dark',
              isSelected: false,
              onTap: () => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),
          // Collapse sidebar
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
            child: _CollapseExpandButton(
              icon: LucideIcons.panelLeftClose,
              tooltip: 'Collapse sidebar',
              isDark: isDark,
              onTap: () =>
                  ref.read(sidebarCollapsedProvider.notifier).state = true,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CollapsedSidebar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onExpand;

  const _CollapsedSidebar({required this.isDark, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 64),
          _CollapseExpandButton(
            icon: LucideIcons.panelLeftOpen,
            tooltip: 'Expand sidebar',
            isDark: isDark,
            onTap: onExpand,
          ),
        ],
      ),
    );
  }
}

class _CollapseExpandButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _CollapseExpandButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_CollapseExpandButton> createState() => _CollapseExpandButtonState();
}

class _CollapseExpandButtonState extends State<_CollapseExpandButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _hovered
                    ? (widget.isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1))
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered
                  ? (widget.isDark ? Colors.white70 : Colors.black54)
                  : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor;
    if (widget.isSelected) {
      bgColor = ColorTokens.primary.withValues(alpha: 0.15);
    } else if (_isHovered) {
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04);
    } else {
      bgColor = Colors.transparent;
    }

    final iconColor = widget.isSelected
        ? ColorTokens.primary
        : isDark
            ? const Color(0xFF8B949E)
            : const Color(0xFF656D76);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: widget.isSelected
                  ? Border.all(
                      color: ColorTokens.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(widget.icon, size: 20, color: iconColor),
                    if (widget.isLocked)
                      Positioned(
                        right: -6,
                        bottom: -4,
                        child: Icon(
                          LucideIcons.lock,
                          size: 9,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.isLocked
                        ? Colors.grey[600]
                        : iconColor,
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

class _ConnectionBadge extends StatelessWidget {
  final int deviceCount;

  const _ConnectionBadge({required this.deviceCount});

  @override
  Widget build(BuildContext context) {
    final isConnected = deviceCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isConnected
            ? ColorTokens.success.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConnected ? ColorTokens.success : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$deviceCount',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isConnected ? ColorTokens.success : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionHubPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final hubR = size.width * 0.22;
    final nodeR = size.width * 0.1;
    final nodeDist = size.width * 0.4;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = Colors.white;
    final hubPaint = Paint()..color = Colors.white;
    final innerPaint = Paint()..color = const Color(0xFF14A096);

    // 3 connection lines
    const angles = [-0.5236, 1.5708, 3.6652]; // -30°, 90°, 210° in radians
    for (final a in angles) {
      final nx = cx + nodeDist * _cos(a);
      final ny = cy + nodeDist * _sin(a);
      canvas.drawLine(Offset(cx, cy), Offset(nx, ny), linePaint);
    }

    // Outer nodes
    for (final a in angles) {
      final nx = cx + nodeDist * _cos(a);
      final ny = cy + nodeDist * _sin(a);
      canvas.drawCircle(Offset(nx, ny), nodeR, nodePaint);
    }

    // Center hub
    canvas.drawCircle(Offset(cx, cy), hubR, hubPaint);
    canvas.drawCircle(Offset(cx, cy), hubR * 0.5, innerPaint);
  }

  double _cos(double rad) => rad == 1.5708 ? 0.0 : (rad == -0.5236 ? 0.866 : -0.866);
  double _sin(double rad) => rad == 1.5708 ? 1.0 : (rad == -0.5236 ? -0.5 : -0.5);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
