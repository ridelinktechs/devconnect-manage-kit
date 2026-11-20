import 'package:flutter/material.dart';

/// The blue that marks a picked table, row or cell, the way desktop
/// database clients mark a selection.
Color dbSelection(bool isDark) =>
    isDark ? const Color(0xFF388BFD) : const Color(0xFF0969DA);

/// The gold of a primary-key glyph.
const dbKeyGold = Color(0xFFD29922);
