import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state_with_pulse.dart';
import '../../../core/utils/ui/toast_utils.dart';
import '../../../models/round/mock_entry.dart';
import '../../../server/providers/server_providers.dart';
import '../../round/provider/round_providers.dart';
import 'editor/rule_editor.dart';
import 'empty/empty_rules_state.dart';
import 'empty/rule_deleted_view.dart';
import 'empty/undo_pill.dart';
import 'header/mock_toolbar.dart';
import 'list/rule_list.dart';
import 'shared/rule_templates.dart';

/// The Mock Server: rules that answer the app's requests on the device
/// instead of the network. The list is on the left, the picked rule's
/// editor on the right; "Push all" sends every rule to the selected device
/// and keeps it in step from then on.
class MockServerPage extends ConsumerStatefulWidget {
  const MockServerPage({super.key});

  @override
  ConsumerState<MockServerPage> createState() => _MockServerPageState();
}

class _MockServerPageState extends ConsumerState<MockServerPage> {
  /// Whether the open editor holds unsaved changes.
  final _dirty = ValueNotifier(false);

  /// Fired to make the editor's unsaved bar refuse a move away.
  final _nudge = ValueNotifier(0);

  /// The rule just held to deletion, and where it was, for Undo.
  ({MockRule rule, int index})? _deleted;

  @override
  void dispose() {
    _dirty.dispose();
    _nudge.dispose();
    super.dispose();
  }

  /// False, with a shake of the unsaved bar, while the editor has changes.
  bool _canLeave() {
    if (!_dirty.value) return true;
    _nudge.value++;
    return false;
  }

  void _select(String id) {
    if (ref.read(selectedMockRuleIdProvider) == id || !_canLeave()) return;
    setState(() => _deleted = null);
    ref.read(selectedMockRuleIdProvider.notifier).set(id);
  }

  void _add([RuleTemplate? template]) {
    if (!_canLeave()) return;
    final rule = newMockRule(template);
    ref.read(mockRulesProvider.notifier).add(rule);
    ref.read(selectedMockRuleIdProvider.notifier).set(rule.id);
    setState(() => _deleted = null);
  }

  void _delete(MockRule rule) {
    final rules = ref.read(mockRulesProvider);
    final index = rules.indexWhere((r) => r.id == rule.id);
    if (index < 0) return;
    ref.read(mockRulesProvider.notifier).remove(rule.id);
    ref.read(selectedMockRuleIdProvider.notifier).set(null);
    setState(() => _deleted = (rule: rules[index], index: index));
  }

  void _undo() {
    final deleted = _deleted;
    if (deleted == null) return;
    final rules = [...ref.read(mockRulesProvider)];
    rules.insert(deleted.index.clamp(0, rules.length), deleted.rule);
    ref.read(mockRulesProvider.notifier).replaceAll(rules);
    ref.read(selectedMockRuleIdProvider.notifier).set(deleted.rule.id);
    setState(() => _deleted = null);
  }

  String _deviceName(String id) =>
      ref
          .read(connectedDevicesProvider)
          .where((d) => d.deviceId == id)
          .firstOrNull
          ?.deviceName ??
      id;

  void _push() {
    final target = ref.read(roundActionTargetProvider);
    if (target == null || !_canLeave()) return;
    final count = ref.read(mockRulesProvider).length;
    try {
      ref.read(mockRulesSyncProvider.notifier).push(target);
      showSuccessToast(
        context,
        message: 'Pushed $count rule${count == 1 ? '' : 's'}',
        subtitle: _deviceName(target),
      );
    } catch (e) {
      showErrorToast(context, message: 'Push failed', error: e.toString());
    }
  }

  void _clear() {
    final target = ref.read(roundActionTargetProvider);
    if (target == null) return;
    try {
      ref.read(mockRulesSyncProvider.notifier).clear(target);
      showSuccessToast(
        context,
        message: 'Cleared the rules on the device',
        subtitle: _deviceName(target),
      );
    } catch (e) {
      showErrorToast(context, message: 'Clear failed', error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(mockRulesProvider);
    final selectedId = ref.watch(selectedMockRuleIdProvider);
    final selected = rules.where((r) => r.id == selectedId).firstOrNull;
    final deleted = _deleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MockToolbar(onAdd: _add, onPush: _push, onClear: _clear),
        const Divider(height: 1),
        Expanded(
          child: rules.isEmpty
              ? EmptyRulesState(
                  onCreate: _add,
                  dropIn: deleted != null,
                  footer: deleted == null ? null : UndoPill(onUndo: _undo),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 340,
                      child: RuleList(
                        selectedId: selected?.id,
                        onSelect: _select,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(
                      child: deleted != null
                          ? RuleDeletedView(
                              key: ValueKey(deleted.rule.id),
                              rule: deleted.rule,
                              onUndo: _undo,
                            )
                          : selected != null
                          ? RuleEditor(
                              key: ValueKey(selected.id),
                              ruleId: selected.id,
                              dirty: _dirty,
                              nudge: _nudge,
                              onDelete: _delete,
                            )
                          : const EmptyStateWithPulse(
                              icon: LucideIcons.mousePointerClick,
                              title: 'Pick a rule to edit',
                              subtitle: 'Or press Add rule to make a new one.',
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
