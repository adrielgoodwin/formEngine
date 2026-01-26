import 'form_definition.dart';
import 'group_instance.dart';

class FormInstance {
  final Map<String, Object?> values;
  final Map<String, List<GroupInstance>> groupInstances;
  final Map<String, int> _groupCounters;

  FormInstance._(this.values, this.groupInstances, this._groupCounters);

  factory FormInstance.emptyFromDefinition(FormDefinition definition) {
    final Map<String, Object?> baseValues = {
      for (final nodeId in definition.nodes.keys) nodeId: null,
    };

    final Map<String, List<GroupInstance>> groups = {};
    final Map<String, int> counters = {};

    // Pre-seed minimum instances declared in schema
    for (final entry in definition.groups.entries) {
      final groupId = entry.key;
      final def = entry.value;
      final minCount = def.minInstances;
      counters[groupId] = 0;
      groups[groupId] = [];
      for (var i = 0; i < minCount; i++) {
        final inst = GroupInstance(
          instanceId: _nextInstanceIdFor(groupId, counters),
          groupId: groupId,
          values: {},
        );
        groups[groupId]!.add(inst);
      }
    }

    return FormInstance._(baseValues, groups, counters);
  }

  T? getValue<T>(String nodeId) {
    final value = values[nodeId];
    return value is T ? value : null;
  }

  void setValue(String nodeId, Object? value) {
    values[nodeId] = value;
  }

  // ===== Group instance helpers =====

  List<GroupInstance> getGroupInstances(String groupId) {
    return groupInstances[groupId] ?? const [];
  }

  GroupInstance addGroupInstance(String groupId) {
    final list = groupInstances.putIfAbsent(groupId, () => []);
    final inst = GroupInstance(
      instanceId: _nextInstanceIdFor(groupId, _groupCounters),
      groupId: groupId,
      values: {},
    );
    list.add(inst);
    return inst;
  }

  void removeGroupInstance(String groupId, String instanceId) {
    final list = groupInstances[groupId];
    if (list == null) return;
    list.removeWhere((g) => g.instanceId == instanceId);
  }

  T? getGroupValue<T>(String groupId, String instanceId, String nodeId) {
    final list = groupInstances[groupId];
    if (list == null) return null;
    final inst = list.firstWhere(
      (g) => g.instanceId == instanceId,
      orElse: () => GroupInstance(instanceId: '', groupId: groupId, values: const {}),
    );
    if (inst.instanceId.isEmpty) return null;
    final value = inst.values[nodeId];
    return value is T ? value : null;
  }

  void setGroupValue(String groupId, String instanceId, String nodeId, Object? value) {
    final list = groupInstances.putIfAbsent(groupId, () => []);
    GroupInstance? inst = list.firstWhere(
      (g) => g.instanceId == instanceId,
      orElse: () => GroupInstance(instanceId: '', groupId: groupId, values: {}),
    );
    if (inst.instanceId.isEmpty) {
      inst = GroupInstance(instanceId: instanceId, groupId: groupId, values: {});
      list.add(inst);
    }
    inst.values[nodeId] = value;
  }

  static String _nextInstanceIdFor(String groupId, Map<String, int> counters) {
    final next = (counters[groupId] ?? 0) + 1;
    counters[groupId] = next;
    return next.toString();
  }

  Map<String, dynamic> toJson() => {
        'values': values,
        'groupInstances': groupInstances.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
      };

  factory FormInstance.fromJson(Map<String, dynamic> json) {
    return FormInstance._(
      _coerceValuesMap(json['values'] as Map),
      (json['groupInstances'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List).map((e) => GroupInstance.fromJson(e as Map<String, dynamic>)).toList(),
        ),
      ),
      {},
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
