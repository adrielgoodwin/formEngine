import 'file_log_sink.dart';
import 'log_level.dart';
import 'log_sink.dart';

/// Central logging facility for the application.
///
/// Usage:
/// ```dart
/// // Get the singleton instance
/// final logger = AppLogger.instance;
///
/// // Log at various levels
/// logger.info('repo', 'Updated case id=abc123 updatedAt=2026-01-21T15:04:05Z');
/// logger.debug('form', 'Loaded definition schemaVersion=3');
/// logger.warn('persistence', 'Lock contention on case id=xyz');
/// logger.error('io', 'Failed to write file', error: e, stackTrace: stack);
///
/// // PRIVACY: Never log user-entered values like SIN, addresses, money amounts.
/// // Only log: event types, case IDs, group IDs, counts, schema versions, exceptions.
/// ```
class AppLogger {
  static AppLogger? _instance;

  final List<LogSink> _sinks;
  bool _disposed = false;

  /// Minimum log level. Messages below this level are ignored.
  LogLevel minLevel;

  AppLogger._({
    required List<LogSink> sinks,
    this.minLevel = LogLevel.info,
  }) : _sinks = sinks;

  /// Returns the singleton logger instance.
  /// Initializes with default sinks on first access.
  static AppLogger get instance {
    _instance ??= AppLogger._create();
    return _instance!;
  }

  /// Creates a logger with default sinks for the current platform.
  factory AppLogger._create() {
    final sinks = <LogSink>[
      ConsoleLogSink(),
      // FileLogSink internally checks for Windows; no-ops on other platforms
      FileLogSink(),
    ];

    // Check compile-time flag for debug logs
    const debugLogsEnabled = bool.fromEnvironment('FORMENGINE_DEBUG_LOGS', defaultValue: false);
    final minLevel = debugLogsEnabled ? LogLevel.debug : LogLevel.info;

    return AppLogger._(sinks: sinks, minLevel: minLevel);
  }

  /// Creates a logger with custom sinks (for testing or dependency injection).
  factory AppLogger.withSinks(List<LogSink> sinks, {LogLevel minLevel = LogLevel.info}) {
    return AppLogger._(sinks: sinks, minLevel: minLevel);
  }

  void debug(String category, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, category, message, error: error, stackTrace: stackTrace);
  }

  void info(String category, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, category, message, error: error, stackTrace: stackTrace);
  }

  void warn(String category, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warn, category, message, error: error, stackTrace: stackTrace);
  }

  void error(String category, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, category, message, error: error, stackTrace: stackTrace);
  }

  void _log(LogLevel level, String category, String message, {Object? error, StackTrace? stackTrace}) {
    if (_disposed) return;
    if (level.index < minLevel.index) return;

    for (final sink in _sinks) {
      try {
        sink.write(level, category, message, error: error, stackTrace: stackTrace);
      } catch (_) {
        // Silently ignore sink failures to prevent logging from crashing the app
      }
    }
  }

  /// Disposes all sinks. Call on app shutdown if needed.
  /// Safe to call multiple times.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final sink in _sinks) {
      try {
        sink.dispose();
      } catch (_) {}
    }
  }
}
