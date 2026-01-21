import 'case_repository.dart';

// Conditional import: uses _io version on non-web, _web on web
import 'repository_factory_stub.dart'
    if (dart.library.io) 'repository_factory_io.dart';

/// Creates the appropriate CaseRepository for the current platform.
CaseRepository createRepository() => createPlatformRepository();
