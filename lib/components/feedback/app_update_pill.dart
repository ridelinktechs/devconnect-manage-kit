import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_update_provider.dart';
import '../../core/providers/sdk_versions_provider.dart';
import '../../core/theme/chrome_palette.dart';
import '../../l10n/app_localizations.dart';
import 'title_bar_flyout.dart';

/// The desktop app's own version, top-left of the title bar (the right
/// side's `LibUpdateTips` covers the SDKs). Same pill and popover as the
/// tips: hover previews, click pins.
///
/// The pill's glyph carries the state — a spinner while asking GitHub, a
/// green check when up to date, an amber arrow when a newer release is
/// out, a cloud-off when the check failed — so the version itself stays
/// neutral. The popover compares versions and links to the release page.
///
/// The version comparison lives in [appUpdateProvider]; this widget is
/// presentation-only.
class AppUpdatePill extends ConsumerWidget {
  const AppUpdatePill({super.key});

  static const _releasePageFallback =
      'https://github.com/ridelinktechs/devconnect-manage-kit/releases/latest';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ChromePalette.of(context);
    final loc = S.of(context);
    final state = ref.watch(appUpdateProvider);
    final release = state.release;
    final current = state.currentVersion;
    final fetch = state.fetchedAt == null
        ? SdkVersionFetch.loading
        : state.error != null || release == null
        ? SdkVersionFetch.error
        : SdkVersionFetch.loaded;

    final Widget leading = switch (fetch) {
      SdkVersionFetch.loading => SizedBox.square(
        dimension: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: palette.textMuted,
        ),
      ),
      SdkVersionFetch.error => Icon(
        LucideIcons.cloudOff,
        size: 12,
        color: palette.textMuted,
      ),
      SdkVersionFetch.loaded =>
        state.hasUpdate
            ? Icon(LucideIcons.arrowUpCircle, size: 12, color: palette.accent)
            : Icon(LucideIcons.circleCheck, size: 12, color: palette.success),
    };

    return TitleBarFlyout(
      semanticLabel: loc.appUpdateTitle,
      pill: (open, focusRing) => FlyoutPill(
        palette: palette,
        leading: leading,
        label: current != null ? loc.sdkTipsVersionLabel(current) : '—',
        mono: true,
        active: open,
        focusRing: focusRing,
      ),
      popover: (context) => FlyoutPanel(
        palette: palette,
        width: 300,
        icon: LucideIcons.appWindow,
        title: loc.appUpdateTitle,
        subtitle: fetch == SdkVersionFetch.loaded
            ? (state.hasUpdate ? loc.appUpdateAvailable : loc.appUpdateUpToDate)
            : null,
        trailing: state.hasUpdate
            ? FlyoutUpdateBadge(palette: palette, label: loc.sdkTipsUpdate)
            : null,
        sections: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlyoutVersionLine(
                palette: palette,
                installed: current,
                latest: release?.version,
                fetch: fetch,
                onRetry: () => ref.read(appUpdateProvider.notifier).refresh(),
              ),
              if (fetch == SdkVersionFetch.loaded) ...[
                const SizedBox(height: 10),
                FlyoutButton(
                  palette: palette,
                  icon: LucideIcons.externalLink,
                  label: loc.appUpdateViewRelease,
                  primary: state.hasUpdate,
                  onPressed: () => _openRelease(release?.htmlUrl),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _openRelease(String? url) async {
    // `tryParse`: the URL comes from a third-party API response.
    final uri = Uri.tryParse(url ?? _releasePageFallback);
    if (uri == null) return;
    // Default browser first; the in-app handler so a click is never a
    // dead end.
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }
}
