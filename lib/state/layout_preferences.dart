import 'package:flutter/foundation.dart';

/// Layout mode for the form editor - determines how many columns are displayed.
/// This explicitly overrides automatic responsiveness.
enum LayoutMode {
  oneColumn,
  twoColumn,
  threeColumn,
}

/// Spacing density for the form editor - controls vertical and horizontal gaps.
enum SpacingDensity {
  tight,
  normal,
  spacious,
}

extension SpacingDensityExtension on SpacingDensity {
  String get label {
    switch (this) {
      case SpacingDensity.tight:
        return 'Tight';
      case SpacingDensity.normal:
        return 'Normal';
      case SpacingDensity.spacious:
        return 'Spacious';
    }
  }
}

/// Centralized spacing metrics derived from SpacingDensity preference.
/// 
/// This provides a single source of truth for all spacing values in the form UI.
/// Layout orchestrators and section shells consume these tokens rather than
/// hardcoding spacing values, enabling global density changes without
/// scattering conditional logic across leaf widgets.
class DensityMetrics {
  /// Vertical margin between section blocks
  final double blockVerticalMargin;
  
  /// Horizontal margin around section blocks
  final double blockHorizontalMargin;
  
  /// Padding inside section block containers
  final double blockInternalPadding;
  
  /// Vertical gap between rows/fields inside a block
  final double rowGap;
  
  /// Horizontal gap between fields in a row
  final double fieldGap;
  
  /// Padding around the entire form scroll area
  final double formPadding;
  
  /// Divider vertical spacing (space above/below dividers)
  final double dividerVerticalSpacing;
  
  /// Header bottom padding (below block title)
  final double headerBottomPadding;

  const DensityMetrics({
    required this.blockVerticalMargin,
    required this.blockHorizontalMargin,
    required this.blockInternalPadding,
    required this.rowGap,
    required this.fieldGap,
    required this.formPadding,
    required this.dividerVerticalSpacing,
    required this.headerBottomPadding,
  });

  /// Creates metrics for the given density level.
  factory DensityMetrics.fromDensity(SpacingDensity density) {
    switch (density) {
      case SpacingDensity.tight:
        return const DensityMetrics(
          blockVerticalMargin: 2,
          blockHorizontalMargin: 1,
          blockInternalPadding: 2,
          rowGap: 1,
          fieldGap: 4,
          formPadding: 2,
          dividerVerticalSpacing: 1,
          headerBottomPadding: 2,
        );
      case SpacingDensity.normal:
        return const DensityMetrics(
          blockVerticalMargin: 4,
          blockHorizontalMargin: 2,
          blockInternalPadding: 4,
          rowGap: 2,
          fieldGap: 6,
          formPadding: 4,
          dividerVerticalSpacing: 2,
          headerBottomPadding: 4,
        );
      case SpacingDensity.spacious:
        return const DensityMetrics(
          blockVerticalMargin: 8,
          blockHorizontalMargin: 4,
          blockInternalPadding: 8,
          rowGap: 6,
          fieldGap: 10,
          formPadding: 8,
          dividerVerticalSpacing: 4,
          headerBottomPadding: 6,
        );
    }
  }
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
  SpacingDensity _spacingDensity = SpacingDensity.normal;

  /// Current layout mode (1, 2, or 3 columns)
  LayoutMode get layoutMode => _layoutMode;

  /// Whether section blocks should show their background fill colors.
  /// When false, only borders remain colored.
  bool get showBackgroundColors => _showBackgroundColors;

  /// Current spacing density (tight, normal, or spacious)
  SpacingDensity get spacingDensity => _spacingDensity;

  /// Computed density metrics based on current spacing density.
  /// Use this to access spacing tokens throughout the UI.
  DensityMetrics get densityMetrics => DensityMetrics.fromDensity(_spacingDensity);

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

  /// Sets the spacing density and notifies listeners.
  void setSpacingDensity(SpacingDensity density) {
    if (_spacingDensity != density) {
      _spacingDensity = density;
      notifyListeners();
    }
  }

  /// Serializes preferences to a map for future persistence.
  Map<String, dynamic> toJson() => {
        'layoutMode': _layoutMode.index,
        'showBackgroundColors': _showBackgroundColors,
        'spacingDensity': _spacingDensity.index,
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
    final densityIndex = json['spacingDensity'] as int?;
    if (densityIndex != null && densityIndex >= 0 && densityIndex < SpacingDensity.values.length) {
      _spacingDensity = SpacingDensity.values[densityIndex];
    }
    notifyListeners();
  }
}
