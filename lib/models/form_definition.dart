import 'package:form_engine/models/form_block.dart';
import 'node_group_definition.dart';
import 'form_node.dart';

class FormDefinition {
  final String id;
  final String title;
  final Map<String, FormNode> nodes;
  final List<FormBlock> blocks;
  final Map<String, DataSpec> dataSpecs;
  final int schemaVersion;
  final Map<String, NodeGroupDefinition> groups;

  FormDefinition({
    required this.id,
    required this.title,
    required this.nodes,
    required this.blocks,
    required this.dataSpecs,
    required this.schemaVersion,
    Map<String, NodeGroupDefinition> groups = const {},
  }) : groups = groups;

//   factory FormDefinition.fromJson(Map<String, dynamic> json) {
//     return FormDefinition(
//       id: json['id'],
//       title: json['title'],
//       schemaVersion: json['schemaVersion'],
//       nodes: (json['nodes'] as Map<String, dynamic>).map(
//         (key, value) => MapEntry(
//           key,
//           FormNode.fromJson(key, value),
//         ),
//       ),
//       blocks: (json['blocks'] as List)
//           .map((e) => FormBlock.fromJson(e))
//           .toList(),
//       dataSpecs: (json['dataSpecs'] as Map<String, dynamic>).map(
//   (key, value) => MapEntry(
//     key,
//     DataSpec.fromJson(key, value),
//   ),
// ),

//     );
//   }
}
