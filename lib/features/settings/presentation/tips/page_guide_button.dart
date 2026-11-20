import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../server/providers/server_providers.dart';
import 'guides.dart';
import 'tip_detail_dialog.dart';

/// The guides that belong to the page at [route]: its own card first, then
/// the workflows done on it.
List<Guide> guidesForPage(S s, String route) => [
  for (final g in buildGuides(s))
    if (g.route == route) g,
];

/// "i" button beside a page title; opens [guidesForPage] in the guide modal.
class PageGuideButton extends ConsumerWidget {
  final String route;

  const PageGuideButton({super.key, required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: const Icon(LucideIcons.info),
      iconSize: 14,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      color: isDark ? Colors.grey[500] : Colors.grey[600],
      tooltip: s.pageGuide,
      onPressed: () {
        final port = ref.read(wsServerProvider).port;
        showGuideDialog(
          context,
          guides: guidesForPage(s, route),
          index: 0,
          tabLabel: s.settingsGroupGuides,
          port: port == 0 ? AppConstants.defaultPort : port,
          // shortcut: page guides have no {host} snippet; pass the Mac's IP if one ever does.
          host: 'localhost',
        );
      },
    );
  }
}
