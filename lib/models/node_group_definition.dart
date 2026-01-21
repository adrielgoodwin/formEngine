import 'layout_item.dart';

class NodeGroupDefinition {
  final String id;
  final String label;
  final List<LayoutItem> children;
  final bool repeatable;
  final int minInstances;
  final int? maxInstances;

  const NodeGroupDefinition({
    required this.id,
    required this.label,
    required this.children,
    this.repeatable = false,
    this.minInstances = 1,
    this.maxInstances,
  });

  // Convenience factory for Requested / Received / Notes
  factory NodeGroupDefinition.rrn({
    required String id,
    required String label,
  }) {
    // Node IDs for this group (caller should ensure these nodes exist in FormDefinition.nodes)
    final requestedId = '${id}_requested';
    final receivedId = '${id}_received';
    final notesId = '${id}_notes';

    return NodeGroupDefinition(
      id: id,
      label: label,
      repeatable: true,
      children: [
        LayoutRow(
          id: '${id}_row',
          children: [
            LayoutNodeRef(id: '${id}_req_ref', nodeId: requestedId, widthFraction: 0.2),
            LayoutNodeRef(id: '${id}_rcv_ref', nodeId: receivedId, widthFraction: 0.2),
            LayoutNodeRef(id: '${id}_notes_ref', nodeId: notesId, widthFraction: 0.6),
          ],
        ),
      ],
    );
  }
}
