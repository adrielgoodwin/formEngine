import '../models/form_definition.dart';
import '../models/form_block.dart';
import '../models/form_node.dart';
import '../models/layout_item.dart';
import '../models/node_group_definition.dart';
import '../models/visibility_condition.dart';

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
  return FormDefinition(
    id: 'estate_intake_v1',
    title: 'Estate Intake',
    schemaVersion: 1,
    nodes: {
      // ===== Block 1 — Deceased Information =====
      'deceased_full_name': TextInputNode(
        id: 'deceased_full_name',
        label: 'Full Name',
      ),
      'deceased_date_of_birth': TextInputNode(
        id: 'deceased_date_of_birth',
        label: 'Date of Birth',
      ),
      'deceased_date_of_death': TextInputNode(
        id: 'deceased_date_of_death',
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
      'partner_full_name': TextInputNode(
        id: 'partner_full_name',
        label: 'Partner Full Name',
      ),
      'partner_date_of_birth': TextInputNode(
        id: 'partner_date_of_birth',
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
      'executor_primary_full_name': TextInputNode(
        id: 'executor_primary_full_name',
        label: 'Full Name',
      ),
      'executor_primary_address': TextInputNode(
        id: 'executor_primary_address',
        label: 'Address',
        multiLine: true,
      ),
      'executor_primary_contact_info': TextInputNode(
        id: 'executor_primary_contact_info',
        label: 'Contact Info (email / phone)',
      ),
      'executor_other_full_name': TextInputNode(
        id: 'executor_other_full_name',
        label: 'Full Name',
      ),
      'executor_other_address': TextInputNode(
        id: 'executor_other_address',
        label: 'Address',
        multiLine: true,
      ),
      'executor_other_contact_info': TextInputNode(
        id: 'executor_other_contact_info',
        label: 'Contact Info (email / phone)',
      ),
      'executor_compensation': ChoiceInputNode(
        id: 'executor_compensation',
        label: 'Executor Compensation',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'executor_compensation_sin': TextInputNode(
        id: 'executor_compensation_sin',
        label: 'SIN',
      ),
      'executor_compensation_income_notes': TextInputNode(
        id: 'executor_compensation_income_notes',
        label: 'Income Notes',
        multiLine: true,
      ),

      // ===== Block 3 — Other Professionals =====
      'other_professionals_involved': ChoiceInputNode(
        id: 'other_professionals_involved',
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
      'investment_advisor_firm_phone': TextInputNode(
        id: 'investment_advisor_firm_phone',
        label: 'Firm Phone',
      ),
      'investment_advisor_firm_email': TextInputNode(
        id: 'investment_advisor_firm_email',
        label: 'Firm Email',
      ),
      'investment_advisor_rep_phone': TextInputNode(
        id: 'investment_advisor_rep_phone',
        label: 'Rep Phone',
      ),
      'investment_advisor_rep_email': TextInputNode(
        id: 'investment_advisor_rep_email',
        label: 'Rep Email',
      ),
      'investment_advisor_name': TextInputNode(
        id: 'investment_advisor_name',
        label: 'Name',
      ),

      // ===== Block 4 — Things to Retrieve (RRN, non-repeatable) =====
      'retrieve_death_certificate_requested': ChoiceInputNode(
        id: 'retrieve_death_certificate_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_death_certificate_received': ChoiceInputNode(
        id: 'retrieve_death_certificate_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_death_certificate_notes': TextInputNode(
        id: 'retrieve_death_certificate_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'retrieve_will_certificate_requested': ChoiceInputNode(
        id: 'retrieve_will_certificate_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_will_certificate_received': ChoiceInputNode(
        id: 'retrieve_will_certificate_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_will_certificate_notes': TextInputNode(
        id: 'retrieve_will_certificate_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'retrieve_list_of_assets_requested': ChoiceInputNode(
        id: 'retrieve_list_of_assets_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_list_of_assets_received': ChoiceInputNode(
        id: 'retrieve_list_of_assets_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_list_of_assets_notes': TextInputNode(
        id: 'retrieve_list_of_assets_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'retrieve_estate_information_return_requested': ChoiceInputNode(
        id: 'retrieve_estate_information_return_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_estate_information_return_received': ChoiceInputNode(
        id: 'retrieve_estate_information_return_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'retrieve_estate_information_return_notes': TextInputNode(
        id: 'retrieve_estate_information_return_notes',
        label: 'Notes',
        multiLine: true,
      ),

      // ===== Block 5 — Asset Details =====
      'rrsp_riff_value_at_death': TextInputNode(
        id: 'rrsp_riff_value_at_death',
        label: 'Value at Death',
      ),
      'rrsp_riff_named_beneficiary': ChoiceInputNode(
        id: 'rrsp_riff_named_beneficiary',
        label: 'Named Beneficiary?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'rrsp_statement_month_of_liquidation_requested': ChoiceInputNode(
        id: 'rrsp_statement_month_of_liquidation_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'rrsp_statement_month_of_liquidation_received': ChoiceInputNode(
        id: 'rrsp_statement_month_of_liquidation_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'rrsp_statement_month_of_liquidation_notes': TextInputNode(
        id: 'rrsp_statement_month_of_liquidation_notes',
        label: 'Notes',
        multiLine: true,
      ),

      'non_registered_unrealized_gain_loss_at_death': TextInputNode(
        id: 'non_registered_unrealized_gain_loss_at_death',
        label: 'Unrealized gain / loss at death',
      ),
      'non_registered_dividends': ChoiceInputNode(
        id: 'non_registered_dividends',
        label: 'Dividends?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'non_registered_statements_year_of_death_requested': ChoiceInputNode(
        id: 'non_registered_statements_year_of_death_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'non_registered_statements_year_of_death_received': ChoiceInputNode(
        id: 'non_registered_statements_year_of_death_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'non_registered_statements_year_of_death_notes': TextInputNode(
        id: 'non_registered_statements_year_of_death_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'non_registered_statements_to_liquidation_requested': ChoiceInputNode(
        id: 'non_registered_statements_to_liquidation_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'non_registered_statements_to_liquidation_received': ChoiceInputNode(
        id: 'non_registered_statements_to_liquidation_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'non_registered_statements_to_liquidation_notes': TextInputNode(
        id: 'non_registered_statements_to_liquidation_notes',
        label: 'Notes',
        multiLine: true,
      ),

      'shares_notes': TextInputNode(
        id: 'shares_notes',
        label: 'Notes',
        multiLine: true,
      ),

      'rrsp_account_group_institution': TextInputNode(
        id: 'rrsp_account_group_institution',
        label: 'Institution',
      ),
      'rrsp_account_group_account_number': TextInputNode(
        id: 'rrsp_account_group_account_number',
        label: 'Account Number',
      ),

      'non_registered_account_group_institution': TextInputNode(
        id: 'non_registered_account_group_institution',
        label: 'Institution',
      ),
      'non_registered_account_group_account_number': TextInputNode(
        id: 'non_registered_account_group_account_number',
        label: 'Account Number',
      ),

      'real_estate_principal_residence': ChoiceInputNode(
        id: 'real_estate_principal_residence',
        label: 'Principal Residence?',
        choiceLabels: ['Yes', 'No'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'real_estate_principal_year_of_purchase': TextInputNode(
        id: 'real_estate_principal_year_of_purchase',
        label: 'Year of Purchase',
      ),
      'real_estate_principal_value_at_death': TextInputNode(
        id: 'real_estate_principal_value_at_death',
        label: 'Value at Death',
      ),
      'real_estate_principal_whats_happening_notes': TextInputNode(
        id: 'real_estate_principal_whats_happening_notes',
        label: "What's happening",
        multiLine: true,
      ),
      'real_estate_non_principal_year_of_purchase': TextInputNode(
        id: 'real_estate_non_principal_year_of_purchase',
        label: 'Year of Purchase',
      ),
      'real_estate_non_principal_purchase_price': TextInputNode(
        id: 'real_estate_non_principal_purchase_price',
        label: 'Purchase Price',
      ),
      'real_estate_non_principal_value_at_death': TextInputNode(
        id: 'real_estate_non_principal_value_at_death',
        label: 'Value at Death',
      ),
      'real_estate_non_principal_ownership_history_notes': TextInputNode(
        id: 'real_estate_non_principal_ownership_history_notes',
        label: 'Ownership History',
        multiLine: true,
      ),
      'real_estate_non_principal_significant_improvements_notes': TextInputNode(
        id: 'real_estate_non_principal_significant_improvements_notes',
        label: 'Significant Improvements',
        multiLine: true,
      ),
      'real_estate_non_principal_whats_happening_notes': TextInputNode(
        id: 'real_estate_non_principal_whats_happening_notes',
        label: "What's happening",
        multiLine: true,
      ),

      'real_estate_address': TextInputNode(
        id: 'real_estate_address',
        label: 'Address',
        multiLine: true,
      ),

      'other_asset_description': TextInputNode(
        id: 'other_asset_description',
        label: 'Description',
      ),
      'other_asset_value': TextInputNode(
        id: 'other_asset_value',
        label: 'Value',
      ),

      // Real estate (repeatable group will reuse these node IDs)

      // ===== Block 6 — Other Documents (RRN, non-repeatable) =====
      'other_docs_prior_two_years_tax_returns_requested': ChoiceInputNode(
        id: 'other_docs_prior_two_years_tax_returns_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'other_docs_prior_two_years_tax_returns_received': ChoiceInputNode(
        id: 'other_docs_prior_two_years_tax_returns_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'other_docs_prior_two_years_tax_returns_notes': TextInputNode(
        id: 'other_docs_prior_two_years_tax_returns_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'other_docs_donations_requested': ChoiceInputNode(
        id: 'other_docs_donations_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'other_docs_donations_received': ChoiceInputNode(
        id: 'other_docs_donations_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'other_docs_donations_notes': TextInputNode(
        id: 'other_docs_donations_notes',
        label: 'Notes',
        multiLine: true,
      ),
      'other_docs_medical_receipts_requested': ChoiceInputNode(
        id: 'other_docs_medical_receipts_requested',
        label: 'Requested',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'other_docs_medical_receipts_received': ChoiceInputNode(
        id: 'other_docs_medical_receipts_received',
        label: 'Received',
        choiceLabels: ['Yes'],
        choiceCardinality: ChoiceCardinality.single,
      ),
      'other_docs_medical_receipts_notes': TextInputNode(
        id: 'other_docs_medical_receipts_notes',
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
                nodeId: 'executor_other_full_name',
                widthFraction: 0.4,
              ),
              LayoutNodeRef(
                id: 'executor_other_contact_ref',
                nodeId: 'executor_other_contact_info',
                widthFraction: 0.3,
              ),
              LayoutNodeRef(
                id: 'executor_other_compensation_ref',
                nodeId: 'executor_compensation',
                widthFraction: 0.3,
              ),
            ],
          ),
          LayoutNodeRef(
            id: 'executor_other_address_ref',
            nodeId: 'executor_other_address',
            widthFraction: 1.0,
          ),
          LayoutGroup(
            id: 'executor_compensation_details_group',
            label: 'Compensation Details',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'executor_compensation',
              choiceIndex: 0,
              expectedValue: true,
            ),
            children: [
              LayoutRow(
                id: 'executor_compensation_details_row',
                children: [
                  LayoutNodeRef(
                    id: 'executor_compensation_sin_ref',
                    nodeId: 'executor_compensation_sin',
                    widthFraction: 0.3,
                  ),
                  LayoutNodeRef(
                    id: 'executor_compensation_income_notes_ref',
                    nodeId: 'executor_compensation_income_notes',
                    widthFraction: 0.7,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      'retrieve_death_certificate_rrn': NodeGroupDefinition(
        id: 'retrieve_death_certificate_rrn',
        label: 'Death Certificate',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('retrieve_death_certificate'),
      ),
      'retrieve_will_certificate_rrn': NodeGroupDefinition(
        id: 'retrieve_will_certificate_rrn',
        label: 'Will / Certificate of Appointment',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('retrieve_will_certificate'),
      ),
      'retrieve_list_of_assets_rrn': NodeGroupDefinition(
        id: 'retrieve_list_of_assets_rrn',
        label: 'List of Assets',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('retrieve_list_of_assets'),
      ),
      'retrieve_estate_information_return_rrn': NodeGroupDefinition(
        id: 'retrieve_estate_information_return_rrn',
        label: 'Estate Information Return',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('retrieve_estate_information_return'),
      ),

      'rrsp_statement_month_of_liquidation': NodeGroupDefinition(
        id: 'rrsp_statement_month_of_liquidation',
        label: 'Statement for month of liquidation',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('rrsp_statement_month_of_liquidation'),
      ),
      'non_registered_statements_year_of_death': NodeGroupDefinition(
        id: 'non_registered_statements_year_of_death',
        label: 'Monthly statements (year of death)',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('non_registered_statements_year_of_death'),
      ),
      'non_registered_statements_to_liquidation': NodeGroupDefinition(
        id: 'non_registered_statements_to_liquidation',
        label: 'Monthly statements (to liquidation)',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('non_registered_statements_to_liquidation'),
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
                nodeId: 'rrsp_account_group_institution',
                widthFraction: 0.5,
              ),
              LayoutNodeRef(
                id: 'rrsp_account_group_account_number_ref',
                nodeId: 'rrsp_account_group_account_number',
                widthFraction: 0.5,
              ),
            ],
          ),
          LayoutRow(
            id: 'rrsp_account_row',
            children: [
              LayoutNodeRef(
                id: 'rrsp_riff_value_at_death_ref',
                nodeId: 'rrsp_riff_value_at_death',
                widthFraction: 0.6,
              ),
              LayoutNodeRef(
                id: 'rrsp_riff_named_beneficiary_ref',
                nodeId: 'rrsp_riff_named_beneficiary',
                widthFraction: 0.4,
              ),
            ],
          ),
          LayoutGroup(
            id: 'rrsp_statement_group_no_beneficiary',
            label: 'Statement for month of liquidation',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'rrsp_riff_named_beneficiary',
              choiceIndex: 1,
              expectedValue: true,
            ),
            groupId: 'rrsp_statement_month_of_liquidation',
            children: const [],
          ),
        ],
      ),
      'non_registered_account_group': NodeGroupDefinition(
        id: 'non_registered_account_group',
        label: 'Non-Registered Account',
        repeatable: true,
        minInstances: 1,
        children: [
          LayoutRow(
            id: 'non_registered_account_institution_row',
            children: [
              LayoutNodeRef(
                id: 'non_registered_account_group_institution_ref',
                nodeId: 'non_registered_account_group_institution',
                widthFraction: 0.5,
              ),
              LayoutNodeRef(
                id: 'non_registered_account_group_account_number_ref',
                nodeId: 'non_registered_account_group_account_number',
                widthFraction: 0.5,
              ),
            ],
          ),
          LayoutRow(
            id: 'non_registered_row',
            children: [
              LayoutNodeRef(
                id: 'non_registered_gain_loss_ref',
                nodeId: 'non_registered_unrealized_gain_loss_at_death',
                widthFraction: 0.65,
              ),
              LayoutNodeRef(
                id: 'non_registered_dividends_ref',
                nodeId: 'non_registered_dividends',
                widthFraction: 0.35,
              ),
            ],
          ),
          LayoutGroup(
            id: 'non_registered_dividends_yes_group',
            label: 'Monthly Statements',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'non_registered_dividends',
              choiceIndex: 0,
              expectedValue: true,
            ),
            children: [
              LayoutGroup(
                id: 'non_registered_year_of_death_statements_group',
                label: 'Monthly statements (year of death)',
                groupId: 'non_registered_statements_year_of_death',
                children: const [],
              ),
              LayoutGroup(
                id: 'non_registered_to_liquidation_statements_group',
                label: 'Monthly statements (to liquidation)',
                groupId: 'non_registered_statements_to_liquidation',
                children: const [],
              ),
            ],
          ),
        ],
      ),

      'other_assets_group': NodeGroupDefinition(
        id: 'other_assets_group',
        label: 'Other Assets',
        repeatable: true,
        minInstances: 1,
        children: [
          LayoutRow(
            id: 'other_assets_row',
            children: [
              LayoutNodeRef(
                id: 'other_asset_description_ref',
                nodeId: 'other_asset_description',
                widthFraction: 0.7,
              ),
              LayoutNodeRef(
                id: 'other_asset_value_ref',
                nodeId: 'other_asset_value',
                widthFraction: 0.3,
              ),
            ],
          ),
        ],
      ),

      'real_estate_group': NodeGroupDefinition(
        id: 'real_estate_group',
        label: 'Real Estate',
        repeatable: true,
        minInstances: 1,
        children: [
          LayoutNodeRef(
            id: 'real_estate_principal_residence_ref',
            nodeId: 'real_estate_principal_residence',
            widthFraction: 1.0,
          ),
          LayoutNodeRef(
            id: 'real_estate_address_ref',
            nodeId: 'real_estate_address',
            widthFraction: 1.0,
          ),
          LayoutGroup(
            id: 'real_estate_principal_details_group',
            label: 'Principal Residence Details',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'real_estate_principal_residence',
              choiceIndex: 0,
              expectedValue: true,
            ),
            children: [
              LayoutRow(
                id: 'real_estate_principal_row',
                children: [
                  LayoutNodeRef(
                    id: 'real_estate_principal_year_ref',
                    nodeId: 'real_estate_principal_year_of_purchase',
                    widthFraction: 0.3,
                  ),
                  LayoutNodeRef(
                    id: 'real_estate_principal_value_ref',
                    nodeId: 'real_estate_principal_value_at_death',
                    widthFraction: 0.3,
                  ),
                  LayoutNodeRef(
                    id: 'real_estate_principal_whats_happening_ref',
                    nodeId: 'real_estate_principal_whats_happening_notes',
                    widthFraction: 0.4,
                  ),
                ],
              ),
            ],
          ),
          LayoutGroup(
            id: 'real_estate_non_principal_details_group',
            label: 'Non-Principal Residence Details',
            visibilityCondition: const ChoiceEqualsCondition(
              nodeId: 'real_estate_principal_residence',
              choiceIndex: 1,
              expectedValue: true,
            ),
            children: [
              LayoutRow(
                id: 'real_estate_non_principal_row_1',
                children: [
                  LayoutNodeRef(
                    id: 'real_estate_non_principal_year_ref',
                    nodeId: 'real_estate_non_principal_year_of_purchase',
                    widthFraction: 0.3,
                  ),
                  LayoutNodeRef(
                    id: 'real_estate_non_principal_purchase_price_ref',
                    nodeId: 'real_estate_non_principal_purchase_price',
                    widthFraction: 0.35,
                  ),
                  LayoutNodeRef(
                    id: 'real_estate_non_principal_value_ref',
                    nodeId: 'real_estate_non_principal_value_at_death',
                    widthFraction: 0.35,
                  ),
                ],
              ),
              LayoutRow(
                id: 'real_estate_non_principal_row_2',
                children: [
                  LayoutNodeRef(
                    id: 'real_estate_non_principal_ownership_history_ref',
                    nodeId: 'real_estate_non_principal_ownership_history_notes',
                    widthFraction: 0.5,
                  ),
                  LayoutNodeRef(
                    id: 'real_estate_non_principal_improvements_ref',
                    nodeId: 'real_estate_non_principal_significant_improvements_notes',
                    widthFraction: 0.5,
                  ),
                ],
              ),
              LayoutNodeRef(
                id: 'real_estate_non_principal_whats_happening_ref',
                nodeId: 'real_estate_non_principal_whats_happening_notes',
                widthFraction: 1.0,
              ),
            ],
          ),
        ],
      ),

      'other_docs_prior_two_years_tax_returns_rrn': NodeGroupDefinition(
        id: 'other_docs_prior_two_years_tax_returns_rrn',
        label: 'Prior two years tax returns',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('other_docs_prior_two_years_tax_returns'),
      ),
      'other_docs_donations_rrn': NodeGroupDefinition(
        id: 'other_docs_donations_rrn',
        label: 'Donations',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('other_docs_donations'),
      ),
      'other_docs_medical_receipts_rrn': NodeGroupDefinition(
        id: 'other_docs_medical_receipts_rrn',
        label: 'Medical receipts',
        repeatable: false,
        minInstances: 1,
        children: rrnChildren('other_docs_medical_receipts'),
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
                  nodeId: 'deceased_full_name',
                  widthFraction: 0.35,
                ),
                LayoutNodeRef(
                  id: 'deceased_dob_ref',
                  nodeId: 'deceased_date_of_birth',
                  widthFraction: 0.2,
                ),
                LayoutNodeRef(
                  id: 'deceased_dod_ref',
                  nodeId: 'deceased_date_of_death',
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
                  id: 'partner_info_group_married',
                  label: 'Partner Info',
                  visibilityCondition: const ChoiceEqualsCondition(
                    nodeId: 'deceased_marital_status',
                    choiceIndex: 0,
                    expectedValue: true,
                  ),
                  children: [
                    LayoutRow(
                      id: 'partner_row_married',
                      children: [
                        LayoutNodeRef(
                          id: 'partner_full_name_ref_married',
                          nodeId: 'partner_full_name',
                          widthFraction: 0.4,
                        ),
                        LayoutNodeRef(
                          id: 'partner_dob_ref_married',
                          nodeId: 'partner_date_of_birth',
                          widthFraction: 0.3,
                        ),
                        LayoutNodeRef(
                          id: 'partner_sin_ref_married',
                          nodeId: 'partner_sin',
                          widthFraction: 0.3,
                        ),
                      ],
                    ),
                    LayoutNodeRef(
                      id: 'partner_address_ref_married',
                      nodeId: 'partner_address',
                      widthFraction: 1.0,
                    ),
                  ],
                ),
                LayoutGroup(
                  id: 'partner_info_group_common_law',
                  label: 'Partner Info',
                  visibilityCondition: const ChoiceEqualsCondition(
                    nodeId: 'deceased_marital_status',
                    choiceIndex: 1,
                    expectedValue: true,
                  ),
                  children: [
                    LayoutRow(
                      id: 'partner_row_common_law',
                      children: [
                        LayoutNodeRef(
                          id: 'partner_full_name_ref_common_law',
                          nodeId: 'partner_full_name',
                          widthFraction: 0.4,
                        ),
                        LayoutNodeRef(
                          id: 'partner_dob_ref_common_law',
                          nodeId: 'partner_date_of_birth',
                          widthFraction: 0.3,
                        ),
                        LayoutNodeRef(
                          id: 'partner_sin_ref_common_law',
                          nodeId: 'partner_sin',
                          widthFraction: 0.3,
                        ),
                      ],
                    ),
                    LayoutNodeRef(
                      id: 'partner_address_ref_common_law',
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
              nodeId: 'other_professionals_involved',
              widthFraction: 1.0,
            ),
            LayoutGroup(
              id: 'lawyer_group',
              label: 'Lawyer',
              visibilityCondition: const ChoiceEqualsCondition(
                nodeId: 'other_professionals_involved',
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
              id: 'investment_advisor_group',
              label: 'Investment Advisor',
              visibilityCondition: const ChoiceEqualsCondition(
                nodeId: 'other_professionals_involved',
                choiceIndex: 1,
                expectedValue: true,
              ),
              children: [
                LayoutNodeRef(
                  id: 'investment_advisor_name_ref',
                  nodeId: 'investment_advisor_name',
                  widthFraction: 1.0,
                ),
                LayoutRow(
                  id: 'investment_advisor_row_1',
                  children: [
                    LayoutNodeRef(
                      id: 'investment_advisor_firm_phone_ref',
                      nodeId: 'investment_advisor_firm_phone',
                      widthFraction: 0.5,
                    ),
                    LayoutNodeRef(
                      id: 'investment_advisor_firm_email_ref',
                      nodeId: 'investment_advisor_firm_email',
                      widthFraction: 0.5,
                    ),
                  ],
                ),
                LayoutRow(
                  id: 'investment_advisor_row_2',
                  children: [
                    LayoutNodeRef(
                      id: 'investment_advisor_rep_phone_ref',
                      nodeId: 'investment_advisor_rep_phone',
                      widthFraction: 0.5,
                    ),
                    LayoutNodeRef(
                      id: 'investment_advisor_rep_email_ref',
                      nodeId: 'investment_advisor_rep_email',
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
              id: 'retrieve_death_certificate_group',
              label: 'Death Certificate',
              groupId: 'retrieve_death_certificate_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'retrieve_will_certificate_group',
              label: 'Will / Certificate of Appointment',
              groupId: 'retrieve_will_certificate_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'retrieve_list_of_assets_group',
              label: 'List of Assets',
              groupId: 'retrieve_list_of_assets_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'retrieve_estate_information_return_group',
              label: 'Estate Information Return',
              groupId: 'retrieve_estate_information_return_rrn',
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
              id: 'non_registered_accounts_repeatable_section',
              label: 'Non-Registered Accounts',
              groupId: 'non_registered_account_group',
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
              id: 'real_estate_repeatable_section',
              label: 'Real Estate',
              groupId: 'real_estate_group',
              children: const [],
            ),
            LayoutGroup(
              id: 'other_assets_repeatable_section',
              label: 'Other Assets',
              groupId: 'other_assets_group',
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
              id: 'other_docs_tax_returns_group',
              label: 'Prior two years tax returns',
              groupId: 'other_docs_prior_two_years_tax_returns_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'other_docs_donations_group',
              label: 'Donations',
              groupId: 'other_docs_donations_rrn',
              children: const [],
            ),
            LayoutGroup(
              id: 'other_docs_medical_receipts_group',
              label: 'Medical receipts',
              groupId: 'other_docs_medical_receipts_rrn',
              children: const [],
            ),
          ],
        ),
      ),
    ],
    dataSpecs: {
      'deceased_full_name': DataSpec(
        formNodeID: 'deceased_full_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'deceased_date_of_birth': DataSpec(
        formNodeID: 'deceased_date_of_birth',
        valueKind: ValueKind.date,
        profile: ValueProfile.dateDdMmYyyy,
      ),
      'deceased_date_of_death': DataSpec(
        formNodeID: 'deceased_date_of_death',
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
      'partner_full_name': DataSpec(
        formNodeID: 'partner_full_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'partner_date_of_birth': DataSpec(
        formNodeID: 'partner_date_of_birth',
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

      'executor_primary_full_name': DataSpec(
        formNodeID: 'executor_primary_full_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_primary_address': DataSpec(
        formNodeID: 'executor_primary_address',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_primary_contact_info': DataSpec(
        formNodeID: 'executor_primary_contact_info',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_other_full_name': DataSpec(
        formNodeID: 'executor_other_full_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_other_address': DataSpec(
        formNodeID: 'executor_other_address',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_other_contact_info': DataSpec(
        formNodeID: 'executor_other_contact_info',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'executor_compensation': DataSpec(
        formNodeID: 'executor_compensation',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'executor_compensation_sin': DataSpec(
        formNodeID: 'executor_compensation_sin',
        valueKind: ValueKind.number,
        profile: ValueProfile.sinCanada,
      ),
      'executor_compensation_income_notes': DataSpec(
        formNodeID: 'executor_compensation_income_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'other_professionals_involved': DataSpec(
        formNodeID: 'other_professionals_involved',
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
      'investment_advisor_firm_phone': DataSpec(
        formNodeID: 'investment_advisor_firm_phone',
        valueKind: ValueKind.string,
        profile: ValueProfile.phoneNorthAmerica,
      ),
      'investment_advisor_firm_email': DataSpec(
        formNodeID: 'investment_advisor_firm_email',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'investment_advisor_rep_phone': DataSpec(
        formNodeID: 'investment_advisor_rep_phone',
        valueKind: ValueKind.string,
        profile: ValueProfile.phoneNorthAmerica,
      ),
      'investment_advisor_rep_email': DataSpec(
        formNodeID: 'investment_advisor_rep_email',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'investment_advisor_name': DataSpec(
        formNodeID: 'investment_advisor_name',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'retrieve_death_certificate_requested': DataSpec(
        formNodeID: 'retrieve_death_certificate_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_death_certificate_received': DataSpec(
        formNodeID: 'retrieve_death_certificate_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_death_certificate_notes': DataSpec(
        formNodeID: 'retrieve_death_certificate_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'retrieve_will_certificate_requested': DataSpec(
        formNodeID: 'retrieve_will_certificate_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_will_certificate_received': DataSpec(
        formNodeID: 'retrieve_will_certificate_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_will_certificate_notes': DataSpec(
        formNodeID: 'retrieve_will_certificate_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'retrieve_list_of_assets_requested': DataSpec(
        formNodeID: 'retrieve_list_of_assets_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_list_of_assets_received': DataSpec(
        formNodeID: 'retrieve_list_of_assets_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_list_of_assets_notes': DataSpec(
        formNodeID: 'retrieve_list_of_assets_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'retrieve_estate_information_return_requested': DataSpec(
        formNodeID: 'retrieve_estate_information_return_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_estate_information_return_received': DataSpec(
        formNodeID: 'retrieve_estate_information_return_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'retrieve_estate_information_return_notes': DataSpec(
        formNodeID: 'retrieve_estate_information_return_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'rrsp_riff_value_at_death': DataSpec(
        formNodeID: 'rrsp_riff_value_at_death',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'rrsp_riff_named_beneficiary': DataSpec(
        formNodeID: 'rrsp_riff_named_beneficiary',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'rrsp_statement_month_of_liquidation_requested': DataSpec(
        formNodeID: 'rrsp_statement_month_of_liquidation_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'rrsp_statement_month_of_liquidation_received': DataSpec(
        formNodeID: 'rrsp_statement_month_of_liquidation_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'rrsp_statement_month_of_liquidation_notes': DataSpec(
        formNodeID: 'rrsp_statement_month_of_liquidation_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'rrsp_account_group_institution': DataSpec(
        formNodeID: 'rrsp_account_group_institution',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'rrsp_account_group_account_number': DataSpec(
        formNodeID: 'rrsp_account_group_account_number',
        valueKind: ValueKind.number,
        profile: ValueProfile.plainText,
      ),

      'non_registered_unrealized_gain_loss_at_death': DataSpec(
        formNodeID: 'non_registered_unrealized_gain_loss_at_death',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'non_registered_dividends': DataSpec(
        formNodeID: 'non_registered_dividends',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'non_registered_statements_year_of_death_requested': DataSpec(
        formNodeID: 'non_registered_statements_year_of_death_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'non_registered_statements_year_of_death_received': DataSpec(
        formNodeID: 'non_registered_statements_year_of_death_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'non_registered_statements_year_of_death_notes': DataSpec(
        formNodeID: 'non_registered_statements_year_of_death_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'non_registered_statements_to_liquidation_requested': DataSpec(
        formNodeID: 'non_registered_statements_to_liquidation_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'non_registered_statements_to_liquidation_received': DataSpec(
        formNodeID: 'non_registered_statements_to_liquidation_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'non_registered_statements_to_liquidation_notes': DataSpec(
        formNodeID: 'non_registered_statements_to_liquidation_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'non_registered_account_group_institution': DataSpec(
        formNodeID: 'non_registered_account_group_institution',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'non_registered_account_group_account_number': DataSpec(
        formNodeID: 'non_registered_account_group_account_number',
        valueKind: ValueKind.number,
        profile: ValueProfile.plainText,
      ),

      'shares_notes': DataSpec(
        formNodeID: 'shares_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'real_estate_principal_residence': DataSpec(
        formNodeID: 'real_estate_principal_residence',
        valueKind: ValueKind.stringList,
        profile: ValueProfile.plainText,
      ),
      'real_estate_principal_year_of_purchase': DataSpec(
        formNodeID: 'real_estate_principal_year_of_purchase',
        valueKind: ValueKind.number,
        profile: ValueProfile.plainText,
      ),
      'real_estate_principal_value_at_death': DataSpec(
        formNodeID: 'real_estate_principal_value_at_death',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'real_estate_principal_whats_happening_notes': DataSpec(
        formNodeID: 'real_estate_principal_whats_happening_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'real_estate_non_principal_year_of_purchase': DataSpec(
        formNodeID: 'real_estate_non_principal_year_of_purchase',
        valueKind: ValueKind.date,
        profile: ValueProfile.dateDdMmYyyy,
      ),
      'real_estate_non_principal_purchase_price': DataSpec(
        formNodeID: 'real_estate_non_principal_purchase_price',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'real_estate_non_principal_value_at_death': DataSpec(
        formNodeID: 'real_estate_non_principal_value_at_death',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),
      'real_estate_non_principal_ownership_history_notes': DataSpec(
        formNodeID: 'real_estate_non_principal_ownership_history_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'real_estate_non_principal_significant_improvements_notes': DataSpec(
        formNodeID: 'real_estate_non_principal_significant_improvements_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'real_estate_non_principal_whats_happening_notes': DataSpec(
        formNodeID: 'real_estate_non_principal_whats_happening_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'real_estate_address': DataSpec(
        formNodeID: 'real_estate_address',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),

      'other_asset_description': DataSpec(
        formNodeID: 'other_asset_description',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'other_asset_value': DataSpec(
        formNodeID: 'other_asset_value',
        valueKind: ValueKind.number,
        profile: ValueProfile.moneyCents,
      ),

      'other_docs_prior_two_years_tax_returns_requested': DataSpec(
        formNodeID: 'other_docs_prior_two_years_tax_returns_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'other_docs_prior_two_years_tax_returns_received': DataSpec(
        formNodeID: 'other_docs_prior_two_years_tax_returns_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'other_docs_prior_two_years_tax_returns_notes': DataSpec(
        formNodeID: 'other_docs_prior_two_years_tax_returns_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'other_docs_donations_requested': DataSpec(
        formNodeID: 'other_docs_donations_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'other_docs_donations_received': DataSpec(
        formNodeID: 'other_docs_donations_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'other_docs_donations_notes': DataSpec(
        formNodeID: 'other_docs_donations_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
      'other_docs_medical_receipts_requested': DataSpec(
        formNodeID: 'other_docs_medical_receipts_requested',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'other_docs_medical_receipts_received': DataSpec(
        formNodeID: 'other_docs_medical_receipts_received',
        valueKind: ValueKind.boolean,
        profile: ValueProfile.plainText,
      ),
      'other_docs_medical_receipts_notes': DataSpec(
        formNodeID: 'other_docs_medical_receipts_notes',
        valueKind: ValueKind.string,
        profile: ValueProfile.plainText,
      ),
    },
  );
}
