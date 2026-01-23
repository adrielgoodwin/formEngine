import 'package:flutter/material.dart';
import 'layout_item.dart';

/// Border styling for form blocks
enum BlockBorderStyle {
  none,
  leftHeavy,
  allLight,
  leftHeavyAllLight,
}

/// Color scheme for form blocks
enum BlockColorScheme {
  none,
  deceased,    // Red
  executor,    // Orange  
  professional, // Yellow
  receive,     // Blue
  asset,       // Green
  documents,   // Purple
}

class FormBlock {
  final String id;
  final String title;
  final String description;
  final LayoutItem layout;
  final BlockBorderStyle borderStyle;
  final BlockColorScheme colorScheme;

  FormBlock({
    required this.id,
    required this.title,
    required this.layout,
    this.description = "",
    this.borderStyle = BlockBorderStyle.none,
    this.colorScheme = BlockColorScheme.none,
  });

  /// Gets the primary color for this block's color scheme
  Color getPrimaryColor() {
    switch (colorScheme) {
      case BlockColorScheme.deceased:
        return const Color(0xFFE53935); // Red
      case BlockColorScheme.executor:
        return const Color(0xFFFF9800); // Orange
      case BlockColorScheme.professional:
        return const Color(0xFFFDD835); // Yellow
      case BlockColorScheme.receive:
        return const Color(0xFF2196F3); // Blue
      case BlockColorScheme.asset:
        return const Color(0xFF4CAF50); // Green
      case BlockColorScheme.documents:
        return const Color(0xFF9C27B0); // Purple
      case BlockColorScheme.none:
        return Colors.transparent;
    }
  }

  /// Gets the light color for borders
  Color getLightColor() {
    final primary = getPrimaryColor();
    if (primary == Colors.transparent) return Colors.transparent;
    return primary.withOpacity(0.3);
  }
}


