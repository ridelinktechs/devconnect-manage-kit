import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/tab_visibility_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../device_history/provider/device_history_providers.dart';

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
  final _scrollController = SmoothScrollController();
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
    if (lower.startsWith('en') || lower.startsWith('eth')) return S.of(context).ethernet;
    if (lower.startsWith('wl') ||
        lower.contains('wi-fi') ||
        lower.contains('wifi')) return S.of(context).wifi;
    if (lower.startsWith('utun') ||
        lower.startsWith('tun') ||
        lower.startsWith('ipsec')) return S.of(context).vpn;
    if (lower.startsWith('bridge')) return S.of(context).bridge;
    if (lower.startsWith('lo')) return S.of(context).loopback;
    return name;
  }

  @override
  void dispose() {
    _portController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _copy(String text, [String? label]) {
    Clipboard.setData(ClipboardData(text: text));
    showCopiedToast(context, label: label ?? S.of(context).copied);
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
        controller: _scrollController,
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
                          const SizedBox(height: 16),

                          // Cached Devices (persistent history)
                          _Card(
                            surface: surface,
                            border: border,
                            child: const _DeviceHistorySection(),
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
              S.of(context).settings,
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
          label: server.isRunning ? S.of(context).serverRunning : S.of(context).serverStopped,
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

  _SectionTitle({
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
        _SectionTitle(icon: LucideIcons.server, title: S.of(context).server),
        Row(
          children: [
            Text(S.of(context).port, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
              label: server.isRunning ? S.of(context).stop : S.of(context).start,
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
        _SectionTitle(icon: LucideIcons.wifi, title: S.of(context).network),
        if (hostName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(S.of(context).hostname,
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
          Text(S.of(context).noNetworkInterfaces,
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
        onTap: () => onCopy(info.ip, S.of(context).copiedIp(info.ip)),
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
          title: S.of(context).connectedDevices(devices.length),
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
                  S.of(context).noDevicesConnected,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: LucideIcons.palette, title: S.of(context).appearance),
        // Theme
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).theme,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(LucideIcons.moon, size: 14),
                    label: Text(S.of(context).dark),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(LucideIcons.sun, size: 14),
                    label: Text(S.of(context).light),
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
              child: Text(S.of(context).autoScroll,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<ScrollDirection>(
                segments: [
                  ButtonSegment(
                    value: ScrollDirection.bottom,
                    icon: Icon(LucideIcons.arrowDownToLine, size: 14),
                    label: Text(S.of(context).bottom),
                  ),
                  ButtonSegment(
                    value: ScrollDirection.top,
                    icon: Icon(LucideIcons.arrowUpToLine, size: 14),
                    label: Text(S.of(context).top),
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
        const SizedBox(height: 12),
        // Language
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).language,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: _LanguageDropdown(
                selected: ref.watch(localeProvider),
                isDark: isDark,
                onSelect: (locale) {
                  ref.read(localeProvider.notifier).setLocale(locale);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Smooth scroll
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                S.of(context).smoothScrolling,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            Switch.adaptive(
              value: ref.watch(smoothScrollEnabledProvider),
              onChanged: (v) =>
                  ref.read(smoothScrollEnabledProvider.notifier).set(v),
            ),
            const SizedBox(width: 8),
            Text(
              ref.watch(smoothScrollEnabledProvider)
                  ? S.of(context).on
                  : S.of(context).off,
              style: TextStyle(
                fontSize: 12,
                color: ref.watch(smoothScrollEnabledProvider)
                    ? ColorTokens.primary
                    : Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Text(
            S.of(context).smoothScrollingDesc,
            style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Language Dropdown
// ═══════════════════════════════════════════════════════════════════

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  final Locale selected;
  final bool isDark;
  final ValueChanged<Locale> onSelect;

  String _selectedLabel() {
    final key = selected.countryCode != null
        ? '${selected.languageCode}_${selected.countryCode}'
        : selected.languageCode;
    return localeDisplayNames[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<Locale>(
        onSelected: onSelect,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        itemBuilder: (context) => supportedLocales.map((locale) {
          final key = locale.countryCode != null
              ? '${locale.languageCode}_${locale.countryCode}'
              : locale.languageCode;
          final label = localeDisplayNames[key] ?? key;
          final isSelected = locale == selected;
          return PopupMenuItem<Locale>(
            value: locale,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                if (isSelected)
                  Icon(LucideIcons.check, size: 14, color: ColorTokens.primary)
                else
                  const SizedBox(width: 14),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? ColorTokens.primary
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(LucideIcons.languages, size: 15, color: Colors.grey[500]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
              ),
              Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Tab Visibility Section
// ═══════════════════════════════════════════════════════════════════

class _TabVisibilitySection extends ConsumerWidget {
  const _TabVisibilitySection();

  List<(TabKey, String, IconData, Color)> _getTabs(BuildContext context) => [
    (TabKey.console, S.of(context).console, LucideIcons.terminal, const Color(0xFF58A6FF)),
    (TabKey.network, S.of(context).network, LucideIcons.globe, ColorTokens.success),
    (TabKey.state, S.of(context).state, LucideIcons.layers, ColorTokens.secondary),
    (TabKey.storage, S.of(context).storage, LucideIcons.database, ColorTokens.warning),
    (TabKey.database, S.of(context).database, LucideIcons.hardDrive, const Color(0xFFD2A8FF)),
    (TabKey.performance, S.of(context).performance, LucideIcons.gauge, ColorTokens.chartGreen),
    (TabKey.memoryLeaks, S.of(context).memoryLeaks, LucideIcons.bug, ColorTokens.chartRed),
    (TabKey.history, S.of(context).history, LucideIcons.history, Colors.grey),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledTabs = ref.watch(tabVisibilityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: LucideIcons.layoutGrid,
          title: S.of(context).tabVisibility,
        ),
        Text(
          S.of(context).tabVisibilityDesc,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 12),
        ..._getTabs(context).map((t) {
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
        _SectionTitle(
          icon: LucideIcons.panelRight,
          title: S.of(context).detailView,
        ),
        Text(
          S.of(context).detailViewDesc,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 14),

        // Body view mode
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).bodyView,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Expanded(
              child: SegmentedButton<BodyViewMode>(
                segments: [
                  ButtonSegment(
                    value: BodyViewMode.tree,
                    icon: Icon(LucideIcons.listTree, size: 14),
                    label: Text(S.of(context).tree),
                  ),
                  ButtonSegment(
                    value: BodyViewMode.json,
                    icon: Icon(LucideIcons.braces, size: 14),
                    label: Text(S.of(context).json),
                  ),
                  ButtonSegment(
                    value: BodyViewMode.code,
                    icon: Icon(LucideIcons.code, size: 14),
                    label: Text(S.of(context).code),
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
            S.of(context).codeModeDesc,
            style: TextStyle(fontSize: 10, color: Colors.grey[600], height: 1.4),
          ),
        ),
        const SizedBox(height: 14),

        // Tab animation toggle
        Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(S.of(context).tabAnimation,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
            Switch.adaptive(
              value: animEnabled,
              onChanged: (v) =>
                  ref.read(tabAnimationEnabledProvider.notifier).set(v),
            ),
            const SizedBox(width: 8),
            Text(
              animEnabled ? S.of(context).on : S.of(context).off,
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
                  child: Text(S.of(context).duration,
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
        _SectionTitle(icon: LucideIcons.usb, title: S.of(context).usbConnection),

        // Android
        Text(S.of(context).android,
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
              label: S.of(context).runAdbReverse,
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
              label: S.of(context).devices,
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
                        title: Text(S.of(context).adbDevices),
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
                            child: Text(S.of(context).ok),
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
        Text(S.of(context).ios,
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
                  S.of(context).wifiAutoConnect,
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
        _SectionTitle(icon: LucideIcons.zap, title: S.of(context).quickStart),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StepCard(
                number: '1',
                icon: LucideIcons.package,
                accent: const Color(0xFF42A5F5),
                title: S.of(context).installSdk,
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
                icon: LucideIcons.playCircle,
                accent: ColorTokens.primary,
                title: S.of(context).initialize,
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
                icon: LucideIcons.radio,
                accent: ColorTokens.success,
                title: S.of(context).connect,
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
  final IconData icon;
  final Color accent;
  final String title;
  final String code;
  final Color codeBg;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.accent,
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontFamily: AppConstants.monoFontFamily,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              height: 1.55,
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
      onTap: () => onCopy(code, S.of(context).copied),
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

// ═══════════════════════════════════════════════════════════════════
// Cached Devices (persistent history) Section
// ═══════════════════════════════════════════════════════════════════

/// Shows the list of devices that have ever connected to this desktop.
/// History is persisted across restarts via AppPreferences.
class _DeviceHistorySection extends ConsumerWidget {
  const _DeviceHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(deviceHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionTitle(
          icon: LucideIcons.history,
          title: S.of(context).deviceHistory,
        ),
        Text(
          S.of(context).deviceHistoryDesc,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.inbox, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  S.of(context).noDeviceHistory,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          for (final entry in history)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _DeviceHistoryRow(entry: entry),
            ),
      ],
    );
  }
}

class _DeviceHistoryRow extends ConsumerStatefulWidget {
  final DeviceHistoryEntry entry;
  const _DeviceHistoryRow({required this.entry});

  @override
  ConsumerState<_DeviceHistoryRow> createState() => _DeviceHistoryRowState();
}

class _DeviceHistoryRowState extends ConsumerState<_DeviceHistoryRow> {
  Color get _platformColor {
    final p = widget.entry.platform.toLowerCase();
    if (p == 'ios' || p == 'flutter') return const Color(0xFF58A6FF);
    if (p == 'android') return const Color(0xFF3DDC84);
    return Colors.grey;
  }

  IconData get _platformIcon {
    final p = widget.entry.platform.toLowerCase();
    if (p == 'ios') return LucideIcons.apple;
    if (p == 'android') return LucideIcons.smartphone;
    if (p == 'flutter' || p == 'react_native') return LucideIcons.boxes;
    return LucideIcons.monitor;
  }

  Future<void> _toggleOnline() async {
    // Locally flip the flag in the entry — no network call, this is just
    // a UI hint so the user can mark a stale "online" entry as gone.
    final history = ref.read(deviceHistoryProvider.notifier);
    final updated = DeviceHistoryEntry(
      deviceId: widget.entry.deviceId,
      deviceName: widget.entry.deviceName,
      platform: widget.entry.platform,
      appName: widget.entry.appName,
      appVersion: widget.entry.appVersion,
      clientIp: widget.entry.clientIp,
      firstConnectedAt: widget.entry.firstConnectedAt,
      lastConnectedAt: widget.entry.lastConnectedAt,
      isOnline: !widget.entry.isOnline,
      totalConnections: widget.entry.totalConnections,
    );
    await ref
        .read(deviceHistoryProvider.notifier)
        .replaceEntry(widget.entry.deviceId, updated);
  }

  Future<void> _forget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).forgetDevice),
        content: Text(S.of(context).forgetDeviceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorTokens.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(context).forgetDevice),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(deviceHistoryProvider.notifier)
          .forget(widget.entry.deviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _platformColor;
    final entry = widget.entry;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: entry.isOnline
              ? ColorTokens.success.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: Row(
        children: [
          Icon(_platformIcon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.deviceName.isNotEmpty
                  ? entry.deviceName
                  : '${entry.deviceId.substring(0, entry.deviceId.length.clamp(0, 8))}…',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '● ${entry.isOnline ? S.of(context).online : S.of(context).offline}',
            style: TextStyle(
              fontSize: 10,
              color: entry.isOnline ? ColorTokens.success : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 6),
          // Toggle online/offline (e.g. mark a stale "online" as gone)
          _IconAction(
            icon: entry.isOnline ? LucideIcons.wifiOff : LucideIcons.wifi,
            tooltip: entry.isOnline
                ? S.of(context).markOffline
                : S.of(context).markOnline,
            color: entry.isOnline ? Colors.grey[500]! : ColorTokens.success,
            onTap: _toggleOnline,
          ),
          const SizedBox(width: 2),
          // Forget — remove this entry from history
          _IconAction(
            icon: LucideIcons.x,
            tooltip: S.of(context).forgetDevice,
            color: Colors.grey[500]!,
            onTap: _forget,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(widget.icon, size: 12, color: widget.color),
          ),
        ),
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
              S.of(context).supportDevConnect,
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
          S.of(context).supportDevConnectDesc,
          style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _DonateButton(
              label: S.of(context).kofi,
              icon: LucideIcons.coffee,
              color: const Color(0xFFFF5E5B),
              onTap: () => _openUrl('https://ko-fi.com/buivietphi'),
            ),
            const SizedBox(width: 10),
            _DonateButton(
              label: S.of(context).paypal,
              icon: LucideIcons.creditCard,
              color: const Color(0xFF0070BA),
              onTap: () => _openUrl('https://paypal.me/buivietphi'),
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
