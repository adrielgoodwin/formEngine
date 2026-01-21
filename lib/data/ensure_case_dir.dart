import 'dart:io';
import 'package:path/path.dart' as p;

/// Debug utility to verify case directory exists after initialization.
/// Can be called from main() or tests to sanity-check directory setup.
Future<void> ensureCaseDir(String basePath) async {
  final dir = Directory(basePath);
  if (!dir.existsSync()) {
    throw StateError(
      'Case directory does not exist after initialization: $basePath',
    );
  }

  // Verify we can write to it
  final testFile = File(p.join(basePath, '.write_test'));
  try {
    await testFile.writeAsString('test');
    await testFile.delete();
  } catch (e) {
    throw StateError(
      'Case directory exists but is not writable: $basePath. Error: $e',
    );
  }
}
