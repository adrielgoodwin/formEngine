import 'package:flutter/material.dart';
import '../models/form_instance.dart';

/// Uniquely identifies a text field in base scope or group scope.
/// Safe as a Map key via == and hashCode.
class FieldKey {
  final String nodeId;
  final String? groupId;
  final String? instanceId;

  const FieldKey(this.nodeId, this.groupId, this.instanceId);

  @override
  bool operator ==(Object other) =>
      other is FieldKey &&
      nodeId == other.nodeId &&
      groupId == other.groupId &&
      instanceId == other.instanceId;

  @override
  int get hashCode => Object.hash(nodeId, groupId, instanceId);

  @override
  String toString() => 'FieldKey($nodeId, $groupId, $instanceId)';
}

class FormControllers {
  final FormInstance formInstance;
  final Map<FieldKey, TextEditingController> _textControllers = {};
  final Map<FieldKey, String?> _fieldErrors = {};

  FormControllers({required this.formInstance});

  /// Returns the error for a given field key, or null if none.
  String? errorFor(FieldKey key) => _fieldErrors[key];

  /// Sets or clears an error for a given field key.
  void setError(FieldKey key, String? error) {
    _fieldErrors[key] = error;
  }

  /// Clears all errors for a specific group instance.
  void clearErrorsForGroupInstance(String groupId, String instanceId) {
    final keysToRemove = _fieldErrors.keys
        .where((k) => k.groupId == groupId && k.instanceId == instanceId)
        .toList();
    for (final key in keysToRemove) {
      _fieldErrors.remove(key);
    }
  }

  /// Returns a controller for the given field, creating lazily if needed.
  /// Initializes text from FormInstance on first creation.
  TextEditingController controllerFor({
    required String nodeId,
    String? groupId,
    String? instanceId,
  }) {
    final key = FieldKey(nodeId, groupId, instanceId);
    if (_textControllers.containsKey(key)) {
      return _textControllers[key]!;
    }

    // Initialize from FormInstance
    final String initialText;
    if (groupId != null && instanceId != null) {
      final value = formInstance.getGroupValue<dynamic>(groupId, instanceId, nodeId);
      initialText = value?.toString() ?? '';
    } else {
      final value = formInstance.getValue<dynamic>(nodeId);
      initialText = value?.toString() ?? '';
    }

    final controller = TextEditingController(text: initialText);
    _textControllers[key] = controller;
    return controller;
  }

  /// Disposes and removes all controllers for a specific group instance.
  void removeControllersForGroupInstance(String groupId, String instanceId) {
    final keysToRemove = _textControllers.keys
        .where((k) => k.groupId == groupId && k.instanceId == instanceId)
        .toList();
    for (final key in keysToRemove) {
      _textControllers[key]?.dispose();
      _textControllers.remove(key);
    }
  }

  /// Disposes all controllers. Call from provider dispose.
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
  }
}
