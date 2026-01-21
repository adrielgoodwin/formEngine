import 'visibility_condition.dart';

sealed class LayoutItem {
  final String id;
  final VisibilityCondition? visibilityCondition;

  const LayoutItem({
    required this.id,
    this.visibilityCondition,
  });

  Map<String, dynamic> toJson();

  static LayoutItem fromJson(Map<String, dynamic> json) {
    final visibilityConditionJson = json['visibilityCondition'];
    final visibilityCondition = visibilityConditionJson == null
        ? null
        : VisibilityCondition.fromJson(
            visibilityConditionJson as Map<String, dynamic>,
          );

    switch (json['type']) {
      case 'row':
        return LayoutRow(
          id: json['id'] as String,
          visibilityCondition: visibilityCondition,
          children: (json['children'] as List)
              .map(
                (e) => LayoutItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        );
      case 'column':
        return LayoutColumn(
          id: json['id'] as String,
          visibilityCondition: visibilityCondition,
          children: (json['children'] as List)
              .map(
                (e) => LayoutItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        );
      case 'nodeRef':
        return LayoutNodeRef(
          id: json['id'] as String,
          visibilityCondition: visibilityCondition,
          nodeId: json['nodeId'] as String,
          widthFraction: (json['widthFraction'] as num).toDouble(),
        );
      case 'group':
        return LayoutGroup(
          id: json['id'] as String,
          visibilityCondition: visibilityCondition,
          label: json['label'] as String,
          groupId: json['groupId'] as String?,
          children: (json['children'] as List)
              .map(
                (e) => LayoutItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        );
      default:
        throw StateError('Unknown LayoutItem type: ${json['type']}');
    }
  }
}

class LayoutRow extends LayoutItem {
  final List<LayoutItem> children; // max 3 top-level, max 2 nested

  const LayoutRow({
    required super.id,
    super.visibilityCondition,
    required this.children,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'row',
      'id': id,
      'children': children.map((c) => c.toJson()).toList(),
      if (visibilityCondition != null)
        'visibilityCondition': visibilityCondition!.toJson(),
    };
  }
}

class LayoutColumn extends LayoutItem {
  final List<LayoutItem> children;

  const LayoutColumn({
    required super.id,
    super.visibilityCondition,
    required this.children,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'column',
      'id': id,
      'children': children.map((c) => c.toJson()).toList(),
      if (visibilityCondition != null)
        'visibilityCondition': visibilityCondition!.toJson(),
    };
  }
}

class LayoutNodeRef extends LayoutItem {
  final String nodeId;
  final double widthFraction; // 0.0–1.0

  const LayoutNodeRef({
    required super.id,
    super.visibilityCondition,
    required this.nodeId,
    required this.widthFraction,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'nodeRef',
      'id': id,
      'nodeId': nodeId,
      'widthFraction': widthFraction,
      if (visibilityCondition != null)
        'visibilityCondition': visibilityCondition!.toJson(),
    };
  }
}

class LayoutGroup extends LayoutItem {
  final String label;
  final List<LayoutItem> children;
  final String? groupId; // optional reference to NodeGroupDefinition

  const LayoutGroup({
    required super.id,
    super.visibilityCondition,
    required this.label,
    required this.children,
    this.groupId,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'group',
      'id': id,
      'label': label,
      'children': children.map((c) => c.toJson()).toList(),
      if (groupId != null) 'groupId': groupId,
      if (visibilityCondition != null)
        'visibilityCondition': visibilityCondition!.toJson(),
    };
  }
}

final deceasedInfoLayout = LayoutColumn(
  id: 'deceased_root',
  children: [
    LayoutRow(
      id: 'name_dates_row',
      children: [
        LayoutNodeRef(
          id: 'full_name_ref',
          nodeId: 'full_name',
          widthFraction: 0.4,
        ),
        LayoutNodeRef(
          id: 'dob_ref',
          nodeId: 'dob',
          widthFraction: 0.3,
        ),
        LayoutNodeRef(
          id: 'dod_ref',
          nodeId: 'dod',
          widthFraction: 0.3,
        ),
      ],
    ),

    LayoutRow(
      id: 'sin_status_row',
      children: [
        LayoutNodeRef(
          id: 'sin_ref',
          nodeId: 'sin',
          widthFraction: 0.4,
        ),
        LayoutNodeRef(
          id: 'marital_status_ref',
          nodeId: 'marital_status',
          widthFraction: 0.6,
        ),
      ],
    ),

    LayoutGroup(
      id: 'partner_group',
      label: 'Partner Information',
      children: [
        LayoutRow(
          id: 'partner_row_1',
          children: [
            LayoutNodeRef(
              id: 'partner_name_ref',
              nodeId: 'partner_name',
              widthFraction: 0.6,
            ),
            LayoutNodeRef(
              id: 'partner_dob_ref',
              nodeId: 'partner_dob',
              widthFraction: 0.4,
            ),
          ],
        ),
        LayoutRow(
          id: 'partner_row_2',
          children: [
            LayoutNodeRef(
              id: 'partner_sin_ref',
              nodeId: 'partner_sin',
              widthFraction: 0.4,
            ),
            LayoutNodeRef(
              id: 'partner_address_ref',
              nodeId: 'partner_address',
              widthFraction: 0.6,
            ),
          ],
        ),
      ],
    ),
  ],
);
