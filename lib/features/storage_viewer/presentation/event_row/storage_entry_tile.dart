import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../models/storage/storage_entry.dart';
import '../shared/storage_preview.dart';
import '../shared/storage_tokens.dart';

/// One row in the storage entry list — fixed 58px height with:
///   • left border: 2px storage-type accent (3px selected), or
///     selected-accent when the row is the current detail panel target
///   • timestamp + OP badge (read/write/delete) + TYPE abbreviation
///     + mono key + truncated value preview.
///
/// Opaque hit-testing wraps the GestureDetector so subsequent taps
/// after a rebuild aren't swallowed by an outer MouseRegion.
class StorageEntryTile extends StatelessWidget {
  final StorageEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const StorageEntryTile({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('HH:mm:ss.SSS').format(
      DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
    );
    final tColor = storageTypeColor(entry.storageType);
    final opColor = storageOpColor(entry.operation);

    return GestureDetector(
      onTap: onTap,
      // Opaque hit-testing so taps land on the tile's full area — without
      // this, an outer MouseRegion can swallow the hit for hover handling
      // before the GestureDetector sees it, breaking subsequent taps after
      // a rebuild.
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 58,
          padding: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorTokens.selectedBg(isDark)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              left: BorderSide(
                color: isSelected ? ColorTokens.selectedAccent : tColor,
                width: isSelected ? 3 : 2,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              // Timestamp
              SizedBox(
                width: 84,
                child: Text(
                  time,
                  style: TextStyle(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: 10,
                    color: Colors.grey[500],
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              // Operation badge
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: opColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    entry.operation.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: opColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Storage type badge
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: tColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    storageTypeAbbrev(entry.storageType),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: tColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Key + value preview
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? ColorTokens.lightBackground
                            : ColorTokens.darkNeutral,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      storageValuePreview(entry.value),
                      style: TextStyle(
                        fontFamily: AppConstants.monoFontFamily,
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}