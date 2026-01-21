import 'dart:convert';
import 'dart:io';

import '../logging/app_logger.dart';
import '../logging/log_level.dart';
import '../models/case_record.dart';
import '../models/form_definition.dart';
import '../models/form_instance.dart';
import 'case_repository.dart';

class FileLockException implements Exception {
  final String message;
  final String filePath;

  FileLockException(this.message, this.filePath);

  @override
  String toString() => 'FileLockException: $message (file: $filePath)';
}

class CaseDirectoryNotFoundException implements Exception {
  final String directoryPath;

  CaseDirectoryNotFoundException(this.directoryPath);

  @override
  String toString() =>
      'CaseDirectoryNotFoundException: Directory does not exist: $directoryPath';
}

class FileCaseRepository extends CaseRepository {
  static const String _defaultBasePath = r'C:\ProgramData\YourApp\cases';

  final String _basePath;
  final AppLogger _logger = AppLogger.instance;

  FileCaseRepository({String? basePath}) : _basePath = basePath ?? _defaultBasePath {
    final dir = Directory(_basePath);
    final exists = dir.existsSync();
    _safeLog(
      LogLevel.info,
      'repo',
      'FileCaseRepository init basePath=$_basePath exists=$exists',
    );

    if (!exists) {
      _safeLog(
        LogLevel.error,
        'repo',
        'Case directory missing at $_basePath',
      );
      throw CaseDirectoryNotFoundException(_basePath);
    }
  }

  String _filePathForId(String id) => '$_basePath\\$id.json';
  String _tempFilePathForId(String id) => '$_basePath\\$id.json.tmp';
  String _lockFilePathForId(String id) => '$_basePath\\$id.lock';

  @override
  List<CaseRecord> getAll({bool includeArchived = false}) {
    final dir = Directory(_basePath);
    final List<CaseRecord> results = [];

    int totalFiles = 0;
    int parsedOk = 0;
    int malformed = 0;

    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.json') && !entity.path.endsWith('.tmp')) {
        totalFiles++;
        try {
          final content = entity.readAsStringSync();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final record = CaseRecord.fromJson(json);
          if (includeArchived || !record.isArchived) {
            results.add(record);
          }
          parsedOk++;
        } catch (e, st) {
          malformed++;
          final filename = entity.uri.pathSegments.last;
          _safeLog(
            LogLevel.warn,
            'repo',
            'Skipped malformed case file $filename: ${e.runtimeType}',
            error: e,
            stackTrace: st,
          );
        }
      }
    }

    _safeLog(
      LogLevel.info,
      'repo',
      'Loaded cases: totalFiles=$totalFiles parsedOk=$parsedOk malformed=$malformed includeArchived=$includeArchived',
    );

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  @override
  CaseRecord? getById(String id) {
    final file = File(_filePathForId(id));
    if (!file.existsSync()) {
      _safeLog(LogLevel.info, 'repo', 'Case miss id=$id');
      return null;
    }

    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final record = CaseRecord.fromJson(json);
      _safeLog(LogLevel.info, 'repo', 'Case hit id=$id');
      return record;
    } catch (e, st) {
      _safeLog(
        LogLevel.warn,
        'repo',
        'Failed to parse case file for id=$id: ${e.runtimeType}',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  CaseRecord createNew(FormDefinition def) {
    final instance = FormInstance.emptyFromDefinition(def);
    final record = CaseRecord.create(
      definitionId: def.id,
      schemaVersion: def.schemaVersion,
      formInstance: instance,
    );

    _writeRecordWithLock(record);
    _safeLog(
      LogLevel.info,
      'repo',
      'Created case id=${record.id} updatedAt=${record.updatedAt.toUtc().toIso8601String()}',
    );
    notifyListeners();
    return record;
  }

  @override
  void update(CaseRecord record) {
    record.touch();
    _writeRecordWithLock(record);
    _safeLog(
      LogLevel.info,
      'repo',
      'Updated case id=${record.id} updatedAt=${record.updatedAt.toUtc().toIso8601String()}',
    );
    notifyListeners();
  }

  @override
  void archive(String id, bool archived) {
    final record = getById(id);
    if (record != null) {
      record.isArchived = archived;
      record.touch();
      _writeRecordWithLock(record);
      _safeLog(
        LogLevel.info,
        'repo',
        'Archived state change for id=$id archived=$archived updatedAt=${record.updatedAt.toUtc().toIso8601String()}',
      );
      notifyListeners();
    }
  }

  void _writeRecordWithLock(CaseRecord record) {
    final id = record.id;
    final lockFile = File(_lockFilePathForId(id));
    final tempFile = File(_tempFilePathForId(id));
    final targetFile = File(_filePathForId(id));

    RandomAccessFile? lockHandle;
    bool lockAcquired = false;

    try {
      // Acquire exclusive lock via lock file
      lockHandle = lockFile.openSync(mode: FileMode.write);
      try {
        lockHandle.lockSync(FileLock.exclusive);
        lockAcquired = true;
      } catch (e) {
        lockHandle.closeSync();
        _safeLog(
          LogLevel.warn,
          'lock',
          'Lock contention for case $id: ${e.runtimeType}',
          error: e,
        );
        throw FileLockException(
          'Failed to acquire exclusive lock for case $id',
          lockFile.path,
        );
      }

      _safeLog(LogLevel.debug, 'lock', 'Lock acquired for case $id');

      // Write to temp file
      final jsonContent = jsonEncode(record.toJson());
      tempFile.writeAsStringSync(jsonContent, flush: true);
      _safeLog(LogLevel.debug, 'io', 'Temp write success for case $id');

      // Atomic rename: temp -> target
      if (targetFile.existsSync()) {
        targetFile.deleteSync();
      }
      tempFile.renameSync(targetFile.path);
      _safeLog(LogLevel.info, 'io', 'Persisted case $id');
    } finally {
      // Release lock
      if (lockHandle != null) {
        try {
          lockHandle.unlockSync();
        } catch (_) {}
        lockHandle.closeSync();
      }

      if (lockAcquired) {
        _safeLog(LogLevel.debug, 'lock', 'Lock released for case $id');
      }

      // Clean up lock file
      try {
        if (lockFile.existsSync()) {
          lockFile.deleteSync();
        }
      } catch (_) {}
    }
    // Note: Any exception thrown above will propagate; logging is best-effort only
  }

  void _safeLog(
    LogLevel level,
    String category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      switch (level) {
        case LogLevel.debug:
          _logger.debug(category, message, error: error, stackTrace: stackTrace);
          break;
        case LogLevel.info:
          _logger.info(category, message, error: error, stackTrace: stackTrace);
          break;
        case LogLevel.warn:
          _logger.warn(category, message, error: error, stackTrace: stackTrace);
          break;
        case LogLevel.error:
          _logger.error(category, message, error: error, stackTrace: stackTrace);
          break;
      }
    } catch (_) {
      // Logging must never throw
    }
  }
}
