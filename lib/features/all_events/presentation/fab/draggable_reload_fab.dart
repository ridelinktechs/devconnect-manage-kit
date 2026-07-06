import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/device_info.dart';

/// Description of one reload action exposed by the FAB.
///
/// Carries the icon, tooltip, current spinner state, and the callback to
/// fire when the user taps this slot.
class FabAction {
  final IconData icon;
  final String tooltip;
  final bool spinning;
  final VoidCallback onTap;

  const FabAction({
    required this.icon,
    required this.tooltip,
    required this.spinning,
    required this.onTap,
  });
}

/// Draggable, glass-effect reload FAB. The button's contents adapt to the
/// platform of the connected devices (Flutter = Hot Reload + Hot Restart,
/// RN = Metro reload, Android = Activity reset, mixed = universal reload).
///
/// The user can drag the FAB anywhere inside a safe area — it never
/// overlaps the page header / filter bar and stays at least 20px from
/// every viewport edge. Position is intentionally NOT persisted: every cold
/// start resets to the bottom-right corner.
class DraggableReloadFab extends StatefulWidget {
  final List<DeviceInfo> devices;
  final bool reloading;
  final bool hotRestarting;
  final VoidCallback onReload;
  final VoidCallback onHotRestart;

  const DraggableReloadFab({
    super.key,
    required this.devices,
    required this.reloading,
    required this.hotRestarting,
    required this.onReload,
    required this.onHotRestart,
  });

  @override
  State<DraggableReloadFab> createState() => _DraggableReloadFabState();
}

class _DraggableReloadFabState extends State<DraggableReloadFab>
    with SingleTickerProviderStateMixin {
  /// Distance from the bottom-right corner of the parent (the All Events
  /// page content). 20 = default 20px margin from bottom + right edges.
  double _right = 20;
  double _bottom = 20;

  bool _hovered = false;
  bool _dragging = false;

  // Drag tracking — we record the starting screen position and the
  // starting edge-distances, then compute new distances from the delta.
  late double _dragStartRight;
  late double _dragStartBottom;
  late Offset _dragStartGlobal;
  // Press feedback: a brief scale-down + opacity dip on the FAB.
  bool _pressed = false;

  static const double _fabHeight = 44;
  static const double _collapsedWidth = 44;
  static const double _actionWidth = 38; // each action button is 38px wide
  static const double _actionGap = 4;
  static const double _edgeMargin = 20; // distance from screen edges
  /// Combined height of the page chrome the FAB must never overlap:
  ///   • page header (48) — "All Events" title bar
  ///   • filter bar   (44) — LOG / API / STATE / ... chip row
  /// Mirrors the `Container(height: 48, ...)` at `Header` and the
  /// `Container(height: 44, ...)` at `FilterBar` in this file; if you
  /// change either, change the constants here.
  static const double _headerHeight = 48;
  static const double _filterBarHeight = 44;

  @override
  void initState() {
    super.initState();
    // Always start at the default position (bottom-right, 20px margin).
    // Position is NOT persisted across launches — every cold start
    // resets the FAB so the user always knows where to find it
    // without hunting around the screen for a previously-dragged ghost.
    _right = _edgeMargin;
    _bottom = _edgeMargin;
    // Eagerly allocate the controller so dispose() never trips over an
    // uninitialised `late` field. The FAB can be mounted without ever
    // triggering a reload (e.g. user has no devices), in which case the
    // old lazy form was never read and dispose() would throw
    // LateInitializationError.
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  // ── Drag handlers ────────────────────────────────────────────────────────
  //
  // The FAB drops **wherever the user releases it** within a safe area:
  // never above the header, never outside the viewport, never behind
  // the dock. Position is intentionally NOT persisted — every launch
  // starts fresh.

  void _onPanStart(DragStartDetails d) {
    _dragStartRight = _right;
    _dragStartBottom = _bottom;
    _dragStartGlobal = d.globalPosition;
    setState(() {
      _dragging = true;
      _pressed = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final delta = d.globalPosition - _dragStartGlobal;
    final media = MediaQuery.of(context);
    final size = media.size;

    // Clamp so the FAB:
    //   • is at least [_edgeMargin] from each viewport edge,
    //   • never overlaps the page chrome — its top edge stays at least
    //     [_edgeMargin] below the filter bar bottom (= header + filter
    //     bar height from the top of the screen). This ensures the FAB
    //     can never float on top of the title or chip rows.
    final minRight = _edgeMargin;
    final maxRight = (size.width - _collapsedWidth - _edgeMargin)
        .clamp(minRight, double.infinity);
    final minBottom = _edgeMargin;
    final maxBottom = (size.height -
            _fabHeight -
            _headerHeight -
            _filterBarHeight -
            _edgeMargin -
            media.padding.bottom)
        .clamp(minBottom, double.infinity);

    setState(() {
      _right = (_dragStartRight - delta.dx).clamp(minRight, maxRight);
      _bottom = (_dragStartBottom - delta.dy).clamp(minBottom, maxBottom);
    });
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    setState(() {
      _dragging = false;
      _pressed = false;
    });
    // Stay where the user dropped. Do NOT persist — see initState
    // for the rationale.
  }

  /// Dispatch a tap to the right action. We need this on the *outer*
  /// GestureDetector (alongside the pan handlers) because a nested
  /// GestureDetector around each action icon would out-compete the pan
  /// recognizer in the gesture arena and silently break dragging.
  ///
  /// For a single-action FAB the whole surface triggers that one action.
  /// For multi-action FABs (e.g. Flutter = Hot reload + Hot restart) we
  /// pick the action by horizontal position — each action owns a strip
  /// of width [_actionWidth] with [_actionGap] between strips.
  void _onTapUp(TapUpDetails details) {
    final actions = _actionsFor();
    if (actions.isEmpty) return;

    if (actions.length == 1) {
      actions[0].onTap();
      return;
    }
    final localX = details.localPosition.dx;
    for (var i = 0; i < actions.length; i++) {
      final start = i * (_actionWidth + _actionGap);
      final end = start + _actionWidth;
      if (localX >= start && localX <= end) {
        actions[i].onTap();
        return;
      }
    }
  }

  // ── Action discovery ─────────────────────────────────────────────────────

  /// Returns the list of available reload actions for the currently
  /// connected devices (in a stable, predictable order: hot reload before
  /// hot restart). Mirrors the per-platform IDE hotkeys:
  ///
  ///   Flutter → Hot Reload + Hot Restart
  ///   RN      → Reload Metro
  ///   Android → Rebuild
  ///   Mixed   → single universal "Reload app"
  List<FabAction> _actionsFor() {
    if (widget.devices.isEmpty) return const [];
    bool isFlutter(String p) => p.toLowerCase() == 'flutter';
    bool isRN(String p) {
      final lo = p.toLowerCase();
      return lo == 'reactnative' || lo == 'react_native' || lo == 'rn';
    }
    bool isAndroid(String p) => p.toLowerCase() == 'android';

    final hasFlutter = widget.devices.any((d) => isFlutter(d.platform));
    final hasRN = widget.devices.any((d) => isRN(d.platform));
    final hasAndroid = widget.devices.any((d) => isAndroid(d.platform));
    final platforms = (hasFlutter ? 1 : 0) +
        (hasRN ? 1 : 0) +
        (hasAndroid ? 1 : 0);

    if (platforms > 1) {
      // Mixed: universal reload only.
      return [
        FabAction(
          icon: LucideIcons.zap,
          tooltip: S.of(context).reloadApp,
          spinning: widget.reloading,
          onTap: widget.onReload,
        ),
      ];
    }
    if (hasFlutter) {
      return [
        FabAction(
          icon: LucideIcons.zap,
          tooltip: S.of(context).reloadAppHotReload,
          spinning: widget.reloading,
          onTap: widget.onReload,
        ),
        FabAction(
          icon: LucideIcons.refreshCcw,
          tooltip: S.of(context).reloadAppHotRestart,
          spinning: widget.hotRestarting,
          onTap: widget.onHotRestart,
        ),
      ];
    }
    if (hasRN) {
      return [
        FabAction(
          icon: LucideIcons.rocket,
          tooltip: S.of(context).reloadAppMetro,
          spinning: widget.reloading,
          onTap: widget.onReload,
        ),
      ];
    }
    if (hasAndroid) {
      // Android: Activity.recreate() is a runtime state reset — NOT a real
      // "rebuild" of the APK. We label and icon this the same as Flutter's
      // "Hot restart" so the UI reflects what actually happens (full state
      // reset, no code recompile). For the *real* Android rebuild the
      // developer has to run gradle assembleDebug + reinstall — which is
      // outside what a runtime SDK can trigger.
      return [
        FabAction(
          icon: LucideIcons.refreshCcw,
          tooltip: S.of(context).reloadAppHotRestart,
          spinning: widget.reloading,
          onTap: widget.onReload,
        ),
      ];
    }
    return [
      FabAction(
        icon: LucideIcons.zap,
        tooltip: S.of(context).reloadApp,
        spinning: widget.reloading,
        onTap: widget.onReload,
      ),
    ];
  }

  // ── Sizing ──────────────────────────────────────────────────────────────

  double _currentFabWidth() {
    final actions = _actionsFor();
    if (actions.isEmpty) return _collapsedWidth;
    // When multiple actions exist, the FAB expands on hover to show them.
    // For single-action platforms it stays the same size (no expand needed).
    if (actions.length > 1 && _hovered) {
      return _actionWidth * actions.length +
          _actionGap * (actions.length - 1);
    }
    return _collapsedWidth;
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = _actionsFor();

    // When the FAB has multiple actions available (Flutter = Hot Reload +
    // Hot Restart) the *width* animates from 44 → 80 on hover — but the
    // *Row* underneath still tries to lay out every action. With a 44px
    // container and an 80px-tall row of two 38px icons + 4px gap, the
    // second one overflows invisibly until the user hovers. Drop it
    // until the pill actually expands.
    final visibleActions = (actions.length > 1 && !_hovered)
        ? actions.take(1).toList()
        : actions;

    final fabWidth = _currentFabWidth();
    final disabled = actions.isEmpty;

    // Shared spinner — whichever reload is in flight, the shared
    // `_spinCtrl` ticks. Toggled once per build so the multi-action case
    // doesn't fight itself (the old per-icon helper would reset the
    // controller while the other icon was still spinning).
    _syncSpinner(visibleActions.any((a) => a.spinning));

    // Clamp in build() too, not just `_onPanUpdate` — if the user
    // resizes the window smaller than the dragged position, the
    // Positioned offsets need to be re-clamped to the new viewport or
    // the FAB escapes the screen.
    final media = MediaQuery.of(context);
    final size = media.size;
    final maxRight = (size.width - fabWidth - _edgeMargin)
        .clamp(_edgeMargin, double.infinity);
    final maxBottom = (size.height -
            _fabHeight -
            _headerHeight -
            _filterBarHeight -
            _edgeMargin -
            media.padding.bottom)
        .clamp(_edgeMargin, double.infinity);
    final clampedRight = _right.clamp(_edgeMargin, maxRight);
    final clampedBottom = _bottom.clamp(_edgeMargin, maxBottom);

    return Positioned(
      // Plain Positioned (no AnimatedPositioned) so the FAB tracks the
      // cursor instantly during drag. Any animation here would lag behind
      // the pointer and feel sticky.
      right: clampedRight,
      bottom: clampedBottom,
      child: AnimatedScale(
        // Press feedback + slight grow while dragging.
        scale: _pressed ? 0.94 : (_dragging ? 1.04 : 1.0),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          onEnter: (_) {
            if (!_dragging) setState(() => _hovered = true);
          },
          onExit: (_) {
            if (!_dragging) setState(() => _hovered = false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            // Single tap dispatch lives on the OUTER detector too — that way
            // the inner per-icon GestureDetectors can't out-compete the
            // pan recognizer in the gesture arena (which is what blocked
            // the drag from working). Tap vs. drag is decided by Flutter's
            // built-in slop: a quick release → onTapUp, a movement past
            // the touch slop → onPanStart.
            onTapUp: _onTapUp,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: _fabHeight,
              width: fabWidth,
              decoration: _decoration(isDark, disabled, _hovered || _dragging),
              child: Stack(
                children: [
                  // Inner top highlight — a 1px-tall gradient line simulating
                  // the refraction on a glass surface's top edge. Cheaper and
                  // crisper than a true inset shadow.
                  Positioned(
                    top: 0,
                    left: 10,
                    right: 10,
                    child: IgnorePointer(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              (isDark ? Colors.white : Colors.white)
                                  .withValues(alpha: isDark ? 0.35 : 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (actions.isEmpty)
                        _fabIcon(
                          icon: LucideIcons.zap,
                          tooltip: S.of(context).reloadAppNoDevices,
                          spinning: false,
                          disabled: true,
                          isDark: isDark,
                        )
                      else
                        for (int i = 0; i < visibleActions.length; i++) ...[
                          if (i > 0) const SizedBox(width: _actionGap),
                          _fabIcon(
                            icon: visibleActions[i].icon,
                            tooltip: visibleActions[i].tooltip,
                            spinning: visibleActions[i].spinning,
                            disabled: false,
                            isDark: isDark,
                          ),
                        ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Frosted-glass decoration. Three layers (top to bottom):
  ///   1. Outer drop shadow — tinted to the background, never pure black,
  ///      no neon glow.
  ///   2. Background fill — high-alpha neutral (260 of 255 alpha) so the
  ///      surface beneath shows through subtly without backdrop-blur cost.
  ///      For the *true* frosted look we wrap it in BackdropFilter so it
  ///      actually blurs what's behind when there's content (e.g. event
  ///      rows); we drop BackdropFilter when content is empty (no perf
  ///      cost on idle empty states).
  ///   3. 1px border — translucent white in dark, translucent black in light.
  BoxDecoration _decoration(bool isDark, bool disabled, bool emphasised) {
    final surfaceColor = isDark
        ? const Color(0xFF1B2129)
        : const Color(0xFFFDFEFF);
    return BoxDecoration(
      color: disabled
          ? surfaceColor.withValues(alpha: 0.72)
          : surfaceColor.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.06),
        width: 1,
      ),
      boxShadow: [
        // Drop shadow, tinted to background.
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.18),
          blurRadius: disabled ? 16 : 22,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        // Slight forward "lift" when hovered/dragged — felt, not loud.
        if (emphasised)
          BoxShadow(
            color: ColorTokens.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
      ],
    );
  }

  /// One icon "slot" inside the pill. Spins while its action is in flight.
  ///
  /// IMPORTANT: this widget is purely visual. It does **not** wrap its child
  /// in a [GestureDetector] — taps are dispatched by the outer FAB-level
  /// handler via [_onTapUp] using horizontal position. Adding an inner
  /// `GestureDetector(onTap: ...)` here would out-compete the outer pan
  /// recognizer in the gesture arena and silently break dragging.
  Widget _fabIcon({
    required IconData icon,
    required String tooltip,
    required bool spinning,
    required bool disabled,
    required bool isDark,
  }) {
    final color = disabled
        ? (isDark ? Colors.grey[700]! : Colors.grey[400]!)
        : (isDark ? Colors.grey[200]! : Colors.grey[800]!);

    final iconWidget = spinning
        ? RotationTransition(
            // Always drive from the shared `_spinCtrl` — whether it's
            // actually animating or not is decided by `_syncSpinner()` in
            // `build()`, not per-icon here.
            turns: _spinCtrl,
            child: Icon(icon, size: 17, color: color),
          )
        : Icon(icon, size: 17, color: color);

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: _actionWidth,
        height: _fabHeight,
        child: Center(child: iconWidget),
      ),
    );
  }

  // Spinner — one controller, repeats when in flight. Cheap because every
  // icon uses the same controller (visual only; not part of any layout
  // pass that affects the parent). Initialised in initState() (not as a
  // `late final` with an initializer) so dispose() never trips over an
  // uninitialised controller — the FAB can be mounted without ever
  // triggering a reload, in which case the old lazy form threw
  // LateInitializationError when the widget tree was torn down.
  late AnimationController _spinCtrl;

  /// Single source of truth for the shared spinner: any action currently
  /// in flight → repeat; otherwise → stop. Called once per build so the
  /// multi-action case doesn't fight itself (the old `_spinController(bool)`
  /// helper toggled start/stop per icon and the second action would reset
  /// the controller while the first was still spinning).
  void _syncSpinner(bool shouldSpin) {
    if (shouldSpin && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!shouldSpin && _spinCtrl.isAnimating) {
      _spinCtrl.stop();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }
}