import 'dart:io';

import '../config/config_manager.dart';

/// Helper for determining log file paths.
class LogPaths {
  /// Returns the base log directory for the current platform.
  /// Returns null if file logging is not supported on this platform.
  static String? getLogDirectory() {
    if (Platform.isWindows) {
      return ConfigManager.logPath;
    }
    // Mac/Linux: could add ~/Library/Logs or ~/.local/share, but disabled for now
    return null;
  }

  /// Generates a log filename for the given date.
  static String filenameForDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'app_$year-$month-$day.log';
  }

  /// Parses a date from a log filename, or returns null if not matching pattern.
  static DateTime? parseDateFromFilename(String filename) {
    final regex = RegExp(r'^app_(\d{4})-(\d{2})-(\d{2})\.log$');
    final match = regex.firstMatch(filename);
    if (match == null) return null;

    try {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}
