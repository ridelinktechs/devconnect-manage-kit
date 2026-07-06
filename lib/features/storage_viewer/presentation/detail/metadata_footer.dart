import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/storage/storage_entry.dart';

/// Key/value list rendered at the bottom of the detail panel —
/// `Type / Operation / Shape / Device`. Mono-style values, 96px
/// label gutter, no bottom row spacing override so consecutive
/// rows stay close.
class MetadataFooter extends StatelessWidget {
  final StorageEntry entry;
  final bool isDark;
  final String stats;

  const MetadataFooter({
    super.key,
    required this.entry,
    required this.isDark,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final valueColor = isDark ? Colors.white70 : Colors.black87;
    final monoStyle = TextStyle(
      fontFamily: AppConstants.monoFontFamily,
      fontSize: 11,
      color: valueColor,
    );

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: monoStyle,
                  softWrap: true,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Type', entry.storageType.name),
        row('Operation', entry.operation),
        row('Shape', stats),
        row('Device', entry.deviceId),
      ],
    );
  }
}