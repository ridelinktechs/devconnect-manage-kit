import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../core/utils/ui/toast_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../server/providers/server_providers.dart';
import '../header/card.dart';
import '../nav/settings_sidebar.dart';
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
import '../sections/tips_section.dart';
import '../sections/usb_tools_section.dart';
import '../shared/network_info.dart';

// ═══════════════════════════════════════════════════════════════════
// Settings Page — a menu of groups on the left, the chosen group's
// section cards on the right
// ═══════════════════════════════════════════════════════════════════

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _portController;
  final _scrollController = SmoothScrollController();
  int _group = 0;
  bool _restarting = false;
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

  Future<void> _startStop(dynamic server) async {
    final p = int.tryParse(_portController.text) ?? AppConstants.defaultPort;
    if (server.isRunning) {
      await server.stop();
      ref.read(serverStartErrorProvider.notifier).set(null);
    } else {
      try {
        await server.start(port: p);
        ref.read(serverStartErrorProvider.notifier).set(null);
      } catch (e) {
        ref
            .read(serverStartErrorProvider.notifier)
            .set(describeStartError(e, p));
      }
    }
    setState(() {});
  }

  /// Stops and starts the server on the same port; apps reconnect on
  /// their own.
  Future<void> _restart(dynamic server) async {
    final int p = server.port;
    setState(() => _restarting = true);
    await server.stop();
    try {
      await server.start(port: p);
      ref.read(serverStartErrorProvider.notifier).set(null);
    } catch (e) {
      ref.read(serverStartErrorProvider.notifier).set(describeStartError(e, p));
    }
    if (mounted) setState(() => _restarting = false);
  }

  void _select(int i) {
    if (i == _group) return;
    setState(() => _group = i);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final server = ref.watch(wsServerProvider);
    final devices = ref.watch(connectedDevicesProvider);
    final s = S.of(context);

    final surface = isDark ? ColorTokens.darkBackground : Colors.white;
    final surfaceAlt = isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);
    final port = server.isRunning ? server.port : AppConstants.defaultPort;
    final ip = _networkInfos.isNotEmpty ? _networkInfos.first.ip : 'your-pc-ip';
    Widget card(Widget child) =>
        SettingsCard(surface: surface, border: border, child: child);

    final groups = <(IconData, String, String, List<Widget>)>[
      (
        LucideIcons.plug,
        s.settingsGroupConnection,
        s.settingsGroupConnectionDesc,
        [
          card(
            ServerSection(
              portController: _portController,
              server: server,
              address: _networkInfos.isNotEmpty ? 'ws://$ip:$port' : '',
              restarting: _restarting,
              onStartStop: () => _startStop(server),
              onRestart: () => _restart(server),
              onCopy: _copy,
            ),
          ),
          card(
            NetworkSection(
              hostName: _hostName,
              networkInfos: _networkInfos,
              onCopy: _copy,
            ),
          ),
          card(UsbToolsSection(port: port, onCopy: _copy)),
        ],
      ),
      (
        LucideIcons.smartphone,
        s.settingsGroupDevices,
        s.settingsGroupDevicesDesc,
        [
          card(DevicesSection(devices: devices)),
          card(const DeviceHistorySection()),
        ],
      ),
      (
        LucideIcons.palette,
        s.settingsGroupAppearance,
        s.settingsGroupAppearanceDesc,
        [card(const AppearanceSection()), card(const TabVisibilitySection())],
      ),
      (
        LucideIcons.slidersHorizontal,
        s.settingsGroupData,
        s.settingsGroupDataDesc,
        [
          card(const DetailViewSection()),
          card(const DataRetentionSection()),
          card(const AllEventsDisplaySection()),
        ],
      ),
      (
        LucideIcons.bookOpen,
        s.settingsGroupGuides,
        s.settingsGroupGuidesDesc,
        [
          card(QuickStartSection(ip: ip, port: port)),
          card(TipsSection(port: port, host: ip)),
        ],
      ),
      (
        LucideIcons.heart,
        s.settingsGroupSupport,
        s.settingsGroupSupportDesc,
        [card(const DonateSection())],
      ),
    ];
    final (_, title, description, cards) = groups[_group];
    final p = ChromePalette.of(context);

    return Container(
      color: surfaceAlt,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSidebar(
                items: [
                  for (final (i, g) in groups.indexed)
                    (
                      icon: g.$1,
                      label: g.$2,
                      badge: i == 1 && devices.isNotEmpty ? devices.length : null,
                    ),
                ],
                index: _group,
                onSelect: _select,
                compact: constraints.maxWidth < 900,
                running: server.isRunning,
                port: port,
                devices: devices.length,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(32, 30, 32, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: _GroupSwap(
                        id: _group,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.settings,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: p.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 24,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: p.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: p.textMuted,
                              ),
                            ),
                            const SizedBox(height: 22),
                            for (var i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(height: 14),
                              cards[i],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Swaps the group shown on the right: the new one fades in while rising
/// 8px on a spring.
class _GroupSwap extends StatelessWidget {
  final int id;
  final Widget child;

  const _GroupSwap({required this.id, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 150),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final rise = const Cubic(0.34, 1.45, 0.64, 1).transform(animation.value);
          return Opacity(
            opacity: const Interval(0, 0.5).transform(animation.value),
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - rise)),
              child: child,
            ),
          );
        },
        child: child,
      ),
      child: KeyedSubtree(key: ValueKey(id), child: child),
    );
  }
}
