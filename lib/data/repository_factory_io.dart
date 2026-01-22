import 'dart:io';

import 'case_repository.dart';
import 'file_case_repository.dart';

/// Creates FileCaseRepository on Windows, InMemoryCaseRepository otherwise.
/// This is an async wrapper that ensures directory creation AND cache initialization.
/// IMPORTANT: Cache is initialized here so getAll() never hits disk.
Future<CaseRepository> createPlatformRepository() async {
  if (Platform.isWindows) {
    final repo = await FileCaseRepository.create();
    // Initialize cache asynchronously at startup - getAll() will never block
    await repo.refreshCache();
    return repo;
  }
  return InMemoryCaseRepository();
}
