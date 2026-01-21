import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'log_level.dart';
import 'log_paths.dart';
import 'log_sink.dart';

/// Writes logs to daily-rotated files on Windows.
/// Falls back to no-op on unsupported platforms or if directory creation fails.
class FileLogSink implements LogSink {
  static const int _retentionDays = 14;
  static const int _flushThreshold = 20;
  static const Duration _flushInterval = Duration(seconds: 5);

  final String? _baseDir;
  IOSink? _currentSink;
  String? _currentFilename;
  bool _initialized = false;
  bool _disabled = false;
  bool _disposed = false;
  bool _warnedInitFailure = false;
  int _linesSinceFlush = 0;
  Timer? _flushTimer;

  FileLogSink() : _baseDir = _getBaseDir();

  static String? _getBaseDir() {
    if (kIsWeb) return null;
    // Only enable file logging on Windows
    if (!Platform.isWindows) return null;
    return LogPaths.getLogDirectory();
  }

  @override
  void write(LogLevel level, String category, String message, {Object? error, StackTrace? stackTrace}) {
    if (_disposed || _disabled || _baseDir == null) return;

    _ensureInitialized();
    if (_disabled) return;

    final sink = _getSinkForToday();
    if (sink == null) return;

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final line = '[$timestamp] [${level.label}] [$category] $message';
    sink.writeln(line);
    _linesSinceFlush++;

    if (error != null) {
      sink.writeln('  Error: $error');
      _linesSinceFlush++;
    }
    if (stackTrace != null) {
      sink.writeln('  StackTrace:\n$stackTrace');
      _linesSinceFlush++;
    }

    // Flush immediately for warn/error, otherwise use buffered strategy
    if (level == LogLevel.warn || level == LogLevel.error) {
      _flush();
    } else if (_linesSinceFlush >= _flushThreshold) {
      _flush();
    } else {
      _scheduleFlush();
    }
  }

  void _flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _currentSink?.flush();
    _linesSinceFlush = 0;
  }

  void _scheduleFlush() {
    if (_flushTimer != null) return;
    _flushTimer = Timer(_flushInterval, _flush);
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    try {
      final dir = Directory(_baseDir!);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      _rotateOldLogs();
    } catch (e) {
      _disableWithWarning('Failed to initialize log directory: $e');
    }
  }

  void _disableWithWarning(String reason) {
    if (_warnedInitFailure) return;
    _warnedInitFailure = true;
    _disabled = true;
    debugPrint('[AppLogger] File logging disabled: $reason');
  }

  IOSink? _getSinkForToday() {
    final today = DateTime.now();
    final filename = LogPaths.filenameForDate(today);

    if (_currentFilename == filename && _currentSink != null) {
      return _currentSink;
    }

    // Close previous sink if switching days
    _currentSink?.flush();
    _currentSink?.close();
    _currentSink = null;
    _currentFilename = null;

    try {
      final filePath = '$_baseDir${Platform.pathSeparator}$filename';
      final file = File(filePath);
      _currentSink = file.openWrite(mode: FileMode.append);
      _currentFilename = filename;
      return _currentSink;
    } catch (e) {
      _disableWithWarning('Failed to open log file: $e');
      return null;
    }
  }

  void _rotateOldLogs() {
    try {
      final dir = Directory(_baseDir!);
      if (!dir.existsSync()) return;

      final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));

      for (final entity in dir.listSync()) {
        if (entity is! File) continue;

        final filename = entity.uri.pathSegments.last;
        final fileDate = LogPaths.parseDateFromFilename(filename);
        if (fileDate == null) continue;

        if (fileDate.isBefore(cutoff)) {
          try {
            entity.deleteSync();
          } catch (_) {
            // Ignore deletion failures
          }
        }
      }
    } catch (_) {
      // Ignore rotation failures
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    try {
      _currentSink?.flush();
      _currentSink?.close();
    } catch (_) {}
    _currentSink = null;
    _currentFilename = null;
  }
}
