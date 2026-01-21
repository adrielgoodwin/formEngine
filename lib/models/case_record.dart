import 'package:uuid/uuid.dart';
import 'form_instance.dart';

class CaseRecord {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isArchived;
  final String definitionId;
  final int schemaVersion;
  final FormInstance formInstance;

  CaseRecord({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    required this.definitionId,
    required this.schemaVersion,
    required this.formInstance,
  });

  factory CaseRecord.create({
    required String definitionId,
    required int schemaVersion,
    required FormInstance formInstance,
    String? title,
  }) {
    final now = DateTime.now();
    return CaseRecord(
      id: const Uuid().v4(),
      title: title ?? 'Untitled Case',
      createdAt: now,
      updatedAt: now,
      isArchived: false,
      definitionId: definitionId,
      schemaVersion: schemaVersion,
      formInstance: formInstance,
    );
  }

  void touch() {
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isArchived': isArchived,
        'definitionId': definitionId,
        'schemaVersion': schemaVersion,
        'formInstance': formInstance.toJson(),
      };

  factory CaseRecord.fromJson(Map<String, dynamic> json) {
    return CaseRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isArchived: json['isArchived'] as bool,
      definitionId: json['definitionId'] as String,
      schemaVersion: json['schemaVersion'] as int,
      formInstance: FormInstance.fromJson(json['formInstance'] as Map<String, dynamic>),
    );
  }
}
