// Shared exception types for repository operations.
// These exceptions are decoupled from specific repository implementations.

/// Thrown when a file lock cannot be acquired for a case record.
class FileLockException implements Exception {
  final String message;
  final String? filePath;

  FileLockException(this.message, [this.filePath]);

  @override
  String toString() => filePath != null
      ? 'FileLockException: $message (file: $filePath)'
      : 'FileLockException: $message';
}

/// Thrown when the case directory does not exist.
class CaseDirectoryNotFoundException implements Exception {
  final String directoryPath;

  CaseDirectoryNotFoundException(this.directoryPath);

  @override
  String toString() =>
      'CaseDirectoryNotFoundException: Directory does not exist: $directoryPath';
}
