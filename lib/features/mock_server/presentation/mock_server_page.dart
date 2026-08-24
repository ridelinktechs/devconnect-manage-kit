import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/feedback/empty_state.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../models/round/mock_entry.dart';
import '../../round/presentation/round_ui.dart';
import '../../round/provider/round_providers.dart';

/// Round 4 — server-side CRUD UI for mock rules.
///
/// Two columns:
/// - left: list of rules with quick toggle/remove
/// - right: editor for the selected rule (or +Add new)
///
/// Toolbar at the top has the global actions: push all to device,
/// clear all from device, push selected. Uses the shared round_ui
/// widget library so it lines up with the rest of the inspector
/// stack.
class MockServerPage extends ConsumerStatefulWidget {
  const MockServerPage({super.key});

  @override
  ConsumerState<MockServerPage> createState() => _MockServerPageState();
}

class _MockServerPageState extends ConsumerState<MockServerPage> {
  bool _pushing = false;

  Future<void> _pushAll() async {
    final rules = ref.read(mockRulesProvider);
    final device = ref.read(roundActionTargetProvider);
    if (device == null) {
      showInfoToast(context, message: 'Select a device first');
      return;
    }
    setState(() => _pushing = true);
    try {
      ref.read(roundActionBridgeProvider).installMockRules(device, rules);
      showSuccessToast(
        context,
        message: 'Pushed ${rules.length} rule${rules.length == 1 ? '' : 's'}',
        subtitle: device,
      );
    } catch (e) {
      showErrorToast(context, message: 'Push failed', error: e.toString());
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  Future<void> _clearAll() async {
    final device = ref.read(roundActionTargetProvider);
    if (device == null) {
      showInfoToast(context, message: 'Select a device first');
      return;
    }
    setState(() => _pushing = true);
    try {
      ref.read(roundActionBridgeProvider).clearMockRules(device);
      showSuccessToast(
        context,
        message: 'Cleared mock rules',
        subtitle: device,
      );
    } catch (e) {
      showErrorToast(context, message: 'Clear failed', error: e.toString());
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  void _addRule() {
    final id = 'r_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    ref.read(mockRulesProvider.notifier).add(
          MockRule(
            id: id,
            name: 'New rule',
            method: 'GET',
            urlPattern: '/api/example',
            statusCode: 200,
            headers: const {'Content-Type': 'application/json'},
            body: '{"ok": true}',
            enabled: true,
            hitCount: 0,
            updatedAt: now,
          ),
        );
    ref.read(selectedMockRuleIdProvider.notifier).state = id;
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(mockRulesProvider);
    final selectedId = ref.watch(selectedMockRuleIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageBar(
          icon: LucideIcons.server,
          title: 'Mock Server',
          count: rules.length,
          countLabel: 'rule',
          actions: [
            ActionButton(
              icon: LucideIcons.plus,
              label: 'Add rule',
              onTap: _addRule,
              style: ActionStyle.ghost,
            ),
            ActionButton(
              icon: LucideIcons.refreshCw,
              label: 'Push all',
              onTap: _pushing ? null : _pushAll,
              loading: _pushing,
              style: ActionStyle.primary,
            ),
            ActionButton(
              icon: LucideIcons.trash2,
              label: 'Clear device',
              onTap: _pushing ? null : _clearAll,
              loading: _pushing,
              style: ActionStyle.danger,
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListHeader(
                      title: 'Rules',
                      trailing: ActionButton(
                        icon: LucideIcons.plus,
                        label: 'Add',
                        onTap: _addRule,
                        style: ActionStyle.ghost,
                      ),
                    ),
                    Expanded(
                      child: rules.isEmpty
                          ? EmptyState(
                              icon: LucideIcons.scrollText,
                              title: 'No rules',
                              subtitle:
                                  'Add a rule and push it to the device.',
                            )
                          : ListView.separated(
                              itemCount: rules.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox.shrink(),
                              itemBuilder: (context, i) {
                                final rule = rules[i];
                                final isSel = rule.id == selectedId;
                                return _RuleRow(
                                  rule: rule,
                                  selected: isSel,
                                  onTap: () => ref
                                          .read(selectedMockRuleIdProvider
                                              .notifier)
                                          .state =
                                      isSel ? null : rule.id,
                                  onToggle: (v) => ref
                                      .read(mockRulesProvider.notifier)
                                      .toggle(rule.id, v),
                                  onDelete: () {
                                    ref
                                        .read(mockRulesProvider.notifier)
                                        .remove(rule.id);
                                    if (isSel) {
                                      ref
                                          .read(selectedMockRuleIdProvider
                                              .notifier)
                                          .state = null;
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                  width: 1, color: ColorTokens.hairline(context)),
              Expanded(
                child: selectedId == null
                    ? EmptyState(
                        icon: LucideIcons.mousePointerClick,
                        title: 'Select a rule',
                        subtitle:
                            'Pick a rule on the left, or click + to add one.',
                      )
                    : _RuleEditor(
                        key: ValueKey(selectedId),
                        ruleId: selectedId,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// List row
// ============================================================

class _RuleRow extends StatelessWidget {
  final MockRule rule;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _RuleRow({
    required this.rule,
    required this.selected,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListRow(
      selected: selected,
      onTap: onTap,
      leading: MethodBadge(rule.method),
      title: Text(
        rule.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        rule.urlPattern,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: rule.enabled,
            onChanged: onToggle,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          _DeleteButton(onTap: onDelete),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: 'Delete rule',
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hover
                  ? ColorTokens.error.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              LucideIcons.trash2,
              size: 12,
              color: _hover
                  ? ColorTokens.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Editor
// ============================================================

class _RuleEditor extends ConsumerStatefulWidget {
  final String ruleId;
  const _RuleEditor({super.key, required this.ruleId});

  @override
  ConsumerState<_RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends ConsumerState<_RuleEditor> {
  late TextEditingController _name;
  late TextEditingController _url;
  late TextEditingController _body;
  late TextEditingController _headers;
  late TextEditingController _statusCtrl;
  late TextEditingController _delayCtrl;
  late TextEditingController _scopeCtrl;
  late TextEditingController _expiresCtrl;
  String _method = 'GET';
  int _status = 200;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _url = TextEditingController();
    _body = TextEditingController();
    _headers = TextEditingController();
    _statusCtrl = TextEditingController();
    _delayCtrl = TextEditingController();
    _scopeCtrl = TextEditingController();
    _expiresCtrl = TextEditingController();
  }

  void _hydrateFrom(MockRule rule) {
    _name.text = rule.name;
    _url.text = rule.urlPattern;
    _method = rule.method;
    _status = rule.statusCode;
    _statusCtrl.text = rule.statusCode.toString();
    _body.text = _prettyJsonIfPossible(rule.body);
    _headers.text = rule.headers.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    final md = rule.metadata ?? const <String, dynamic>{};
    _delayCtrl.text = (md['delayMs'] as int?)?.toString() ?? '';
    final scope = md['scope'];
    if (scope is Map && scope['deviceIds'] is List) {
      _scopeCtrl.text = (scope['deviceIds'] as List).join(', ');
    } else {
      _scopeCtrl.text = '';
    }
    _expiresCtrl.text = (md['expiresAt'] as String?) ?? '';
  }

  String _prettyJsonIfPossible(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  @override
  void didUpdateWidget(covariant _RuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ruleId != widget.ruleId) {
      final rule = ref
          .read(mockRulesProvider)
          .where((r) => r.id == widget.ruleId)
          .firstOrNull;
      if (rule != null) {
        _hydrateFrom(rule);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _body.dispose();
    _headers.dispose();
    _statusCtrl.dispose();
    _delayCtrl.dispose();
    _scopeCtrl.dispose();
    _expiresCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildMetadata() {
    final md = <String, dynamic>{};
    final delay = int.tryParse(_delayCtrl.text.trim());
    if (delay != null && delay >= 0) md['delayMs'] = delay;
    final scopeIds = _scopeCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (scopeIds.isNotEmpty) {
      md['scope'] = {'deviceIds': scopeIds};
    }
    final expires = _expiresCtrl.text.trim();
    if (expires.isNotEmpty) md['expiresAt'] = expires;
    return md;
  }

  void _commit() {
    final rules = ref.read(mockRulesProvider);
    final rule = rules.where((r) => r.id == widget.ruleId).firstOrNull;
    if (rule == null) return;
    final headers = <String, String>{};
    for (final line in _headers.text.split('\n')) {
      final idx = line.indexOf(':');
      if (idx > 0) {
        headers[line.substring(0, idx).trim()] =
            line.substring(idx + 1).trim();
      }
    }
    ref.read(mockRulesProvider.notifier).update(
          rule.copyWith(
            name: _name.text,
            urlPattern: _url.text,
            method: _method,
            statusCode: _status,
            headers: headers,
            body: _body.text,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            metadata: _buildMetadata(),
          ),
        );
  }

  Future<void> _pushThisOne() async {
    _commit();
    final device = ref.read(roundActionTargetProvider);
    if (device == null) {
      _toast('Select a device first');
      return;
    }
    final rule = ref
        .read(mockRulesProvider)
        .where((r) => r.id == widget.ruleId)
        .firstOrNull;
    if (rule == null) return;
    try {
      ref.read(roundActionBridgeProvider).installMockRules(
            device,
            [rule],
          );
      if (!mounted) return;
      _toast('Pushed "${rule.name}" to $device');
    } catch (e) {
      if (!mounted) return;
      _toast('Push failed: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rule = ref
        .watch(mockRulesProvider)
        .where((r) => r.id == widget.ruleId)
        .firstOrNull;
    if (rule == null) return const SizedBox.shrink();
    if (!_initialized) {
      _hydrateFrom(rule);
      _initialized = true;
    }

    final dirty = _name.text != rule.name ||
        _url.text != rule.urlPattern ||
        _method != rule.method ||
        _status != rule.statusCode ||
        _body.text != rule.body ||
        _headers.text !=
            rule.headers.entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n') ||
        _delayCtrl.text !=
            ((rule.metadata?['delayMs'] as int?)?.toString() ?? '') ||
        _scopeCtrl.text !=
            ((rule.metadata?['scope'] is Map &&
                    (rule.metadata!['scope'] as Map)['deviceIds'] is List)
                ? ((rule.metadata!['scope'] as Map)['deviceIds'] as List)
                    .join(', ')
                : '') ||
        _expiresCtrl.text != ((rule.metadata?['expiresAt'] as String?) ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailHeader(
          title: rule.name.isEmpty ? '(unnamed rule)' : rule.name,
          subtitle: rule.urlPattern,
          meta: [
            MetricChip(
              label: 'method',
              value: rule.method.toUpperCase(),
              color: ColorTokens.httpMethodColor(rule.method),
            ),
            MetricChip(
              label: 'status',
              value: rule.statusCode.toString(),
              color: ColorTokens.statusCodeColor(rule.statusCode),
            ),
            MetricChip(
              label: 'updated',
              value: formatHmSs(rule.updatedAt),
              color: Colors.grey,
            ),
          ],
          trailing: ActionButton(
            icon: LucideIcons.send,
            label: dirty ? 'Save & push' : 'Push this',
            onTap: dirty ? _commit : _pushThisOne,
            style: ActionStyle.primary,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Rule name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        initialValue: _method,
                        decoration: const InputDecoration(
                          labelText: 'Method',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'GET', child: Text('GET')),
                          DropdownMenuItem(
                              value: 'POST', child: Text('POST')),
                          DropdownMenuItem(value: 'PUT', child: Text('PUT')),
                          DropdownMenuItem(
                              value: 'PATCH', child: Text('PATCH')),
                          DropdownMenuItem(
                              value: 'DELETE', child: Text('DELETE')),
                        ],
                        onChanged: (v) {
                          setState(() => _method = v ?? 'GET');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _statusCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null) setState(() => _status = n);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _url,
                        decoration: const InputDecoration(
                          labelText: 'URL pattern',
                          hintText: '/api/users/:id',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _headers,
                  decoration: const InputDecoration(
                    labelText: 'Response headers (one per line: key: value)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _delayCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Delay (ms)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _scopeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Scope deviceIds (comma-separated)',
                          hintText: 'all empty = every device',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _expiresCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Expires at (ISO-8601)',
                          hintText: '2026-12-31T23:59:59Z',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _body,
                  decoration: const InputDecoration(
                    labelText: 'Response body (JSON)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 14,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  onChanged: (_) => setState(() {}),
                ),
                if (dirty) ...[
                  const SizedBox(height: 12),
                  ActionButton(
                    icon: LucideIcons.save,
                    label: 'Save changes',
                    onTap: _commit,
                    style: ActionStyle.ghost,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}