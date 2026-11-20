import 'package:flutter/material.dart';

class TimelineEvent {
  final int timestamp;
  final String type;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  TimelineEvent({
    required this.timestamp,
    required this.type,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
