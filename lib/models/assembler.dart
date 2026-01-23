import 'form_definition.dart';
import 'form_block.dart';
import 'form_node.dart';
import 'layout_item.dart';
import 'visibility_condition.dart';
import 'node_group_definition.dart';

sealed class AssembledLayout {
  final String id;
  final VisibilityCondition? visibilityCondition;

  const AssembledLayout({
    required this.id,
    this.visibilityCondition,
  });
}

class AssembledRow extends AssembledLayout {
  final List<AssembledLayout> children;

  const AssembledRow({
    required super.id,
    super.visibilityCondition,
    required this.children,
  });
}

class AssembledColumn extends AssembledLayout {
  final List<AssembledLayout> children;

  const AssembledColumn({
    required super.id,
    super.visibilityCondition,
    required this.children,
  });
}

class AssembledGroup extends AssembledLayout {
  final String label;
  final List<AssembledLayout> children;
  final String? groupId;
  final bool repeatable;

  const AssembledGroup({
    required super.id,
    super.visibilityCondition,
    required this.label,
    required this.children,
    this.groupId,
    this.repeatable = false,
  });
}

class AssembledNode extends AssembledLayout {
  final FormNode node;
  final DataSpec dataSpec;
  final double widthFraction;

  const AssembledNode({
    required super.id,
    super.visibilityCondition,
    required this.node,
    required this.dataSpec,
    required this.widthFraction,
  });
}

class AssembledBlock {
  final String id;
  final String title;
  final AssembledLayout layout;
  final FormBlock formBlock;

  AssembledBlock({
    required this.id,
    required this.title,
    required this.layout,
    required this.formBlock,
  });
}


AssembledLayout resolveLayout(
  LayoutItem item,
  Map<String, FormNode> nodes,
  Map<String, DataSpec> dataSpecs,
  Map<String, NodeGroupDefinition> groups,
) {
  switch (item) {
    case LayoutRow():
      return AssembledRow(
        id: item.id,
        visibilityCondition: item.visibilityCondition,
        children: item.children
            .map((child) => resolveLayout(child, nodes, dataSpecs, groups))
            .toList(),
      );

    case LayoutColumn():
      return AssembledColumn(
        id: item.id,
        visibilityCondition: item.visibilityCondition,
        children: item.children
            .map((child) => resolveLayout(child, nodes, dataSpecs, groups))
            .toList(),
      );

    case LayoutGroup():
      final def = item.groupId == null ? null : groups[item.groupId!];
      final children = def != null ? def.children : item.children;
      return AssembledGroup(
        id: item.id,
        visibilityCondition: item.visibilityCondition,
        label: item.label,
        groupId: item.groupId,
        repeatable: def?.repeatable ?? false,
        children: children
            .map((child) => resolveLayout(child, nodes, dataSpecs, groups))
            .toList(),
      );

    case LayoutNodeRef():
      final node = nodes[item.nodeId];
      final spec = dataSpecs[item.nodeId];

      if (node == null || spec == null) {
        throw StateError('Node or DataSpec not found for ${item.nodeId}');
      }

      return AssembledNode(
        id: item.id,
        visibilityCondition: item.visibilityCondition,
        node: node,
        dataSpec: spec,
        widthFraction: item.widthFraction,
      );
  }
}

AssembledForm assembleForm(FormDefinition definition) {
  final assembledBlocks = definition.blocks.map((block) {
    return AssembledBlock(
      id: block.id,
      title: block.title,
      layout: resolveLayout(
        block.layout,
        definition.nodes,
        definition.dataSpecs,
        definition.groups,
      ),
      formBlock: block,
    );
  }).toList();

  return AssembledForm(
    id: definition.id,
    title: definition.title,
    blocks: assembledBlocks,
  );
}

class AssembledForm {
  final String id;
  final String title;
  List<AssembledBlock> blocks;

  AssembledForm({
    required this.id,
    required this.title,
    required this.blocks,
  });
}


