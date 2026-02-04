import '../models/form_definition.dart';
import '../models/form_block.dart';
import '../models/form_node.dart';
import '../models/layout_item.dart';
import '../models/node_group_definition.dart';
import '../models/visibility_condition.dart';
import 'validate_form_definition.dart';

// =============================================================================
// CANONICAL NODE ID NAMING SCHEME
// =============================================================================
// All node IDs follow these conventions:
//
// BASE FIELDS (not in repeatable groups):
//   deceased_*      : Deceased person info (deceased_name, deceased_dob, deceased_dod, deceased_sin)
//   partner_*       : Partner/spouse info (partner_name, partner_dob, partner_sin, partner_address)
//   executor_*      : Executor info (executor_name, executor_address, executor_contact, etc.)
//   lawyer_*        : Lawyer contact info
//   advisor_*       : Investment advisor contact (shortened from investment_advisor_*)
//   professionals_* : Which professionals involved
//
// RRN (Requested/Received/Notes) FIELDS:
//   retrieve_*      : Things to retrieve (retrieve_death_cert_*, retrieve_will_*, etc.)
//   docs_*          : Other documents (docs_tax_returns_*, docs_donations_*, docs_medical_*)
//
// GROUP-SCOPED FIELDS (used within repeatable groups):
//   rrsp_*          : RRSP account group (rrsp_institution, rrsp_account_number, rrsp_value, etc.)
//   nonreg_*        : Non-registered account group (nonreg_institution, nonreg_account_number, etc.)
//   realestate_*    : Real estate group (realestate_address, realestate_is_principal, etc.)
//   asset_*         : Other assets group (asset_description, asset_value)
//
// GROUP IDs:
//   executor_group, rrsp_group, nonreg_group, realestate_group, asset_group
// =============================================================================

List<LayoutItem> rrnChildren(String baseId) {
  return [
    LayoutRow(
      id: '${baseId}_rrn_row',
      children: [
        LayoutNodeRef(
          id: '${baseId}_requested_ref',
          nodeId: '${baseId}_requested',
          widthFraction: 0.12,
        ),
        LayoutNodeRef(
          id: '${baseId}_received_ref',
          nodeId: '${baseId}_received',
          widthFraction: 0.12,
        ),
        LayoutNodeRef(
          id: '${baseId}_notes_ref',
          nodeId: '${baseId}_notes',
          widthFraction: 0.76,
        ),
      ],
    ),
  ];
}

Future<FormDefinition> loadFormDefinition() async {
  final definition = FormDefinition(
    id: 'estate_intake_v1',
    title: 'Estate Intake',
    schemaVersion: 1,
    nodes: {
      // ===== Block 1 — Deceased Information =====
      'deceased_name': TextInputNode(
        id: 'deceased_name',
        label: 'Full Name',
      ),
      'deceased_dob': TextInputNode(
        id: 'deceased_dob',
        label: 'Date of Birth',
      ),
      'deceased_dod': TextInputNode(
        id: 'deceased_dod',
        label: 'Date of Death',
      ),
      'deceased_sin': TextInputNode(
        id: 'deceased_sin',
        label: 'SIN',
      ),
      'deceased_marital_status': ChoiceInputNode(
        id: 'deceased_marital_status',
        label: 'Marital Status',
        choiceLabels: [
          'Married',
          'Common-law',
          'Widowed',
          'Divorced',
          'Separated',
          'Single',
        ],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'deceased_notes': TextInputNode(
        id: 'deceased_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'partner_name': TextInputNode(
        id: 'partner_name',
        label: 'Partner Full Name',
      ),
      'partner_dob': TextInputNode(
        id: 'partner_dob',
        label: 'Partner DOB',
      ),
      'partner_sin': TextInputNode(
        id: 'partner_sin',
        label: 'Partner SIN',
      ),
      'partner_address': TextInputNode(
        id: 'partner_address',
        label: 'Partner Address',
        multiLine: true,
      ),

      // ===== Block 2 — Trustee and Contact Persons =====
      'meeting_type': ChoiceInputNode(
        id: 'meeting_type',
        label: 'Meeting Type',
        choiceLabels: ['In person', 'Telephone', 'Zoom'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'meeting_attendees': ChoiceInputNode(
        id: 'meeting_attendees',
        label: 'Attendees',
        choiceLabels: ['MM', 'DG', 'EL', 'Other'],
        choiceCardinality: ChoiceCardinality.multiple,
      ),
      'meeting_other_attendees': TextInputNode(
        id: 'meeting_other_attendees',
        label: 'Other attendee',
      ),
      'trustee_name': TextInputNode(
        id: 'trustee_name',
        label: 'Full Name',
      ),
      'trustee_relationship': TextInputNode(
        id: 'trustee_relationship',
        label: 'Relationship to deceased',
      ),
      'trustee_address': TextInputNode(
        id: 'trustee_address',
        label: 'Address',
        multiLine: true,
      ),
      'trustee_contact': TextInputNode(
        id: 'trustee_contact',
        label: 'Contact Info (email / phone)',
      ),
      'trustee_wants_compensation': ChoiceInputNode(
        id: 'trustee_wants_compensation',
        label: 'Trustee Compensation',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'trustee_sin': TextInputNode(
        id: 'trustee_sin',
        label: 'SIN',
      ),
      'trustee_income_notes': TextInputNode(
        id: 'trustee_income_notes',
        label: 'Income Notes (DOB, CPP, RSP)',
        multiLine: true,
      ),
      'trustee_is_other_person': ChoiceInputNode(
        id: 'trustee_is_other_person',
        label: 'Other person?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'trustee_relationship_to_trustee': TextInputNode(
        id: 'trustee_relationship_to_trustee',
        label: 'Relationship to trustee',
      ),
      'trustee_is_trustee': ChoiceInputNode(
        id: 'trustee_is_trustee',
        label: 'Trustee?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'trustee_notes': TextInputNode(
        id: 'trustee_notes',
        label: 'Notes',
        multiLine: true,
      ),

      // ===== Block 3 — Other Professionals (Repeatable) =====
      'professional_profession': TextInputNode(
        id: 'professional_profession',
        label: 'Profession',
      ),
      'professional_name': TextInputNode(
        id: 'professional_name',
        label: 'Name',
      ),
      'professional_email': TextInputNode(
        id: 'professional_email',
        label: 'Email',
      ),
      'professional_phone': TextInputNode(
        id: 'professional_phone',
        label: 'Phone',
      ),
      'professional_notes': TextInputNode(
        id: 'professional_notes',
        label: 'Notes',
        multiLine: true,
      ),

      // ===== Block 4 — Documents (RRN) =====
      'docs_death_cert_requested': ChoiceInputNode(
        id: 'docs_death_cert_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_death_cert_received': ChoiceInputNode(
        id: 'docs_death_cert_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_death_cert_notes': TextInputNode(
        id: 'docs_death_cert_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'docs_will_requested': ChoiceInputNode(
        id: 'docs_will_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_will_received': ChoiceInputNode(
        id: 'docs_will_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_will_notes': TextInputNode(
        id: 'docs_will_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'docs_probate_requested': ChoiceInputNode(
        id: 'docs_probate_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_probate_received': ChoiceInputNode(
        id: 'docs_probate_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_probate_notes': TextInputNode(
        id: 'docs_probate_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'docs_assets_requested': ChoiceInputNode(
        id: 'docs_assets_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_assets_received': ChoiceInputNode(
        id: 'docs_assets_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_assets_notes': TextInputNode(
        id: 'docs_assets_notes',
        label: 'Joint ownerships, named beneficiaries, beneficial ownerships, recent transfers',
        multiLine: true,
      ),

      // ===== Block 5 — Asset Details =====
      'rrsp_value': TextInputNode(
        id: 'rrsp_value',
        label: 'Value at Death',
      ),
      'rrsp_has_beneficiary': ChoiceInputNode(
        id: 'rrsp_has_beneficiary',
        label: 'Named Beneficiary?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'rrsp_liquidation_requested': ChoiceInputNode(
        id: 'rrsp_liquidation_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'rrsp_liquidation_received': ChoiceInputNode(
        id: 'rrsp_liquidation_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'rrsp_liquidation_notes': TextInputNode(
        id: 'rrsp_liquidation_notes',
        label: 'Notes',
        multiLine: true,
      ),

      'nonreg_value_at_death': TextInputNode(
        id: 'nonreg_value_at_death',
        label: 'Value at death',
      ),
      'nonreg_gain_loss': TextInputNode(
        id: 'nonreg_gain_loss',
        label: 'Unrealized gain / loss at death',
      ),
      'nonreg_yod_requested': ChoiceInputNode(
        id: 'nonreg_yod_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'nonreg_yod_received': ChoiceInputNode(
        id: 'nonreg_yod_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'nonreg_yod_notes': TextInputNode(
        id: 'nonreg_yod_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'nonreg_liquidation_requested': ChoiceInputNode(
        id: 'nonreg_liquidation_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'nonreg_liquidation_received': ChoiceInputNode(
        id: 'nonreg_liquidation_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'nonreg_liquidation_notes': TextInputNode(
        id: 'nonreg_liquidation_notes',
        label: 'Notes',
        multiLine: true,
      ),

      'share_company_name': TextInputNode(
        id: 'share_company_name',
        label: 'Company name',
      ),
      'share_number_of_shares': TextInputNode(
        id: 'share_number_of_shares',
        label: 'Number of shares',
      ),
      'share_notes': TextInputNode(
        id: 'share_notes',
        label: 'History, DRIP, Reinvested, Cash',
        multiLine: true,
      ),
      'asset_notes': TextInputNode(
        id: 'asset_notes',
        label: 'Notes',
        multiLine: true,
      ),

      'rrsp_institution': TextInputNode(
        id: 'rrsp_institution',
        label: 'Institution',
      ),
      'rrsp_account_number': TextInputNode(
        id: 'rrsp_account_number',
        label: 'Account Number',
      ),

      'nonreg_institution': TextInputNode(
        id: 'nonreg_institution',
        label: 'Institution',
      ),
      'nonreg_account_number': TextInputNode(
        id: 'nonreg_account_number',
        label: 'Account Number',
      ),

      'realestate_is_principal': ChoiceInputNode(
        id: 'realestate_is_principal',
        label: 'Principal Residence?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'realestate_principal_year': TextInputNode(
        id: 'realestate_principal_year',
        label: 'Year of Purchase',
      ),
      'realestate_principal_value': TextInputNode(
        id: 'realestate_principal_value',
        label: 'Value at Death',
      ),
      'realestate_principal_notes': TextInputNode(
        id: 'realestate_principal_notes',
        label: "What's happening",
        multiLine: true,
      ),
      'realestate_principal_all_years': ChoiceInputNode(
        id: 'realestate_principal_all_years',
        label: 'Principal residence for all years owned?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'realestate_principal_all_years_notes': TextInputNode(
        id: 'realestate_principal_all_years_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'realestate_other_year_of_purchase': TextInputNode(
        id: 'realestate_other_year_of_purchase',
        label: 'Year of Purchase',
      ),
      'realestate_other_purchase_price': TextInputNode(
        id: 'realestate_other_purchase_price',
        label: 'Purchase Price',
      ),
      'realestate_other_value_at_death': TextInputNode(
        id: 'realestate_other_value_at_death',
        label: 'Value at Death',
      ),
      'realestate_capital_improvements': TextInputNode(
        id: 'realestate_capital_improvements',
        label: 'Capital improvements',
        multiLine: true,
      ),
      'realestate_ownership_tax_history': TextInputNode(
        id: 'realestate_ownership_tax_history',
        label: 'Ownership / tax history (1994 election, 1972 FMV / RTC)',
        multiLine: true,
      ),
      'realestate_other_whats_happening_notes': TextInputNode(
        id: 'realestate_other_whats_happening_notes',
        label: "What's happening",
        multiLine: true,
      ),

      'realestate_address': TextInputNode(
        id: 'realestate_address',
        label: 'Address',
        multiLine: true,
      ),

      'asset_description': TextInputNode(
        id: 'asset_description',
        label: 'Description',
      ),
      'asset_value': TextInputNode(
        id: 'asset_value',
        label: 'Value',
      ),

      // Real estate (repeatable group will reuse these node IDs)

      // ===== Block 6 — Tax History =====
      'tax_gph_client': ChoiceInputNode(
        id: 'tax_gph_client',
        label: 'GPH Client?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'tax_gph_notes': TextInputNode(
        id: 'tax_gph_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'tax_returns_requested': ChoiceInputNode(
        id: 'tax_returns_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'tax_returns_received': ChoiceInputNode(
        id: 'tax_returns_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'tax_returns_notes': TextInputNode(
        id: 'tax_returns_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'tax_income_types': ChoiceInputNode(
        id: 'tax_income_types',
        label: 'Income Types',
        choiceLabels: ['CPP', 'T4', 'OAS', 'T5', 'T3', 'Foreign Pension', 'T4A', 'RRIF', 'Other'],
        choiceCardinality: ChoiceCardinality.multiple,
      ),
      'tax_income_notes': TextInputNode(
        id: 'tax_income_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'tax_credits': ChoiceInputNode(
        id: 'tax_credits',
        label: 'Tax credits/deductions',
        choiceLabels: ['Donations', 'Medical', 'DTC', 'Other'],
        choiceCardinality: ChoiceCardinality.multiple,
      ),
      'tax_credits_other_notes': TextInputNode(
        id: 'tax_credits_other_notes',
        label: 'Other notes',
      ),
      'tax_credits_notes': TextInputNode(
        id: 'tax_credits_notes',
        label: 'Notes',
        multiLine: true,
      ),
    },
    groups: {

      'trustee_group': NodeGroupDefinition(
        id: 'trustee_group',
        label: 'Trustee/Contact Person',
        repeatable: true,
        minInstances: 1,
        children: [
          // Trustee? Yes/No as first field
          LayoutNodeRef(
            id: 'trustee_is_trustee_ref',
            nodeId: 'trustee_is_trustee',
            widthFraction: 0.3,
          ),
          LayoutRow(
            id: 'trustee_row_1',
            children: [
              LayoutNodeRef(
                id: 'trustee_name_ref',
                nodeId: 'trustee_name',
                widthFraction: 0.4,
              ),
              LayoutNodeRef(
                id: 'trustee_relationship_ref',
                nodeId: 'trustee_relationship',
                widthFraction: 0.3,
              ),
              LayoutNodeRef(
                id: 'trustee_contact_ref',
                nodeId: 'trustee_contact',
                widthFraction: 0.3,
              ),
            ],
          ),
          LayoutNodeRef(
            id: 'trustee_address_ref',
            nodeId: 'trustee_address',
            widthFraction: 1.0,
          ),
          // Compensation section - only visible when Trustee? = Yes
          LayoutGroup(
            id: 'trustee_compensation_section',
            label: '',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'trustee_is_trustee',
              choiceIndex: 0, // Yes
              expectedValue: true,
            ),
            children: [
              LayoutRow(
                id: 'trustee_compensation_row',
                children: [
                  LayoutNodeRef(
                    id: 'trustee_compensation_ref',
                    nodeId: 'trustee_wants_compensation',
                    widthFraction: 0.3,
                  ),
                  LayoutGroup(
                    id: 'trustee_compensation_details_inline',
                    label: '',
                    visibilityCondition: const ChoiceEqualsCondition(
                      nodeId: 'trustee_wants_compensation',
                      choiceIndex: 0,
                      expectedValue: true,
                    ),
                    children: [
                      LayoutNodeRef(
                        id: 'trustee_sin_ref',
                        nodeId: 'trustee_sin',
                        widthFraction: 0.3,
                      ),
                      LayoutNodeRef(
                        id: 'trustee_income_notes_ref',
                        nodeId: 'trustee_income_notes',
                        widthFraction: 0.4,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          LayoutRow(
            id: 'trustee_other_person_row',
            children: [
              LayoutNodeRef(
                id: 'trustee_other_person_ref',
                nodeId: 'trustee_is_other_person',
                widthFraction: 0.3,
              ),
              LayoutGroup(
                id: 'trustee_other_person_details_inline',
                label: '',
                visibilityCondition: const ChoiceEqualsCondition(
                  nodeId: 'trustee_is_other_person',
                  choiceIndex: 0,
                  expectedValue: true,
                ),
                children: [
                  LayoutNodeRef(
                    id: 'trustee_relationship_to_trustee_ref',
                    nodeId: 'trustee_relationship_to_trustee',
                    widthFraction: 0.7,
                  ),
                ],
              ),
            ],
          ),
          // Notes field at end of each trustee entry
          LayoutNodeRef(
            id: 'trustee_notes_ref',
            nodeId: 'trustee_notes',
            widthFraction: 1.0,
          ),
        ],
      ),

      'professional_group': NodeGroupDefinition(
        id: 'professional_group',
        label: 'Professional',
        repeatable: true,
        minInstances: 0,
        children: [
          LayoutRow(
            id: 'professional_row_1',
            children: [
              LayoutNodeRef(
                id: 'professional_profession_ref',
                nodeId: 'professional_profession',
                widthFraction: 0.4,
              ),
              LayoutNodeRef(
                id: 'professional_name_ref',
                nodeId: 'professional_name',
                widthFraction: 0.6,
              ),
            ],
          ),
          LayoutRow(
            id: 'professional_row_2',
            children: [
              LayoutNodeRef(
                id: 'professional_email_ref',
                nodeId: 'professional_email',
                widthFraction: 0.5,
              ),
              LayoutNodeRef(
                id: 'professional_phone_ref',
                nodeId: 'professional_phone',
                widthFraction: 0.5,
              ),
            ],
          ),
          // Notes field at end of each professional entry
          LayoutNodeRef(
            id: 'professional_notes_ref',
            nodeId: 'professional_notes',
            widthFraction: 1.0,
          ),
        ],
      ),

      'docs_death_cert_rrn': NodeGroupDefinition(
        id: 'docs_death_cert_rrn',
        label: 'Death Certificate',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('docs_death_cert'),
      ),
      'docs_will_rrn': NodeGroupDefinition(
        id: 'docs_will_rrn',
        label: 'Will',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('docs_will'),
      ),
      'docs_probate_rrn': NodeGroupDefinition(
        id: 'docs_probate_rrn',
        label: 'Probate',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('docs_probate'),
      ),
      'docs_assets_rrn': NodeGroupDefinition(
        id: 'docs_assets_rrn',
        label: 'Complete List of Assets',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('docs_assets'),
      ),
      'tax_returns_rrn': NodeGroupDefinition(
        id: 'tax_returns_rrn',
        label: 'Tax returns – previous 2 years',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('tax_returns'),
      ),

      'rrsp_liquidation': NodeGroupDefinition(
        id: 'rrsp_liquidation',
        label: 'Statement for month of liquidation',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('rrsp_liquidation'),
      ),
      'nonreg_yod': NodeGroupDefinition(
        id: 'nonreg_yod',
        label: 'Statements, year of death',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('nonreg_yod'),
      ),
      'nonreg_liquidation': NodeGroupDefinition(
        id: 'nonreg_liquidation',
        label: 'Statements, to liquidation',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('nonreg_liquidation'),
      ),

      'rrsp_account_group': NodeGroupDefinition(
        id: 'rrsp_account_group',
        label: 'RRSP / RIFF Account',
        repeatable: true,
        minInstances: 0,
        children: [
          LayoutRow(
            id: 'rrsp_account_institution_row',
            children: [
              LayoutNodeRef(
                id: 'rrsp_account_group_institution_ref',
                nodeId: 'rrsp_institution',
                widthFraction: 0.5,
              ),
              LayoutNodeRef(
                id: 'rrsp_account_group_account_number_ref',
                nodeId: 'rrsp_account_number',
                widthFraction: 0.5,
              ),
            ],
          ),
          LayoutRow(
            id: 'rrsp_account_row',
            children: [
              LayoutNodeRef(
                id: 'rrsp_riff_value_at_death_ref',
                nodeId: 'rrsp_value',
                widthFraction: 0.6,
              ),
              LayoutNodeRef(
                id: 'rrsp_riff_named_beneficiary_ref',
                nodeId: 'rrsp_has_beneficiary',
                widthFraction: 0.4,
              ),
            ],
          ),
          LayoutGroup(
            id: 'rrsp_statement_group_no_beneficiary',
            label: 'Statement for month of liquidation',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'rrsp_has_beneficiary',
              choiceIndex: 1,
              expectedValue: true,
            ),
            groupId: 'rrsp_liquidation',
            children: const [],
          ),
        ],
      ),
      'nonreg_account_group': NodeGroupDefinition(
        id: 'nonreg_account_group',
        label: 'Non-Registered Account',
        repeatable: true,
        minInstances: 0,
        children: [
          LayoutRow(
            id: 'nonreg_account_institution_row',
            children: [
              LayoutNodeRef(
                id: 'nonreg_account_group_institution_ref',
                nodeId: 'nonreg_institution',
                widthFraction: 0.5,
              ),
              LayoutNodeRef(
                id: 'nonreg_account_group_account_number_ref',
                nodeId: 'nonreg_account_number',
                widthFraction: 0.5,
              ),
            ],
          ),
          LayoutRow(
            id: 'nonreg_row',
            children: [
              LayoutNodeRef(
                id: 'nonreg_value_at_death_ref',
                nodeId: 'nonreg_value_at_death',
                widthFraction: 0.35,
              ),
              LayoutNodeRef(
                id: 'nonreg_gain_loss_ref',
                nodeId: 'nonreg_gain_loss',
                widthFraction: 0.65,
              ),
            ],
          ),
          LayoutGroup(
            id: 'nonreg_statements_group',
            label: '',
            children: [
              LayoutGroup(
                id: 'nonreg_year_of_death_statements_group',
                label: 'Statements, year of death',
                groupId: 'nonreg_yod',
                children: const [],
              ),
              LayoutGroup(
                id: 'nonreg_to_liquidation_statements_group',
                label: 'Statements, to liquidation',
                groupId: 'nonreg_liquidation',
                children: const [],
              ),
            ],
          ),
        ],
      ),

      'share_certificate_group': NodeGroupDefinition(
        id: 'share_certificate_group',
        label: 'Share Certificate',
        repeatable: true,
        minInstances: 0,
        children: [
          LayoutRow(
            id: 'share_certificate_row_1',
            children: [
              LayoutNodeRef(
                id: 'share_company_name_ref',
                nodeId: 'share_company_name',
                widthFraction: 0.6,
              ),
              LayoutNodeRef(
                id: 'share_number_of_shares_ref',
                nodeId: 'share_number_of_shares',
                widthFraction: 0.4,
              ),
            ],
          ),
          LayoutNodeRef(
            id: 'share_notes_ref',
            nodeId: 'share_notes',
            widthFraction: 1.0,
          ),
        ],
      ),

      'asset_group': NodeGroupDefinition(
        id: 'asset_group',
        label: 'Other Asset',
        repeatable: true,
        minInstances: 0,
        children: [
          LayoutRow(
            id: 'other_assets_row',
            children: [
              LayoutNodeRef(
                id: 'asset_value_ref',
                nodeId: 'asset_value',
                widthFraction: 0.3,
              ),
              LayoutNodeRef(
                id: 'asset_description_ref',
                nodeId: 'asset_description',
                widthFraction: 0.7,
              ),
            ],
          ),
          LayoutNodeRef(
            id: 'asset_notes_ref',
            nodeId: 'asset_notes',
            widthFraction: 1.0,
          ),
        ],
      ),

      'realestate_group': NodeGroupDefinition(
        id: 'realestate_group',
        label: 'Real Estate',
        repeatable: true,
        minInstances: 0,
        children: [
          LayoutNodeRef(
            id: 'realestate_principal_residence_ref',
            nodeId: 'realestate_is_principal',
            widthFraction: 1.0,
          ),
          LayoutNodeRef(
            id: 'realestate_address_ref',
            nodeId: 'realestate_address',
            widthFraction: 1.0,
          ),
          LayoutGroup(
            id: 'realestate_principal_details_group',
            label: '',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'realestate_is_principal',
              choiceIndex: 0,
              expectedValue: true,
            ),
            children: [
              LayoutRow(
                id: 'realestate_principal_row',
                children: [
                  LayoutNodeRef(
                    id: 'realestate_principal_year_ref',
                    nodeId: 'realestate_principal_year',
                    widthFraction: 0.5,
                  ),
                  LayoutNodeRef(
                    id: 'realestate_principal_value_ref',
                    nodeId: 'realestate_principal_value',
                    widthFraction: 0.5,
                  ),
                ],
              ),
              LayoutNodeRef(
                id: 'realestate_principal_whats_happening_ref',
                nodeId: 'realestate_principal_notes',
                widthFraction: 1.0,
              ),
              LayoutNodeRef(
                id: 'realestate_principal_all_years_ref',
                nodeId: 'realestate_principal_all_years',
                widthFraction: 1.0,
              ),
              LayoutGroup(
                id: 'realestate_principal_all_years_no_group',
                label: '',
                visibilityCondition: const ChoiceEqualsCondition(
                  nodeId: 'realestate_principal_all_years',
                  choiceIndex: 1,
                  expectedValue: true,
                ),
                children: [
                  LayoutNodeRef(
                    id: 'realestate_principal_all_years_notes_ref',
                    nodeId: 'realestate_principal_all_years_notes',
                    widthFraction: 1.0,
                  ),
                ],
              ),
            ],
          ),
          LayoutGroup(
            id: 'realestate_other_details_group',
            label: '',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'realestate_is_principal',
              choiceIndex: 1,
              expectedValue: true,
            ),
            children: [
              LayoutRow(
                id: 'realestate_other_row_1',
                children: [
                  LayoutNodeRef(
                    id: 'realestate_other_year_ref',
                    nodeId: 'realestate_other_year_of_purchase',
                    widthFraction: 0.3,
                  ),
                  LayoutNodeRef(
                    id: 'realestate_other_purchase_price_ref',
                    nodeId: 'realestate_other_purchase_price',
                    widthFraction: 0.35,
                  ),
                  LayoutNodeRef(
                    id: 'realestate_other_value_ref',
                    nodeId: 'realestate_other_value_at_death',
                    widthFraction: 0.35,
                  ),
                ],
              ),
              LayoutNodeRef(
                id: 'realestate_capital_improvements_ref',
                nodeId: 'realestate_capital_improvements',
                widthFraction: 1.0,
              ),
              LayoutNodeRef(
                id: 'realestate_ownership_tax_history_ref',
                nodeId: 'realestate_ownership_tax_history',
                widthFraction: 1.0,
              ),
              LayoutNodeRef(
                id: 'realestate_other_whats_happening_ref',
                nodeId: 'realestate_other_whats_happening_notes',
                widthFraction: 1.0,
              ),
            ],
          ),
        ],
      ),

    },
    blocks: [
      FormBlock(
        id: 'block_deceased_information',
        title: 'Deceased Information',
        borderStyle: BlockBorderStyle.leftHeavyAllLight,
        colorScheme: BlockColorScheme.deceased,
        column: 1,
        layout: LayoutColumn(
          id: 'deceased_information_root',
          children: [
            LayoutRow(
              id: 'deceased_row_1',
              children: [
                LayoutNodeRef(
                  id: 'deceased_full_name_ref',
                  nodeId: 'deceased_name',
                  widthFraction: 0.28,  // Reduced from 0.35 to 0.28 (20% reduction)
                ),
                LayoutNodeRef(
                  id: 'deceased_dob_ref',
                  nodeId: 'deceased_dob',
                  widthFraction: 0.2,
                ),
                LayoutNodeRef(
                  id: 'deceased_dod_ref',
                  nodeId: 'deceased_dod',
                  widthFraction: 0.2,
                ),
                LayoutNodeRef(
                  id: 'deceased_sin_ref',
                  nodeId: 'deceased_sin',
                  widthFraction: 0.25,
                ),
              ],
            ),
            LayoutNodeRef(
              id: 'deceased_marital_status_ref',
              nodeId: 'deceased_marital_status',
              widthFraction: 1.0,
            ),
            LayoutGroup(
              id: 'partner_info_group',
              label: 'Partner Info',
              visibilityCondition: const ChoiceAnyOfCondition(
                nodeId: 'deceased_marital_status',
                choiceIndices: [0, 1], // Married and Common-law
                expectedValue: true,
              ),
              children: [
                LayoutRow(
                  id: 'partner_row',
                  children: [
                    LayoutNodeRef(
                      id: 'partner_full_name_ref',
                      nodeId: 'partner_name',
                      widthFraction: 0.4,
                    ),
                    LayoutNodeRef(
                      id: 'partner_dob_ref',
                      nodeId: 'partner_dob',
                      widthFraction: 0.3,
                    ),
                    LayoutNodeRef(
                      id: 'partner_sin_ref',
                      nodeId: 'partner_sin',
                      widthFraction: 0.3,
                    ),
                  ],
                ),
                LayoutNodeRef(
                  id: 'partner_address_ref',
                  nodeId: 'partner_address',
                  widthFraction: 1.0,
                ),
              ],
            ),
            LayoutNodeRef(
              id: 'deceased_notes_ref',
              nodeId: 'deceased_notes',
              widthFraction: 1.0,
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_trustee_contact_persons',
        title: 'Trustees/Contact Persons',
        borderStyle: BlockBorderStyle.leftHeavyAllLight,
        colorScheme: BlockColorScheme.executor,
        column: 1,
        layout: LayoutColumn(
          id: 'trustee_root',
          children: [
            LayoutNodeRef(
              id: 'meeting_type_ref',
              nodeId: 'meeting_type',
              widthFraction: 1.0,
            ),
            LayoutRow(
              id: 'meeting_attendees_row',
              children: [
                LayoutNodeRef(
                  id: 'meeting_attendees_ref',
                  nodeId: 'meeting_attendees',
                  widthFraction: 1.0,
                ),
              ],
            ),
            LayoutGroup(
              id: 'meeting_other_attendees_group',
              label: '',
              visibilityCondition: const ChoiceAnyOfCondition(
                nodeId: 'meeting_attendees',
                choiceIndices: [3], // 'Other' choice
                expectedValue: true,
              ),
              children: [
                LayoutNodeRef(
                  id: 'meeting_other_attendees_ref',
                  nodeId: 'meeting_other_attendees',
                  widthFraction: 1.0,
                ),
              ],
            ),
            LayoutGroup(
              id: 'trustee_repeatable_group',
              label: 'Trustees/contact persons',
              groupId: 'trustee_group',
              children: const [],
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_other_professionals',
        title: 'Other Professionals',
        borderStyle: BlockBorderStyle.leftHeavyAllLight,
        colorScheme: BlockColorScheme.professional,
        column: 2,
        layout: LayoutColumn(
          id: 'other_professionals_root',
          children: [
            LayoutGroup(
              id: 'professionals_repeatable_group',
              label: 'Professionals',
              groupId: 'professional_group',
              children: const [],
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_documents',
        title: 'Documents',
        borderStyle: BlockBorderStyle.leftHeavyAllLight,
        colorScheme: BlockColorScheme.receive,
        column: 2,
        layout: LayoutColumn(
          id: 'documents_root',
          children: [
            LayoutGroup(
              id: 'docs_death_cert_group',
              label: 'Death Certificate',
              groupId: 'docs_death_cert_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'docs_will_group',
              label: 'Will',
              groupId: 'docs_will_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'docs_probate_group',
              label: 'Probate',
              groupId: 'docs_probate_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'docs_assets_group',
              label: 'Complete List of Assets',
              groupId: 'docs_assets_rrn',
              children: const [],
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_tax_history',
        title: 'Tax History',
        borderStyle: BlockBorderStyle.leftHeavyAllLight,
        colorScheme: BlockColorScheme.documents,
        column: 2,
        layout: LayoutColumn(
          id: 'tax_history_root',
          children: [
            LayoutNodeRef(
              id: 'tax_gph_client_ref',
              nodeId: 'tax_gph_client',
              widthFraction: 1.0,
            ),
            LayoutGroup(
              id: 'tax_gph_yes_group',
              label: '',
              visibilityCondition: const ChoiceEqualsCondition(
                nodeId: 'tax_gph_client',
                choiceIndex: 0,
                expectedValue: true,
              ),
              children: [
                LayoutNodeRef(
                  id: 'tax_gph_notes_ref',
                  nodeId: 'tax_gph_notes',
                  widthFraction: 1.0,
                ),
              ],
            ),
            LayoutGroup(
              id: 'tax_gph_no_group',
              label: '',
              visibilityCondition: const ChoiceEqualsCondition(
                nodeId: 'tax_gph_client',
                choiceIndex: 1,
                expectedValue: true,
              ),
              children: [
                LayoutGroup(
                  id: 'tax_returns_rrn_group',
                  label: 'Tax returns – previous 2 years',
                  groupId: 'tax_returns_rrn',
                  children: const [],
                ),
                LayoutNodeRef(
                  id: 'tax_income_types_ref',
                  nodeId: 'tax_income_types',
                  widthFraction: 1.0,
                ),
                LayoutNodeRef(
                  id: 'tax_income_notes_ref',
                  nodeId: 'tax_income_notes',
                  widthFraction: 1.0,
                ),
                LayoutRow(
                  id: 'tax_credits_row',
                  children: [
                    LayoutNodeRef(
                      id: 'tax_credits_ref',
                      nodeId: 'tax_credits',
                      widthFraction: 0.5,
                    ),
                    LayoutGroup(
                      id: 'tax_credits_other_inline',
                      label: '',
                      visibilityCondition: const ChoiceEqualsCondition(
                        nodeId: 'tax_credits',
                        choiceIndex: 3, // "Other" is index 3
                        expectedValue: true,
                      ),
                      children: [
                        LayoutNodeRef(
                          id: 'tax_credits_other_notes_ref',
                          nodeId: 'tax_credits_other_notes',
                          widthFraction: 0.5,
                        ),
                      ],
                    ),
                  ],
                ),
                LayoutNodeRef(
                  id: 'tax_credits_notes_ref',
                  nodeId: 'tax_credits_notes',
                  widthFraction: 1.0,
                ),
              ],
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_asset_details',
        title: 'Asset Details',
        borderStyle: BlockBorderStyle.leftHeavyAllLight,
        colorScheme: BlockColorScheme.asset,
        column: 3,
        layout: LayoutColumn(
          id: 'asset_details_root',
          children: [
            LayoutGroup(
              id: 'rrsp_accounts_repeatable_section',
              label: 'RRSP / RIFF Accounts',
              groupId: 'rrsp_account_group',
              children: const [],
            ),
            LayoutGroup(
              id: 'nonreg_accounts_repeatable_section',
              label: 'Non-Registered Accounts',
              groupId: 'nonreg_account_group',
              children: const [],
            ),
            LayoutGroup(
              id: 'realestate_repeatable_section',
              label: 'Real Estate',
              groupId: 'realestate_group',
              children: const [],
            ),
            LayoutGroup(
              id: 'share_certificates_repeatable_section',
              label: 'Share Certificates',
              groupId: 'share_certificate_group',
              children: const [],
            ),
            LayoutGroup(
              id: 'other_assets_repeatable_section',
              label: 'Other Assets',
              groupId: 'asset_group',
              children: const [],
            ),
          ],
        ),
      ),

      ],
    dataSpecs: {
      'deceased_name': DataSpec(
        formNodeID: 'deceased_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'deceased_dob': DataSpec(
        formNodeID: 'deceased_dob',
        valueKind: ValueKind.date,
        profile: ValueProfile.dateDdMmYyyy,
      ),
      'deceased_dod': DataSpec(
        formNodeID: 'deceased_dod',
        valueKind: ValueKind.date,
        profile: ValueProfile.dateDdMmYyyy,
      ),
      'deceased_sin': DataSpec(
        formNodeID: 'deceased_sin',
        valueKind: ValueKind.number,
        profile: ValueProfile.sinCanada,
      ),
      'deceased_marital_status': DataSpec(
        formNodeID: 'deceased_marital_status',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'deceased_notes': DataSpec(
        formNodeID: 'deceased_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'partner_name': DataSpec(
        formNodeID: 'partner_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'partner_dob': DataSpec(
        formNodeID: 'partner_dob',
        valueKind: ValueKind.date,
        profile: ValueProfile.dateDdMmYyyy,
      ),
      'partner_sin': DataSpec(
        formNodeID: 'partner_sin',
        valueKind: ValueKind.number,
        profile: ValueProfile.sinCanada,
      ),
      'partner_address': DataSpec(
        formNodeID: 'partner_address',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'meeting_type': DataSpec(
        formNodeID: 'meeting_type',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'meeting_attendees': DataSpec(
        formNodeID: 'meeting_attendees',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'meeting_other_attendees': DataSpec(
        formNodeID: 'meeting_other_attendees',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'trustee_name': DataSpec(
        formNodeID: 'trustee_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'trustee_relationship': DataSpec(
        formNodeID: 'trustee_relationship',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'trustee_address': DataSpec(
        formNodeID: 'trustee_address',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'trustee_contact': DataSpec(
        formNodeID: 'trustee_contact',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'trustee_wants_compensation': DataSpec(
        formNodeID: 'trustee_wants_compensation',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'trustee_sin': DataSpec(
        formNodeID: 'trustee_sin',
        valueKind: ValueKind.number,
        profile: ValueProfile.sinCanada,
      ),
      'trustee_income_notes': DataSpec(
        formNodeID: 'trustee_income_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'trustee_is_other_person': DataSpec(
        formNodeID: 'trustee_is_other_person',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'trustee_relationship_to_trustee': DataSpec(
        formNodeID: 'trustee_relationship_to_trustee',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'professional_profession': DataSpec(
        formNodeID: 'professional_profession',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'professional_name': DataSpec(
        formNodeID: 'professional_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'professional_email': DataSpec(
        formNodeID: 'professional_email',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'professional_phone': DataSpec(
        formNodeID: 'professional_phone',
        valueKind: ValueKind.string,
        profile: ValueProfile.phoneNorthAmerica,
      ),

      'docs_death_cert_requested': DataSpec(
        formNodeID: 'docs_death_cert_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_death_cert_received': DataSpec(
        formNodeID: 'docs_death_cert_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_death_cert_notes': DataSpec(
        formNodeID: 'docs_death_cert_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'docs_will_requested': DataSpec(
        formNodeID: 'docs_will_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_will_received': DataSpec(
        formNodeID: 'docs_will_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_will_notes': DataSpec(
        formNodeID: 'docs_will_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'docs_probate_requested': DataSpec(
        formNodeID: 'docs_probate_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_probate_received': DataSpec(
        formNodeID: 'docs_probate_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_probate_notes': DataSpec(
        formNodeID: 'docs_probate_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'docs_assets_requested': DataSpec(
        formNodeID: 'docs_assets_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_assets_received': DataSpec(
        formNodeID: 'docs_assets_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_assets_notes': DataSpec(
        formNodeID: 'docs_assets_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'rrsp_value': DataSpec(
        formNodeID: 'rrsp_value',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'rrsp_has_beneficiary': DataSpec(
        formNodeID: 'rrsp_has_beneficiary',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'rrsp_liquidation_requested': DataSpec(
        formNodeID: 'rrsp_liquidation_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'rrsp_liquidation_received': DataSpec(
        formNodeID: 'rrsp_liquidation_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'rrsp_liquidation_notes': DataSpec(
        formNodeID: 'rrsp_liquidation_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'rrsp_institution': DataSpec(
        formNodeID: 'rrsp_institution',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'rrsp_account_number': DataSpec(
        formNodeID: 'rrsp_account_number',
        valueKind: ValueKind.number,
        profile: ValueProfile.plainText,
      ),

      'nonreg_value_at_death': DataSpec(
        formNodeID: 'nonreg_value_at_death',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'nonreg_gain_loss': DataSpec(
        formNodeID: 'nonreg_gain_loss',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'nonreg_yod_requested': DataSpec(
        formNodeID: 'nonreg_yod_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'nonreg_yod_received': DataSpec(
        formNodeID: 'nonreg_yod_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'nonreg_yod_notes': DataSpec(
        formNodeID: 'nonreg_yod_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'nonreg_liquidation_requested': DataSpec(
        formNodeID: 'nonreg_liquidation_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'nonreg_liquidation_received': DataSpec(
        formNodeID: 'nonreg_liquidation_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'nonreg_liquidation_notes': DataSpec(
        formNodeID: 'nonreg_liquidation_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'nonreg_institution': DataSpec(
        formNodeID: 'nonreg_institution',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'nonreg_account_number': DataSpec(
        formNodeID: 'nonreg_account_number',
        valueKind: ValueKind.number,
        profile: ValueProfile.plainText,
      ),

      'share_company_name': DataSpec(
        formNodeID: 'share_company_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'share_number_of_shares': DataSpec(
        formNodeID: 'share_number_of_shares',
        valueKind: ValueKind.number,
        profile: ValueProfile.plainText,
      ),
      'share_notes': DataSpec(
        formNodeID: 'share_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'asset_notes': DataSpec(
        formNodeID: 'asset_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'realestate_is_principal': DataSpec(
        formNodeID: 'realestate_is_principal',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'realestate_principal_year': DataSpec(
        formNodeID: 'realestate_principal_year',
        valueKind: ValueKind.number,
        profile: ValueProfile.plainText,
      ),
      'realestate_principal_value': DataSpec(
        formNodeID: 'realestate_principal_value',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'realestate_principal_notes': DataSpec(
        formNodeID: 'realestate_principal_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'realestate_other_year_of_purchase': DataSpec(
        formNodeID: 'realestate_other_year_of_purchase',
        valueKind: ValueKind.date,
        profile: ValueProfile.dateDdMmYyyy,
      ),
      'realestate_other_purchase_price': DataSpec(
        formNodeID: 'realestate_other_purchase_price',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'realestate_other_value_at_death': DataSpec(
        formNodeID: 'realestate_other_value_at_death',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'realestate_principal_all_years': DataSpec(
        formNodeID: 'realestate_principal_all_years',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'realestate_principal_all_years_notes': DataSpec(
        formNodeID: 'realestate_principal_all_years_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'realestate_capital_improvements': DataSpec(
        formNodeID: 'realestate_capital_improvements',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'realestate_ownership_tax_history': DataSpec(
        formNodeID: 'realestate_ownership_tax_history',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'realestate_other_whats_happening_notes': DataSpec(
        formNodeID: 'realestate_other_whats_happening_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'realestate_address': DataSpec(
        formNodeID: 'realestate_address',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'asset_description': DataSpec(
        formNodeID: 'asset_description',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'asset_value': DataSpec(
        formNodeID: 'asset_value',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),

      'tax_gph_client': DataSpec(
        formNodeID: 'tax_gph_client',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'tax_gph_notes': DataSpec(
        formNodeID: 'tax_gph_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'tax_returns_requested': DataSpec(
        formNodeID: 'tax_returns_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'tax_returns_received': DataSpec(
        formNodeID: 'tax_returns_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'tax_returns_notes': DataSpec(
        formNodeID: 'tax_returns_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'tax_income_types': DataSpec(
        formNodeID: 'tax_income_types',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'tax_income_notes': DataSpec(
        formNodeID: 'tax_income_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'tax_credits': DataSpec(
        formNodeID: 'tax_credits',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'tax_credits_other_notes': DataSpec(
        formNodeID: 'tax_credits_other_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'tax_credits_notes': DataSpec(
        formNodeID: 'tax_credits_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'trustee_is_trustee': DataSpec(
        formNodeID: 'trustee_is_trustee',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'trustee_notes': DataSpec(
        formNodeID: 'trustee_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'professional_notes': DataSpec(
        formNodeID: 'professional_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
    },
  );

  // Validate node ID consistency before returning
  validateFormDefinition(definition);

  return definition;
}
