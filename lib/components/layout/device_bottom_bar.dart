import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/color_tokens.dart';
import '../../models/device_info.dart';
import '../../server/providers/server_providers.dart';

/// Bottom bar showing connected devices with glow animation on selected item.
class DeviceBottomBar extends ConsumerWidget {
  const DeviceBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(connectedDevicesProvider);
    final selectedId = ref.watch(selectedDeviceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (devices.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Status indicator
          _StatusDot(count: devices.length, isDark: isDark),
          const SizedBox(width: 10),
          // Vertical divider
          Container(
            width: 1,
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(width: 6),
          // "All" chip when multiple devices
          if (devices.length > 1) ...[
            _DeviceChip(
              label: 'All',
              subtitle: '${devices.length} devices',
              icon: LucideIcons.layers,
              color: ColorTokens.primary,
              isSelected: selectedId == null,
              isDark: isDark,
              onTap: () =>
                  ref.read(selectedDeviceProvider.notifier).select(null),
            ),
            const SizedBox(width: 4),
          ],
          // Device chips
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final d = devices[index];
                final isActive = selectedId == d.deviceId;
                return _DeviceChip(
                  label: _platformLabel(d.platform),
                  subtitle: d.appName,
                  icon: _platformIcon(d.platform),
                  color: _platformColor(d.platform),
                  isSelected: isActive,
                  isDark: isDark,
                  device: d,
                  onTap: () => ref
                      .read(selectedDeviceProvider.notifier)
                      .select(isActive ? null : d.deviceId),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ---- Status Dot ----

class _StatusDot extends StatelessWidget {
  final int count;
  final bool isDark;

  const _StatusDot({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: ColorTokens.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorTokens.success.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$count connected',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

// ---- Device Chip (with glow animation on selected) ----

class _DeviceChip extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final DeviceInfo? device;
  final VoidCallback onTap;

  const _DeviceChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isDark,
    this.device,
    required this.onTap,
  });

  @override
  State<_DeviceChip> createState() => _DeviceChipState();
}

class _DeviceChipState extends State<_DeviceChip>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.isSelected) _glowController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_DeviceChip old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isSelected && old.isSelected) {
      _glowController.stop();
      _glowController.value = 0;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _glowController.dispose();
    super.dispose();
  }

  void _showPopup() {
    if (widget.device == null) return;
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _DevicePopup(
        device: widget.device!,
        color: widget.color,
        isDark: widget.isDark,
        anchor: Offset(
          offset.dx + size.width / 2,
          offset.dy,
        ),
        onDismiss: _removeOverlay,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _showPopup();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _removeOverlay();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            final glowAlpha = widget.isSelected ? _glowAnimation.value : 0.0;

            return Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.color.withValues(alpha: 0.12)
                    : _hovered
                        ? widget.color.withValues(alpha: 0.06)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isSelected
                      ? widget.color.withValues(alpha: 0.4)
                      : _hovered
                          ? widget.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                  width: widget.isSelected ? 1.2 : 0.8,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: glowAlpha * 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: widget.color.withValues(alpha: glowAlpha * 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Platform icon
                  Icon(widget.icon, size: 13, color: widget.color),
                  const SizedBox(width: 6),
                  // Label
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isSelected
                          ? widget.color
                          : widget.isDark
                              ? Colors.white70
                              : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // App name
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.isDark ? Colors.white30 : Colors.black26,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Glow dot for selected
                  if (widget.isSelected) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                widget.color.withValues(alpha: glowAlpha * 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---- Hover Popup ----

class _DevicePopup extends StatefulWidget {
  final DeviceInfo device;
  final Color color;
  final bool isDark;
  final Offset anchor;
  final VoidCallback onDismiss;

  const _DevicePopup({
    required this.device,
    required this.color,
    required this.isDark,
    required this.anchor,
    required this.onDismiss,
  });

  @override
  State<_DevicePopup> createState() => _DevicePopupState();
}

class _DevicePopupState extends State<_DevicePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final color = widget.color;
    final isDark = widget.isDark;

    const popupWidth = 240.0;

    // Position popup above the chip, centered
    final left = (widget.anchor.dx - popupWidth / 2)
        .clamp(8.0, MediaQuery.of(context).size.width - popupWidth - 8);
    final top = widget.anchor.dy - 8; // 8px gap above chip

    return Stack(
      children: [
        // Tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: left,
          bottom: MediaQuery.of(context).size.height - top,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: AnimatedBuilder(
              animation: _slideAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: _slideAnim.value,
                  child: child,
                );
              },
              child: MouseRegion(
                // Keep popup visible while hovering it
                onEnter: (_) {},
                onExit: (_) => widget.onDismiss(),
                child: Container(
                  width: popupWidth,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161B22) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.08),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              _platformIcon(d.platform),
                              size: 16,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.appName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _platformLabel(d.platform),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Connected indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  ColorTokens.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: ColorTokens.success,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: ColorTokens.success
                                            .withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: ColorTokens.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Divider
                      Container(
                        height: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      const SizedBox(height: 10),
                      // Info rows
                      _PopupInfoRow(
                        icon: LucideIcons.monitor,
                        label: 'Device',
                        value: d.deviceName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 6),
                      _PopupInfoRow(
                        icon: LucideIcons.cog,
                        label: 'OS',
                        value: d.osVersion,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 6),
                      _PopupInfoRow(
                        icon: LucideIcons.tag,
                        label: 'Version',
                        value: 'v${d.appVersion}',
                        isDark: isDark,
                      ),
                      if (d.sdkVersion != null) ...[
                        const SizedBox(height: 6),
                        _PopupInfoRow(
                          icon: LucideIcons.box,
                          label: 'SDK',
                          value: 'v${d.sdkVersion}',
                          isDark: isDark,
                        ),
                      ],
                      // Arrow pointing down
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopupInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _PopupInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 11,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ---- Platform helpers ----

Color _platformColor(String platform) {
  switch (platform.toLowerCase()) {
    case 'flutter':
      return const Color(0xFF02569B);
    case 'react_native':
    case 'reactnative':
      return const Color(0xFF61DAFB);
    case 'android':
      return const Color(0xFF3DDC84);
    default:
      return Colors.grey;
  }
}

IconData _platformIcon(String platform) {
  switch (platform.toLowerCase()) {
    case 'flutter':
      return LucideIcons.smartphone;
    case 'react_native':
    case 'reactnative':
      return LucideIcons.atom;
    case 'android':
      return LucideIcons.tablet;
    default:
      return LucideIcons.monitor;
  }
}

String _platformLabel(String platform) {
  switch (platform.toLowerCase()) {
    case 'flutter':
      return 'Flutter';
    case 'react_native':
    case 'reactnative':
      return 'React Native';
    case 'android':
      return 'Android';
    default:
      return platform;
  }
}
