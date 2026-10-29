import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'toast_utils.dart';

/// Asks where to save [content] (suggesting [suggestedName]), writes it,
/// and toasts the path. Does nothing if the dialog is cancelled.
Future<void> saveTextFile(
  BuildContext context, {
  required String suggestedName,
  required String typeLabel,
  required String extension,
  required String content,
}) async {
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: [
      XTypeGroup(label: typeLabel, extensions: [extension]),
    ],
  );
  if (location == null) return;
  try {
    await File(location.path).writeAsString(content);
    if (context.mounted) {
      showSuccessToast(
        context,
        message: S.of(context).fileSaved,
        subtitle: location.path,
      );
    }
  } on FileSystemException catch (e) {
    if (context.mounted) {
      showErrorToast(context, message: e.message, error: location.path);
    }
  }
}

/// `devconnect-<what>-20261028-152103.<extension>`.
String exportFileName(String what, String extension) {
  final t = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'devconnect-$what-${t.year}${two(t.month)}${two(t.day)}-'
      '${two(t.hour)}${two(t.minute)}${two(t.second)}.$extension';
}
