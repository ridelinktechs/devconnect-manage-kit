import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/local_projects_provider.dart';
import '../../core/theme/chrome_palette.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/utils/smooth_scroll_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/device_info.dart';
import '../../server/providers/server_providers.dart';

/// Bottom bar listing connected devices; picking one scopes the app to it.
/// The selected chip is a raised segment — the platform glyph keeps the
/// only color, so a row of devices stays calm.
class DeviceBottomBar extends ConsumerStatefulWidget {
  const DeviceBottomBar({super.key});

  @override
  ConsumerState<DeviceBottomBar> createState() => _DeviceBottomBarState();
}

class _DeviceBottomBarState extends ConsumerState<DeviceBottomBar> {
  final _scrollController = SmoothScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final devices = ref.watch(connectedDevicesProvider);
    final selectedId = ref.watch(selectedDeviceProvider);
    final localProjects = ref.watch(localProjectsProvider).value ?? const [];
    final palette = ChromePalette.of(context);
    final loc = S.of(context);
    final isDark = palette.isDark;

    if (devices.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          _LiveCount(
            label: loc.devicesConnected(devices.length),
            palette: palette,
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 16, color: palette.border),
          const SizedBox(width: 8),
          // "All" chip when multiple devices
          if (devices.length > 1) ...[
            _DeviceChip(
              label: loc.devicesAll,
              subtitle: loc.devicesCount(devices.length),
              icon: LucideIcons.layers,
              color: ColorTokens.primary,
              isSelected: selectedId == allDevicesValue,
              palette: palette,
              onTap: () => ref
                  .read(selectedDeviceProvider.notifier)
                  .select(
                    selectedId == allDevicesValue ? null : allDevicesValue,
                  ),
            ),
            const SizedBox(width: 4),
          ],
          // Device chips
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final d = devices[index];
                final isActive = selectedId == d.deviceId;
                final (icon, color) = platformLook(d.platform, isDark: isDark);
                return _DeviceChip(
                  label: d.appName,
                  subtitle: d.osVersion,
                  icon: icon,
                  color: color,
                  isSelected: isActive,
                  palette: palette,
                  device: d,
                  sdkVersion: deviceSdkVersion(d, localProjects),
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

// ---- Live count ----

/// "● 2 connected" — a static dot with a soft halo; the bar is on screen
/// all day, so nothing here pulses.
class _LiveCount extends StatelessWidget {
  final String label;
  final ChromePalette palette;

  const _LiveCount({required this.label, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: palette.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.success.withValues(alpha: 0.25),
                spreadRadius: 2.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}

// ---- Device Chip ----

class _DeviceChip extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final ChromePalette palette;
  final DeviceInfo? device;

  /// Shown in the details popup; null when unknown.
  final String? sdkVersion;
  final VoidCallback onTap;

  const _DeviceChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.palette,
    this.device,
    this.sdkVersion,
    required this.onTap,
  });

  @override
  State<_DeviceChip> createState() => _DeviceChipState();
}

class _DeviceChipState extends State<_DeviceChip> {
  bool _hovered = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
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
        sdkVersion: widget.sdkVersion,
        icon: widget.icon,
        color: widget.color,
        isDark: widget.palette.isDark,
        anchor: Offset(offset.dx + size.width / 2, offset.dy),
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
    final p = widget.palette;
    final selected = widget.isSelected;
    // Transparent variants of the same colors, so hover/selection fade
    // instead of flashing through black.
    final background = selected
        ? p.selected
        : _hovered
        ? p.hover
        : p.hover.withValues(alpha: 0);
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) {
          setState(() => _hovered = false);
          _removeOverlay();
        },
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: _showPopup,
          onSecondaryTap: _showPopup,
          child: Semantics(
            button: true,
            selected: selected,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? p.border : p.border.withValues(alpha: 0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 13, color: widget.color),
                  const SizedBox(width: 7),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected || _hovered ? p.text : p.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: p.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Hover Popup ----

class _DevicePopup extends StatefulWidget {
  final DeviceInfo device;
  final String? sdkVersion;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Offset anchor;
  final VoidCallback onDismiss;

  const _DevicePopup({
    required this.device,
    required this.sdkVersion,
    required this.icon,
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
    final left = (widget.anchor.dx - popupWidth / 2).clamp(
      8.0,
      MediaQuery.of(context).size.width - popupWidth - 8,
    );
    final top = widget.anchor.dy - 8; // 8px gap above chip

    return Stack(
      children: [
        // Dismiss on tap outside — uses opaque to not block chip clicks
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => widget.onDismiss(),
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
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    width: popupWidth,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? ColorTokens.darkBackground : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.4 : 0.12,
                          ),
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
                              child: Icon(widget.icon, size: 16, color: color),
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
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
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
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorTokens.success.withValues(
                                  alpha: 0.12,
                                ),
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
                                          color: ColorTokens.success.withValues(
                                            alpha: 0.5,
                                          ),
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
                          label: 'App Version',
                          value: d.versionCode != null
                              ? '${d.appVersion}(${d.versionCode})'
                              : d.appVersion,
                          isDark: isDark,
                        ),
                        if (widget.sdkVersion case final sdk?) ...[
                          const SizedBox(height: 6),
                          _PopupInfoRow(
                            icon: LucideIcons.box,
                            label: 'SDK',
                            value: 'v$sdk',
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
        Icon(icon, size: 11, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(width: 6),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        Expanded(
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
