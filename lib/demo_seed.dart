import 'data/case_repository.dart';
import 'data/repository_exceptions.dart';
import 'logging/app_logger.dart';
import 'models/form_definition.dart';
import 'models/form_instance.dart';
import 'models/group_instance.dart';

/// Seeds demo cases if the repository is empty (or if force=true).
/// Works with both InMemoryCaseRepository and FileCaseRepository.
/// Does NOT delete existing cases when force=true.
Future<void> seedDemoCasesIfEmpty(
  FormDefinition def,
  CaseRepository repo, {
  bool force = false,
}) async {
  final existingCases = repo.getAll(includeArchived: true);
  if (!force && existingCases.isNotEmpty) {
    _safeLog('Skipping seed: repo already has ${existingCases.length} cases');
    return;
  }

  _safeLog('Starting demo seed (force=$force, existing=${existingCases.length})');
  await _seedAllDemoCases(def, repo);
  _safeLog('Demo seed complete');
}

Future<void> _seedAllDemoCases(FormDefinition def, CaseRepository repo) async {
  // Production mode - no demo data seeding
  _safeLog('Demo data seeding disabled for production');
}

/// Seeds a single case through the repository interface.
/// Handles FileLockException and SeedDataException gracefully by logging and continuing.
Future<void> _seedCase({
  required FormDefinition def,
  required CaseRepository repo,
  required String title,
  required void Function(FormInstance instance) populate,
  bool archived = false,
}) async {
  final caseIndex = _seedIndex++;
  try {
    // TODO: createNew may persist immediately in some repos; consider lazy-create pattern
    // to avoid redundant writes. For now, we accept create + update as two writes.
    final record = repo.createNew(def);
    record.title = title;
    
    // Populate form values
    populate(record.formInstance);
    
    // Persist the populated case (single update after population)
    repo.update(record);
    
    // Archive if needed
    if (archived) {
      repo.archive(record.id, true);
    }
    
    _safeLogDebug('Seeded case #$caseIndex id=${record.id} template=${def.id} archived=$archived');
  } on _SeedDataException catch (e) {
    _safeLogWarn('Seed data error for case #$caseIndex: ${e.message}');
  } on FileLockException catch (e) {
    _safeLogWarn('Lock contention seeding case #$caseIndex: ${e.message}');
  } catch (e) {
    _safeLogWarn('Failed to seed case #$caseIndex: ${e.runtimeType}');
  }
}

/// Counter for seeded cases (avoids logging titles which may be sensitive)
int _seedIndex = 0;

/// Exception thrown when seed data operations fail (e.g., group instance creation).
class _SeedDataException implements Exception {
  final String message;
  _SeedDataException(this.message);
  @override
  String toString() => 'SeedDataException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// Group Instance Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the first existing group instance, or creates one if none exist.
/// Works regardless of addGroupInstance return type.
/// Throws _SeedDataException if creation fails.
GroupInstance _ensureGroupInstance(FormInstance instance, String groupId) {
  final existing = instance.getGroupInstances(groupId);
  if (existing.isNotEmpty) {
    return existing.first;
  }
  instance.addGroupInstance(groupId);
  final afterAdd = instance.getGroupInstances(groupId);
  if (afterAdd.isEmpty) {
    final msg = 'Failed to create group instance for groupId=$groupId '
        '(possibly maxInstances constraint or missing group definition)';
    _safeLogWarn(msg);
    throw _SeedDataException(msg);
  }
  return afterAdd.first;
}

/// Adds a new group instance and returns it.
/// Works regardless of addGroupInstance return type.
/// Throws _SeedDataException if addition fails.
GroupInstance _addNewGroupInstance(FormInstance instance, String groupId) {
  final countBefore = instance.getGroupInstances(groupId).length;
  instance.addGroupInstance(groupId);
  final allInstances = instance.getGroupInstances(groupId);
  final countAfter = allInstances.length;
  
  if (countAfter <= countBefore) {
    final msg = 'Failed to add new group instance for groupId=$groupId '
        '(countBefore=$countBefore, countAfter=$countAfter)';
    _safeLogWarn(msg);
    throw _SeedDataException(msg);
  }
  
  // Return the newly added instance (last one)
  return allInstances.last;
}

// ─────────────────────────────────────────────────────────────────────────────
// Safe Logging Helpers
// ─────────────────────────────────────────────────────────────────────────────

void _safeLog(String message) {
  try {
    AppLogger.instance.info('seed', message);
  } catch (_) {
    // Logging must never throw
  }
}

void _safeLogDebug(String message) {
  try {
    AppLogger.instance.debug('seed', message);
  } catch (_) {
    // Logging must never throw
  }
}

void _safeLogWarn(String message) {
  try {
    AppLogger.instance.warn('seed', message);
  } catch (_) {
    // Logging must never throw
  }
}
