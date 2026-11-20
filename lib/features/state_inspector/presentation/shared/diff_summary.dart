import '../../../../models/state/state_change.dart';

/// What a state change did, in brief: how many paths it added, changed and
/// removed, and which.
class DiffSummary {
  final int added;
  final int changed;
  final int removed;

  /// The paths it touched, first seen first.
  final List<String> paths;

  /// The one change, when there is exactly one.
  final StateDiffEntry? only;

  const DiffSummary({
    required this.added,
    required this.changed,
    required this.removed,
    required this.paths,
    this.only,
  });

  factory DiffSummary.of(List<StateDiffEntry> diff) {
    var added = 0;
    var changed = 0;
    var removed = 0;
    final paths = <String>{};
    for (final d in diff) {
      switch (d.operation) {
        case 'add':
          added++;
        case 'remove':
          removed++;
        default:
          changed++;
      }
      paths.add(d.path);
    }
    return DiffSummary(
      added: added,
      changed: changed,
      removed: removed,
      paths: paths.toList(),
      only: diff.length == 1 ? diff.single : null,
    );
  }

  bool get isEmpty => paths.isEmpty;

  /// The one change in a line: `user.name  "Ann" → "Bob"`.
  String? get onlyLine {
    final d = only;
    if (d == null) return null;
    return switch (d.operation) {
      'add' => '${d.path}  + ${briefValue(d.newValue)}',
      'remove' => '${d.path}  − ${briefValue(d.oldValue)}',
      _ => '${d.path}  ${briefValue(d.oldValue)} → ${briefValue(d.newValue)}',
    };
  }
}

/// [value] short enough for one line: strings quoted and cut at 24
/// characters, maps and lists as their size.
String briefValue(dynamic value) => switch (value) {
  null => 'null',
  String s => s.length > 24 ? '"${s.substring(0, 23)}…"' : '"$s"',
  Map m => '{${m.length}}',
  List l => '[${l.length}]',
  _ => '$value',
};
