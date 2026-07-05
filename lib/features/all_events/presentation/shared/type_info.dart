import 'package:flutter/material.dart';

/// Per-event-type metadata used by both the event row badge and the
/// filter chip (so they stay visually in sync). Color drives the badge
/// background, icon, and the chip's active state.
class TypeInfo {
  final Color color;
  final IconData icon;
  final String label;
  const TypeInfo({required this.color, required this.icon, required this.label});
}