import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../core/utils/scroll/smooth_scroll_controller.dart';
import '../../../../models/round/mock_entry.dart';
import '../../../../server/providers/server_providers.dart';
import '../../../round/provider/round_providers.dart';
import '../../../settings/presentation/controls/segmented_picker.dart';
import '../shared/mock_look.dart';
import 'body_field.dart';
import 'form_section.dart';
import 'hold_to_delete.dart';
import 'notched_field.dart';
import 'preset_chips.dart';
import 'rule_draft.dart';
import 'rule_header.dart';
import 'unsaved_bar.dart';

const _statusPresets = [200, 201, 204, 400, 401, 403, 404, 500, 503];
const _delayPresets = [0, 300, 1000, 3000];

/// Edits one rule as a draft: nothing reaches the rule list, or a synced
/// device, until "Save changes". While the draft differs from the rule,
/// [dirty] is true and the page fires [nudge] to refuse leaving it.
class RuleEditor extends ConsumerStatefulWidget {
  final String ruleId;
  final ValueNotifier<bool> dirty;
  final ValueListenable<int> nudge;
  final ValueChanged<MockRule> onDelete;

  const RuleEditor({
    super.key,
    required this.ruleId,
    required this.dirty,
    required this.nudge,
    required this.onDelete,
  });

  @override
  ConsumerState<RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends ConsumerState<RuleEditor> {
  final _scroll = SmoothScrollController();
  final _boxes = {
    for (final f in RuleField.values)
      if (f != RuleField.method) f: TextEditingController(),
  };
  final _nodes = {
    for (final f in RuleField.values)
      if (f != RuleField.method && f != RuleField.body) f: FocusNode(),
  };
  String _method = 'GET';
  late RuleDraft _saved;
  int _reveal = 0;
  int _flash = 0;
  Set<RuleField> _flashed = const {};

  MockRule? get _rule => ref
      .read(mockRulesProvider)
      .where((r) => r.id == widget.ruleId)
      .firstOrNull;

  RuleDraft get _draft => RuleDraft(
    name: _boxes[RuleField.name]!.text,
    method: _method,
    url: _boxes[RuleField.url]!.text,
    status: _boxes[RuleField.status]!.text,
    delay: _boxes[RuleField.delay]!.text,
    headers: _boxes[RuleField.headers]!.text,
    body: _boxes[RuleField.body]!.text,
    devices: _boxes[RuleField.devices]!.text,
    expires: _boxes[RuleField.expires]!.text,
  );

  @override
  void initState() {
    super.initState();
    final rule = _rule;
    _saved = rule == null
        ? const RuleDraft(
            name: '',
            method: 'GET',
            url: '',
            status: '200',
            delay: '',
            headers: '',
            body: '',
            devices: '',
            expires: '',
          )
        : RuleDraft.of(rule);
    _fill(_saved);
  }

  void _fill(RuleDraft draft) {
    for (final MapEntry(key: field, value: box) in _boxes.entries) {
      box.text = draft.text(field);
    }
    _method = draft.method;
  }

  @override
  void dispose() {
    widget.dirty.value = false;
    _scroll.dispose();
    for (final box in _boxes.values) {
      box.dispose();
    }
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.dirty.value = _draft.changesFrom(_saved).isNotEmpty;
  }

  void _set(RuleField field, String text) {
    _boxes[field]!.text = text;
    _changed();
  }

  String? _save() {
    final draft = _draft;
    final bad = draft.invalid;
    if (bad.isNotEmpty) {
      setState(() => _reveal++);
      _nodes[bad.first]?.requestFocus();
      return bad.length == 1
          ? 'Fix 1 field first'
          : 'Fix ${bad.length} fields first';
    }
    final rule = _rule;
    if (rule == null) return null;
    ref
        .read(mockRulesProvider.notifier)
        .update(
          draft.applyTo(rule, now: DateTime.now().millisecondsSinceEpoch),
        );
    setState(() => _saved = draft);
    widget.dirty.value = false;
    return null;
  }

  void _discard() {
    final changed = _draft.changesFrom(_saved);
    _fill(_saved);
    setState(() {
      _flashed = changed;
      _flash++;
    });
    widget.dirty.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final rule = ref.watch(
      mockRulesProvider.select(
        (rules) => rules.where((r) => r.id == widget.ruleId).firstOrNull,
      ),
    );
    if (rule == null) return const SizedBox.shrink();
    final p = ChromePalette.of(context);
    final draft = _draft;
    final changes = draft.changesFrom(_saved);
    final target = ref.watch(roundActionTargetProvider);
    final targetName = target == null
        ? null
        : ref
                  .watch(connectedDevicesProvider)
                  .where((d) => d.deviceId == target)
                  .firstOrNull
                  ?.deviceName ??
              target;
    final status = int.tryParse(draft.status.trim());
    final validStatus = draft.errorOf(RuleField.status) == null ? status : null;
    final delay = int.tryParse(draft.delay.trim());
    final devices = [
      for (final id in draft.devices.split(','))
        if (id.trim().isNotEmpty) id.trim(),
    ];
    final accent = mockAccent(p.isDark);

    NotchedField field(
      RuleField f,
      String label, {
      String? helper,
      bool? check,
      bool mono = false,
      int minLines = 1,
      int maxLines = 1,
      TextInputType? keyboardType,
    }) => NotchedField(
      controller: _boxes[f]!,
      focusNode: _nodes[f],
      label: label,
      error: draft.errorOf(f),
      helper: helper,
      check: check,
      mono: mono,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      reveal: _reveal,
      flash: _flash,
      flashing: _flashed.contains(f),
      onChanged: (_) => _changed(),
    );

    Widget withPresets(Widget box, Widget presets) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 156, child: box),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: presets,
          ),
        ),
      ],
    );

    return UnsavedBar(
      changes: changes.length,
      onSave: _save,
      onDiscard: _discard,
      nudge: widget.nudge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RuleHeader(
            name: draft.name,
            method: draft.method,
            url: draft.url,
            status: validStatus,
            delayMs: delay,
            devices: devices.length,
            expires: draft.expires.trim(),
            enabled: rule.enabled,
            action: HoldToDelete(
              semanticLabel: 'Hold to delete ${rule.name}',
              onDeleted: () => widget.onDelete(rule),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      field(RuleField.name, 'Rule name'),
                      const SizedBox(height: 14),
                      FormSection(
                        icon: LucideIcons.arrowUpRight,
                        title: 'When the app sends',
                        children: [
                          SegmentedPicker<String>(
                            segments: [
                              for (final m in mockMethods)
                                (value: m, label: m, icon: null),
                            ],
                            value: _method,
                            onChanged: (m) {
                              _method = m;
                              _changed();
                            },
                          ),
                          field(
                            RuleField.url,
                            'URL pattern',
                            mono: true,
                            check:
                                draft.errorOf(RuleField.url) == null &&
                                draft.url.trim().isNotEmpty,
                            helper:
                                r'A regex found anywhere in the URL, e.g. /api/users/\d+',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FormSection(
                        icon: LucideIcons.reply,
                        title: 'Answer with',
                        children: [
                          withPresets(
                            field(
                              RuleField.status,
                              'Status',
                              mono: true,
                              keyboardType: TextInputType.number,
                              helper: validStatus == null
                                  ? null
                                  : statusReason(validStatus),
                            ),
                            PresetChips(
                              mono: true,
                              current: draft.status,
                              presets: [
                                for (final code in _statusPresets)
                                  (
                                    value: '$code',
                                    label: '$code',
                                    tooltip: statusReason(code),
                                  ),
                              ],
                              tintOf: (v) => statusTint(int.parse(v)),
                              inkOf: (v) =>
                                  statusInk(int.parse(v), isDark: p.isDark),
                              onPick: (v) => _set(RuleField.status, v),
                            ),
                          ),
                          withPresets(
                            field(
                              RuleField.delay,
                              'Delay (ms)',
                              mono: true,
                              keyboardType: TextInputType.number,
                              helper: delay == null || delay <= 0
                                  ? 'Answers at once'
                                  : 'Answers after ${formatDelay(delay)}',
                            ),
                            PresetChips(
                              current: delay == 0 ? '' : draft.delay,
                              presets: [
                                for (final ms in _delayPresets)
                                  (
                                    value: ms == 0 ? '' : '$ms',
                                    label: ms == 0 ? 'None' : formatDelay(ms),
                                    tooltip: null,
                                  ),
                              ],
                              tintOf: (_) => accent,
                              inkOf: (_) => accent,
                              onPick: (v) => _set(RuleField.delay, v),
                            ),
                          ),
                          field(
                            RuleField.headers,
                            'Response headers',
                            mono: true,
                            minLines: 2,
                            maxLines: 6,
                            helper: 'One per line, key: value',
                          ),
                          BodyField(
                            controller: _boxes[RuleField.body]!,
                            flash: _flash,
                            flashing: _flashed.contains(RuleField.body),
                            onChanged: (_) => _changed(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FormSection(
                        icon: LucideIcons.shieldCheck,
                        title: 'Limits',
                        note: 'optional',
                        children: [
                          field(
                            RuleField.devices,
                            'Only on device IDs',
                            mono: true,
                            helper:
                                'Comma-separated; empty means every device the rules are pushed to',
                          ),
                          if (target != null && !devices.contains(target))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: PresetChips(
                                current: '',
                                presets: [
                                  (
                                    value: target,
                                    label: '+ $targetName',
                                    tooltip: target,
                                  ),
                                ],
                                tintOf: (_) => accent,
                                inkOf: (_) => accent,
                                onPick: (id) => _set(
                                  RuleField.devices,
                                  [...devices, id].join(', '),
                                ),
                              ),
                            ),
                          field(
                            RuleField.expires,
                            'Expires at',
                            mono: true,
                            check:
                                draft.expires.trim().isNotEmpty &&
                                draft.errorOf(RuleField.expires) == null,
                            helper:
                                'ISO-8601 such as 2026-12-31T23:59:59Z; empty means never',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
