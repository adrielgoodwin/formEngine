import 'data/case_repository.dart';
import 'data/repository_exceptions.dart';
import 'logging/app_logger.dart';
import 'models/form_definition.dart';
import 'models/form_instance.dart';
import 'models/group_instance.dart';

/// Seeds demo cases if the repository is empty (or if force=true).
/// Works with both InMemoryCaseRepository and FileCaseRepository.
/// Does NOT delete existing cases when force=true.
Future<void> seedDemoCasesIfEmpty(
  FormDefinition def,
  CaseRepository repo, {
  bool force = false,
}) async {
  final existingCases = repo.getAll(includeArchived: true);
  if (!force && existingCases.isNotEmpty) {
    _safeLog('Skipping seed: repo already has ${existingCases.length} cases');
    return;
  }

  _safeLog('Starting demo seed (force=$force, existing=${existingCases.length})');
  await _seedAllDemoCases(def, repo);
  _safeLog('Demo seed complete');
}

Future<void> _seedAllDemoCases(FormDefinition def, CaseRepository repo) async {
  // A) Almost Empty
  await _seedCase(
    def: def,
    repo: repo,
    title: 'Almost Empty',
    populate: (instance) {
      instance.setValue('deceased_name', 'John Doe');
      instance.setValue('deceased_dob', '01/01/1950');
      instance.setValue('deceased_dod', '15/12/2023');
      instance.setValue('deceased_sin', '123456789');
      instance.setValue('deceased_marital_status', [true, false, false, false, false, false]);
    },
  );

  // B) Basic Complete
  await _seedCase(
    def: def,
    repo: repo,
    title: 'Jane Smith',
    populate: (instance) {
      instance.setValue('deceased_name', 'Jane Smith');
      instance.setValue('deceased_dob', '01/01/1950');
      instance.setValue('deceased_dod', '15/12/2023');
      instance.setValue('deceased_sin', '123456789');
      instance.setValue('deceased_marital_status', [true, false, false, false, false, false]);
    },
  );

  // C) Complex Estate
  await _seedCase(
    def: def,
    repo: repo,
    title: 'Robert Johnson',
    populate: (instance) {
      instance.setValue('deceased_name', 'Robert Johnson');
      instance.setValue('deceased_sin', '987654321');
      instance.setValue('deceased_marital_status', [true, false, false, false, false, false]);
      instance.setValue('partner_name', 'Alice Johnson');
      instance.setValue('partner_dob', '02/02/1952');
      instance.setValue('partner_sin', '123123123');
      // RRSP 1
      final rrspInst1 = _ensureGroupInstance(instance, 'rrsp_account_group');
      instance.setGroupValue('rrsp_account_group', rrspInst1.instanceId, 'rrsp_institution', 'TD Bank');
      instance.setGroupValue('rrsp_account_group', rrspInst1.instanceId, 'rrsp_account_number', '123456789');
      instance.setGroupValue('rrsp_account_group', rrspInst1.instanceId, 'rrsp_value', 500000);
      // RRSP 2
      final rrspInst2 = _addNewGroupInstance(instance, 'rrsp_account_group');
      instance.setGroupValue('rrsp_account_group', rrspInst2.instanceId, 'rrsp_institution', 'BMO');
      instance.setGroupValue('rrsp_account_group', rrspInst2.instanceId, 'rrsp_account_number', '987654321');
      instance.setGroupValue('rrsp_account_group', rrspInst2.instanceId, 'rrsp_value', 250000);
      // Non-Registered
      final nonRegInst = _ensureGroupInstance(instance, 'nonreg_account_group');
      instance.setGroupValue('nonreg_account_group', nonRegInst.instanceId, 'nonreg_institution', 'Scotiabank');
      instance.setGroupValue('nonreg_account_group', nonRegInst.instanceId, 'nonreg_account_number', '111222333');
      // Real Estate
      final realEstInst = _ensureGroupInstance(instance, 'realestate_group');
      instance.setGroupValue('realestate_group', realEstInst.instanceId, 'realestate_address', '123 Main St, Toronto, ON M5V 1A1');
    },
  );

  // D) Edge Values
  await _seedCase(
    def: def,
    repo: repo,
    title: 'Edge Case Tester',
    populate: (instance) {
      instance.setValue('deceased_name', 'Edge Case Tester');
      instance.setValue('deceased_dob', '31/12/1999');
      instance.setValue('deceased_dod', '19/01/2026');
      instance.setValue('deceased_sin', '000000000');
      instance.setValue('deceased_marital_status', [false, false, true, false, false]);
      // RRSP with large balance
      final rrspEdge = _ensureGroupInstance(instance, 'rrsp_account_group');
      instance.setGroupValue('rrsp_account_group', rrspEdge.instanceId, 'rrsp_institution', 'Bank of Edge Cases');
      instance.setGroupValue('rrsp_account_group', rrspEdge.instanceId, 'rrsp_account_number', '999999999999999');
      instance.setGroupValue('rrsp_account_group', rrspEdge.instanceId, 'rrsp_value', 999999999);
    },
  );

  // E) Archived Case
  await _seedCase(
    def: def,
    repo: repo,
    title: 'Archived Person',
    archived: true,
    populate: (instance) {
      instance.setValue('deceased_name', 'Archived Person');
      instance.setValue('deceased_sin', '555555555');
    },
  );

  // F) Comprehensive - Ardal Allgood (Everything Filled Out)
  await _seedCase(
    def: def,
    repo: repo,
    title: 'Ardal Allgood',
    populate: (instance) {
      // Basic deceased info
      instance.setValue('deceased_name', 'Ardal Allgood');
      instance.setValue('deceased_dob', '15/03/1945');
      instance.setValue('deceased_dod', '22/11/2023');
      instance.setValue('deceased_sin', '123456789');
      instance.setValue('deceased_marital_status', [true, false, false, false, false, false]);

      // Partner info
      instance.setValue('partner_name', 'Margaret Allgood');
      instance.setValue('partner_dob', '08/07/1948');
      instance.setValue('partner_sin', '987654321');
      instance.setValue('partner_address', '742 Evergreen Terrace, Springfield, ON L1A 2B3');

      // Meeting info
      instance.setValue('meeting_type', [true, false, false]); // In person
      instance.setValue('meeting_attendees', [true, true, false]); // MM, DG
      instance.setValue('meeting_other_attendees', 'John Smith (family lawyer)');

      // Trustees
      final trustee1 = _ensureGroupInstance(instance, 'trustee_group');
      instance.setGroupValue('trustee_group', trustee1.instanceId, 'trustee_name', 'James Allgood');
      instance.setGroupValue('trustee_group', trustee1.instanceId, 'trustee_relationship', 'Son');
      instance.setGroupValue('trustee_group', trustee1.instanceId, 'trustee_address', '123 Main St, Toronto, ON M5V 1A1');
      instance.setGroupValue('trustee_group', trustee1.instanceId, 'trustee_contact', 'james.allgood@email.com, (416) 555-0123');
      instance.setGroupValue('trustee_group', trustee1.instanceId, 'trustee_wants_compensation', [true, false]);
      instance.setGroupValue('trustee_group', trustee1.instanceId, 'trustee_sin', '111222333');
      instance.setGroupValue('trustee_group', trustee1.instanceId, 'trustee_income_notes', 'Professional accountant with 25+ years experience');
      instance.setGroupValue('trustee_group', trustee1.instanceId, 'trustee_is_other_person', [false, true]);

      final trustee2 = _addNewGroupInstance(instance, 'trustee_group');
      instance.setGroupValue('trustee_group', trustee2.instanceId, 'trustee_name', 'Sarah Allgood');
      instance.setGroupValue('trustee_group', trustee2.instanceId, 'trustee_relationship', 'Daughter');
      instance.setGroupValue('trustee_group', trustee2.instanceId, 'trustee_address', '456 Oak Ave, Toronto, ON M4B 2C4');
      instance.setGroupValue('trustee_group', trustee2.instanceId, 'trustee_contact', 'sarah.allgood@email.com, (416) 555-0456');
      instance.setGroupValue('trustee_group', trustee2.instanceId, 'trustee_wants_compensation', [false, true]);
      instance.setGroupValue('trustee_group', trustee2.instanceId, 'trustee_is_other_person', [false, true]);

      // Professionals
      final prof1 = _ensureGroupInstance(instance, 'professional_group');
      instance.setGroupValue('professional_group', prof1.instanceId, 'professional_profession', 'Lawyer');
      instance.setGroupValue('professional_group', prof1.instanceId, 'professional_name', 'Robert Thompson');
      instance.setGroupValue('professional_group', prof1.instanceId, 'professional_email', 'r.thompson@thompsonlaw.com');
      instance.setGroupValue('professional_group', prof1.instanceId, 'professional_phone', '(416) 555-1001');

      final prof2 = _addNewGroupInstance(instance, 'professional_group');
      instance.setGroupValue('professional_group', prof2.instanceId, 'professional_profession', 'Investment Advisor');
      instance.setGroupValue('professional_group', prof2.instanceId, 'professional_name', 'Jennifer Walsh');
      instance.setGroupValue('professional_group', prof2.instanceId, 'professional_email', 'j.walsh@walshinvestments.com');
      instance.setGroupValue('professional_group', prof2.instanceId, 'professional_phone', '(416) 555-2001');

      // Documents RRN fields
      instance.setValue('docs_death_cert_requested', [true]);
      instance.setValue('docs_death_cert_received', [true]);
      instance.setValue('docs_death_cert_notes', 'Death certificate obtained from ServiceOntario, original filed with estate documents');
      instance.setValue('docs_will_requested', [true]);
      instance.setValue('docs_will_received', [true]);
      instance.setValue('docs_will_notes', 'Last will and testament dated 2020-03-15, stored in safety deposit box at TD Bank');
      instance.setValue('docs_probate_requested', [true]);
      instance.setValue('docs_probate_received', [true]);
      instance.setValue('docs_probate_notes', 'Probate application filed, certificate pending');
      instance.setValue('docs_assets_requested', [true]);
      instance.setValue('docs_assets_received', [true]);
      instance.setValue('docs_assets_notes', 'Complete asset list compiled from bank statements, investment accounts, and property records');

      // RRSP accounts
      final rrsp1 = _ensureGroupInstance(instance, 'rrsp_account_group');
      instance.setGroupValue('rrsp_account_group', rrsp1.instanceId, 'rrsp_institution', 'TD Bank');
      instance.setGroupValue('rrsp_account_group', rrsp1.instanceId, 'rrsp_account_number', 'RRSP-123456789');
      instance.setGroupValue('rrsp_account_group', rrsp1.instanceId, 'rrsp_value', 50000000);
      instance.setGroupValue('rrsp_account_group', rrsp1.instanceId, 'rrsp_has_beneficiary', [false, true]);

      final rrsp2 = _addNewGroupInstance(instance, 'rrsp_account_group');
      instance.setGroupValue('rrsp_account_group', rrsp2.instanceId, 'rrsp_institution', 'RBC Royal Bank');
      instance.setGroupValue('rrsp_account_group', rrsp2.instanceId, 'rrsp_account_number', 'RRSP-987654321');
      instance.setGroupValue('rrsp_account_group', rrsp2.instanceId, 'rrsp_value', 75000000);
      instance.setGroupValue('rrsp_account_group', rrsp2.instanceId, 'rrsp_has_beneficiary', [true, false]);

      // Non-registered accounts
      final nonReg1 = _ensureGroupInstance(instance, 'nonreg_account_group');
      instance.setGroupValue('nonreg_account_group', nonReg1.instanceId, 'nonreg_institution', 'BMO');
      instance.setGroupValue('nonreg_account_group', nonReg1.instanceId, 'nonreg_account_number', 'TFSA-111222333');
      instance.setGroupValue('nonreg_account_group', nonReg1.instanceId, 'nonreg_value_at_death', 15000000);
      instance.setGroupValue('nonreg_account_group', nonReg1.instanceId, 'nonreg_gain_loss', 2500000);

      // Other assets
      final asset1 = _ensureGroupInstance(instance, 'asset_group');
      instance.setGroupValue('asset_group', asset1.instanceId, 'asset_description', 'Antique car collection (3 vehicles)');
      instance.setGroupValue('asset_group', asset1.instanceId, 'asset_value', 12500000);

      final asset2 = _addNewGroupInstance(instance, 'asset_group');
      instance.setGroupValue('asset_group', asset2.instanceId, 'asset_description', 'Art collection and jewelry');
      instance.setGroupValue('asset_group', asset2.instanceId, 'asset_value', 7500000);

      // Share certificates
      final share1 = _ensureGroupInstance(instance, 'share_certificate_group');
      instance.setGroupValue('share_certificate_group', share1.instanceId, 'share_company_name', 'Royal Bank of Canada');
      instance.setGroupValue('share_certificate_group', share1.instanceId, 'share_number_of_shares', '500');
      instance.setGroupValue('share_certificate_group', share1.instanceId, 'share_notes', 'DRIP enrolled since 2010, reinvested dividends');

      final share2 = _addNewGroupInstance(instance, 'share_certificate_group');
      instance.setGroupValue('share_certificate_group', share2.instanceId, 'share_company_name', 'Enbridge Inc.');
      instance.setGroupValue('share_certificate_group', share2.instanceId, 'share_number_of_shares', '1000');
      instance.setGroupValue('share_certificate_group', share2.instanceId, 'share_notes', 'Cash dividends, purchased in 2005');

      // Real estate
      final realEst1 = _ensureGroupInstance(instance, 'realestate_group');
      instance.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_is_principal', [true, false]);
      instance.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_address', '742 Evergreen Terrace, Springfield, ON L1A 2B3');
      instance.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_principal_year', '1985');
      instance.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_principal_value', 85000000);
      instance.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_principal_notes', 'Primary residence for 38 years, recently renovated kitchen and bathrooms');

      final realEst2 = _addNewGroupInstance(instance, 'realestate_group');
      instance.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_is_principal', [false, true]);
      instance.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_address', '123 Cottage Lane, Muskoka, ON P1A 2B3');
      instance.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_year_of_purchase', '2005');
      instance.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_purchase_price', 45000000);
      instance.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_value_at_death', 67500000);
      instance.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_capital_improvements', 'Added deck and hot tub in 2010, renovated basement in 2018');
      instance.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_ownership_tax_history', 'Purchased in 2005, used as vacation property. 1994 election made.');
      instance.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_whats_happening_notes', 'Currently listed for sale, expected to close in March 2024');

      // Tax History (Not GPH client, so show full tax history)
      instance.setValue('tax_gph_client', [false, true]); // No
      instance.setValue('tax_returns_requested', [true]);
      instance.setValue('tax_returns_received', [true]);
      instance.setValue('tax_returns_notes', 'Tax returns for 2021 and 2022 obtained from accountant');
      instance.setValue('tax_income_types', [true, true, true, true, false, false, false, false, false]); // CPP, T4, OAS, T5
      instance.setValue('tax_income_notes', 'Pension income from government and employer sources');
      instance.setValue('tax_credits', [true, true, false]); // Donations, Medical
      instance.setValue('tax_credits_notes', 'Charitable donations \$25,000, Medical expenses \$12,500');
    },
  );
}

/// Seeds a single case through the repository interface.
/// Handles FileLockException and SeedDataException gracefully by logging and continuing.
Future<void> _seedCase({
  required FormDefinition def,
  required CaseRepository repo,
  required String title,
  required void Function(FormInstance instance) populate,
  bool archived = false,
}) async {
  final caseIndex = _seedIndex++;
  try {
    // TODO: createNew may persist immediately in some repos; consider lazy-create pattern
    // to avoid redundant writes. For now, we accept create + update as two writes.
    final record = repo.createNew(def);
    record.title = title;
    
    // Populate form values
    populate(record.formInstance);
    
    // Persist the populated case (single update after population)
    repo.update(record);
    
    // Archive if needed
    if (archived) {
      repo.archive(record.id, true);
    }
    
    _safeLogDebug('Seeded case #$caseIndex id=${record.id} template=${def.id} archived=$archived');
  } on _SeedDataException catch (e) {
    _safeLogWarn('Seed data error for case #$caseIndex: ${e.message}');
  } on FileLockException catch (e) {
    _safeLogWarn('Lock contention seeding case #$caseIndex: ${e.message}');
  } catch (e) {
    _safeLogWarn('Failed to seed case #$caseIndex: ${e.runtimeType}');
  }
}

/// Counter for seeded cases (avoids logging titles which may be sensitive)
int _seedIndex = 0;

/// Exception thrown when seed data operations fail (e.g., group instance creation).
class _SeedDataException implements Exception {
  final String message;
  _SeedDataException(this.message);
  @override
  String toString() => 'SeedDataException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// Group Instance Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the first existing group instance, or creates one if none exist.
/// Works regardless of addGroupInstance return type.
/// Throws _SeedDataException if creation fails.
GroupInstance _ensureGroupInstance(FormInstance instance, String groupId) {
  final existing = instance.getGroupInstances(groupId);
  if (existing.isNotEmpty) {
    return existing.first;
  }
  instance.addGroupInstance(groupId);
  final afterAdd = instance.getGroupInstances(groupId);
  if (afterAdd.isEmpty) {
    final msg = 'Failed to create group instance for groupId=$groupId '
        '(possibly maxInstances constraint or missing group definition)';
    _safeLogWarn(msg);
    throw _SeedDataException(msg);
  }
  return afterAdd.first;
}

/// Adds a new group instance and returns it.
/// Works regardless of addGroupInstance return type.
/// Throws _SeedDataException if addition fails.
GroupInstance _addNewGroupInstance(FormInstance instance, String groupId) {
  final countBefore = instance.getGroupInstances(groupId).length;
  instance.addGroupInstance(groupId);
  final allInstances = instance.getGroupInstances(groupId);
  final countAfter = allInstances.length;
  
  if (countAfter <= countBefore) {
    final msg = 'Failed to add new group instance for groupId=$groupId '
        '(countBefore=$countBefore, countAfter=$countAfter)';
    _safeLogWarn(msg);
    throw _SeedDataException(msg);
  }
  
  // Return the newly added instance (last one)
  return allInstances.last;
}

// ─────────────────────────────────────────────────────────────────────────────
// Safe Logging Helpers
// ─────────────────────────────────────────────────────────────────────────────

void _safeLog(String message) {
  try {
    AppLogger.instance.info('seed', message);
  } catch (_) {
    // Logging must never throw
  }
}

void _safeLogDebug(String message) {
  try {
    AppLogger.instance.debug('seed', message);
  } catch (_) {
    // Logging must never throw
  }
}

void _safeLogWarn(String message) {
  try {
    AppLogger.instance.warn('seed', message);
  } catch (_) {
    // Logging must never throw
  }
}
