import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state_with_pulse.dart';
import '../../../core/theme/chrome_palette.dart';
import '../../../core/utils/files/save_file.dart';
import '../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../server/providers/server_providers.dart';
import '../provider/layout_providers.dart';
import 'canvas/layout_canvas.dart';
import 'canvas/path_bar.dart';
import 'header/toolbar.dart';
import 'properties/properties_panel.dart';
import 'shared/layout_style.dart';
import 'shared/mini_button.dart';
import 'shared/notice.dart';
import 'shared/section_label.dart';
import 'shared/splitter.dart';
import 'tree/element_tree.dart';
import 'tree/tree_search_bar.dart';

/// A capture as one file: what was captured, from where, and when.
String _snapshotJson(LayoutSnapshot s, String device) => prettyJson.convert({
  'device': device,
  'capturedAt': s.capturedAt?.toIso8601String(),
  'width': s.size.width,
  'height': s.size.height,
  if (s.truncated) 'truncated': true,
  'error': ?s.error,
  if (s.screenshot case final png?) 'screenshot': base64Encode(png),
  'root': s.root?.toJson(),
});

/// Layout inspector: a capture of the app's screen with its element tree
/// (widgets, React components or Android views). Hover the screenshot to
/// see an element's box model, click it — or pick it in the tree, in the
/// path bar, with the arrow keys or by searching — to see its properties.
/// Hold ⌥ to measure from the selection to the hovered element.
class LayoutInspectorPage extends ConsumerStatefulWidget {
  const LayoutInspectorPage({super.key});

  @override
  ConsumerState<LayoutInspectorPage> createState() =>
      _LayoutInspectorPageState();
}

class _LayoutInspectorPageState extends ConsumerState<LayoutInspectorPage> {
  String? _hoveredId;
  String? _selectedId;
  final _expanded = <String>{};
  final _treeScroll = SmoothScrollController();
  final _propsScroll = SmoothScrollController();
  final _treeFocus = FocusNode(debugLabel: 'layout tree');
  final _search = TextEditingController();
  LayoutSnapshot? _seen;
  String? _seenDevice;

  /// The tree as listed: the capture's, or only its app elements.
  LayoutNode? _shown;
  bool _appOnly = false;
  int _total = 0;
  int _count = 0;

  /// Rows holding a search match, and which one is current.
  List<String> _matches = const [];
  int _match = 0;

  double _panelWidth = 400;
  double _treeShare = 0.56;

  @override
  void dispose() {
    _treeScroll.dispose();
    _propsScroll.dispose();
    _treeFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  void _hover(String? id) {
    if (id != _hoveredId) setState(() => _hoveredId = id);
  }

  /// Lists [root] — whole, or its app elements only — keeping what was
  /// open and selected: by id, or by place in the tree for a [recapture]
  /// (ids don't survive one).
  void _show(LayoutNode? root, {bool recapture = false}) {
    final old = _shown;
    final places = {
      if (recapture && old != null)
        for (final id in [?_selectedId, ..._expanded])
          id: layoutSignature(old, id),
    };
    final shown = _shown = root == null
        ? null
        : _appOnly
        ? layoutFiltered(root, isAppElement)
        : root;
    String? find(String id) {
      if (shown == null) return null;
      if (!recapture) return layoutPathTo(shown, id).isEmpty ? null : id;
      final place = places[id];
      return place == null ? null : layoutFindSignature(shown, place);
    }

    final open = [for (final id in _expanded) ?find(id)];
    final selected = _selectedId == null ? null : find(_selectedId!);
    _selectedId = selected;
    _expanded
      ..clear()
      ..addAll([?shown?.id, ...open]);
    if (shown != null && selected != null) {
      _expanded.addAll(layoutPathTo(shown, selected).map((n) => n.id));
    }
    _count = shown == null ? 0 : layoutNodeCount(shown);
    _matches = shown == null ? const [] : layoutSearch(shown, _search.text);
    _match = 0;
  }

  void _toggleAppOnly() => setState(() {
    _appOnly = !_appOnly;
    _show(_seen?.root);
  });

  void _onSearch(String query) {
    final shown = _shown;
    if (shown == null) return;
    setState(() {
      _matches = layoutSearch(shown, query);
      _match = 0;
    });
    if (_matches.isNotEmpty) _select(shown, _matches.first);
  }

  void _step(int by) {
    final shown = _shown;
    if (shown == null || _matches.isEmpty) return;
    _match = (_match + by) % _matches.length;
    _select(shown, _matches[_match]);
  }

  /// Selects [id], opens the rows above it and scrolls it into view.
  void _select(LayoutNode root, String id) {
    setState(() {
      _selectedId = id;
      _expanded.addAll(layoutPathTo(root, id).map((n) => n.id));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(root, id));
  }

  void _reveal(LayoutNode root, String id) {
    if (!mounted || !_treeScroll.hasClients) return;
    final index = layoutTreeRows(
      root,
      _expanded,
    ).indexWhere((row) => row.$1.any((n) => n.id == id));
    if (index < 0) return;
    final position = _treeScroll.position;
    final top = index * ElementTree.rowHeight;
    final double? target = top < position.pixels
        ? top
        : top + ElementTree.rowHeight >
              position.pixels + position.viewportDimension
        ? top + ElementTree.rowHeight - position.viewportDimension
        : null;
    if (target == null) return;
    _treeScroll.animateTo(
      target.clamp(0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
  }

  /// ↑ / ↓ move through the rows; → opens a row (then steps in), ← closes
  /// it (then steps out); Esc lets go of the selection.
  KeyEventResult _onTreeKey(LayoutNode root, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rows = layoutTreeRows(root, _expanded);
    final i = rows.indexWhere((row) => row.$1.any((n) => n.id == _selectedId));
    final row = i < 0 ? null : rows[i];
    String? next;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        if (_selectedId == null) return KeyEventResult.ignored;
        setState(() => _selectedId = null);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        next = rows[i < 0 ? 0 : math.min(i + 1, rows.length - 1)].$1.first.id;
      case LogicalKeyboardKey.arrowUp:
        next = rows[math.max(i - 1, 0)].$1.first.id;
      case LogicalKeyboardKey.arrowRight when row != null:
        final head = row.$1.first;
        if (row.$1.last.children.isEmpty) return KeyEventResult.handled;
        if (!_expanded.contains(head.id)) {
          setState(() => _expanded.add(head.id));
          return KeyEventResult.handled;
        }
        next = rows[i + 1].$1.first.id;
      case LogicalKeyboardKey.arrowLeft when row != null:
        final head = row.$1.first;
        if (_expanded.contains(head.id) && row.$1.last.children.isNotEmpty) {
          setState(() => _expanded.remove(head.id));
          return KeyEventResult.handled;
        }
        for (var j = i - 1; j >= 0; j--) {
          if (rows[j].$2 < row.$2) {
            next = rows[j].$1.first.id;
            break;
          }
        }
      default:
        return KeyEventResult.ignored;
    }
    if (next != null) _select(root, next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final devices = ref.watch(connectedDevicesProvider);
    final selectedDeviceId = ref.watch(selectedDeviceProvider);
    final target =
        devices.where((d) => d.deviceId == selectedDeviceId).firstOrNull ??
        (devices.length == 1 ? devices.single : null);
    final snapshots = ref.watch(layoutSnapshotsProvider);
    final notifier = ref.read(layoutSnapshotsProvider.notifier);
    final snapshot = target == null ? null : snapshots[target.deviceId];
    final capturing =
        target != null && notifier.pending.contains(target.deviceId);
    final unanswered =
        target != null && notifier.unanswered.contains(target.deviceId);
    final root = snapshot?.root;
    if (!identical(snapshot, _seen)) {
      final sameDevice = target?.deviceId == _seenDevice;
      if (!sameDevice) {
        _shown = null;
        _selectedId = null;
        _expanded.clear();
      }
      _seen = snapshot;
      _seenDevice = target?.deviceId;
      _hoveredId = null;
      _total = root == null ? 0 : layoutNodeCount(root);
      _show(root, recapture: true);
    }
    final shown = _shown;
    final device = target == null
        ? null
        : '${target.appName} · ${target.deviceName}';

    return Column(
      children: [
        Toolbar(
          title: loc.layoutTitle,
          device: target == null ? null : (target.platform, device!),
          count: root == null ? null : _total,
          capturedAt: snapshot?.capturedAt,
          captureLabel: target == null ? null : loc.layoutCapture,
          capturing: capturing,
          onCapture: target == null
              ? null
              : () => notifier.capture(target.deviceId),
          onClose: snapshot == null
              ? null
              : () {
                  _search.clear();
                  notifier.clear(target!.deviceId);
                },
          exports: snapshot == null || root == null
              ? null
              : [
                  MenuItemButton(
                    leadingIcon: const Icon(LucideIcons.image, size: 14),
                    onPressed: switch (snapshot.screenshot) {
                      final png? => () => saveBytesFile(
                        context,
                        suggestedName: exportFileName('layout', 'png'),
                        typeLabel: 'PNG',
                        extension: 'png',
                        bytes: png,
                      ),
                      null => null,
                    },
                    child: Text(loc.layoutSavePng),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(LucideIcons.fileJson, size: 14),
                    onPressed: () => saveTextFile(
                      context,
                      suggestedName: exportFileName('layout', 'json'),
                      typeLabel: 'JSON',
                      extension: 'json',
                      content: _snapshotJson(snapshot, device!),
                    ),
                    child: Text(loc.layoutSaveJson),
                  ),
                ],
        ),
        Expanded(
          child: target == null
              ? EmptyStateWithPulse(
                  icon: LucideIcons.scanSearch,
                  title: loc.layoutTitle,
                  subtitle: loc.layoutNoDevice,
                )
              : snapshot == null || shown == null
              ? EmptyStateWithPulse(
                  icon: LucideIcons.scanSearch,
                  title: loc.layoutTitle,
                  subtitle: unanswered
                      ? loc.layoutNoAnswer
                      : snapshot?.error != null
                      ? '${loc.layoutTreeError}: ${snapshot!.error}'
                      : loc.layoutHint,
                )
              : _inspector(context, snapshot, shown, unanswered),
        ),
      ],
    );
  }

  /// The canvas, then the tree over the properties, split by draggable
  /// dividers.
  Widget _inspector(
    BuildContext context,
    LayoutSnapshot snapshot,
    LayoutNode shown,
    bool unanswered,
  ) {
    final loc = S.of(context);
    final path = _selectedId == null
        ? const <LayoutNode>[]
        : layoutPathTo(shown, _selectedId!);
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = clampDouble(
          _panelWidth,
          300,
          math.max(300, constraints.maxWidth - 360),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutCanvas(
                      // Another device or screen size starts from "fit".
                      key: ValueKey((_seenDevice, snapshot.size)),
                      snapshot: snapshot,
                      root: shown,
                      hoveredId: _hoveredId,
                      selected: path.lastOrNull,
                      notices: [
                        if (snapshot.screenshot == null)
                          Notice(text: loc.layoutNoScreenshot),
                        if (unanswered)
                          Notice(
                            text: loc.layoutNoAnswer,
                            icon: LucideIcons.alertTriangle,
                            color: LayoutColors.warning,
                          ),
                      ],
                      hint: path.isEmpty ? null : loc.layoutMeasureHint,
                      onHover: _hover,
                      onSelect: (id) {
                        // So the arrow keys and Esc work from here on.
                        _treeFocus.requestFocus();
                        _select(shown, id);
                      },
                    ),
                  ),
                  PathBar(
                    path: path,
                    onHover: _hover,
                    onSelect: (id) => _select(shown, id),
                  ),
                ],
              ),
            ),
            Splitter(
              axis: Axis.vertical,
              onDrag: (dx) => setState(() => _panelWidth = panelWidth - dx),
            ),
            SizedBox(
              width: panelWidth,
              child: LayoutBuilder(
                builder: (context, panel) {
                  final treeHeight = clampDouble(
                    panel.maxHeight * _treeShare,
                    140,
                    math.max(140, panel.maxHeight - 120),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: treeHeight,
                        child: _treePane(context, snapshot, shown),
                      ),
                      Splitter(
                        axis: Axis.horizontal,
                        onDrag: (dy) => setState(
                          () =>
                              _treeShare = ((treeHeight + dy) / panel.maxHeight)
                                  .clamp(0.1, 0.9),
                        ),
                      ),
                      Expanded(
                        child: PropertiesPanel(
                          node: path.lastOrNull,
                          scroll: _propsScroll,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _treePane(
    BuildContext context,
    LayoutSnapshot snapshot,
    LayoutNode shown,
  ) {
    final loc = S.of(context);
    final palette = ChromePalette.of(context);
    final meta = chromeMono(context, size: 11, color: palette.textMuted);
    final searching = _search.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
          child: SectionLabel(
            loc.layoutTree,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_count', style: meta),
                const SizedBox(width: 6),
                MiniButton(
                  icon: LucideIcons.filter,
                  tooltip: loc.layoutAppOnly,
                  active: _appOnly,
                  onTap: _toggleAppOnly,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
          child: TreeSearchBar(
            controller: _search,
            matches: _matches.length,
            current: _match,
            onChanged: _onSearch,
            onClear: () {
              _search.clear();
              _onSearch('');
            },
            onStep: _step,
          ),
        ),
        if (snapshot.truncated)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Notice(
              text: loc.layoutTruncated,
              icon: LucideIcons.scissors,
              color: LayoutColors.warning,
            ),
          ),
        if (snapshot.error case final error?)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Notice(
              text: '${loc.layoutTreeError}: $error',
              icon: LucideIcons.alertTriangle,
              color: LayoutColors.warning,
            ),
          ),
        Expanded(
          child: Focus(
            focusNode: _treeFocus,
            onKeyEvent: (_, event) => _onTreeKey(shown, event),
            child: ElementTree(
              rows: layoutTreeRows(shown, _expanded),
              matches: searching ? _matches.toSet() : const {},
              expanded: _expanded,
              hoveredId: _hoveredId,
              selectedId: _selectedId,
              scroll: _treeScroll,
              onToggle: (id) => setState(
                () => _expanded.contains(id)
                    ? _expanded.remove(id)
                    : _expanded.add(id),
              ),
              onHover: _hover,
              onSelect: (id) {
                _treeFocus.requestFocus();
                _select(shown, id);
              },
            ),
          ),
        ),
      ],
    );
  }
}
