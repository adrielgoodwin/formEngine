import 'package:flutter/material.dart';

enum SortOption {
  alphabeticalAZ('A-Z', 'sort_by_alpha'),
  alphabeticalZA('Z-A', 'sort_by_alpha'),
  oldestCreated('Oldest', 'calendar_today'),
  newestCreated('Newest', 'calendar_today'),
  oldestUpdated('Not Recently Updated', 'update'),
  newestUpdated('Recently Updated', 'update');

  const SortOption(this.label, this.iconName);
  
  final String label;
  final String iconName;
  
  IconData get icon {
    switch (this) {
      case SortOption.alphabeticalAZ:
      case SortOption.alphabeticalZA:
        return Icons.sort_by_alpha;
      case SortOption.oldestCreated:
      case SortOption.newestCreated:
        return Icons.calendar_today;
      case SortOption.oldestUpdated:
      case SortOption.newestUpdated:
        return Icons.update;
    }
  }
}
