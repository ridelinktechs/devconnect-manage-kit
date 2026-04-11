import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/tab_visibility_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../server/providers/server_providers.dart';

// ═══════════════════════════════════════════════════════════════════
// Settings Page — redesigned with two-column grid, tab visibility
// ═══════════════════════════════════════════════════════════════════

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _portController;
  List<_NetworkInfo> _networkInfos = [];
  String _hostName = '';

  @override
  void initState() {
    super.initState();
    final server = ref.read(wsServerProvider);
    final actualPort = server.isRunning ? server.port : AppConstants.defaultPort;
    _portController = TextEditingController(text: '$actualPort');
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    try {
      final interfaces = await NetworkInterface.list();
      final infos = <_NetworkInfo>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            infos.add(_NetworkInfo(
              ip: addr.address,
              interfaceName: iface.name,
              type: _guessInterfaceType(iface.name),
            ));
          }
        }
      }
      final hostName = Platform.localHostname;
      if (mounted) {
        setState(() {
          _networkInfos = infos;
          _hostName = hostName;
        });
      }
    } catch (_) {}
  }

  String _guessInterfaceType(String name) {
    final lower = name.toLowerCase();
    if (lower.startsWith('en') || lower.startsWith('eth')) return 'Ethernet';
    if (lower.startsWith('wl') ||
        lower.contains('wi-fi') ||
        lower.contains('wifi')) return 'WiFi';
    if (lower.startsWith('utun') ||
        lower.startsWith('tun') ||
        lower.startsWith('ipsec')) return 'VPN';
    if (lower.startsWith('bridge')) return 'Bridge';
    if (lower.startsWith('lo')) return 'Loopback';
    return name;
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  void _copy(String text, [String? label]) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label ?? 'Copied'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 200,
      ),
    );
  }

  String _describeStartError(Object error, int port) {
    final msg = error.toString();
    if (msg.contains('Address already in use') ||
        msg.contains('errno = 48') ||
        msg.contains('errno = 98')) {
      return 'Port $port is already in use. '
          'Close the other app using this port, or enter a different port above and press Start.';
    }
    return 'Failed to start server on port $port: $msg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final server = ref.watch(wsServerProvider);
    final devices = ref.watch(connectedDevicesProvider);

    final surface = isDark ? ColorTokens.darkBackground : Colors.white;
    final surfaceAlt = isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);
    final port = server.isRunning ? server.port : AppConstants.defaultPort;

    return Container(
      color: surfaceAlt,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page Header ──
                _PageHeader(server: server, deviceCount: devices.length),
                const SizedBox(height: 24),

                // ── Two-column grid ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        children: [
                          // Server & Connection
                          _Card(
                            surface: surface,
                            border: border,
                            child: _ServerSection(
                              portController: _portController,
                              server: server,
                              onStartStop: () async {
                                final p = int.tryParse(_portController.text) ??
                                    AppConstants.defaultPort;
                                if (server.isRunning) {
                                  await server.stop();
                                  ref
                                      .read(serverStartErrorProvider.notifier)
                                      .state = null;
                                } else {
                                  try {
                                    await server.start(port: p);
                                    ref
                                        .read(
                                            serverStartErrorProvider.notifier)
                                        .state = null;
                                  } catch (e) {
                                    ref
                                            .read(serverStartErrorProvider
                                                .notifier)
                                            .state =
                                        _describeStartError(e, p);
                                  }
                                }
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Network IPs
                          _Card(
                            surface: surface,
                            border: border,
                            child: _NetworkSection(
                              hostName: _hostName,
                              networkInfos: _networkInfos,
                              onCopy: _copy,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Connected Devices
                          _Card(
                            surface: surface,
                            border: border,
                            child: _DevicesSection(devices: devices),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right column
                    Expanded(
                      child: Column(
                        children: [
                          // Appearance
                          _Card(
                            surface: surface,
                            border: border,
                            child: const _AppearanceSection(),
                          ),
                          const SizedBox(height: 16),

                          // Tab Visibility
                          _Card(
                            surface: surface,
                            border: border,
                            child: const _TabVisibilitySection(),
                          ),
                          const SizedBox(height: 16),

                          // Detail View
                          _Card(
                            surface: surface,
                            border: border,
                            child: const _DetailViewSection(),
                          ),
                          const SizedBox(height: 16),

                          // USB Tools
                          _Card(
                            surface: surface,
                            border: border,
                            child: _UsbToolsSection(
                              port: port,
                              onCopy: _copy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Quick Start Guide ──
                _Card(
                  surface: surface,
                  border: border,
                  child: _QuickStartSection(
                    ip: _networkInfos.isNotEmpty
                        ? _networkInfos.first.ip
                        : 'your-pc-ip',
                  ),
                ),
                const SizedBox(height: 16),

                // ── Support / Donate ──
                _Card(
                  surface: surface,
                  border: border,
                  child: const _DonateSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Page Header
// ═══════════════════════════════════════════════════════════════════

class _PageHeader extends StatelessWidget {
  final dynamic server;
  final int deviceCount;

  const _PageHeader({required this.server, required this.deviceCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8B7EF0)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.settings, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const Spacer(),
        _StatusChip(
          color: server.isRunning ? ColorTokens.success : ColorTokens.error,
          label: server.isRunning ? 'Server Running' : 'Server Stopped',
          icon: server.isRunning ? LucideIcons.wifi : LucideIcons.wifiOff,
        ),
        const SizedBox(width: 8),
        _StatusChip(
          color: deviceCount > 0 ? ColorTokens.info : Colors.grey,
          label: '$deviceCount device${deviceCount != 1 ? 's' : ''}',
          icon: LucideIcons.smartphone,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _StatusChip({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Card wrapper
// ═══════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Color surface;
  final Color border;
  final Widget child;

  const _Card({
    required this.surface,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Section header helper
// ═══════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ColorTokens.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Server Section
// ═══════════════════════════════════════════════════════════════════

class _ServerSection extends ConsumerWidget {
  final TextEditingController portController;
  final dynamic server;
  final VoidCallback onStartStop;

  const _ServerSection({
    required this.portController,
    required this.server,
    required this.onStartStop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startError = ref.watch(serverStartErrorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: LucideIcons.server, title: 'Server'),
        Row(
          children: [
            Text('Port', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              height: 34,
              child: TextField(
                controller: portController,
                enabled: !server.isRunning,
                style: TextStyle(
                  fontFamily: AppConstants.monoFontFamily,
                  fontSize: 13,
                  color: server.isRunning ? Colors.grey : null,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: server.isRunning ? 'Stop' : 'Start',
              icon: server.isRunning ? LucideIcons.square : LucideIcons.play,
              color: server.isRunning ? ColorTokens.error : ColorTokens.success,
              onTap: onStartStop,
            ),
          ],
        ),
        if (startError != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorTokens.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorTokens.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.triangleAlert,
                  size: 14,
                  color: ColorTokens.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    startError,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ColorTokens.error,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref
                      .read(serverStartErrorProvider.notifier)
                      .state = null,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: ColorTokens.error.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Network Section
// ═══════════════════════════════════════════════════════════════════

class _NetworkSection extends StatelessWidget {
  final String hostName;
  final List<_NetworkInfo> networkInfos;
  final void Function(String, [String?]) onCopy;

  const _NetworkSection({
    required this.hostName,
    required this.networkInfos,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: LucideIcons.wifi, title: 'Network'),
        if (hostName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('Hostname',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 8),
                Text(
                  hostName,
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (networkInfos.isEmpty)
          Text('No network interfaces found',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))
        else
          ...networkInfos.map((info) => _IpRow(info: info, onCopy: onCopy)),
      ],
    );
  }
}

class _IpRow extends StatelessWidget {
  final _NetworkInfo info;
  final void Function(String, [String?]) onCopy;

  const _IpRow({required this.info, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => onCopy(info.ip, 'Copied ${info.ip}'),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: ColorTokens.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorTokens.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  info.type == 'WiFi'
                      ? LucideIcons.wifi
                      : info.type == 'VPN'
                          ? LucideIcons.shield
                          : LucideIcons.cable,
                  size: 13,
                  color: ColorTokens.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  info.ip,
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${info.interfaceName} · ${info.type}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: AppConstants.monoFontFamily,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.copy, size: 11, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Devices Section
// ═══════════════════════════════════════════════════════════════════

class _DevicesSection extends ConsumerWidget {
  final List<dynamic> devices;

  const _DevicesSection({required this.devices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: LucideIcons.smartphone,
          title: 'Connected Devices (${devices.length})',
        ),
        if (devices.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.monitorOff, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 10),
                Text(
                  'No devices connected',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ...devices.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : ColorTokens.lightSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    PlatformBadge(platform: d.platform),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.appName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            d.deviceName != d.osVersion
                                ? '${d.deviceName} · ${d.osVersion}'
                                : d.osVersion,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ColorTokens.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Appearance Section
// ═══════════════════════════════════════════════════════════════════

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scrollDir = ref.watch(scrollDirectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: LucideIcons.palette, title: 'Appearance'),
        // Theme
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text('Theme',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(LucideIcons.moon, size: 14),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(LucideIcons.sun, size: 14),
                    label: Text('Light'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (value) {
                  final mode = value.first;
                  if (mode == ThemeMode.dark) {
                    ref.read(themeModeProvider.notifier).setDark();
                  } else {
                    ref.read(themeModeProvider.notifier).setLight();
                  }
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Scroll direction
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text('Auto-scroll',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<ScrollDirection>(
                segments: const [
                  ButtonSegment(
                    value: ScrollDirection.bottom,
                    icon: Icon(LucideIcons.arrowDownToLine, size: 14),
                    label: Text('Bottom'),
                  ),
                  ButtonSegment(
                    value: ScrollDirection.top,
                    icon: Icon(LucideIcons.arrowUpToLine, size: 14),
                    label: Text('Top'),
                  ),
                ],
                selected: {scrollDir},
                onSelectionChanged: (value) {
                  ref.read(scrollDirectionProvider.notifier).state = value.first;
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Tab Visibility Section
// ═══════════════════════════════════════════════════════════════════

class _TabVisibilitySection extends ConsumerWidget {
  const _TabVisibilitySection();

  static const _tabs = <(TabKey, String, IconData, Color)>[
    (TabKey.console, 'Console', LucideIcons.terminal, Color(0xFF58A6FF)),
    (TabKey.network, 'Network', LucideIcons.globe, ColorTokens.success),
    (TabKey.state, 'State', LucideIcons.layers, ColorTokens.secondary),
    (TabKey.storage, 'Storage', LucideIcons.database, ColorTokens.warning),
    (TabKey.database, 'Database', LucideIcons.hardDrive, Color(0xFFD2A8FF)),
    (TabKey.performance, 'Performance', LucideIcons.gauge, ColorTokens.chartGreen),
    (TabKey.memoryLeaks, 'Memory Leaks', LucideIcons.bug, ColorTokens.chartRed),
    (TabKey.history, 'History', LucideIcons.history, Colors.grey),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledTabs = ref.watch(tabVisibilityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: LucideIcons.layoutGrid,
          title: 'Tab Visibility',
        ),
        Text(
          'Toggle which tabs are visible. Disabled tabs show a lock icon and their data is excluded from All Events.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 12),
        ..._tabs.map((t) {
          final (key, label, icon, color) = t;
          final isEnabled = enabledTabs.contains(key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () =>
                  ref.read(tabVisibilityProvider.notifier).toggle(key),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? color.withValues(alpha: 0.06)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.grey.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEnabled
                          ? color.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isEnabled ? color : Colors.grey[600],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isEnabled
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (!isEnabled)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            LucideIcons.lock,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      SizedBox(
                        width: 40,
                        height: 22,
                        child: FittedBox(
                          child: Switch(
                            value: isEnabled,
                            onChanged: (_) => ref
                                .read(tabVisibilityProvider.notifier)
                                .toggle(key),
                            activeTrackColor: color.withValues(alpha: 0.5),
                            activeThumbColor: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// USB Tools Section (ADB + iProxy combined)
// ═══════════════════════════════════════════════════════════════════

/// Resolve the full path to adb binary.
/// Checks common SDK locations and user's shell PATH.
Future<String?> _resolveAdbPath() async {
  final isWindows = Platform.isWindows;
  final adbName = isWindows ? 'adb.exe' : 'adb';

  // 1. Check ANDROID_HOME / ANDROID_SDK_ROOT first
  final androidHome = Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  final candidates = <String>[];
  if (androidHome != null) {
    candidates.add('$androidHome/platform-tools/$adbName');
  }

  if (isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    candidates.addAll([
      '$localAppData\\Android\\Sdk\\platform-tools\\adb.exe',
      '$userProfile\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe',
      'C:\\Android\\sdk\\platform-tools\\adb.exe',
    ]);
  } else {
    final home = Platform.environment['HOME'] ?? '';
    candidates.addAll([
      '$home/Library/Android/sdk/platform-tools/adb', // macOS
      '$home/Android/Sdk/platform-tools/adb', // Linux
      '/usr/local/bin/adb',
      '/opt/homebrew/bin/adb',
    ]);
  }

  for (final path in candidates) {
    if (await File(path).exists()) return path;
  }

  // 2. Try resolving via shell
  try {
    final result = isWindows
        ? await Process.run('where', ['adb'])
        : await Process.run('/bin/sh', ['-lc', 'which adb']);
    final path = result.stdout.toString().trim().split('\n').first;
    if (result.exitCode == 0 && path.isNotEmpty && await File(path).exists()) {
      return path;
    }
  } catch (_) {}

  return null;
}

// ═══════════════════════════════════════════════════════════════════
// Detail View Section — body view mode + tab animation
// ═══════════════════════════════════════════════════════════════════

class _DetailViewSection extends ConsumerWidget {
  const _DetailViewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(bodyViewModeProvider);
    final animEnabled = ref.watch(tabAnimationEnabledProvider);
    final animMs = ref.watch(tabAnimationDurationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: LucideIcons.panelRight,
          title: 'Detail View',
        ),
        Text(
          'Remembers how request/response bodies are shown and controls tab switching animation.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 14),

        // Body view mode
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text('Body view',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<BodyViewMode>(
                segments: const [
                  ButtonSegment(
                    value: BodyViewMode.tree,
                    icon: Icon(LucideIcons.listTree, size: 14),
                    label: Text('Tree'),
                  ),
                  ButtonSegment(
                    value: BodyViewMode.json,
                    icon: Icon(LucideIcons.braces, size: 14),
                    label: Text('JSON'),
                  ),
                  ButtonSegment(
                    value: BodyViewMode.code,
                    icon: Icon(LucideIcons.code, size: 14),
                    label: Text('Code'),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (value) {
                  ref
                      .read(bodyViewModeProvider.notifier)
                      .set(value.first);
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(
            'Code mode exports as TypeScript / Dart / Kotlin based on the connected SDK.',
            style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
          ),
        ),
        const SizedBox(height: 14),

        // Tab animation toggle
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text('Tab animation',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Switch.adaptive(
              value: animEnabled,
              onChanged: (v) =>
                  ref.read(tabAnimationEnabledProvider.notifier).set(v),
            ),
            const SizedBox(width: 8),
            Text(
              animEnabled ? 'On' : 'Off',
              style: TextStyle(
                fontSize: 12,
                color: animEnabled
                    ? ColorTokens.primary
                    : Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Duration slider (only when enabled)
        Opacity(
          opacity: animEnabled ? 1.0 : 0.45,
          child: IgnorePointer(
            ignoring: !animEnabled,
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('Duration',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[500])),
                ),
                Expanded(
                  child: Slider(
                    value: animMs.toDouble(),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    label: '${animMs}ms',
                    onChanged: (v) => ref
                        .read(tabAnimationDurationProvider.notifier)
                        .set(v.round()),
                  ),
                ),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${animMs}ms',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppConstants.monoFontFamily,
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UsbToolsSection extends StatelessWidget {
  final int port;
  final void Function(String, [String?]) onCopy;

  const _UsbToolsSection({required this.port, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBg = isDark ? ColorTokens.darkSurface : const Color(0xFFF0F0F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: LucideIcons.usb, title: 'USB Connection'),

        // Android
        Text('Android',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3DDC84),
            )),
        const SizedBox(height: 6),
        _CodeBlock(
          code: 'adb reverse tcp:$port tcp:$port',
          bg: codeBg,
          onCopy: onCopy,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _ActionButton(
              label: 'Run ADB Reverse',
              icon: LucideIcons.refreshCw,
              color: ColorTokens.secondary,
              onTap: () async {
                try {
                  final adbPath = await _resolveAdbPath();
                  if (adbPath == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'adb not found.\nHOME=${Platform.environment['HOME'] ?? 'null'}\nChecked: ~/Library/Android/sdk/platform-tools/adb',
                          ),
                          backgroundColor: ColorTokens.error,
                          behavior: SnackBarBehavior.floating,
                          width: 500,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                    return;
                  }
                  final result = await Process.run(
                    adbPath,
                    ['reverse', 'tcp:$port', 'tcp:$port'],
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.exitCode == 0
                              ? 'adb reverse OK ($adbPath)'
                              : 'adb error: ${result.stderr}',
                        ),
                        backgroundColor: result.exitCode == 0
                            ? ColorTokens.success
                            : ColorTokens.error,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        width: 400,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('adb exception: $e'),
                        backgroundColor: ColorTokens.error,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(width: 6),
            _ActionButton(
              label: 'Devices',
              icon: LucideIcons.smartphone,
              color: Colors.grey,
              onTap: () async {
                try {
                  final adbPath = await _resolveAdbPath();
                  if (adbPath == null) return;
                  final result = await Process.run(adbPath, ['devices']);
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('ADB Devices'),
                        content: Text(
                          result.stdout.toString().trim(),
                          style: const TextStyle(
                            fontFamily: AppConstants.monoFontFamily,
                            fontSize: 12,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (_) {}
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // iOS
        Text('iOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            )),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorTokens.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: ColorTokens.success.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.wifi, size: 13, color: ColorTokens.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'WiFi auto-connects if same network. USB: install iproxy.',
                  style: TextStyle(fontSize: 11, color: ColorTokens.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _CodeBlock(
          code: 'brew install libimobiledevice',
          bg: codeBg,
          onCopy: onCopy,
        ),
        const SizedBox(height: 4),
        _CodeBlock(
          code: 'iproxy $port $port',
          bg: codeBg,
          onCopy: onCopy,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick Start Section
// ═══════════════════════════════════════════════════════════════════

class _QuickStartSection extends StatelessWidget {
  final String ip;

  const _QuickStartSection({required this.ip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeBg = isDark ? ColorTokens.darkSurface : const Color(0xFFF0F0F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: LucideIcons.zap, title: 'Quick Start'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StepCard(
                number: '1',
                title: 'Install SDK',
                code: 'Flutter:  flutter pub add devconnect_manage_kit\n'
                    'RN:      yarn add devconnect-manage-kit\n'
                    'Android: implementation("com.github...")',
                codeBg: codeBg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StepCard(
                number: '2',
                title: 'Initialize',
                code: 'Flutter:  await DevConnect.init(appName: "MyApp");\n'
                    'RN:      await DevConnect.init({ appName: "MyApp" });\n'
                    'Android: DevConnect.init(ctx, appName = "MyApp")',
                codeBg: codeBg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StepCard(
                number: '3',
                title: 'Connect',
                code: 'Emulator: auto-detect\n'
                    'WiFi:     host: "$ip"\n'
                    'USB:      see USB Tools above',
                codeBg: codeBg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String code;
  final Color codeBg;

  const _StepCard({
    required this.number,
    required this.title,
    required this.code,
    required this.codeBg,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: ColorTokens.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ColorTokens.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: codeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            code,
            style: TextStyle(
              fontFamily: AppConstants.monoFontFamily,
              fontSize: 10,
              color: isDark ? const Color(0xFF8B949E) : Colors.black87,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════

class _CodeBlock extends StatelessWidget {
  final String code;
  final Color bg;
  final void Function(String, [String?]) onCopy;

  const _CodeBlock({
    required this.code,
    required this.bg,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onCopy(code, 'Copied'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: const TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 12,
                    color: ColorTokens.secondary,
                  ),
                ),
              ),
              Icon(LucideIcons.copy, size: 12, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _NetworkInfo {
  final String ip;
  final String interfaceName;
  final String type;

  const _NetworkInfo({
    required this.ip,
    required this.interfaceName,
    required this.type,
  });
}

// ═══════════════════════════════════════════════════════════════════
// Donate / Support Section
// ═══════════════════════════════════════════════════════════════════

class _DonateSection extends StatelessWidget {
  const _DonateSection();

  void _openUrl(String url) {
    if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isWindows) {
      Process.run('start', [url], runInShell: true);
    } else {
      Process.run('xdg-open', [url]);
    }
  }

  void _showQrDialog(BuildContext context, String title, String assetPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(assetPath, width: 280, height: 360, fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.heart, size: 16, color: ColorTokens.error),
            const SizedBox(width: 8),
            Text(
              'Support DevConnect',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'DevConnect Manage Tool is free and open source. If it helps your workflow, consider supporting development.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _DonateButton(
              label: 'Ko-fi',
              icon: LucideIcons.coffee,
              color: const Color(0xFFFF5E5B),
              onTap: () => _openUrl('https://ko-fi.com/buivietphi'),
            ),
            const SizedBox(width: 10),
            _DonateButton(
              label: 'PayPal',
              icon: LucideIcons.creditCard,
              color: const Color(0xFF0070BA),
              onTap: () => _openUrl('https://paypal.me/buivietphi'),
            ),
            const SizedBox(width: 10),
            _DonateButton(
              label: 'MoMo',
              icon: LucideIcons.smartphone,
              color: const Color(0xFFAE2070),
              onTap: () => _showQrDialog(context, 'MoMo', 'docs/donate/momo-qr.jpeg'),
            ),
            const SizedBox(width: 10),
            _DonateButton(
              label: 'ZaloPay',
              icon: LucideIcons.qrCode,
              color: const Color(0xFF0068FF),
              onTap: () => _showQrDialog(context, 'ZaloPay', 'docs/donate/zalopay-qr.jpeg'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonateButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DonateButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DonateButton> createState() => _DonateButtonState();
}

class _DonateButtonState extends State<_DonateButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.12)
                : isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.3)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
