import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/chrome_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/mini_button.dart';

/// "⌘[key]" / "Ctrl+[key]", for tooltips.
String _keyLabel(String key) => Platform.isMacOS ? '⌘$key' : 'Ctrl+$key';

/// −, the zoom (100% = the app's size; a click lists presets), +, then
/// fit, actual size and zoom to the selection.
class ZoomControls extends StatelessWidget {
  final TransformationController zoom;

  /// Device pixels to canvas pixels at zoom 1.
  final double fit;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  /// Zoom to a share of the app's size: 1 for 100%.
  final ValueChanged<double> onPercent;
  final VoidCallback onFit;
  final VoidCallback? onSelection;

  const ZoomControls({
    super.key,
    required this.zoom,
    required this.fit,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onPercent,
    required this.onFit,
    required this.onSelection,
  });

  static const _presets = [50, 100, 200, 400];

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final palette = ChromePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniButton(
            icon: LucideIcons.zoomOut,
            tooltip: '${loc.layoutZoomOut} (${_keyLabel('−')})',
            onTap: onZoomOut,
          ),
          MenuAnchor(
            menuChildren: [
              for (final p in _presets)
                MenuItemButton(
                  onPressed: () => onPercent(p / 100),
                  shortcut: p == 100
                      ? SingleActivator(
                          LogicalKeyboardKey.digit0,
                          meta: Platform.isMacOS,
                          control: !Platform.isMacOS,
                        )
                      : null,
                  child: Text('$p%'),
                ),
            ],
            builder: (context, controller, _) => Tooltip(
              message: loc.layoutZoomLevel,
              child: TextButton(
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                style: TextButton.styleFrom(
                  fixedSize: const Size(52, 26),
                  minimumSize: const Size(52, 26),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: palette.text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: ListenableBuilder(
                  listenable: zoom,
                  builder: (context, _) => Text(
                    '${(fit * zoom.value.getMaxScaleOnAxis() * 100).round()}%',
                    style: chromeMono(context, size: 11, color: palette.text),
                  ),
                ),
              ),
            ),
          ),
          MiniButton(
            icon: LucideIcons.zoomIn,
            tooltip: '${loc.layoutZoomIn} (${_keyLabel('+')})',
            onTap: onZoomIn,
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            color: palette.border,
          ),
          MiniButton(
            icon: LucideIcons.scan,
            tooltip: '${loc.layoutFit} (${_keyLabel('1')})',
            onTap: onFit,
          ),
          MiniButton(
            text: '1:1',
            tooltip: '${loc.layoutActualSize} (${_keyLabel('0')})',
            onTap: () => onPercent(1),
          ),
          MiniButton(
            icon: LucideIcons.focus,
            tooltip: '${loc.layoutZoomToSelection} (${_keyLabel('2')})',
            onTap: onSelection,
          ),
        ],
      ),
    );
  }
}
