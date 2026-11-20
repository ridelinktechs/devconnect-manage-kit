import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/feedback/empty_state.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/disconnected_session.dart';
import '../../../../models/log/log_entry.dart';
import 'event_row.dart';
import 'timeline_event.dart';

class AllEventsList extends StatelessWidget {
  final DisconnectedSession session;
  final ScrollController? controller;

  const AllEventsList({super.key, required this.session, this.controller});

  @override
  Widget build(BuildContext context) {
    // Merge all events sorted by timestamp
    final events = <TimelineEvent>[];
    for (final l in session.logs) {
      events.add(
        TimelineEvent(
          timestamp: l.timestamp,
          type: 'LOG',
          color: _logColor(l.level),
          icon: LucideIcons.terminal,
          title: l.message,
          subtitle: l.level.name.toUpperCase(),
        ),
      );
    }
    for (final n in session.networkEntries) {
      events.add(
        TimelineEvent(
          timestamp: n.startTime,
          type: 'API',
          color: ColorTokens.success,
          icon: LucideIcons.globe,
          title: '${n.method} ${n.url}',
          subtitle: n.isComplete ? '${n.statusCode}' : 'in progress',
        ),
      );
    }
    for (final s in session.stateChanges) {
      events.add(
        TimelineEvent(
          timestamp: s.timestamp,
          type: 'STATE',
          color: ColorTokens.secondary,
          icon: LucideIcons.layers,
          title: s.actionName,
          subtitle: s.stateManagerType,
        ),
      );
    }
    for (final s in session.storageEntries) {
      events.add(
        TimelineEvent(
          timestamp: s.timestamp,
          type: 'STORE',
          color: ColorTokens.warning,
          icon: LucideIcons.database,
          title: s.key,
          subtitle: s.operation,
        ),
      );
    }

    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (events.isEmpty) {
      return EmptyState(
        icon: LucideIcons.inbox,
        title: S.of(context).noEventsYet,
      );
    }

    return ListView.builder(
      controller: controller,
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        return EventRow(event: e);
      },
    );
  }

  Color _logColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return ColorTokens.logDebug;
      case LogLevel.info:
        return ColorTokens.logInfo;
      case LogLevel.warn:
        return ColorTokens.logWarn;
      case LogLevel.error:
        return ColorTokens.logError;
    }
  }
}
