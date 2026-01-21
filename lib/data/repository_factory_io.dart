import 'dart:io';

import 'case_repository.dart';
import 'file_case_repository.dart';

/// Creates FileCaseRepository on Windows, InMemoryCaseRepository otherwise.
CaseRepository createPlatformRepository() {
  if (Platform.isWindows) {
    return FileCaseRepository();
  }
  return InMemoryCaseRepository();
}
