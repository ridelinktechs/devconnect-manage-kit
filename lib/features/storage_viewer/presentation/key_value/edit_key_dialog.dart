import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// The Key-Value tab's add / edit dialog: the key, fixed when editing, and
/// the value as text. It pops `(key, value)` on Save. It owns its fields,
/// so they live through its closing animation.
class EditKeyDialog extends StatefulWidget {
  /// The key being edited; null to add one.
  final String? entryKey;

  /// The value's text to start from.
  final String value;

  const EditKeyDialog({super.key, this.entryKey, required this.value});

  @override
  State<EditKeyDialog> createState() => _EditKeyDialogState();
}

class _EditKeyDialogState extends State<EditKeyDialog> {
  late final _key = TextEditingController(text: widget.entryKey ?? '');
  late final _value = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final adding = widget.entryKey == null;
    final mono = chromeMono(
      context,
      size: 12.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return AlertDialog(
      title: Text(adding ? loc.storageKvAdd : loc.storageKvEdit),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _key,
              enabled: adding,
              autofocus: adding,
              style: mono,
              decoration: InputDecoration(labelText: loc.storageKvKey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              autofocus: !adding,
              minLines: 3,
              maxLines: 12,
              style: mono,
              decoration: InputDecoration(
                labelText: loc.storageKvValue,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (_key.text.trim(), _value.text)),
          child: Text(loc.storageKvSave),
        ),
      ],
    );
  }
}
