import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state_with_pulse.dart';
import '../../provider/last_connected_providers.dart';
import '../detail/session_detail_panel.dart';
import '../header/toolbar.dart';
import '../session/session_tile.dart';

class LastConnectedPage extends ConsumerStatefulWidget {
  const LastConnectedPage({super.key});

  @override
  ConsumerState<LastConnectedPage> createState() => _LastConnectedPageState();
}

class _LastConnectedPageState extends ConsumerState<LastConnectedPage> {
  int? _selectedSessionIndex;
  int _selectedTab = 0; // 0=all, 1=logs, 2=network, 3=state, 4=storage

  final _sessionScrollController = SmoothScrollController();
  final _allEventsScrollController = SmoothScrollController();
  final _logsScrollController = SmoothScrollController();
  final _networkScrollController = SmoothScrollController();
  final _stateScrollController = SmoothScrollController();
  final _storageScrollController = SmoothScrollController();

  /// Reset every detail scroll controller to the top. The same controller
  /// instances are reused across different sessions — without this, switching
  /// sessions would leave the new panel scrolled to whatever offset the
  /// previous session was at.
  void _resetDetailScroll() {
    for (final c in [
      _allEventsScrollController,
      _logsScrollController,
      _networkScrollController,
      _stateScrollController,
      _storageScrollController,
    ]) {
      if (c.hasClients) c.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _sessionScrollController.dispose();
    _allEventsScrollController.dispose();
    _logsScrollController.dispose();
    _networkScrollController.dispose();
    _stateScrollController.dispose();
    _storageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(lastConnectedProvider);
    final theme = Theme.of(context);

    // Reset selection if out of bounds
    if (_selectedSessionIndex != null && _selectedSessionIndex! >= sessions.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedSessionIndex = null);
      });
    }

    final selected = _selectedSessionIndex != null && _selectedSessionIndex! < sessions.length
        ? sessions[_selectedSessionIndex!]
        : null;

    return Column(
      children: [
        // Toolbar
        Toolbar(
          sessionCount: sessions.length,
          onClearAll: () {
            ref.read(lastConnectedProvider.notifier).clearAll();
            setState(() => _selectedSessionIndex = null);
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: sessions.isEmpty
              ? EmptyStateWithPulse(
                  icon: LucideIcons.history,
                  title: 'No history',
                  subtitle:
                      'Sessions from disconnected devices will appear here',
                )
              : Row(
                  children: [
                    // Session list
                    SizedBox(
                      width: selected != null ? 260 : 360,
                      child: ListView.builder(
                        controller: _sessionScrollController,
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final isSelected = _selectedSessionIndex == index;
                          return SessionTile(
                            session: session,
                            isSelected: isSelected,
                            onTap: () => setState(() {
                              _selectedSessionIndex = isSelected ? null : index;
                              _selectedTab = 0;
                              _resetDetailScroll();
                            }),
                            onRemove: () {
                              ref
                                  .read(lastConnectedProvider.notifier)
                                  .removeSession(session.deviceInfo.deviceId);
                              if (isSelected) {
                                setState(() => _selectedSessionIndex = null);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    // Detail panel
                    if (selected != null) ...[
                      VerticalDivider(width: 1, color: theme.dividerColor),
                      Expanded(
                        child: SessionDetailPanel(
                          session: selected,
                          selectedTab: _selectedTab,
                          onTabChanged: (tab) =>
                              setState(() => _selectedTab = tab),
                          onClose: () => setState(() {
                            _selectedSessionIndex = null;
                            _resetDetailScroll();
                          }),
                          allEventsScrollController: _allEventsScrollController,
                          logsScrollController: _logsScrollController,
                          networkScrollController: _networkScrollController,
                          stateScrollController: _stateScrollController,
                          storageScrollController: _storageScrollController,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
