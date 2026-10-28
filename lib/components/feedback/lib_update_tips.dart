import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/local_projects_provider.dart';
import '../../core/providers/sdk_versions_provider.dart';
import '../../core/theme/chrome_palette.dart';
import '../../core/utils/sdk_version.dart';
import '../../l10n/app_localizations.dart';
import '../../models/device_info.dart';
import '../../server/providers/server_providers.dart';
import 'title_bar_flyout.dart';

/// "Tips" pill anchored at the top-right of the title bar. Hover
/// previews — or click pins — a popover below it with the SDK a client
/// app must be on for DevConnect to ingest the full payload.
///
/// Follows the project selected in the device bar: with one selected,
/// the pill turns into that project's SDK version (when known) and the
/// popover shows only its platform; switching project switches both. With
/// "all" (or nothing) selected it lists every SDK against the oldest
/// connected one.
///
/// Each SDK row shows:
///   - **Latest** version, fetched live from pub.dev / npm / Maven
///     Central by [sdkLatestVersionsProvider].
///   - **Installed** version, from [deviceSdkVersion]: read from the
///     connected project's files on this machine (found through its
///     Metro / `flutter run` process), else the handshake. Across several
///     devices the oldest one wins. When it's unknown — Android, a folder
///     the OS won't let us read, no dev server here — the row asks the
///     user to check their project instead.
///   - **Update** badge when device < latest. Amber is reserved for that
///     state (the pill grows an amber dot too) so it keeps its meaning.
///   - Copyable install snippets pinned to the latest version.
class LibUpdateTips extends ConsumerWidget {
  const LibUpdateTips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ChromePalette.of(context);
    final loc = S.of(context);
    final latest = ref.watch(sdkLatestVersionsProvider);
    final localProjects = ref.watch(localProjectsProvider).value ?? const [];
    final devices = ref.watch(connectedDevicesProvider);
    final selectedId = ref.watch(selectedDeviceProvider);

    _SdkStatus status(
      _SdkEntry entry,
      String? installed, {
      String? project,
      LocalProject? local,
    }) => _SdkStatus(
      entry: entry,
      fetch: latest.fetchStateFor(entry.platform),
      latest: latest.latestFor(entry.platform),
      installed: installed,
      project: project,
      local: local,
    );

    final selected = devices.where((d) => d.deviceId == selectedId).firstOrNull;
    final selectedEntry = _SdkCatalog.entries
        .where((e) => e.platform.handshakeId == selected?.platform)
        .firstOrNull;
    final project = selected != null && selectedEntry != null
        ? status(
            selectedEntry,
            deviceSdkVersion(selected, localProjects),
            project: '${selected.appName} · ${selected.deviceName}',
            local: localProjectFor(selected, localProjects),
          )
        : null;
    final rows = project != null
        ? [project]
        : [
            for (final entry in _SdkCatalog.entries)
              status(
                entry,
                _installedFor(devices, entry.platform, localProjects),
                // A folder we couldn't read, so the row can say why.
                local: localProjects
                    .where((p) => p.platform == entry.platform)
                    .where((p) => p.accessDenied)
                    .firstOrNull,
              ),
          ];
    final projectVersion = project?.installed;
    final needsUpdate = rows.any((r) => r.outdated);

    return TitleBarFlyout(
      semanticLabel: loc.sdkTipsHeader,
      alignRight: true,
      // Re-scan on open: picks up a dev server started, or folder access
      // granted, since the device connected.
      onOpen: () => ref.invalidate(localProjectsProvider),
      pill: (open, focusRing) {
        // A selected project turns the pill into its version.
        final (icon, color) = projectVersion != null
            ? platformLook(
                project!.entry.platform.handshakeId,
                isDark: palette.isDark,
              )
            : (
                LucideIcons.sparkles,
                needsUpdate ? palette.accent : palette.textMuted,
              );
        return FlyoutPill(
          palette: palette,
          leading: Icon(icon, size: 12, color: color),
          label: projectVersion != null
              ? loc.sdkTipsVersionLabel(projectVersion)
              : loc.sdkTipsPill,
          mono: projectVersion != null,
          active: open,
          focusRing: focusRing,
          dot: needsUpdate,
        );
      },
      popover: (context) => FlyoutPanel(
        palette: palette,
        icon: LucideIcons.sparkles,
        title: loc.sdkTipsHeader,
        subtitle: loc.sdkTipsSubtitle,
        sections: [
          for (final row in rows)
            _SdkRow(
              status: row,
              palette: palette,
              onRetry: () =>
                  ref.read(sdkLatestVersionsProvider.notifier).refresh(),
            ),
        ],
      ),
    );
  }
}

/// Oldest known SDK version among connected devices of [p] — the one that
/// most needs the update. Null when none is known.
String? _installedFor(
  List<DeviceInfo> devices,
  SdkPlatform p,
  List<LocalProject> projects,
) {
  final versions =
      devices
          .where((d) => d.platform == p.handshakeId)
          .map((d) => deviceSdkVersion(d, projects))
          .nonNulls
          .toList()
        ..sort(compareSdkVersions);
  return versions.firstOrNull;
}

// ─── Data ─────────────────────────────────────────────────────────────

class _SdkEntry {
  final SdkPlatform platform;

  /// Copyable install lines; `<version>` is swapped for the latest release.
  final List<String> snippets;

  const _SdkEntry(this.platform, this.snippets);
}

class _SdkCatalog {
  static const entries = [
    _SdkEntry(SdkPlatform.flutter, ['devconnect_manage_kit: ^<version>']),
    _SdkEntry(SdkPlatform.reactNative, [
      'npm i devconnect-manage-kit@<version>',
      'yarn add devconnect-manage-kit@<version>',
    ]),
    _SdkEntry(SdkPlatform.android, [
      'implementation("io.github.buivietphi:devconnect-android:<version>")',
    ]),
  ];
}

/// One SDK row: what the registry says vs what connected devices run.
class _SdkStatus {
  final _SdkEntry entry;
  final SdkVersionFetch fetch;
  final String? latest;
  final String? installed;

  /// "App · device" when this row is for the selected project.
  final String? project;

  /// The local project [installed] was read from — or couldn't be.
  final LocalProject? local;

  const _SdkStatus({
    required this.entry,
    required this.fetch,
    required this.latest,
    required this.installed,
    this.project,
    this.local,
  });

  bool get outdated =>
      installed != null &&
      latest != null &&
      compareSdkVersions(installed!, latest!) < 0;

  bool get upToDate => installed != null && latest != null && !outdated;

  List<String> get snippets => [
    for (final s in entry.snippets)
      latest == null ? s : s.replaceAll('<version>', latest!),
  ];
}

// ─── Look ─────────────────────────────────────────────────────────────

String _platformLabel(S loc, SdkPlatform p) => switch (p) {
  SdkPlatform.flutter => loc.sdkTipsFlutter,
  SdkPlatform.reactNative => loc.sdkTipsReactNative,
  SdkPlatform.android => loc.sdkTipsAndroid,
};

/// System Settings › Privacy & Security › Files and Folders.
final _filesAndFoldersSettings = Uri.parse(
  'x-apple.systempreferences:com.apple.preference.security'
  '?Privacy_FilesAndFolders',
);

class _SdkRow extends StatelessWidget {
  final _SdkStatus status;
  final ChromePalette palette;
  final VoidCallback onRetry;

  const _SdkRow({
    required this.status,
    required this.palette,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final muted = TextStyle(
      fontSize: 11.5,
      height: 1.45,
      color: palette.textMuted,
    );
    final (icon, tint) = platformLook(
      status.entry.platform.handshakeId,
      isDark: palette.isDark,
    );
    final local = status.local;
    final denied = local?.accessDenied ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 15, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _platformLabel(loc, status.entry.platform),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  if (status.project case final project?)
                    Text(
                      project,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textMuted,
                      ),
                    ),
                  // Where the version was read from, so a wrong match is
                  // easy to spot. Last three segments; full path on hover.
                  if (local != null)
                    Tooltip(
                      message: local.root,
                      child: Row(
                        children: [
                          Icon(
                            denied
                                ? LucideIcons.folderLock
                                : LucideIcons.folder,
                            size: 11,
                            color: palette.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              local.root
                                  .split('/')
                                  .reversed
                                  .take(3)
                                  .toList()
                                  .reversed
                                  .join('/'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: chromeMono(
                                context,
                                size: 10.5,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (status.outdated)
              FlyoutUpdateBadge(palette: palette, label: loc.sdkTipsUpdate)
            else if (status.upToDate)
              Tooltip(
                message: loc.sdkTipsLatestLabel,
                child: Icon(
                  LucideIcons.circleCheck,
                  size: 15,
                  color: palette.success,
                  semanticLabel: loc.sdkTipsLatestLabel,
                ),
              ),
          ],
        ),
        // Indented to line up with the platform name, past the icon tile.
        Padding(
          padding: const EdgeInsets.only(left: 40, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlyoutVersionLine(
                palette: palette,
                installed: status.installed,
                latest: status.latest,
                fetch: status.fetch,
                onRetry: onRetry,
              ),
              if (denied)
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(loc.sdkTipsAccessDenied, style: muted),
                    if (Platform.isMacOS)
                      FlyoutButton(
                        palette: palette,
                        icon: LucideIcons.settings,
                        label: loc.sdkTipsOpenSettings,
                        onPressed: () => launchUrl(_filesAndFoldersSettings),
                      ),
                  ],
                )
              else if (status.installed == null &&
                  status.fetch == SdkVersionFetch.loaded)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(loc.sdkTipsCheckProject, style: muted),
                ),
            ],
          ),
        ),
        for (final (i, snippet) in status.snippets.indexed)
          Padding(
            padding: EdgeInsets.only(left: 40, top: i == 0 ? 8 : 6),
            child: _Snippet(text: snippet, palette: palette),
          ),
      ],
    );
  }
}

/// Install line in an inset code box with a copy button that flips to a
/// check for a moment after copying.
class _Snippet extends StatefulWidget {
  final String text;
  final ChromePalette palette;

  const _Snippet({required this.text, required this.palette});

  @override
  State<_Snippet> createState() => _SnippetState();
}

class _SnippetState extends State<_Snippet> {
  Timer? _reset;
  bool _copied = false;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.text));
    _reset?.cancel();
    setState(() => _copied = true);
    _reset = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final loc = S.of(context);
    return Material(
      color: palette.codeBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 3, 3, 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                // Zero-width break after ':' so long Gradle coordinates
                // wrap between segments, not mid-word. Copy keeps the raw text.
                widget.text.replaceAll(':', ':'),
                style: chromeMono(context, size: 11, color: palette.text),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _copy,
              tooltip: _copied ? loc.copied : loc.copy,
              icon: Icon(
                _copied ? LucideIcons.check : LucideIcons.copy,
                size: 13,
              ),
              style: IconButton.styleFrom(
                foregroundColor: _copied ? palette.success : palette.textMuted,
                fixedSize: const Size.square(26),
                minimumSize: const Size.square(26),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
