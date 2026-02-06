import 'package:flutter/material.dart';
import '../data/case_repository.dart';
import '../data/repository_exceptions.dart';
import '../controllers/form_controllers.dart';
import '../data/load_form.dart';
import '../logging/app_logger.dart';
import '../models/case_record.dart';
import '../models/form_definition.dart';
import '../models/form_instance.dart';
import '../models/assembler.dart';
import '../models/form_definition_validation.dart';

class FormStateProvider extends ChangeNotifier {
  final CaseRepository _repository;
  final AppLogger _logger = AppLogger.instance;
  bool _isDirty = false;

  AssembledForm? _assembledForm;
  FormDefinition? _formDefinition;
  FormInstance? _formInstance;
  FormControllers? _controllers;
  CaseRecord? _currentCase;
  bool _isLoading = true;

  FormStateProvider({required CaseRepository repository})
      : _repository = repository;

  /// Whether the form has unsaved changes.
  bool get isDirty => _isDirty;

  AssembledForm get assembledForm => _assembledForm!;
  FormDefinition get formDefinition => _formDefinition!;
  FormInstance? get formInstance => _formInstance;
  FormControllers get controllers => _controllers!;
  CaseRecord? get currentCase => _currentCase;
  bool get isLoading => _isLoading;

  /// Returns a controller for the given field (base or group scope).
  TextEditingController controllerFor({
    required String nodeId,
    String? groupId,
    String? instanceId,
  }) {
    return _controllers!.controllerFor(
      nodeId: nodeId,
      groupId: groupId,
      instanceId: instanceId,
    );
  }

  /// Returns the error for a given field key, or null if none.
  String? errorFor(FieldKey key) => _controllers?.errorFor(key);

  /// Sets or clears an error for a given field key.
  void setError(FieldKey key, String? error) {
    _controllers?.setError(key, error);
    notifyListeners();
  }

  void setNodeValue(String nodeId, dynamic value) {
    _formInstance!.setValue(nodeId, value);
    _markDirty();
    notifyListeners();
  }

  void addGroupInstance(String groupId) {
    final def = _formDefinition?.groups[groupId];
    if (def != null) {
      final current = _formInstance!.getGroupInstances(groupId).length;
      final max = def.maxInstances;
      if (max != null && current >= max) {
        return;
      }
    }
    _formInstance!.addGroupInstance(groupId);
    _markDirty();
    notifyListeners();
  }

  void setGroupNodeValue(String groupId, String instanceId, String nodeId, dynamic value) {
    _formInstance!.setGroupValue(groupId, instanceId, nodeId, value);
    _markDirty();
    notifyListeners();
  }

  void removeGroupInstance(String groupId, String instanceId) {
    final def = _formDefinition?.groups[groupId];
    if (def != null) {
      final current = _formInstance!.getGroupInstances(groupId).length;
      if (current <= def.minInstances) {
        return;
      }
    }
    // Dispose controllers and clear errors for this instance before removing data
    _controllers?.removeControllersForGroupInstance(groupId, instanceId);
    _controllers?.clearErrorsForGroupInstance(groupId, instanceId);
    _formInstance!.removeGroupInstance(groupId, instanceId);
    _markDirty();
    notifyListeners();
  }

  void _markDirty() {
    if (!_isDirty) {
      _isDirty = true;
      _safeLog('state', 'Form marked dirty for case ${_currentCase?.id}');
    }
  }

  /// Explicitly saves the current case to the repository.
  /// Returns true on success, false on failure.
  bool saveNow() {
    final caseToSave = _currentCase;
    if (caseToSave == null) return false;

    // Derive title from deceased_name before saving
    _updateCaseTitleFromInstance();

    _safeLog('state', 'Explicit save for case ${caseToSave.id}');
    try {
      _repository.update(caseToSave);
      _isDirty = false;
      _safeLog('state', 'Save success for case ${caseToSave.id}');
      notifyListeners();
      return true;
    } catch (e, st) {
      if (e is FileLockException) {
        _safeLogWarn('state', 'Lock contention during save for case ${caseToSave.id}', error: e);
      } else {
        _safeLogError('state', 'Save failed for case ${caseToSave.id}', error: e, stackTrace: st);
      }
      return false;
    }
  }

  /// Discards unsaved changes by reloading the case from the repository.
  void discardChanges() {
    final caseToReload = _currentCase;
    if (caseToReload == null) return;

    _safeLog('state', 'Discarding changes for case ${caseToReload.id}');
    final fresh = _repository.getById(caseToReload.id);
    if (fresh != null) {
      _currentCase = fresh;
      _formInstance = fresh.formInstance;
      _controllers?.dispose();
      _controllers = FormControllers(formInstance: fresh.formInstance);
    }
    _isDirty = false;
    notifyListeners();
  }

  /// Updates the case title from the deceased_name field value.
  void _updateCaseTitleFromInstance() {
    final inst = _formInstance;
    final caseRecord = _currentCase;
    if (inst == null || caseRecord == null) return;
    final name = (inst.getValue<String>('deceased_name') ?? '').trim();
    if (name.isNotEmpty) {
      caseRecord.title = name;
    }
  }

  @override
  void dispose() {
    final caseId = _currentCase?.id;
    _safeLog('state', 'Dispose: case=${caseId ?? "none"} isDirty=$_isDirty');
    _controllers?.dispose();
    _controllers = null;
    super.dispose();
  }

  Future<FormDefinition> loadDefinition() async {
    _safeLog('state', 'loadDefinition start');
    try {
      final formDefinition = await loadFormDefinition();
      validateFormDefinition(formDefinition);
    
      final assembled = assembleForm(formDefinition);

      _assembledForm = assembled;
      _formDefinition = formDefinition;
      
      final nodeCount = formDefinition.nodes.length;
      final blockCount = formDefinition.blocks.length;
      final groupCount = formDefinition.groups.length;
      _safeLog(
        'state',
        'loadDefinition end: id=${formDefinition.id} schemaVersion=${formDefinition.schemaVersion} '
        'nodes=$nodeCount blocks=$blockCount groups=$groupCount',
      );
      
      return formDefinition;
    } catch (e, st) {
      _safeLogError('state', 'loadDefinition failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> loadCase(CaseRecord caseRecord) async {
    _safeLog(
      'state',
      'loadCase start: id=${caseRecord.id} schemaVersion=${caseRecord.schemaVersion} updatedAt=${caseRecord.updatedAt.toUtc().toIso8601String()}',
    );
    _isLoading = true;
    notifyListeners();

    await loadDefinition();

    // Dispose old controllers to prevent value leakage
    _controllers?.dispose();
    _controllers = null;

    _currentCase = caseRecord;
    _formInstance = caseRecord.formInstance;
    _controllers = FormControllers(formInstance: caseRecord.formInstance);
    _safeLog('state', 'loadCase end: controllers reset');

    _isLoading = false;
    notifyListeners();
  }

  void unloadCase() {
    final caseId = _currentCase?.id;
    _safeLog('state', 'unloadCase: case=${caseId ?? "none"} isDirty=$_isDirty');
    _isDirty = false;
    _controllers?.dispose();
    _controllers = null;
    _formInstance = null;
    _currentCase = null;
    notifyListeners();
  }

  Future<void> loadForm() async {
    _isLoading = true;
    notifyListeners();

    final formDefinition = await loadFormDefinition();

    validateFormDefinition(formDefinition);
    final assembled = assembleForm(formDefinition);

    final instance = FormInstance.emptyFromDefinition(formDefinition);
    final controllers = FormControllers(formInstance: instance);

    _assembledForm = assembled;
    _formDefinition = formDefinition;
    _formInstance = instance;
    _controllers = controllers;

    _isLoading = false;
    notifyListeners();
  }

  void _safeLog(String category, String message) {
    try {
      _logger.info(category, message);
    } catch (_) {
      // Logging must never throw
    }
  }

  void _safeLogWarn(String category, String message, {Object? error}) {
    try {
      _logger.warn(category, message, error: error);
    } catch (_) {
      // Logging must never throw
    }
  }

  void _safeLogError(String category, String message, {Object? error, StackTrace? stackTrace}) {
    try {
      _logger.error(category, message, error: error, stackTrace: stackTrace);
    } catch (_) {
      // Logging must never throw
    }
  }

}
