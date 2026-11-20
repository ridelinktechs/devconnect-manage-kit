import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences/app_preferences.dart';
import '../../core/theme/chrome_palette.dart';
import '../../core/utils/ui/toast_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/device_info.dart';
import '../../server/providers/server_providers.dart';

/// Deep links opened from the desktop, newest first, kept across runs.
final recentDeepLinksProvider =
    NotifierProvider<RecentDeepLinksNotifier, List<String>>(
      RecentDeepLinksNotifier.new,
    );

class RecentDeepLinksNotifier extends Notifier<List<String>> {
  static const _key = 'recent_deep_links';

  @override
  List<String> build() {
    try {
      final raw = AppPreferences().get<String>(_key);
      return raw == null
          ? const []
          : List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const []; // corrupt preference: start over
    }
  }

  void add(String url) {
    state = [url, ...state.where((u) => u != url)].take(8).toList();
    AppPreferences().set(_key, jsonEncode(state));
  }
}

/// Asks for a URL and opens it in [devices] as a deep link — the app
/// routes it as if one of its links had been tapped.
Future<void> openDeepLink(
  BuildContext context,
  WidgetRef ref,
  List<DeviceInfo> devices,
) async {
  final loc = S.of(context);
  final url = await showDialog<String>(
    context: context,
    builder: (_) => _DeepLinkDialog(recent: ref.read(recentDeepLinksProvider)),
  );
  final link = url?.trim();
  if (link == null || link.isEmpty) return;
  ref.read(recentDeepLinksProvider.notifier).add(link);
  final handler = ref.read(wsMessageHandlerProvider);
  for (final d in devices) {
    handler.openUrl(d.deviceId, link);
  }
  if (context.mounted) {
    showSuccessToast(context, message: loc.deepLinkSent, subtitle: link);
  }
}

/// Owns the URL field's controller, so it is disposed only once the dialog
/// has closed: its exit transition still builds the field.
class _DeepLinkDialog extends StatefulWidget {
  const _DeepLinkDialog({required this.recent});

  final List<String> recent;

  @override
  State<_DeepLinkDialog> createState() => _DeepLinkDialogState();
}

class _DeepLinkDialogState extends State<_DeepLinkDialog> {
  late final _field = TextEditingController(
    text: widget.recent.firstOrNull ?? '',
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final mono = chromeMono(
      context,
      size: 12.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return AlertDialog(
      title: Text(loc.deepLinkTitle),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _field,
              autofocus: true,
              style: mono,
              decoration: InputDecoration(
                hintText: 'myapp://orders/42',
                helperText: loc.deepLinkHint,
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            if (widget.recent.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                loc.stateRecentActions.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.grey[500],
                ),
              ),
              for (final link in widget.recent)
                InkWell(
                  onTap: () => Navigator.pop(context, link),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mono.copyWith(color: Colors.grey[500]),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _field.text),
          child: Text(loc.deepLinkOpen),
        ),
      ],
    );
  }
}
