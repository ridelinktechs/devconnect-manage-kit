import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/providers/mcp_install_mode_provider.dart';
import '../../../../core/utils/smooth_scroll_controller.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/mcp_installer.dart';
import '../../../../core/constants/mcp_clients.dart';
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
import '../../../../core/preferences/app_preferences.dart';
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
  late TextEditingController _mcpPortController;
  final _scrollController = SmoothScrollController();
  List<NetworkInfo> _networkInfos = [];
  String _hostName = '';

  @override
  void initState() {
    super.initState();
    final server = ref.read(wsServerProvider);
    final mcpServer = ref.read(mcpWsServerProvider);
    final actualPort = server.isRunning ? server.port : AppConstants.defaultPort;
    final actualMcpPort = mcpServer.isRunning ? mcpServer.port : (AppPreferences().get<int>('mcp_server_port') ?? 5564);
    _portController = TextEditingController(text: '$actualPort');
    _mcpPortController = TextEditingController(text: '$actualMcpPort');
    _portController.addListener(() {
      if (mounted) setState(() {});
    });
    _mcpPortController.addListener(() {
      if (mounted) setState(() {});
    });
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
    _mcpPortController.dispose();
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
    final mcpServer = ref.watch(mcpWsServerProvider);
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
                              mcpPortController: _mcpPortController,
                              server: server,
                              mcpServer: mcpServer,
                              showApply: (int.tryParse(_portController.text) ?? AppConstants.defaultPort) != (server.isRunning ? server.port : AppConstants.defaultPort) ||
                                         (int.tryParse(_mcpPortController.text) ?? 5564) != (mcpServer.isRunning ? mcpServer.port : (AppPreferences().get<int>('mcp_server_port') ?? 5564)),
                              onApply: () async {
                                final p = int.tryParse(_portController.text) ?? AppConstants.defaultPort;
                                final mcpP = int.tryParse(_mcpPortController.text) ?? 5564;

                                // 1. Save configuration parameters
                                await AppPreferences().set('mcp_server_port', mcpP);

                                // 2. Restart device WebSocket server if port changed
                                if (p != server.port) {
                                  if (server.isRunning) {
                                    await server.stop();
                                  }
                                  try {
                                    await server.start(port: p);
                                    ref.read(serverStartErrorProvider.notifier).state = null;
                                  } catch (e) {
                                    ref.read(serverStartErrorProvider.notifier).state = describeStartError(e, p);
                                  }
                                }

                                // 3. Restart MCP server if port changed
                                final mcpPortChanged = mcpP != mcpServer.port;
                                if (mcpPortChanged) {
                                  if (mcpServer.isRunning) {
                                    await mcpServer.stop();
                                  }
                                  try {
                                    await mcpServer.start(port: mcpP);
                                    ref.read(mcpStartErrorProvider.notifier).state = null;
                                  } catch (e) {
                                    ref.read(mcpStartErrorProvider.notifier).state = describeStartError(e, mcpP);
                                  }
                                }

                                // 4. If MCP port changed, trigger auto-reinstall flow for active clients!
                                final installedList = AppPreferences().get<List<dynamic>>('installed_mcp_clients')?.cast<String>() ?? [];
                                if (mcpPortChanged && installedList.isNotEmpty && context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(S.of(ctx).mcpReconfiguringTitle),
                                      content: Row(
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(width: 16),
                                          Expanded(child: Text(S.of(ctx).mcpReconfiguringBody)),
                                        ],
                                      ),
                                    ),
                                  );

                                  final container = ProviderScope.containerOf(context, listen: false);
                                  final installModeMap = container.read(mcpInstallModeProvider);
                                  for (final idName in installedList) {
                                    final clientId = McpClientId.values.firstWhere((c) => c.name == idName);
                                    final mode = installModeMap[clientId.name] ?? McpInstallMode.npx;
                                    final args = McpInstallArgs(
                                      wsPort: mcpP,
                                      httpPort: defaultLocalMcpHttpPort,
                                      localhostMode: mode == McpInstallMode.localhost,
                                    );
                                    await McpInstaller.runUninstall(container, clientId);
                                    await McpInstaller.runInstall(container, clientId, args);
                                  }

                                  if (context.mounted) {
                                    Navigator.of(context).pop(); // dismiss loading dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(S.of(context).mcpReconfiguredSuccess)),
                                    );
                                  }
                                }
                                setState(() {});
                              },
                              onStartStop: () async {
                                final p = int.tryParse(_portController.text) ?? AppConstants.defaultPort;
                                if (server.isRunning) {
                                  await server.stop();
                                  ref.read(serverStartErrorProvider.notifier).state = null;
                                } else {
                                  try {
                                    await server.start(port: p);
                                    ref.read(serverStartErrorProvider.notifier).state = null;
                                  } catch (e) {
                                    ref.read(serverStartErrorProvider.notifier).state = describeStartError(e, p);
                                  }
                                }
                                setState(() {});
                              },
                              onMcpStartStop: () async {
                                final mcpP = int.tryParse(_mcpPortController.text) ?? 5564;
                                if (mcpServer.isRunning) {
                                  await mcpServer.stop();
                                  ref.read(mcpStartErrorProvider.notifier).state = null;
                                } else {
                                  try {
                                    await mcpServer.start(port: mcpP);
                                    ref.read(mcpStartErrorProvider.notifier).state = null;
                                  } catch (e) {
                                    ref.read(mcpStartErrorProvider.notifier).state = describeStartError(e, mcpP);
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
                          const SizedBox(height: 16),

                          // MCP Security Sandbox
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: StatefulBuilder(
                              builder: (context, setState) {
                                final confirm = AppPreferences().get<bool>('mcpConfirmationRequired') ?? true;
                                return SwitchListTile.adaptive(
                                  title: Text(S.of(context).mcpConfirmationTitle),
                                  subtitle: Text(S.of(context).mcpConfirmationSubtitle),
                                  value: confirm,
                                  contentPadding: EdgeInsets.zero,
                                  activeTrackColor: ColorTokens.secondary,
                                  onChanged: (val) {
                                    AppPreferences().set('mcpConfirmationRequired', val);
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // MCP Behavior — auto-start pref + auto-spawn-local pref.
                          // Two independent toggles: auto-start controls whether the
                          // MCP WebSocket server is brought up on app launch;
                          // auto-spawn-local controls whether opening the MCP panel
                          // also launches the local `node dist/index.js` child when
                          // localhost install mode is selected.
                          SettingsCard(
                            surface: surface,
                            border: border,
                            child: Consumer(builder: (context, ref, _) {
                              final autoStart = ref.watch(mcpAutoStartProvider);
                              final autoSpawnLocal = ref.watch(mcpAutoSpawnLocalProvider);
                              return Column(
                                children: [
                                  SwitchListTile.adaptive(
                                    title: Text(S.of(context).mcpAutoStartTitle),
                                    subtitle: Text(S.of(context).mcpAutoStartSubtitle),
                                    value: autoStart,
                                    contentPadding: EdgeInsets.zero,
                                    activeTrackColor: ColorTokens.secondary,
                                    onChanged: (val) => ref
                                        .read(mcpAutoStartProvider.notifier)
                                        .set(val),
                                  ),
                                  SwitchListTile.adaptive(
                                    title: Text(S.of(context).mcpAutoSpawnLocalTitle),
                                    subtitle: Text(S.of(context).mcpAutoSpawnLocalSubtitle),
                                    value: autoSpawnLocal,
                                    contentPadding: EdgeInsets.zero,
                                    activeTrackColor: ColorTokens.secondary,
                                    onChanged: (val) => ref
                                        .read(mcpAutoSpawnLocalProvider.notifier)
                                        .set(val),
                                  ),
                                ],
                              );
                            }),
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