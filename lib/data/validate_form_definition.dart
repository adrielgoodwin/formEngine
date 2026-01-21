import '../models/form_definition.dart';
import '../models/layout_item.dart';
import '../models/visibility_condition.dart';

/// Validates that a FormDefinition is internally consistent:
/// - Every LayoutNodeRef.nodeId exists in FormDefinition.nodes
/// - Every DataSpec key matches DataSpec.formNodeID and exists in nodes
/// - No duplicate node IDs
/// - Every VisibilityCondition nodeId exists in nodes
///
/// Throws StateError with a clear message if any validation fails.
void validateFormDefinition(FormDefinition def) {
  final errors = <String>[];
  final nodeIds = def.nodes.keys.toSet();

  // 1. Check for duplicate node IDs (map keys are unique by definition, but check FormNode.id matches key)
  for (final entry in def.nodes.entries) {
    if (entry.key != entry.value.id) {
      errors.add('Node key "${entry.key}" does not match FormNode.id "${entry.value.id}"');
    }
  }

  // 2. Check DataSpec consistency
  for (final entry in def.dataSpecs.entries) {
    final key = entry.key;
    final spec = entry.value;
    
    if (key != spec.formNodeID) {
      errors.add('DataSpec key "$key" does not match DataSpec.formNodeID "${spec.formNodeID}"');
    }
    
    if (!nodeIds.contains(key)) {
      errors.add('DataSpec key "$key" does not exist in nodes');
    }
  }

  // 3. Check all nodes have a DataSpec
  for (final nodeId in nodeIds) {
    if (!def.dataSpecs.containsKey(nodeId)) {
      errors.add('Node "$nodeId" has no corresponding DataSpec');
    }
  }

  // 4. Check LayoutNodeRef.nodeId references in blocks
  for (final block in def.blocks) {
    _validateLayoutItem(block.layout, nodeIds, errors, 'block "${block.id}"');
  }

  // 5. Check LayoutNodeRef.nodeId references in groups
  for (final entry in def.groups.entries) {
    final groupId = entry.key;
    final group = entry.value;
    
    if (groupId != group.id) {
      errors.add('Group key "$groupId" does not match NodeGroupDefinition.id "${group.id}"');
    }
    
    for (final child in group.children) {
      _validateLayoutItem(child, nodeIds, errors, 'group "$groupId"');
    }
  }

  if (errors.isNotEmpty) {
    throw StateError('FormDefinition validation failed:\n${errors.map((e) => '  - $e').join('\n')}');
  }
}

void _validateLayoutItem(LayoutItem item, Set<String> nodeIds, List<String> errors, String context) {
  switch (item) {
    case LayoutNodeRef():
      if (!nodeIds.contains(item.nodeId)) {
        errors.add('LayoutNodeRef in $context references non-existent nodeId "${item.nodeId}"');
      }
      if (item.visibilityCondition != null) {
        _validateVisibilityCondition(item.visibilityCondition!, nodeIds, errors, context);
      }
    case LayoutRow():
      if (item.visibilityCondition != null) {
        _validateVisibilityCondition(item.visibilityCondition!, nodeIds, errors, context);
      }
      for (final child in item.children) {
        _validateLayoutItem(child, nodeIds, errors, context);
      }
    case LayoutColumn():
      if (item.visibilityCondition != null) {
        _validateVisibilityCondition(item.visibilityCondition!, nodeIds, errors, context);
      }
      for (final child in item.children) {
        _validateLayoutItem(child, nodeIds, errors, context);
      }
    case LayoutGroup():
      if (item.visibilityCondition != null) {
        _validateVisibilityCondition(item.visibilityCondition!, nodeIds, errors, context);
      }
      for (final child in item.children) {
        _validateLayoutItem(child, nodeIds, errors, '$context > group "${item.id}"');
      }
  }
}

void _validateVisibilityCondition(VisibilityCondition condition, Set<String> nodeIds, List<String> errors, String context) {
  switch (condition) {
    case ChoiceEqualsCondition():
      if (!nodeIds.contains(condition.nodeId)) {
        errors.add('VisibilityCondition in $context references non-existent nodeId "${condition.nodeId}"');
      }
    case ChoiceAnyOfCondition():
      if (!nodeIds.contains(condition.nodeId)) {
        errors.add('VisibilityCondition in $context references non-existent nodeId "${condition.nodeId}"');
      }
  }
}
