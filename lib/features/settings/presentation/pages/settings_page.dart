import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../server/providers/server_providers.dart';
import '../header/card.dart';
import '../header/page_header.dart';
import '../sections/all_events_display_section.dart';
import '../sections/appearance_section.dart';
import '../sections/data_retention_section.dart';
import '../sections/device_history_section.dart';
import '../sections/detail_view_section.dart';
import '../sections/devices_section.dart';
import '../sections/donate_section.dart';
import '../sections/network_section.dart';
import '../sections/quick_start_section.dart';
import '../sections/server_section.dart';
import '../sections/tab_visibility_section.dart';
import '../sections/usb_tools_section.dart';
import '../shared/network_info.dart';

// ═══════════════════════════════════════════════════════════════════
// Settings Page — two-column grid composed from header / sections
// ═══════════════════════════════════════════════════════════════════

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _portController;
  final _scrollController = SmoothScrollController();
  List<NetworkInfo> _networkInfos = [];
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
      // Snapshot the type-lookup helper synchronously so the async loop
      // doesn't need a BuildContext across the await gap.
      String typeFor(String name) => guessInterfaceType(context, name);
      final infos = <NetworkInfo>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            infos.add(NetworkInfo(
              ip: addr.address,
              interfaceName: iface.name,
              type: typeFor(iface.name),
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
                PageHeader(server: server, deviceCount: devices.length),
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
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: ServerSection(
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
                                        describeStartError(e, p);
                                  }
                                }
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Network IPs
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: NetworkSection(
                              hostName: _hostName,
                              networkInfos: _networkInfos,
                              onCopy: _copy,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Connected Devices
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: DevicesSection(devices: devices),
                          ),
                          const SizedBox(height: 16),

                          // Cached Devices (persistent history)
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: const DeviceHistorySection(),
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
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: const AppearanceSection(),
                          ),
                          const SizedBox(height: 16),

                          // Tab Visibility
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: const TabVisibilitySection(),
                          ),
                          const SizedBox(height: 16),

                          // Detail View
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: const DetailViewSection(),
                          ),
                          const SizedBox(height: 16),

                          // Data Retention
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: const DataRetentionSection(),
                          ),
                          const SizedBox(height: 16),

                          // All Events Display
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: const AllEventsDisplaySection(),
                          ),
                          const SizedBox(height: 16),

                          // USB Tools
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: UsbToolsSection(
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
                SettingsCard(
                  surface: surface,
                  border: border,
                  child: QuickStartSection(
                    ip: _networkInfos.isNotEmpty
                        ? _networkInfos.first.ip
                        : 'your-pc-ip',
                  ),
                ),
                const SizedBox(height: 16),

                // ── Support / Donate ──
                SettingsCard(
                  surface: surface,
                  border: border,
                  child: const DonateSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}