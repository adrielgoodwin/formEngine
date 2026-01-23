import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';
import '../logging/log_level.dart';
import '../models/case_record.dart';
import '../models/form_definition.dart';
import '../models/form_instance.dart';
import 'case_repository.dart';
import 'repository_exceptions.dart';

/// Result of directory creation attempt
class _DirectoryResult {
  final bool success;
  final String path;
  final String? error;

  _DirectoryResult({required this.success, required this.path, this.error});
}

class FileCaseRepository extends CaseRepository {
  final String _basePath;
  final AppLogger _logger = AppLogger.instance;
  
  // In-memory cache to avoid repeated disk scans
  List<CaseRecord>? _cachedCases;
  bool _cacheInitialized = false;

  FileCaseRepository._internal(this._basePath) {
    _safeLog(
      LogLevel.info,
      'repo',
      'FileCaseRepository initialized with basePath=$_basePath',
    );
  }

  /// Factory constructor that ensures the directory exists or creates it.
  /// Falls back to user-local directory if primary path fails.
  static Future<FileCaseRepository> create({String? basePath}) async {
    final primaryPath = basePath ?? r'C:\ProgramData\YourApp\cases';
    
    // Try primary path first
    final result = await _ensureDirectoryExists(primaryPath);
    if (result.success) {
      return FileCaseRepository._internal(result.path);
    }

    // Fallback to user-local directory
    final fallbackPath = await _getFallbackPath();
    final fallbackResult = await _ensureDirectoryExists(fallbackPath);
    
    if (fallbackResult.success) {
      AppLogger.instance.warn(
        'repo',
        'Using fallback directory: $fallbackPath (primary failed: ${result.error})',
      );
      return FileCaseRepository._internal(fallbackResult.path);
    }

    // Both failed - throw descriptive exception
    throw CaseDirectoryNotFoundException(
      'Failed to create case directory. '
      'Primary path "$primaryPath" failed: ${result.error}. '
      'Fallback path "$fallbackPath" failed: ${fallbackResult.error}',
    );
  }

  /// Synchronous constructor for testing or when directory is guaranteed to exist.
  factory FileCaseRepository({String? basePath}) {
    final path = basePath ?? r'C:\ProgramData\YourApp\cases';
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw CaseDirectoryNotFoundException(
        'Directory does not exist: $path. Use FileCaseRepository.create() instead.',
      );
    }
    return FileCaseRepository._internal(path);
  }

  static Future<_DirectoryResult> _ensureDirectoryExists(String path) async {
    try {
      final dir = Directory(path);
      final exists = dir.existsSync();
      
      AppLogger.instance.info(
        'repo',
        'Checking directory: path=$path exists=$exists',
      );

      if (!exists) {
        AppLogger.instance.info(
          'repo',
          'Creating directory recursively: $path',
        );
        await dir.create(recursive: true);
        AppLogger.instance.info(
          'repo',
          'Directory created successfully: $path',
        );
      }

      return _DirectoryResult(success: true, path: path);
    } catch (e, st) {
      AppLogger.instance.error(
        'repo',
        'Failed to create directory: $path',
        error: e,
        stackTrace: st,
      );
      return _DirectoryResult(success: false, path: path, error: e.toString());
    }
  }

  static Future<String> _getFallbackPath() async {
    try {
      // Use getApplicationSupportDirectory for cross-platform support
      final appSupportDir = await getApplicationSupportDirectory();
      final fallbackPath = p.join(appSupportDir.path, 'YourApp', 'cases');
      
      AppLogger.instance.info(
        'repo',
        'Computed fallback path: $fallbackPath',
      );
      
      return fallbackPath;
    } catch (e) {
      // Ultimate fallback if path_provider fails
      final homePath = Platform.environment['USERPROFILE'] ?? 
                       Platform.environment['HOME'] ?? 
                       Platform.environment['LOCALAPPDATA'] ?? 
                       'C:\\temp';
      final fallbackPath = p.join(homePath, 'YourApp', 'cases');
      
      AppLogger.instance.warn(
        'repo',
        'path_provider failed, using environment-based fallback: $fallbackPath',
        error: e,
      );
      
      return fallbackPath;
    }
  }

  String _filePathForId(String id) => p.join(_basePath, '$id.json');
  String _tempFilePathForId(String id) => p.join(_basePath, '$id.json.tmp');
  String _lockFilePathForId(String id) => p.join(_basePath, '$id.lock');

  /// Whether the cache has been initialized via refreshCache().
  bool get isCacheInitialized => _cacheInitialized;

  @override
  List<CaseRecord> getAll({bool includeArchived = false}) {
    // IMPORTANT: getAll() NEVER performs disk IO.
    // Cache must be initialized at startup via refreshCache().
    // If cache is not initialized, return empty list (fail-safe).
    if (!_cacheInitialized || _cachedCases == null) {
      _safeLog(
        LogLevel.warn,
        'repo',
        'getAll called before cache initialized - returning empty list',
      );
      return const [];
    }

    // Return unmodifiable copy filtered by archive status
    if (includeArchived) {
      return List.unmodifiable(_cachedCases!);
    }
    return List.unmodifiable(_cachedCases!.where((c) => !c.isArchived));
  }

  /// Refreshes the cache by scanning the directory asynchronously.
  /// Use this for explicit refresh or recovery scenarios.
  Future<void> refreshCache() async {
    _logger.info('repo', 'Refreshing cache from disk');
    final dir = Directory(_basePath);
    final List<CaseRecord> results = [];

    int totalFiles = 0;
    int parsedOk = 0;
    int malformed = 0;

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json') && !entity.path.endsWith('.tmp')) {
        totalFiles++;
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final record = CaseRecord.fromJson(json);
          results.add(record);
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
      'Cache refreshed: totalFiles=$totalFiles parsedOk=$parsedOk malformed=$malformed',
    );

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _cachedCases = results;
    _cacheInitialized = true;
    notifyListeners();
  }

  @override
  CaseRecord? getById(String id) {
    // CACHE-FIRST: Check cache before disk to avoid sync IO
    if (_cacheInitialized && _cachedCases != null) {
      for (final c in _cachedCases!) {
        if (c.id == id) {
          _safeLog(LogLevel.debug, 'repo', 'Cache hit for id=$id');
          return c;
        }
      }
      // Cache initialized but ID not found - it doesn't exist
      _safeLog(LogLevel.debug, 'repo', 'Cache miss for id=$id (not on disk)');
      return null;
    }

    // Fallback to disk only if cache not initialized (rare recovery path)
    _safeLog(LogLevel.warn, 'repo', 'getById disk fallback for id=$id (cache not initialized)');
    final file = File(_filePathForId(id));
    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final record = CaseRecord.fromJson(json);
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
    
    // Update cache: remove any existing entry (prevent duplicates), insert at front
    if (_cacheInitialized && _cachedCases != null) {
      _cachedCases!.removeWhere((c) => c.id == record.id);
      _cachedCases!.insert(0, record);
    }
    
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
    
    // Update cache: remove old entry, add updated record, re-sort
    if (_cacheInitialized && _cachedCases != null) {
      _cachedCases!.removeWhere((c) => c.id == record.id);
      _cachedCases!.add(record);
      _cachedCases!.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    
    notifyListeners();
  }

  @override
  void archive(String id, bool archived) {
    // Use cache-first lookup (getById checks cache first)
    final record = getById(id);
    if (record == null) {
      _safeLog(LogLevel.warn, 'repo', 'Archive failed: case not found id=$id');
      return;
    }
    
    record.isArchived = archived;
    record.touch();
    _writeRecordWithLock(record);
    _safeLog(
      LogLevel.info,
      'repo',
      'Archived state change for id=$id archived=$archived',
    );
    
    // Update cache: remove old entry, add updated record, re-sort
    if (_cacheInitialized && _cachedCases != null) {
      _cachedCases!.removeWhere((c) => c.id == id);
      _cachedCases!.add(record);
      _cachedCases!.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    
    notifyListeners();
  }

  @override
  void delete(String id) {
    // Use cache-first lookup (getById checks cache first)
    final record = getById(id);
    if (record == null) {
      _safeLog(LogLevel.warn, 'repo', 'Delete failed: case not found id=$id');
      return;
    }
    
    // Delete the case file
    try {
      final caseFile = File(_filePathForId(id));
      if (caseFile.existsSync()) {
        caseFile.deleteSync();
        _safeLog(LogLevel.info, 'repo', 'Deleted case file for id=$id');
      }
      
      // Remove from cache
      if (_cacheInitialized && _cachedCases != null) {
        _cachedCases!.removeWhere((c) => c.id == id);
      }
      
      notifyListeners();
      _safeLog(LogLevel.info, 'repo', 'Case deleted successfully id=$id');
    } catch (e, st) {
      _safeLog(LogLevel.error, 'repo', 'Failed to delete case file id=$id', error: e, stackTrace: st);
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
