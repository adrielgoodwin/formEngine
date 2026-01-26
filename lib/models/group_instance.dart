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
      values: _coerceValuesMap(json['values'] as Map),
    );
  }

  /// Coerces JSON-deserialized values to their proper Dart types.
  /// In particular, converts List<dynamic> containing bools to List<bool>.
  static Map<String, Object?> _coerceValuesMap(Map<dynamic, dynamic> raw) {
    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      final key = entry.key as String;
      final value = entry.value;
      result[key] = _coerceValue(value);
    }
    return result;
  }

  /// Recursively coerces a single value to proper Dart types.
  static Object? _coerceValue(Object? value) {
    if (value == null) return null;
    if (value is List) {
      // Check if this is a list of booleans (choice input values)
      if (value.isNotEmpty && value.every((e) => e is bool)) {
        return value.cast<bool>().toList();
      }
      // Otherwise, recursively coerce list elements
      return value.map(_coerceValue).toList();
    }
    if (value is Map) {
      return _coerceValuesMap(value);
    }
    return value;
  }
}
