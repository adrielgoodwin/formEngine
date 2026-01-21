import 'case_repository.dart';

/// Stub for conditional import. Returns InMemoryCaseRepository.
Future<CaseRepository> createPlatformRepository() async => InMemoryCaseRepository();
