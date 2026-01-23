import 'package:flutter/foundation.dart';
import '../models/case_record.dart';
import '../models/form_definition.dart';
import '../models/form_instance.dart';

abstract class CaseRepository extends ChangeNotifier {
  List<CaseRecord> getAll({bool includeArchived = false});
  CaseRecord createNew(FormDefinition def);
  void update(CaseRecord record);
  void archive(String id, bool archived);
  void delete(String id);
  CaseRecord? getById(String id);
}

class InMemoryCaseRepository extends CaseRepository {
  final Map<String, CaseRecord> _cases = {};

  @override
  List<CaseRecord> getAll({bool includeArchived = false}) {
    final all = _cases.values.toList();
    if (includeArchived) return all;
    return all.where((c) => !c.isArchived).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  CaseRecord createNew(FormDefinition def) {
    final instance = FormInstance.emptyFromDefinition(def);
    final record = CaseRecord.create(
      definitionId: def.id,
      schemaVersion: def.schemaVersion,
      formInstance: instance,
    );
    _cases[record.id] = record;
    notifyListeners();
    return record;
  }

  @override
  void update(CaseRecord record) {
    record.touch();
    _cases[record.id] = record;
    notifyListeners();
  }

  @override
  void archive(String id, bool archived) {
    final record = _cases[id];
    if (record != null) {
      record.isArchived = archived;
      record.touch();
      notifyListeners();
    }
  }

  @override
  void delete(String id) {
    _cases.remove(id);
    notifyListeners();
  }

  @override
  CaseRecord? getById(String id) {
    return _cases[id];
  }
}
