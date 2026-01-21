// =======================
// VISIBILITY CONDITIONS
// =======================

/// Base condition type (sealed for exhaustiveness)
sealed class VisibilityCondition {
  const VisibilityCondition();

  bool evaluate(Map<String, Object?> formValues);

  Map<String, dynamic> toJson();

  static VisibilityCondition fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'choiceEquals':
        return ChoiceEqualsCondition.fromJson(json);
      case 'choiceAnyOf':
        return ChoiceAnyOfCondition.fromJson(json);
      default:
        throw StateError('Unknown VisibilityCondition type');
    }
  }
}

/// =======================
/// CHOICE CONDITION
/// =======================
///
/// Evaluates a specific checkbox index inside a ChoiceInputNode
/// Example:
/// - nodeId = "owns_house"
/// - choiceIndex = 0 ("Yes")
/// - expectedValue = true
///
class ChoiceEqualsCondition extends VisibilityCondition {
  final String nodeId;
  final int choiceIndex;
  final bool expectedValue;

  const ChoiceEqualsCondition({
    required this.nodeId,
    required this.choiceIndex,
    required this.expectedValue,
  });

  @override
  bool evaluate(Map<String, Object?> formValues) {
    final value = formValues[nodeId];

    if (value is! List<bool>) return false;
    if (choiceIndex >= value.length) return false;

    return value[choiceIndex] == expectedValue;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'choiceEquals',
        'nodeId': nodeId,
        'choiceIndex': choiceIndex,
        'expectedValue': expectedValue,
      };

  factory ChoiceEqualsCondition.fromJson(Map<String, dynamic> json) {
    return ChoiceEqualsCondition(
      nodeId: json['nodeId'],
      choiceIndex: json['choiceIndex'],
      expectedValue: json['expectedValue'],
    );
  }
}

/// =======================
/// CHOICE ANY OF CONDITION
/// =======================
///
/// Evaluates if any of the specified checkbox indices are true inside a ChoiceInputNode
/// Example:
/// - nodeId = "marital_status"
/// - choiceIndices = [0, 1] ("Married", "Common-law")
/// - expectedValue = true
///
class ChoiceAnyOfCondition extends VisibilityCondition {
  final String nodeId;
  final List<int> choiceIndices;
  final bool expectedValue;

  const ChoiceAnyOfCondition({
    required this.nodeId,
    required this.choiceIndices,
    required this.expectedValue,
  });

  @override
  bool evaluate(Map<String, Object?> formValues) {
    final value = formValues[nodeId];

    if (value is! List<bool>) return false;

    for (final choiceIndex in choiceIndices) {
      if (choiceIndex >= value.length) continue;
      if (value[choiceIndex] == expectedValue) return true;
    }

    return false;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'choiceAnyOf',
        'nodeId': nodeId,
        'choiceIndices': choiceIndices,
        'expectedValue': expectedValue,
      };

  factory ChoiceAnyOfCondition.fromJson(Map<String, dynamic> json) {
    return ChoiceAnyOfCondition(
      nodeId: json['nodeId'],
      choiceIndices: List<int>.from(json['choiceIndices']),
      expectedValue: json['expectedValue'],
    );
  }
}
