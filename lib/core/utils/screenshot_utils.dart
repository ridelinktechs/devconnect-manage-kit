import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'toast_utils.dart';

/// Captures a widget as a PNG image and saves to file. Returns the saved
/// file path on success, or null if the user cancelled the save dialog or
/// capture failed.
///
/// [fileName] is the suggested filename shown in the save dialog. If null,
/// a timestamp-based default is used (e.g. `dcmt_1717456789.png`).
/// Callers should pass a meaningful name so the user can recognise the
/// context of the screenshot — e.g. `storage_data_user_token`.
///
/// [pixelRatio] defaults to 3.0 for crisp Retina-class output on
/// macOS/Windows displays. Lower if the screenshot is too large to share.
///
/// [onSaved] is called with the saved path after the file is written. If
/// omitted, the rich "Screenshot saved · Reveal" overlay toast is shown.
///
/// Implementation note: we use [XFile] + [saveTo] (rather than `File.writeAsBytes`)
/// so the user-selected path is treated as authoritative — on macOS the OS
/// won't silently append timestamps or rename to `image.png` after the dialog
/// closes.
Future<String?> captureWidgetAsImage(
  BuildContext context,
  Widget screenshotWidget, {
  double width = 600,
  double pixelRatio = 3.0,
  String? fileName,
  void Function(String savedPath)? onSaved,
}) async {
  try {
    // Show flash
    _showCaptureFlash(context);

    final overlayKey = GlobalKey();
    final theme = Theme.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: 0,
        child: RepaintBoundary(
          key: overlayKey,
          child: Theme(
            data: theme,
            child: Material(
              child: SizedBox(
                width: width,
                child: screenshotWidget,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    // Wait long enough for async widgets (e.g. JsonPrettyViewer's
    // isolate compute) to settle and paint before snapshotting.
    await Future.delayed(const Duration(milliseconds: 600));

    final boundary = overlayKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      overlayEntry.remove();
      return null;
    }

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    overlayEntry.remove();

    if (byteData == null) return null;

    final pngBytes = byteData.buffer.asUint8List();

    final baseName = (fileName == null || fileName.isEmpty)
        ? 'dcmt_${DateTime.now().millisecondsSinceEpoch}'
        : fileName;
    final withExt =
        baseName.endsWith('.png') ? baseName : '$baseName.png';

    final location = await getSaveLocation(
      suggestedName: withExt,
      acceptedTypeGroups: [
        const XTypeGroup(label: 'PNG Image', extensions: ['png']),
      ],
    );

    if (location == null) return null;

    // Force the saved file's name to [withExt] regardless of what the OS
    // returns in [location.path] — some platforms append timestamps or
    // strip extensions after the dialog closes.
    final savedPath = _ensureFilename(location.path, withExt);
    final xfile = XFile.fromData(
      pngBytes,
      mimeType: 'image/png',
      name: withExt,
      length: pngBytes.lengthInBytes,
    );
    await xfile.saveTo(savedPath);

    if (context.mounted) {
      if (onSaved != null) {
        onSaved(savedPath);
      } else {
        // Use the rich overlay toast defined in toast_utils.dart so
        // every page shows the same "Screenshot saved · Reveal" pill.
        showScreenshotSavedToast(context, filePath: savedPath);
      }
    }
    return savedPath;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screenshot failed: $e')),
      );
    }
    return null;
  }
}

/// Returns [path] but with its basename replaced by [desiredName] when the
/// user picked a folder via the save dialog. This keeps our naming
/// convention (`storage_data_user_token.png`) even if the OS would otherwise
/// default the new file to `image.png` or add a numeric suffix.
String _ensureFilename(String path, String desiredName) {
  final sep = path.contains(r'\') ? r'\' : '/';
  final last = path.lastIndexOf(sep);
  if (last == -1) return '$path$sep$desiredName';
  return '${path.substring(0, last + 1)}$desiredName';
}

void _showCaptureFlash(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry flashEntry;
  flashEntry = OverlayEntry(
    builder: (_) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      onEnd: () {
        if (flashEntry.mounted) flashEntry.remove();
      },
      builder: (context, value, _) => IgnorePointer(
        child: Container(color: Colors.white.withValues(alpha: value)),
      ),
    ),
  );
  overlay.insert(flashEntry);
}

