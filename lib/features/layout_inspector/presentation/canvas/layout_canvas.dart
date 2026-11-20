import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show PointMode, clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../provider/layout_providers.dart';
import 'overlay_painter.dart';
import 'zoom_controls.dart';

// Zoom: down to a quarter of "fit", up to 800% of the app's size, by 1.25.
const _minZoom = 0.25;
const _maxScale = 8.0;
const _zoomStep = 1.25;

/// The screen on an artboard: the screenshot (or, without one, every
/// element's outline) in a device frame, with the hovered element's box
/// model and the selection drawn on top — clipped to the screen. Scroll or
/// pinch to zoom, drag to pan; ⌘+ / ⌘− zoom, ⌘0 shows the app's size, ⌘1
/// fits it, ⌘2 zooms to the selection. Hold ⌥ to measure.
class LayoutCanvas extends StatefulWidget {
  final LayoutSnapshot snapshot;
  final LayoutNode root;
  final String? hoveredId;
  final LayoutNode? selected;
  final List<Widget> notices;
  final String? hint;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onSelect;

  const LayoutCanvas({
    super.key,
    required this.snapshot,
    required this.root,
    required this.hoveredId,
    required this.selected,
    required this.notices,
    required this.hint,
    required this.onHover,
    required this.onSelect,
  });

  @override
  State<LayoutCanvas> createState() => _LayoutCanvasState();
}

class _LayoutCanvasState extends State<LayoutCanvas> {
  final _zoom = TransformationController();

  /// ⌥ is held: measure from the selection to the hovered element.
  bool _measuring = false;

  // From the last layout, for the zoom actions: the canvas' size, and
  // device pixels to canvas pixels at zoom 1.
  Size _viewport = Size.zero;
  double _fit = 1;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _zoom.dispose();
    super.dispose();
  }

  /// The zoom, 1 being "fit".
  double get _scale => _zoom.value.getMaxScaleOnAxis();

  /// Zoom [scale] with [focus], a point of the unzoomed canvas, in the
  /// middle of the view.
  void _view(double scale, Offset focus) {
    final s = clampDouble(scale, _minZoom, _maxScale / _fit);
    final middle = _viewport.center(Offset.zero);
    _zoom.value = Matrix4.translationValues(middle.dx, middle.dy, 0)
      ..multiply(Matrix4.diagonal3Values(s, s, 1))
      ..multiply(Matrix4.translationValues(-focus.dx, -focus.dy, 0));
  }

  /// Zoom [scale], keeping what's in the middle of the view there.
  void _zoomTo(double scale) =>
      _view(scale, _zoom.toScene(_viewport.center(Offset.zero)));

  /// The selection, as large as the view takes, in its middle.
  void _zoomToSelection() {
    final r = widget.selected?.rect;
    if (r == null) return;
    final screen = Rect.fromCenter(
      center: _viewport.center(Offset.zero),
      width: widget.snapshot.size.width * _fit,
      height: widget.snapshot.size.height * _fit,
    );
    final box = Rect.fromLTWH(
      screen.left + r.left * _fit,
      screen.top + r.top * _fit,
      math.max(r.width * _fit, 1),
      math.max(r.height * _fit, 1),
    );
    _view(
      math.min(
        (_viewport.width - 96) / box.width,
        (_viewport.height - 96) / box.height,
      ),
      box.center,
    );
  }

  bool _onKey(KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed != _measuring) {
      setState(() => _measuring = keyboard.isAltPressed);
    }
    final command = Platform.isMacOS
        ? keyboard.isMetaPressed
        : keyboard.isControlPressed;
    if (event is KeyUpEvent ||
        !command ||
        keyboard.isAltPressed ||
        !TickerMode.getValuesNotifier(context).value.enabled) {
      return false;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.equal ||
          LogicalKeyboardKey.add ||
          LogicalKeyboardKey.numpadAdd:
        _zoomTo(_scale * _zoomStep);
      case LogicalKeyboardKey.minus || LogicalKeyboardKey.numpadSubtract:
        _zoomTo(_scale / _zoomStep);
      case LogicalKeyboardKey.digit0 || LogicalKeyboardKey.numpad0:
        _zoomTo(1 / _fit);
      case LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1:
        _zoom.value = Matrix4.identity();
      case LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2
          when widget.selected != null:
        _zoomToSelection();
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final snapshot = widget.snapshot;
    final size = snapshot.size;
    return ColoredBox(
      color: palette.codeBg,
      child: CustomPaint(
        painter: _DotGridPainter(
          palette.isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.08),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (size.isEmpty) return const SizedBox.shrink();
            // Device pixels to canvas pixels, at zoom 1.
            final scale = math.min(
              math.min(
                (constraints.maxWidth - 48) / size.width,
                (constraints.maxHeight - 48) / size.height,
              ),
              2.0,
            );
            if (scale <= 0) return const SizedBox.shrink();
            _viewport = constraints.biggest;
            _fit = scale;
            final hovered = widget.hoveredId == null
                ? null
                : layoutPathTo(widget.root, widget.hoveredId!).lastOrNull;
            String? idAt(Offset local) =>
                layoutElementAt(widget.root, local / scale)?.id;
            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _zoom,
                    minScale: _minZoom,
                    maxScale: _maxScale / scale,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: Center(
                      child: Container(
                        width: size.width * scale,
                        height: size.height * scale,
                        decoration: BoxDecoration(
                          color: palette.isDark
                              ? const Color(0xFF05070A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: palette.shadow,
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        // On top: a border inside would shrink the screen
                        // below the size the boxes are placed at.
                        foregroundDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.precise,
                            onHover: (e) =>
                                widget.onHover(idAt(e.localPosition)),
                            onExit: (_) => widget.onHover(null),
                            child: GestureDetector(
                              onTapUp: (e) {
                                if (idAt(e.localPosition) case final id?) {
                                  widget.onSelect(id);
                                }
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (snapshot.screenshot case final png?)
                                    Image.memory(
                                      png,
                                      fit: BoxFit.fill,
                                      gaplessPlayback: true,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  CustomPaint(
                                    painter: OverlayPainter(
                                      root: widget.root,
                                      hovered: hovered,
                                      selected: widget.selected,
                                      scale: scale,
                                      zoom: _zoom,
                                      measuring: _measuring,
                                      outlineAll: snapshot.screenshot == null,
                                      isDark: palette.isDark,
                                      fontFamily: DefaultTextStyle.of(
                                        context,
                                      ).style.fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final notice in widget.notices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: notice,
                        ),
                    ],
                  ),
                ),
                if (widget.hint case final hint?)
                  Positioned(
                    left: 14,
                    right: 220, // clear of the zoom bar
                    bottom: 18,
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: palette.textMuted),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: ZoomControls(
                    zoom: _zoom,
                    fit: scale,
                    onZoomIn: () => _zoomTo(_scale * _zoomStep),
                    onZoomOut: () => _zoomTo(_scale / _zoomStep),
                    onPercent: (p) => _zoomTo(p / scale),
                    onFit: () => _zoom.value = Matrix4.identity(),
                    onSelection: widget.selected == null
                        ? null
                        : _zoomToSelection,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;

  _DotGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const step = 16.0;
    canvas.drawPoints(
      PointMode.points,
      [
        for (var x = step / 2; x < size.width; x += step)
          for (var y = step / 2; y < size.height; y += step) Offset(x, y),
      ],
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}
