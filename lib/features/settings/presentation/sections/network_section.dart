import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../header/section_title.dart';
import '../shared/network_info.dart';

/// Network card — hostname + clickable IP rows. Each row copies its
/// IP to the clipboard via the [onCopy] callback supplied by the page.
class NetworkSection extends StatelessWidget {
  final String hostName;
  final List<NetworkInfo> networkInfos;
  final void Function(String, [String?]) onCopy;

  const NetworkSection({
    super.key,
    required this.hostName,
    required this.networkInfos,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.wifi, title: S.of(context).network),
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
          ...networkInfos.map((info) => IpRow(info: info, onCopy: onCopy)),
      ],
    );
  }
}

/// One clickable IP row. Picking the cable/wifi/shield glyph off the
/// resolved interface type so the user gets a hint about which adapter
/// they tapped.
class IpRow extends StatelessWidget {
  final NetworkInfo info;
  final void Function(String, [String?]) onCopy;

  const IpRow({super.key, required this.info, required this.onCopy});

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

/// File-private lookup: maps a raw network interface name to one of
/// the localized "ethernet / wifi / vpn / bridge / loopback" labels.
/// Lives next to the section that uses it so it isn't accidentally
/// imported by something unrelated.
String guessInterfaceType(BuildContext context, String name) {
  final lower = name.toLowerCase();
  if (lower.startsWith('en') || lower.startsWith('eth')) {
    return S.of(context).ethernet;
  }
  if (lower.startsWith('wl') ||
      lower.contains('wi-fi') ||
      lower.contains('wifi')) {
    return S.of(context).wifi;
  }
  if (lower.startsWith('utun') ||
      lower.startsWith('tun') ||
      lower.startsWith('ipsec')) {
    return S.of(context).vpn;
  }
  if (lower.startsWith('bridge')) return S.of(context).bridge;
  if (lower.startsWith('lo')) return S.of(context).loopback;
  return name;
}