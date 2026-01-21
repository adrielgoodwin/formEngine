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
          widthFraction: 0.2,
        ),
        LayoutNodeRef(
          id: '${baseId}_received_ref',
          nodeId: '${baseId}_received',
          widthFraction: 0.2,
        ),
        LayoutNodeRef(
          id: '${baseId}_notes_ref',
          nodeId: '${baseId}_notes',
          widthFraction: 0.6,
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

      // ===== Block 2 — Executor / Estate Trustee Information =====
      'executor_name': TextInputNode(
        id: 'executor_name',
        label: 'Full Name',
      ),
      'executor_address': TextInputNode(
        id: 'executor_address',
        label: 'Address',
        multiLine: true,
      ),
      'executor_contact': TextInputNode(
        id: 'executor_contact',
        label: 'Contact Info (email / phone)',
      ),
      'executor_wants_compensation': ChoiceInputNode(
        id: 'executor_wants_compensation',
        label: 'Executor Compensation',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'executor_sin': TextInputNode(
        id: 'executor_sin',
        label: 'SIN',
      ),
      'executor_income_notes': TextInputNode(
        id: 'executor_income_notes',
        label: 'Income Notes',
        multiLine: true,
      ),

      // ===== Block 3 — Other Professionals =====
      'professionals_involved': ChoiceInputNode(
        id: 'professionals_involved',
        label: 'Other professionals involved',
        choiceLabels: ['Lawyer', 'Investment Advisor'],
        choiceCardinality: ChoiceCardinality.multiple,
      ),
      'lawyer_firm_phone': TextInputNode(
        id: 'lawyer_firm_phone',
        label: 'Firm Phone',
      ),
      'lawyer_firm_email': TextInputNode(
        id: 'lawyer_firm_email',
        label: 'Firm Email',
      ),
      'lawyer_rep_phone': TextInputNode(
        id: 'lawyer_rep_phone',
        label: 'Rep Phone',
      ),
      'lawyer_rep_email': TextInputNode(
        id: 'lawyer_rep_email',
        label: 'Rep Email',
      ),
      'lawyer_name': TextInputNode(
        id: 'lawyer_name',
        label: 'Name',
      ),
      'advisor_firm_phone': TextInputNode(
        id: 'advisor_firm_phone',
        label: 'Firm Phone',
      ),
      'advisor_firm_email': TextInputNode(
        id: 'advisor_firm_email',
        label: 'Firm Email',
      ),
      'advisor_rep_phone': TextInputNode(
        id: 'advisor_rep_phone',
        label: 'Rep Phone',
      ),
      'advisor_rep_email': TextInputNode(
        id: 'advisor_rep_email',
        label: 'Rep Email',
      ),
      'advisor_name': TextInputNode(
        id: 'advisor_name',
        label: 'Name',
      ),

      // ===== Block 4 — Things to Retrieve (RRN, non-repeatable) =====
      'retrieve_death_cert_requested': ChoiceInputNode(
        id: 'retrieve_death_cert_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_death_cert_received': ChoiceInputNode(
        id: 'retrieve_death_cert_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_death_cert_notes': TextInputNode(
        id: 'retrieve_death_cert_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'retrieve_will_requested': ChoiceInputNode(
        id: 'retrieve_will_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_will_received': ChoiceInputNode(
        id: 'retrieve_will_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_will_notes': TextInputNode(
        id: 'retrieve_will_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'retrieve_assets_requested': ChoiceInputNode(
        id: 'retrieve_assets_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_assets_received': ChoiceInputNode(
        id: 'retrieve_assets_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_assets_notes': TextInputNode(
        id: 'retrieve_assets_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'retrieve_estate_return_requested': ChoiceInputNode(
        id: 'retrieve_estate_return_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_estate_return_received': ChoiceInputNode(
        id: 'retrieve_estate_return_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_estate_return_notes': TextInputNode(
        id: 'retrieve_estate_return_notes',
        label: 'Notes',
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

      'nonreg_gain_loss': TextInputNode(
        id: 'nonreg_gain_loss',
        label: 'Unrealized gain / loss at death',
      ),
      'nonreg_has_dividends': ChoiceInputNode(
        id: 'nonreg_has_dividends',
        label: 'Dividends?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
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

      'shares_notes': TextInputNode(
        id: 'shares_notes',
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
      'realestate_other_ownership_history_notes': TextInputNode(
        id: 'realestate_other_ownership_history_notes',
        label: 'Ownership History',
        multiLine: true,
      ),
      'realestate_other_significant_improvements_notes': TextInputNode(
        id: 'realestate_other_significant_improvements_notes',
        label: 'Significant Improvements',
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

      // ===== Block 6 — Other Documents (RRN, non-repeatable) =====
      'docs_tax_returns_requested': ChoiceInputNode(
        id: 'docs_tax_returns_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_tax_returns_received': ChoiceInputNode(
        id: 'docs_tax_returns_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_tax_returns_notes': TextInputNode(
        id: 'docs_tax_returns_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'docs_donations_requested': ChoiceInputNode(
        id: 'docs_donations_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_donations_received': ChoiceInputNode(
        id: 'docs_donations_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_donations_notes': TextInputNode(
        id: 'docs_donations_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'docs_medical_receipts_requested': ChoiceInputNode(
        id: 'docs_medical_receipts_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_medical_receipts_received': ChoiceInputNode(
        id: 'docs_medical_receipts_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'docs_medical_receipts_notes': TextInputNode(
        id: 'docs_medical_receipts_notes',
        label: 'Notes',
        multiLine: true,
      ),
    },
    groups: {

      'executor_other_info': NodeGroupDefinition(
        id: 'executor_other_info',
        label: 'Executor',
        repeatable: true,
        minInstances: 1,
        children: [
          LayoutRow(
            id: 'executor_other_row_1',
            children: [
              LayoutNodeRef(
                id: 'executor_other_full_name_ref',
                nodeId: 'executor_name',
                widthFraction: 0.4,
              ),
              LayoutNodeRef(
                id: 'executor_other_contact_ref',
                nodeId: 'executor_contact',
                widthFraction: 0.3,
              ),
              LayoutNodeRef(
                id: 'executor_other_compensation_ref',
                nodeId: 'executor_wants_compensation',
                widthFraction: 0.3,
              ),
            ],
          ),
          LayoutNodeRef(
            id: 'executor_other_address_ref',
            nodeId: 'executor_address',
            widthFraction: 1.0,
          ),
          LayoutGroup(
            id: 'executor_compensation_details_group',
            label: 'Compensation Details',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'executor_wants_compensation',
              choiceIndex: 0,
              expectedValue: true,
            ),
            children: [
              LayoutRow(
                id: 'executor_compensation_details_row',
                children: [
                  LayoutNodeRef(
                    id: 'executor_compensation_sin_ref',
                    nodeId: 'executor_sin',
                    widthFraction: 0.3,
                  ),
                  LayoutNodeRef(
                    id: 'executor_compensation_income_notes_ref',
                    nodeId: 'executor_income_notes',
                    widthFraction: 0.7,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      'retrieve_death_cert_rrn': NodeGroupDefinition(
        id: 'retrieve_death_cert_rrn',
        label: 'Death Certificate',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('retrieve_death_cert'),
      ),
      'retrieve_will_rrn': NodeGroupDefinition(
        id: 'retrieve_will_rrn',
        label: 'Will / Certificate of Appointment',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('retrieve_will'),
      ),
      'retrieve_assets_rrn': NodeGroupDefinition(
        id: 'retrieve_assets_rrn',
        label: 'List of Assets',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('retrieve_assets'),
      ),
      'retrieve_estate_return_rrn': NodeGroupDefinition(
        id: 'retrieve_estate_return_rrn',
        label: 'Estate Information Return',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('retrieve_estate_return'),
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
        label: 'Monthly statements (year of death)',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('nonreg_yod'),
      ),
      'nonreg_liquidation': NodeGroupDefinition(
        id: 'nonreg_liquidation',
        label: 'Monthly statements (to liquidation)',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('nonreg_liquidation'),
      ),

      'rrsp_account_group': NodeGroupDefinition(
        id: 'rrsp_account_group',
        label: 'RRSP / RIFF Account',
        repeatable: true,
        minInstances: 1,
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
        minInstances: 1,
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
                id: 'nonreg_gain_loss_ref',
                nodeId: 'nonreg_gain_loss',
                widthFraction: 0.65,
              ),
              LayoutNodeRef(
                id: 'nonreg_dividends_ref',
                nodeId: 'nonreg_has_dividends',
                widthFraction: 0.35,
              ),
            ],
          ),
          LayoutGroup(
            id: 'nonreg_dividends_yes_group',
            label: 'Monthly Statements',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'nonreg_has_dividends',
              choiceIndex: 0,
              expectedValue: true,
            ),
            children: [
              LayoutGroup(
                id: 'nonreg_year_of_death_statements_group',
                label: 'Monthly statements (year of death)',
                groupId: 'nonreg_yod',
                children: const [],
              ),
              LayoutGroup(
                id: 'nonreg_to_liquidation_statements_group',
                label: 'Monthly statements (to liquidation)',
                groupId: 'nonreg_liquidation',
                children: const [],
              ),
            ],
          ),
        ],
      ),

      'asset_group': NodeGroupDefinition(
        id: 'asset_group',
        label: 'Other Assets',
        repeatable: true,
        minInstances: 1,
        children: [
          LayoutRow(
            id: 'other_assets_row',
            children: [
              LayoutNodeRef(
                id: 'asset_description_ref',
                nodeId: 'asset_description',
                widthFraction: 0.7,
              ),
              LayoutNodeRef(
                id: 'asset_value_ref',
                nodeId: 'asset_value',
                widthFraction: 0.3,
              ),
            ],
          ),
        ],
      ),

      'realestate_group': NodeGroupDefinition(
        id: 'realestate_group',
        label: 'Real Estate',
        repeatable: true,
        minInstances: 1,
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
            label: 'Principal Residence Details',
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
                    widthFraction: 0.3,
                  ),
                  LayoutNodeRef(
                    id: 'realestate_principal_value_ref',
                    nodeId: 'realestate_principal_value',
                    widthFraction: 0.3,
                  ),
                  LayoutNodeRef(
                    id: 'realestate_principal_whats_happening_ref',
                    nodeId: 'realestate_principal_notes',
                    widthFraction: 0.4,
                  ),
                ],
              ),
            ],
          ),
          LayoutGroup(
            id: 'realestate_other_details_group',
            label: 'Non-Principal Residence Details',
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
              LayoutRow(
                id: 'realestate_other_row_2',
                children: [
                  LayoutNodeRef(
                    id: 'realestate_other_ownership_history_ref',
                    nodeId: 'realestate_other_ownership_history_notes',
                    widthFraction: 0.5,
                  ),
                  LayoutNodeRef(
                    id: 'realestate_other_improvements_ref',
                    nodeId: 'realestate_other_significant_improvements_notes',
                    widthFraction: 0.5,
                  ),
                ],
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

      'docs_tax_returns_rrn': NodeGroupDefinition(
        id: 'docs_tax_returns_rrn',
        label: 'Prior two years tax returns',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('docs_tax_returns'),
      ),
      'docs_donations_rrn': NodeGroupDefinition(
        id: 'docs_donations_rrn',
        label: 'Donations',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('docs_donations'),
      ),
      'docs_medical_receipts_rrn': NodeGroupDefinition(
        id: 'docs_medical_receipts_rrn',
        label: 'Medical receipts',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('docs_medical_receipts'),
      ),
    },
    blocks: [
      FormBlock(
        id: 'block_deceased_information',
        title: 'Deceased Information',
        layout: LayoutColumn(
          id: 'deceased_information_root',
          children: [
            LayoutRow(
              id: 'deceased_row_1',
              children: [
                LayoutNodeRef(
                  id: 'deceased_full_name_ref',
                  nodeId: 'deceased_name',
                  widthFraction: 0.35,
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
            LayoutRow(
              id: 'deceased_row_2',
              children: [
                LayoutNodeRef(
                  id: 'deceased_marital_status_ref',
                  nodeId: 'deceased_marital_status',
                  widthFraction: 0.35,
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
              ],
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_executor_estate_trustee_information',
        title: 'Executor / Estate Trustee Information',
        layout: LayoutColumn(
          id: 'executor_root',
          children: [
            LayoutGroup(
              id: 'executor_group',
              label: 'Executors',
              groupId: 'executor_other_info',
              children: const [],
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_other_professionals',
        title: 'Other Professionals',
        layout: LayoutColumn(
          id: 'other_professionals_root',
          children: [
            LayoutNodeRef(
              id: 'other_professionals_involved_ref',
              nodeId: 'professionals_involved',
              widthFraction: 1.0,
            ),
            LayoutGroup(
              id: 'lawyer_group',
              label: 'Lawyer',
              visibilityCondition: const ChoiceEqualsCondition(
                nodeId: 'professionals_involved',
                choiceIndex: 0,
                expectedValue: true,
              ),
              children: [
                LayoutNodeRef(
                  id: 'lawyer_name_ref',
                  nodeId: 'lawyer_name',
                  widthFraction: 1.0,
                ),
                LayoutRow(
                  id: 'lawyer_row_1',
                  children: [
                    LayoutNodeRef(
                      id: 'lawyer_firm_phone_ref',
                      nodeId: 'lawyer_firm_phone',
                      widthFraction: 0.5,
                    ),
                    LayoutNodeRef(
                      id: 'lawyer_firm_email_ref',
                      nodeId: 'lawyer_firm_email',
                      widthFraction: 0.5,
                    ),
                  ],
                ),
                LayoutRow(
                  id: 'lawyer_row_2',
                  children: [
                    LayoutNodeRef(
                      id: 'lawyer_rep_phone_ref',
                      nodeId: 'lawyer_rep_phone',
                      widthFraction: 0.5,
                    ),
                    LayoutNodeRef(
                      id: 'lawyer_rep_email_ref',
                      nodeId: 'lawyer_rep_email',
                      widthFraction: 0.5,
                    ),
                  ],
                ),
              ],
            ),
            LayoutGroup(
              id: 'advisor_group',
              label: 'Investment Advisor',
              visibilityCondition: const ChoiceEqualsCondition(
                nodeId: 'professionals_involved',
                choiceIndex: 1,
                expectedValue: true,
              ),
              children: [
                LayoutNodeRef(
                  id: 'advisor_name_ref',
                  nodeId: 'advisor_name',
                  widthFraction: 1.0,
                ),
                LayoutRow(
                  id: 'advisor_row_1',
                  children: [
                    LayoutNodeRef(
                      id: 'advisor_firm_phone_ref',
                      nodeId: 'advisor_firm_phone',
                      widthFraction: 0.5,
                    ),
                    LayoutNodeRef(
                      id: 'advisor_firm_email_ref',
                      nodeId: 'advisor_firm_email',
                      widthFraction: 0.5,
                    ),
                  ],
                ),
                LayoutRow(
                  id: 'advisor_row_2',
                  children: [
                    LayoutNodeRef(
                      id: 'advisor_rep_phone_ref',
                      nodeId: 'advisor_rep_phone',
                      widthFraction: 0.5,
                    ),
                    LayoutNodeRef(
                      id: 'advisor_rep_email_ref',
                      nodeId: 'advisor_rep_email',
                      widthFraction: 0.5,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_things_to_retrieve',
        title: 'Things to Retrieve',
        layout: LayoutColumn(
          id: 'things_to_retrieve_root',
          children: [
            LayoutGroup(
              id: 'retrieve_death_cert_group',
              label: 'Death Certificate',
              groupId: 'retrieve_death_cert_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'retrieve_will_group',
              label: 'Will / Certificate of Appointment',
              groupId: 'retrieve_will_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'retrieve_assets_group',
              label: 'List of Assets',
              groupId: 'retrieve_assets_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'retrieve_estate_return_group',
              label: 'Estate Information Return',
              groupId: 'retrieve_estate_return_rrn',
              children: const [],
            ),
          ],
        ),
      ),

      FormBlock(
        id: 'block_asset_details',
        title: 'Asset Details',
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
              id: 'shares_group',
              label: 'Shares',
              children: [
                LayoutNodeRef(
                  id: 'shares_notes_ref',
                  nodeId: 'shares_notes',
                  widthFraction: 1.0,
                ),
              ],
            ),
            LayoutGroup(
              id: 'realestate_repeatable_section',
              label: 'Real Estate',
              groupId: 'realestate_group',
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

      FormBlock(
        id: 'block_other_documents',
        title: 'Other Documents',
        layout: LayoutColumn(
          id: 'other_documents_root',
          children: [
            LayoutGroup(
              id: 'docs_tax_returns_group',
              label: 'Prior two years tax returns',
              groupId: 'docs_tax_returns_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'docs_donations_group',
              label: 'Donations',
              groupId: 'docs_donations_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'docs_medical_receipts_group',
              label: 'Medical receipts',
              groupId: 'docs_medical_receipts_rrn',
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

      'executor_name': DataSpec(
        formNodeID: 'executor_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_address': DataSpec(
        formNodeID: 'executor_address',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_contact': DataSpec(
        formNodeID: 'executor_contact',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_wants_compensation': DataSpec(
        formNodeID: 'executor_wants_compensation',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'executor_sin': DataSpec(
        formNodeID: 'executor_sin',
        valueKind: ValueKind.number,
        profile: ValueProfile.sinCanada,
      ),
      'executor_income_notes': DataSpec(
        formNodeID: 'executor_income_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'professionals_involved': DataSpec(
        formNodeID: 'professionals_involved',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'lawyer_firm_phone': DataSpec(
        formNodeID: 'lawyer_firm_phone',
        valueKind: ValueKind.string,
        profile: ValueProfile.phoneNorthAmerica,
      ),
      'lawyer_firm_email': DataSpec(
        formNodeID: 'lawyer_firm_email',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'lawyer_rep_phone': DataSpec(
        formNodeID: 'lawyer_rep_phone',
        valueKind: ValueKind.string,
        profile: ValueProfile.phoneNorthAmerica,
      ),
      'lawyer_rep_email': DataSpec(
        formNodeID: 'lawyer_rep_email',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'lawyer_name': DataSpec(
        formNodeID: 'lawyer_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'advisor_firm_phone': DataSpec(
        formNodeID: 'advisor_firm_phone',
        valueKind: ValueKind.string,
        profile: ValueProfile.phoneNorthAmerica,
      ),
      'advisor_firm_email': DataSpec(
        formNodeID: 'advisor_firm_email',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'advisor_rep_phone': DataSpec(
        formNodeID: 'advisor_rep_phone',
        valueKind: ValueKind.string,
        profile: ValueProfile.phoneNorthAmerica,
      ),
      'advisor_rep_email': DataSpec(
        formNodeID: 'advisor_rep_email',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'advisor_name': DataSpec(
        formNodeID: 'advisor_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'retrieve_death_cert_requested': DataSpec(
        formNodeID: 'retrieve_death_cert_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_death_cert_received': DataSpec(
        formNodeID: 'retrieve_death_cert_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_death_cert_notes': DataSpec(
        formNodeID: 'retrieve_death_cert_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'retrieve_will_requested': DataSpec(
        formNodeID: 'retrieve_will_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_will_received': DataSpec(
        formNodeID: 'retrieve_will_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_will_notes': DataSpec(
        formNodeID: 'retrieve_will_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'retrieve_assets_requested': DataSpec(
        formNodeID: 'retrieve_assets_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_assets_received': DataSpec(
        formNodeID: 'retrieve_assets_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_assets_notes': DataSpec(
        formNodeID: 'retrieve_assets_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'retrieve_estate_return_requested': DataSpec(
        formNodeID: 'retrieve_estate_return_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_estate_return_received': DataSpec(
        formNodeID: 'retrieve_estate_return_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_estate_return_notes': DataSpec(
        formNodeID: 'retrieve_estate_return_notes',
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

      'nonreg_gain_loss': DataSpec(
        formNodeID: 'nonreg_gain_loss',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'nonreg_has_dividends': DataSpec(
        formNodeID: 'nonreg_has_dividends',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
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

      'shares_notes': DataSpec(
        formNodeID: 'shares_notes',
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
      'realestate_other_ownership_history_notes': DataSpec(
        formNodeID: 'realestate_other_ownership_history_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'realestate_other_significant_improvements_notes': DataSpec(
        formNodeID: 'realestate_other_significant_improvements_notes',
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

      'docs_tax_returns_requested': DataSpec(
        formNodeID: 'docs_tax_returns_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_tax_returns_received': DataSpec(
        formNodeID: 'docs_tax_returns_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_tax_returns_notes': DataSpec(
        formNodeID: 'docs_tax_returns_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'docs_donations_requested': DataSpec(
        formNodeID: 'docs_donations_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_donations_received': DataSpec(
        formNodeID: 'docs_donations_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_donations_notes': DataSpec(
        formNodeID: 'docs_donations_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'docs_medical_receipts_requested': DataSpec(
        formNodeID: 'docs_medical_receipts_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_medical_receipts_received': DataSpec(
        formNodeID: 'docs_medical_receipts_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'docs_medical_receipts_notes': DataSpec(
        formNodeID: 'docs_medical_receipts_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
    },
  );

  // Validate node ID consistency before returning
  validateFormDefinition(definition);

  return definition;
}
