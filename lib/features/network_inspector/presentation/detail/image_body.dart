import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/chrome_palette.dart';
import 'blob_info.dart';

/// A picture the SDK sent as a `data:` URL ([dataUrl]): shown itself,
/// zoomable, over a line with its type and size. One Flutter can't decode
/// falls back to [BlobInfo].
class ImageBody extends StatefulWidget {
  final String dataUrl;
  final String label;
  final bool isDark;

  const ImageBody({
    super.key,
    required this.dataUrl,
    required this.label,
    required this.isDark,
  });

  @override
  State<ImageBody> createState() => _ImageBodyState();
}

class _ImageBodyState extends State<ImageBody> {
  late Uint8List _bytes = _decode();

  Uint8List _decode() {
    try {
      return base64Decode(
        widget.dataUrl.substring(widget.dataUrl.indexOf(',') + 1),
      );
    } catch (_) {
      return Uint8List(0);
    }
  }

  @override
  void didUpdateWidget(ImageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.dataUrl, widget.dataUrl)) _bytes = _decode();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.dataUrl;
    final mime = url.substring(5, url.indexOf(';'));
    final fallback = BlobInfo(
      label: widget.label,
      sizeBytes: _bytes.length,
      isDark: widget.isDark,
    );
    if (_bytes.isEmpty) return fallback;
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            maxScale: 8,
            child: Center(
              child: Image.memory(
                _bytes,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '$mime · ${AppConstants.formatBytes(_bytes.length)}',
            style: chromeMono(
              context,
              size: 11,
              color: widget.isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
