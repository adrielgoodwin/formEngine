import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';
import '../logging/log_paths.dart';

/// Helper utilities for log file operations (open folder, copy logs).
class LogHelper {
  /// Opens the log directory in Windows Explorer.
  /// Returns true if successful, false otherwise.
  /// Only works on Windows; returns false on other platforms.
  static Future<bool> openLogFolder() async {
    if (kIsWeb) return false;
    
    try {
      if (!Platform.isWindows) return false;

      final logDir = LogPaths.getLogDirectory();
      if (logDir == null) {
        _safeLog('Failed to get log directory path');
        return false;
      }

      final dir = Directory(logDir);
      if (!dir.existsSync()) {
        _safeLog('Log directory does not exist');
        return false;
      }

      // Use explorer.exe to open the folder
      final result = await Process.run('explorer', [logDir]);
      if (result.exitCode != 0) {
        _safeLog('Failed to open log folder: exit code ${result.exitCode}');
      }
      return result.exitCode == 0;
    } catch (e) {
      _safeLog('Exception opening log folder: ${e.runtimeType}');
      return false;
    }
  }

  /// Reads the last ~200 lines from today's log file and returns as a string.
  /// Returns null if log file doesn't exist or can't be read.
  /// Limits memory usage by reading only the last 128KB of the file.
  static Future<String?> getRecentLogs() async {
    if (kIsWeb) return null;

    const int maxBytes = 128 * 1024; // 128KB
    const int maxLines = 200;

    try {
      final logDir = LogPaths.getLogDirectory();
      if (logDir == null) {
        _safeLog('Failed to get log directory path for copy');
        return null;
      }

      final today = DateTime.now();
      final filename = LogPaths.filenameForDate(today);
      final logFile = File('$logDir${Platform.pathSeparator}$filename');

      if (!logFile.existsSync()) {
        _safeLog('Log file does not exist: $filename');
        return null;
      }

      final fileSize = await logFile.length();
      String content;

      if (fileSize <= maxBytes) {
        // File is small enough, read it all
        content = await logFile.readAsString();
      } else {
        // File is large, read only the last maxBytes
        final raf = await logFile.open(mode: FileMode.read);
        try {
          await raf.setPosition(fileSize - maxBytes);
          final bytes = await raf.read(maxBytes);
          content = String.fromCharCodes(bytes);
          // Skip partial first line
          final firstNewline = content.indexOf('\n');
          if (firstNewline != -1) {
            content = content.substring(firstNewline + 1);
          }
        } finally {
          await raf.close();
        }
      }

      final lines = content.split('\n');
      final recentLines = lines.length > maxLines
          ? lines.sublist(lines.length - maxLines)
          : lines;

      return recentLines.join('\n');
    } catch (e) {
      _safeLog('Exception reading log file: ${e.runtimeType}');
      return null;
    }
  }

  /// Copies the provided text to the system clipboard.
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Returns true if log folder operations are supported on this platform.
  static bool get canOpenLogFolder {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if log copying is supported on this platform.
  static bool get canCopyLogs {
    if (kIsWeb) return false;
    // No Platform access needed for copy operation
    return true;
  }

  static void _safeLog(String message) {
    try {
      AppLogger.instance.warn('log_helper', message);
    } catch (_) {
      // Logging must never throw
    }
  }
}
