import 'package:flutter/foundation.dart';

/// Layout mode for the form editor - determines how many columns are displayed.
/// This explicitly overrides automatic responsiveness.
enum LayoutMode {
  oneColumn,
  twoColumn,
  threeColumn,
}

extension LayoutModeExtension on LayoutMode {
  int get columnCount {
    switch (this) {
      case LayoutMode.oneColumn:
        return 1;
      case LayoutMode.twoColumn:
        return 2;
      case LayoutMode.threeColumn:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case LayoutMode.oneColumn:
        return '1 Column';
      case LayoutMode.twoColumn:
        return '2 Columns';
      case LayoutMode.threeColumn:
        return '3 Columns';
    }
  }
}

/// Provider for user-selectable layout and color preferences.
/// 
/// This is a view-layer preference that does not affect form data or validation.
/// Designed to be easily persistable (e.g., to SharedPreferences) in the future.
class LayoutPreferences extends ChangeNotifier {
  LayoutMode _layoutMode = LayoutMode.oneColumn;
  bool _showBackgroundColors = false;

  /// Current layout mode (1, 2, or 3 columns)
  LayoutMode get layoutMode => _layoutMode;

  /// Whether section blocks should show their background fill colors.
  /// When false, only borders remain colored.
  bool get showBackgroundColors => _showBackgroundColors;

  /// Sets the layout mode and notifies listeners.
  void setLayoutMode(LayoutMode mode) {
    if (_layoutMode != mode) {
      _layoutMode = mode;
      notifyListeners();
    }
  }

  /// Toggles background color visibility.
  void toggleBackgroundColors() {
    _showBackgroundColors = !_showBackgroundColors;
    notifyListeners();
  }

  /// Sets background color visibility explicitly.
  void setShowBackgroundColors(bool show) {
    if (_showBackgroundColors != show) {
      _showBackgroundColors = show;
      notifyListeners();
    }
  }

  /// Serializes preferences to a map for future persistence.
  Map<String, dynamic> toJson() => {
        'layoutMode': _layoutMode.index,
        'showBackgroundColors': _showBackgroundColors,
      };

  /// Restores preferences from a map (for future persistence).
  void fromJson(Map<String, dynamic> json) {
    final modeIndex = json['layoutMode'] as int?;
    if (modeIndex != null && modeIndex >= 0 && modeIndex < LayoutMode.values.length) {
      _layoutMode = LayoutMode.values[modeIndex];
    }
    final showColors = json['showBackgroundColors'] as bool?;
    if (showColors != null) {
      _showBackgroundColors = showColors;
    }
    notifyListeners();
  }
}
