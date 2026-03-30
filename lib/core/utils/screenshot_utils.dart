import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Captures a widget as a PNG image and saves to file.
Future<void> captureWidgetAsImage(
  BuildContext context,
  Widget screenshotWidget, {
  double width = 600,
  double pixelRatio = 2.0,
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
    await Future.delayed(const Duration(milliseconds: 300));

    final boundary = overlayKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      overlayEntry.remove();
      return;
    }

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    overlayEntry.remove();

    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();

    final fileName =
        'dcmt_${DateTime.now().millisecondsSinceEpoch}.png';
    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [
        const XTypeGroup(label: 'PNG Image', extensions: ['png']),
      ],
    );

    if (location == null) return;

    final file = File(location.path);
    await file.writeAsBytes(pngBytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screenshot saved: ${file.path}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screenshot failed: $e')),
      );
    }
  }
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
