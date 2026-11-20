import 'package:flutter/material.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/storage/storage_entry.dart';
import '../shared/storage_preview.dart';
import '../shared/storage_tokens.dart';

/// What the detail panel lists under the value — the storage and its store,
/// the operation, the value's shape and size, and the app and device — as
/// label and value rows in a card.
class MetadataFooter extends StatelessWidget {
  final StorageEntry entry;

  /// "App · device" the operation came from, when that device is known.
  final String? source;

  /// The value's size, e.g. "1.2 KB".
  final String size;

  const MetadataFooter({
    super.key,
    required this.entry,
    this.source,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final p = ChromePalette.of(context);
    final rows = [
      ('Storage', storageLabel(entry.storageType, entry.storeId)),
      ('Operation', entry.operation),
      ('Shape', storageShapeOf(entry.value)),
      ('Size', size),
      ('Device', source ?? entry.deviceId),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).details.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: p.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              for (final (i, (label, value)) in rows.indexed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(
                            top: BorderSide(
                              color: p.border.withValues(alpha: 0.6),
                            ),
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          label,
                          style: TextStyle(fontSize: 12, color: p.textMuted),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          value,
                          style: chromeMono(context, size: 12, color: p.text),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
