import 'form_definition.dart';
import 'layout_item.dart';
import 'visibility_condition.dart';

void validateFormDefinition(FormDefinition def) {
  final nodeIds = def.nodes.keys.toSet();

  void requireNodeId(String nodeId, String where) {
    if (!nodeIds.contains(nodeId)) {
      throw StateError(
        'FormDefinition invalid: $where references unknown nodeId "$nodeId"',
      );
    }
  }

  void validateCondition(VisibilityCondition? condition, String where) {
    if (condition == null) return;

    switch (condition) {
      case ChoiceEqualsCondition():
        requireNodeId(condition.nodeId, 'VisibilityCondition at $where');
      case ChoiceAnyOfCondition():
        requireNodeId(condition.nodeId, 'VisibilityCondition at $where');
    }
  }

  void validateLayout(LayoutItem item, String where) {
    switch (item) {
      case LayoutNodeRef():
        requireNodeId(item.nodeId, 'LayoutNodeRef(id: ${item.id}) at $where');
        return;

      case LayoutRow():
        validateCondition(item.visibilityCondition, 'LayoutRow(id: ${item.id}) at $where');
        for (final child in item.children) {
          validateLayout(child, 'LayoutRow(id: ${item.id})');
        }
        return;

      case LayoutColumn():
        validateCondition(item.visibilityCondition, 'LayoutColumn(id: ${item.id}) at $where');
        for (final child in item.children) {
          validateLayout(child, 'LayoutColumn(id: ${item.id})');
        }
        return;

      case LayoutGroup():
        validateCondition(item.visibilityCondition, 'LayoutGroup(id: ${item.id}) at $where');
        for (final child in item.children) {
          validateLayout(child, 'LayoutGroup(id: ${item.id})');
        }
        return;
    }
  }

  // Validate DataSpecs
  for (final entry in def.dataSpecs.entries) {
    final specId = entry.key;
    final spec = entry.value;

    if (specId != spec.formNodeID) {
      throw StateError(
        'FormDefinition invalid: DataSpec key "$specId" does not match formNodeID "${spec.formNodeID}"',
      );
    }

    requireNodeId(spec.formNodeID, 'DataSpec');
  }

  // Ensure every node has a DataSpec (assembler requires it)
  for (final nodeId in nodeIds) {
    if (!def.dataSpecs.containsKey(nodeId)) {
      throw StateError(
        'FormDefinition invalid: missing DataSpec for nodeId "$nodeId"',
      );
    }
  }

  // Validate all group definitions
  for (final entry in def.groups.entries) {
    final groupId = entry.key;
    final group = entry.value;

    if (groupId != group.id) {
      throw StateError(
        'FormDefinition invalid: groups key "$groupId" does not match NodeGroupDefinition.id "${group.id}"',
      );
    }

    for (final child in group.children) {
      validateLayout(child, 'NodeGroupDefinition(id: ${group.id})');
    }
  }

  // Validate all blocks
  for (final block in def.blocks) {
    validateLayout(block.layout, 'FormBlock(id: ${block.id})');
  }
}
