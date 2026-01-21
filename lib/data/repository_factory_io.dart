import 'dart:io';

import 'case_repository.dart';
import 'file_case_repository.dart';

/// Creates FileCaseRepository on Windows, InMemoryCaseRepository otherwise.
/// This is an async wrapper that ensures directory creation.
Future<CaseRepository> createPlatformRepository() async {
  if (Platform.isWindows) {
    return await FileCaseRepository.create();
  }
  return InMemoryCaseRepository();
}
