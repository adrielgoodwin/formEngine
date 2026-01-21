import 'package:flutter/foundation.dart';
import 'log_level.dart';

/// Interface for log output destinations.
abstract class LogSink {
  void write(LogLevel level, String category, String message, {Object? error, StackTrace? stackTrace});
  void dispose() {}
}

/// Outputs logs to the console via debugPrint (debug mode only).
class ConsoleLogSink implements LogSink {
  @override
  void write(LogLevel level, String category, String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final line = '[$timestamp] [${level.label}] [$category] $message';
    debugPrint(line);

    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('  StackTrace:\n$stackTrace');
    }
  }

  @override
  void dispose() {}
}
