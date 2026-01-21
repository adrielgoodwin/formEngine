import '../models/case_record.dart';
import '../models/form_definition.dart';
import '../models/form_instance.dart';
import '../data/case_repository.dart';

Future<void> seedDemoCases(FormDefinition def, InMemoryCaseRepository repo) async {
  // A) Almost Empty
  var instance1 = FormInstance.emptyFromDefinition(def);
  instance1.setValue('deceased_name', 'John Doe');
  instance1.setValue('deceased_dob', '01/01/1950');
  instance1.setValue('deceased_dod', '15/12/2023');
  instance1.setValue('deceased_sin', '123456789');
  instance1.setValue('deceased_marital_status', [true, false, false, false, false, false]); // Married
  var case1 = CaseRecord.create(
    definitionId: def.id,
    schemaVersion: def.schemaVersion,
    formInstance: instance1,
    title: 'Almost Empty',
  );
  repo.update(case1);

  // B) Basic Complete
  var instance2 = FormInstance.emptyFromDefinition(def);
  instance2.setValue('deceased_name', 'Jane Smith');
  instance2.setValue('deceased_dob', '01/01/1950');
  instance2.setValue('deceased_dod', '15/12/2023');
  instance2.setValue('deceased_sin', '123456789');
  instance2.setValue('deceased_marital_status', [true, false, false, false, false, false]); // Married
  var case2 = CaseRecord.create(
    definitionId: def.id,
    schemaVersion: def.schemaVersion,
    formInstance: instance2,
    title: 'Jane Smith',
  );
  repo.update(case2);

  // C) Complex Estate
  var instance3 = FormInstance.emptyFromDefinition(def);
  instance3.setValue('deceased_name', 'Robert Johnson');
  instance3.setValue('deceased_sin', '987654321');
  instance3.setValue('deceased_marital_status', [true, false, false, false, false, false]); // Married
  instance3.setValue('partner_name', 'Alice Johnson');
  instance3.setValue('partner_dob', '02/02/1952');
  instance3.setValue('partner_sin', '123123123');
  // Add RRSP 1 (use existing minInstances=1 instance first)
  final rrspInstances = instance3.getGroupInstances('rrsp_account_group');
  final rrspInst1 = rrspInstances.isNotEmpty ? rrspInstances.first : instance3.addGroupInstance('rrsp_account_group');
  instance3.setGroupValue('rrsp_account_group', rrspInst1.instanceId, 'rrsp_institution', 'TD Bank');
  instance3.setGroupValue('rrsp_account_group', rrspInst1.instanceId, 'rrsp_account_number', '123456789');
  instance3.setGroupValue('rrsp_account_group', rrspInst1.instanceId, 'rrsp_value', 500000); // $5,000.00
  // Add RRSP 2
  var rrspInst2 = instance3.addGroupInstance('rrsp_account_group');
  instance3.setGroupValue('rrsp_account_group', rrspInst2.instanceId, 'rrsp_institution', 'BMO');
  instance3.setGroupValue('rrsp_account_group', rrspInst2.instanceId, 'rrsp_account_number', '987654321');
  instance3.setGroupValue('rrsp_account_group', rrspInst2.instanceId, 'rrsp_value', 250000); // $2,500.00
  // Add Non-Registered (use existing minInstances=1 instance first)
  final nonRegInstances = instance3.getGroupInstances('nonreg_account_group');
  final nonRegInst = nonRegInstances.isNotEmpty ? nonRegInstances.first : instance3.addGroupInstance('nonreg_account_group');
  instance3.setGroupValue('nonreg_account_group', nonRegInst.instanceId, 'nonreg_institution', 'Scotiabank');
  instance3.setGroupValue('nonreg_account_group', nonRegInst.instanceId, 'nonreg_account_number', '111222333');
  // Add Real Estate (use existing minInstances=1 instance first)
  final realEstInstances = instance3.getGroupInstances('realestate_group');
  final realEstInst = realEstInstances.isNotEmpty ? realEstInstances.first : instance3.addGroupInstance('realestate_group');
  instance3.setGroupValue('realestate_group', realEstInst.instanceId, 'realestate_address', '123 Main St, Toronto, ON M5V 1A1');
  var case3 = CaseRecord.create(
    definitionId: def.id,
    schemaVersion: def.schemaVersion,
    formInstance: instance3,
    title: 'Robert Johnson',
  );
  repo.update(case3);

  // D) Edge Values
  var instance4 = FormInstance.emptyFromDefinition(def);
  instance4.setValue('deceased_name', 'Edge Case Tester');
  instance4.setValue('deceased_dob', '31/12/1999');
  instance4.setValue('deceased_dod', '19/01/2026'); // Near today, not future
  instance4.setValue('deceased_sin', '000000000');
  instance4.setValue('deceased_marital_status', [false, false, true, false, false]); // Single
  // Add RRSP with large balance (use existing minInstances=1 instance first)
  final rrspEdgeInstances = instance4.getGroupInstances('rrsp_account_group');
  final rrspEdge = rrspEdgeInstances.isNotEmpty ? rrspEdgeInstances.first : instance4.addGroupInstance('rrsp_account_group');
  instance4.setGroupValue('rrsp_account_group', rrspEdge.instanceId, 'rrsp_institution', 'Bank of Edge Cases');
  instance4.setGroupValue('rrsp_account_group', rrspEdge.instanceId, 'rrsp_account_number', '999999999999999'); // Very long
  instance4.setGroupValue('rrsp_account_group', rrspEdge.instanceId, 'rrsp_value', 999999999); // Large cents $9,999,999.99
  var case4 = CaseRecord.create(
    definitionId: def.id,
    schemaVersion: def.schemaVersion,
    formInstance: instance4,
    title: 'Edge Case Tester',
  );
  repo.update(case4);

  // E) Archived Case
  var instance5 = FormInstance.emptyFromDefinition(def);
  instance5.setValue('deceased_name', 'Archived Person');
  instance5.setValue('deceased_sin', '555555555');
  var case5 = CaseRecord.create(
    definitionId: def.id,
    schemaVersion: def.schemaVersion,
    formInstance: instance5,
    title: 'Archived Person',
  );
  repo.update(case5);
  repo.archive(case5.id, true);

  // F) Comprehensive - Ardal Allgood (Everything Filled Out)
  var instance6 = FormInstance.emptyFromDefinition(def);
  
  // ===== BASIC DECEASED INFO =====
  instance6.setValue('deceased_name', 'Ardal Allgood');
  instance6.setValue('deceased_dob', '15/03/1945');
  instance6.setValue('deceased_dod', '22/11/2023');
  instance6.setValue('deceased_sin', '123456789');
  instance6.setValue('deceased_marital_status', [true, false, false, false, false, false]); // Married

  // ===== PARTNER INFO =====
  instance6.setValue('partner_name', 'Margaret Allgood');
  instance6.setValue('partner_dob', '08/07/1948');
  instance6.setValue('partner_sin', '987654321');
  instance6.setValue('partner_address', '742 Evergreen Terrace, Springfield, ON L1A 2B3');

  // ===== MULTIPLE EXECUTORS =====
  final executorInstances = instance6.getGroupInstances('executor_other_info');
  final executor1 = executorInstances.isNotEmpty ? executorInstances.first : instance6.addGroupInstance('executor_other_info');
  instance6.setGroupValue('executor_other_info', executor1.instanceId, 'executor_name', 'James Allgood');
  instance6.setGroupValue('executor_other_info', executor1.instanceId, 'executor_address', '123 Main St, Toronto, ON M5V 1A1');
  instance6.setGroupValue('executor_other_info', executor1.instanceId, 'executor_contact', 'james.allgood@email.com, (416) 555-0123');
  instance6.setGroupValue('executor_other_info', executor1.instanceId, 'executor_wants_compensation', [true, false]); // Yes
  instance6.setGroupValue('executor_other_info', executor1.instanceId, 'executor_sin', '111222333');
  instance6.setGroupValue('executor_other_info', executor1.instanceId, 'executor_income_notes', 'Professional accountant with 25+ years experience');

  final executor2 = instance6.addGroupInstance('executor_other_info');
  instance6.setGroupValue('executor_other_info', executor2.instanceId, 'executor_name', 'Sarah Allgood');
  instance6.setGroupValue('executor_other_info', executor2.instanceId, 'executor_address', '456 Oak Ave, Toronto, ON M4B 2C4');
  instance6.setGroupValue('executor_other_info', executor2.instanceId, 'executor_contact', 'sarah.allgood@email.com, (416) 555-0456');
  instance6.setGroupValue('executor_other_info', executor2.instanceId, 'executor_wants_compensation', [false, true]); // No

  // ===== PROFESSIONALS =====
  instance6.setValue('professionals_involved', [true, true]); // Both Lawyer and Investment Advisor
  instance6.setValue('lawyer_name', 'Robert Thompson');
  instance6.setValue('lawyer_firm_phone', '(416) 555-1000');
  instance6.setValue('lawyer_firm_email', 'info@thompsonlaw.com');
  instance6.setValue('lawyer_rep_phone', '(416) 555-1001');
  instance6.setValue('lawyer_rep_email', 'r.thompson@thompsonlaw.com');

  // Advisor details
  instance6.setValue('advisor_name', 'Jennifer Walsh');
  instance6.setValue('advisor_firm_phone', '(416) 555-2000');
  instance6.setValue('advisor_firm_email', 'info@walshinvestments.com');
  instance6.setValue('advisor_rep_phone', '(416) 555-2001');
  instance6.setValue('advisor_rep_email', 'j.walsh@walshinvestments.com');

  // ===== RRN FIELDS - ALL CHECKED WITH NOTES =====
  instance6.setValue('retrieve_death_cert_requested', [true]);
  instance6.setValue('retrieve_death_cert_received', [true]);
  instance6.setValue('retrieve_death_cert_notes', 'Death certificate obtained from ServiceOntario, original filed with estate documents');

  instance6.setValue('retrieve_will_requested', [true]);
  instance6.setValue('retrieve_will_received', [true]);
  instance6.setValue('retrieve_will_notes', 'Last will and testament dated 2020-03-15, stored in safety deposit box at TD Bank');

  instance6.setValue('retrieve_assets_requested', [true]);
  instance6.setValue('retrieve_assets_received', [true]);
  instance6.setValue('retrieve_assets_notes', 'Complete asset list compiled from bank statements, investment accounts, and property records');

  instance6.setValue('retrieve_estate_return_requested', [true]);
  instance6.setValue('retrieve_estate_return_received', [true]);
  instance6.setValue('retrieve_estate_return_notes', 'Estate Information Return filed with CRA, reference number ER2023-456789');

  // ===== MULTIPLE RRSP ACCOUNTS =====
  final rrspInstances6 = instance6.getGroupInstances('rrsp_account_group');
  final rrsp1 = rrspInstances6.isNotEmpty ? rrspInstances6.first : instance6.addGroupInstance('rrsp_account_group');
  instance6.setGroupValue('rrsp_account_group', rrsp1.instanceId, 'rrsp_institution', 'TD Bank');
  instance6.setGroupValue('rrsp_account_group', rrsp1.instanceId, 'rrsp_account_number', 'RRSP-123456789');
  instance6.setGroupValue('rrsp_account_group', rrsp1.instanceId, 'rrsp_value', 50000000); // $500,000.00
  instance6.setGroupValue('rrsp_account_group', rrsp1.instanceId, 'rrsp_has_beneficiary', [false, true]); // No beneficiary

  final rrsp2 = instance6.addGroupInstance('rrsp_account_group');
  instance6.setGroupValue('rrsp_account_group', rrsp2.instanceId, 'rrsp_institution', 'RBC Royal Bank');
  instance6.setGroupValue('rrsp_account_group', rrsp2.instanceId, 'rrsp_account_number', 'RRSP-987654321');
  instance6.setGroupValue('rrsp_account_group', rrsp2.instanceId, 'rrsp_value', 75000000); // $750,000.00
  instance6.setGroupValue('rrsp_account_group', rrsp2.instanceId, 'rrsp_has_beneficiary', [true, false]); // Has beneficiary

  // ===== NON-REGISTERED ACCOUNTS =====
  final nonRegInstances6 = instance6.getGroupInstances('nonreg_account_group');
  final nonReg1 = nonRegInstances6.isNotEmpty ? nonRegInstances6.first : instance6.addGroupInstance('nonreg_account_group');
  instance6.setGroupValue('nonreg_account_group', nonReg1.instanceId, 'nonreg_institution', 'BMO');
  instance6.setGroupValue('nonreg_account_group', nonReg1.instanceId, 'nonreg_account_number', 'TFSA-111222333');
  instance6.setGroupValue('nonreg_account_group', nonReg1.instanceId, 'nonreg_gain_loss', 2500000); // $25,000.00 gain
  instance6.setGroupValue('nonreg_account_group', nonReg1.instanceId, 'nonreg_has_dividends', [true, false]); // Has dividends

  // ===== OTHER ASSETS =====
  final assetInstances = instance6.getGroupInstances('asset_group');
  final asset1 = assetInstances.isNotEmpty ? assetInstances.first : instance6.addGroupInstance('asset_group');
  instance6.setGroupValue('asset_group', asset1.instanceId, 'asset_description', 'Antique car collection (3 vehicles)');
  instance6.setGroupValue('asset_group', asset1.instanceId, 'asset_value', 12500000); // $125,000.00

  final asset2 = instance6.addGroupInstance('asset_group');
  instance6.setGroupValue('asset_group', asset2.instanceId, 'asset_description', 'Art collection and jewelry');
  instance6.setGroupValue('asset_group', asset2.instanceId, 'asset_value', 7500000); // $75,000.00

  // ===== SHARES NOTES =====
  instance6.setValue('shares_notes', 'Investment portfolio includes shares in major Canadian banks and energy companies, valued at approximately \$150,000 at time of death');

  // ===== MULTIPLE REAL ESTATE =====
  final realEstInstances6 = instance6.getGroupInstances('realestate_group');
  
  // Principal residence
  final realEst1 = realEstInstances6.isNotEmpty ? realEstInstances6.first : instance6.addGroupInstance('realestate_group');
  instance6.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_is_principal', [true, false]); // Principal residence
  instance6.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_address', '742 Evergreen Terrace, Springfield, ON L1A 2B3');
  instance6.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_principal_year', '1985');
  instance6.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_principal_value', 85000000); // $850,000.00
  instance6.setGroupValue('realestate_group', realEst1.instanceId, 'realestate_principal_notes', 'Primary residence for 38 years, recently renovated kitchen and bathrooms');

  // Non-principal residence 1
  final realEst2 = instance6.addGroupInstance('realestate_group');
  instance6.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_is_principal', [false, true]); // Not principal
  instance6.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_address', '123 Cottage Lane, Muskoka, ON P1A 2B3');
  instance6.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_year_of_purchase', '2005');
  instance6.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_purchase_price', 45000000); // $450,000.00
  instance6.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_value_at_death', 67500000); // $675,000.00
  instance6.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_ownership_history_notes', 'Purchased in 2005, used as vacation property');
  instance6.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_significant_improvements_notes', 'Added deck and hot tub in 2010, renovated basement in 2018');
  instance6.setGroupValue('realestate_group', realEst2.instanceId, 'realestate_other_whats_happening_notes', 'Currently listed for sale, expected to close in March 2024');

  // ===== ADDITIONAL RRN DOCUMENTS =====
  instance6.setValue('docs_tax_returns_requested', [true]);
  instance6.setValue('docs_tax_returns_received', [true]);
  instance6.setValue('docs_tax_returns_notes', 'Tax returns for 2020, 2021, and 2022 obtained from accountant');

  instance6.setValue('docs_donations_requested', [true]);
  instance6.setValue('docs_donations_received', [true]);
  instance6.setValue('docs_donations_notes', 'Charitable donation receipts totaling \$25,000 in 2023');

  instance6.setValue('docs_medical_receipts_requested', [true]);
  instance6.setValue('docs_medical_receipts_received', [true]);
  instance6.setValue('docs_medical_receipts_notes', 'Medical expense receipts for tax purposes, \$12,500 claimed');

  var case6 = CaseRecord.create(
    definitionId: def.id,
    schemaVersion: def.schemaVersion,
    formInstance: instance6,
    title: 'Ardal Allgood',
  );
  repo.update(case6);
}
