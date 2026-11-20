import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../header/section_title.dart';
import '../tips/guides.dart';
import '../tips/tip_detail_dialog.dart';
import '../tips/tip_grid.dart';
import '../tips/tip_tabs.dart';

/// "Tips & Shortcuts" card: pill tabs over a grid of lit guide cards.
/// Pressing a card opens its detail modal, which pages through the tab.
/// Code in the modal uses this machine's [host] and the server [port].
class TipsSection extends StatefulWidget {
  final int port;
  final String host;

  const TipsSection({super.key, required this.port, required this.host});

  @override
  State<TipsSection> createState() => _TipsSectionState();
}

class _TipsSectionState extends State<TipsSection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tab = TipTab.values[_tab];
    final guides = [
      for (final g in buildGuides(s))
        if (g.tab == tab) g,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(icon: LucideIcons.lightbulb, title: s.tipsAndShortcuts),
        Text(
          s.tipsAndShortcutsDesc,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: ChromePalette.of(context).textMuted,
          ),
        ),
        const SizedBox(height: 16),
        TipTabs(
          labels: [for (final t in TipTab.values) tipTabLabel(s, t)],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 14),
        TipGrid(
          tab: _tab,
          guides: guides,
          onOpen: (i) => showGuideDialog(
            context,
            guides: guides,
            index: i,
            tabLabel: tipTabLabel(s, tab),
            port: widget.port,
            host: widget.host,
          ),
        ),
      ],
    );
  }
}
