class GroupInstance {
  final String instanceId;
  final String groupId;
  final Map<String, Object?> values;

  GroupInstance({
    required this.instanceId,
    required this.groupId,
    required this.values,
  });

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'groupId': groupId,
        'values': values,
      };

  factory GroupInstance.fromJson(Map<String, dynamic> json) {
    return GroupInstance(
      instanceId: json['instanceId'] as String,
      groupId: json['groupId'] as String,
      values: Map<String, Object?>.from(json['values'] as Map),
    );
  }
}
