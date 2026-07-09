import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/misc/status_badge.dart';
import '../../../../components/text/text_component.dart';
import '../../../../components/viewers/json_viewer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/utils/network_url_formatter.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../models/network/network_entry.dart';
import '../shared/body_view.dart';
import '../shared/detail_tab_bar.dart';
import '../network/headers_view.dart';
import '../network/timing_view.dart';
import '../shared/copy_button.dart';

/// Right-pane detail for network events. Four tabs:
///
/// - **Headers** — request + response headers ([HeadersView]).
/// - **Request** — request body ([BodyView]).
/// - **Response** — response body ([BodyView]).
/// - **Timing** — duration hero + timeline ([TimingView]).
class NetworkDetail extends ConsumerStatefulWidget {
  final NetworkEntry entry;
  final ValueChanged<int>? onTabChanged;
  final ValueChanged<bool>? onJsonModeChanged;

  const NetworkDetail({
    super.key,
    required this.entry,
    this.onTabChanged,
    this.onJsonModeChanged,
  });

  @override
  ConsumerState<NetworkDetail> createState() => _NetworkDetailState();
}

class _NetworkDetailState extends ConsumerState<NetworkDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = _makeController();
    _tabController.addListener(_onTabIndexChange);
  }

  TabController _makeController([int initialIndex = 0]) {
    return TabController(
      length: 4,
      vsync: this,
      animationDuration: ref.read(tabAnimationProvider),
      initialIndex: initialIndex,
    );
  }

  void _onTabIndexChange() {
    if (!_tabController.indexIsChanging) {
      widget.onTabChanged?.call(_tabController.index);
    }
  }

  void _rebuildController() {
    final oldIndex = _tabController.index;
    _tabController.removeListener(_onTabIndexChange);
    _tabController.dispose();
    _tabController = _makeController(oldIndex);
    _tabController.addListener(_onTabIndexChange);
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabIndexChange);
    _tabController.dispose();
    super.dispose();
  }

  NetworkEntry get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.listen(tabAnimationProvider, (prev, next) {
      if (prev != next) _rebuildController();
    });

    return Column(
      children: [
        // URL bar + actions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkBackground : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HttpMethodBadge(method: entry.method),
                  const SizedBox(width: 8),
                  if (entry.isComplete) ...[
                    StatusBadge(statusCode: entry.statusCode),
                    const SizedBox(width: 8),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ColorTokens.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ColorTokens.warning.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: ColorTokens.warning,
                            ),
                          ),
                          const SizedBox(width: 5),
                          TextComponent(
                            'In Progress...',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ColorTokens.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Tooltip(
                      message: entry.url,
                      waitDuration: const Duration(milliseconds: 300),
                      child: TextComponent(
                        formatUrlPretty(entry.url),
                        style: TextStyle(
                          fontFamily: AppConstants.monoFontFamily,
                          fontSize: 11,
                          height: 1.35,
                          color: isDark
                              ? ColorTokens.lightBackground
                              : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Action buttons row
              Row(
                children: [
                  if (entry.duration != null) ...[
                    TimingBar(duration: entry.duration!),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  CopyButton(
                    tooltip: 'Copy URL',
                    icon: LucideIcons.link,
                    onTap: () => _copyText(
                        context, formatUrlOneLine(entry.url), 'URL'),
                  ),
                  const SizedBox(width: 4),
                  CopyButton(
                    tooltip: 'Copy Path',
                    icon: LucideIcons.route,
                    onTap: () {
                      try {
                        final uri = Uri.parse(entry.url);
                        final path = uri.path.isNotEmpty ? uri.path : entry.url;
                        _copyText(context, path, 'Path');
                      } catch (_) {
                        _copyText(context, entry.url, 'Path');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  CopyButton(
                    tooltip: 'Copy as cURL',
                    icon: LucideIcons.terminal,
                    onTap: () => _copyText(
                        context, _buildCurl(entry), 'cURL'),
                  ),
                  const SizedBox(width: 4),
                  CopyButton(
                    tooltip: 'Copy request',
                    icon: LucideIcons.upload,
                    onTap: () {
                      final body = entry.requestBody;
                      final text = body is String
                          ? body
                          : (body != null
                              ? const JsonEncoder.withIndent('  ')
                                  .convert(body)
                              : '');
                      _copyText(context, text, 'Request');
                    },
                  ),
                  const SizedBox(width: 4),
                  CopyButton(
                    tooltip: 'Copy response',
                    icon: LucideIcons.download,
                    onTap: () {
                      final body = entry.responseBody;
                      final text = body is String
                          ? body
                          : (body != null
                              ? const JsonEncoder.withIndent('  ')
                                  .convert(body)
                              : '');
                      _copyText(context, text, 'Response');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // Tabs
        DetailTabBar(
          controller: _tabController,
          isDark: isDark,
          accentColor: ColorTokens.primary,
          tabs: const ['Headers', 'Request', 'Response', 'Timing'],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              LazyTab(
                controller: _tabController,
                index: 0,
                builder: (_) => HeadersView(entry: entry),
              ),
              LazyTab(
                controller: _tabController,
                index: 1,
                builder: (_) => BodyView(
                  body: entry.requestBody,
                  label: 'Request Body',
                  deviceId: entry.deviceId,
                  onJsonModeChanged: widget.onJsonModeChanged,
                ),
              ),
              LazyTab(
                controller: _tabController,
                index: 2,
                builder: (_) => BodyView(
                  body: entry.responseBody,
                  label: 'Response Body',
                  deviceId: entry.deviceId,
                  onJsonModeChanged: widget.onJsonModeChanged,
                ),
              ),
              LazyTab(
                controller: _tabController,
                index: 3,
                builder: (_) => TimingView(entry: entry),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildCurl(NetworkEntry e) {
    final buf = StringBuffer("curl -X ${e.method} '${e.url}'");
    e.requestHeaders.forEach((k, v) {
      buf.write(" \\\n  -H '$k: $v'");
    });
    if (e.requestBody != null) {
      final body = e.requestBody is String
          ? e.requestBody as String
          : const JsonEncoder().convert(e.requestBody);
      buf.write(" \\\n  -d '$body'");
    }
    return buf.toString();
  }
}

/// Tiny 200px-wide linear progress bar + duration label, used in the
/// network detail's URL bar to give an at-a-glance response-time hint.
class TimingBar extends StatelessWidget {
  final int duration;

  const TimingBar({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    const maxWidth = 200.0;
    final ratio = (duration / 2000).clamp(0.0, 1.0);

    Color barColor;
    if (duration < 200) {
      barColor = ColorTokens.success;
    } else if (duration < 500) {
      barColor = ColorTokens.warning;
    } else {
      barColor = ColorTokens.error;
    }

    return Row(
      children: [
        SizedBox(
          width: maxWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: barColor.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextComponent(
          formatDuration(duration),
          style: TextStyle(
            fontFamily: AppConstants.monoFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: barColor,
          ),
        ),
      ],
    );
  }
}

void _copyText(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  showCopiedToast(context, label: '$label copied');
}