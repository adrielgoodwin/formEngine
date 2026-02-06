import 'dart:typed_data';
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/case_record.dart';
import '../models/form_block.dart';
import '../models/form_definition.dart';
import '../models/form_instance.dart';
import '../models/form_node.dart';
import '../models/group_instance.dart';
import '../models/layout_item.dart';
import '../logging/app_logger.dart';

// =============================================================================
// FieldEntry: Represents a single field for PDF layout
// =============================================================================

class FieldEntry {
  final String label;
  final String value;
  final double weight; // 0.0–1.0, from widthFraction
  final bool preferFullWidth;

  const FieldEntry({
    required this.label,
    required this.value,
    required this.weight,
    this.preferFullWidth = false,
  });
}

bool _hasAnyRenderableValue(
  LayoutItem item,
  FormDefinition def,
  Map<String, Object?> scopeValues,
) {
  switch (item) {
    case LayoutNodeRef():
      final node = def.nodes[item.nodeId];
      if (node == null) return false;
      final value = scopeValues[item.nodeId];
      final spec = def.dataSpecs[item.nodeId];
      final displayValue = _formatValue(value, node, spec);
      return displayValue != null && displayValue.isNotEmpty;

    case LayoutRow():
      for (final child in item.children) {
        if (_hasAnyRenderableValue(child, def, scopeValues)) return true;
      }
      return false;

    case LayoutColumn():
      for (final child in item.children) {
        if (_hasAnyRenderableValue(child, def, scopeValues)) return true;
      }
      return false;

    case LayoutGroup():
      // If groupId is set and children are empty (repeatable groups), we don't
      // have enough info at this layer to introspect the group's internal nodeIds.
      // For inline groups (no groupId), recurse into children.
      if (item.groupId != null && item.children.isEmpty) return false;
      for (final child in item.children) {
        if (_hasAnyRenderableValue(child, def, scopeValues)) return true;
      }
      return false;
  }
}

// =============================================================================
// SectionEntry: Represents a section header or group instance header
// =============================================================================

sealed class PdfElement {}

class PdfSectionHeader extends PdfElement {
  final String title;
  final int level; // 1 = block, 2 = group/subsection
  final PdfColor? color; // Optional color for block headers
  PdfSectionHeader(this.title, {this.level = 1, this.color});
}

class PdfFieldRow extends PdfElement {
  final List<FieldEntry> entries;
  PdfFieldRow(this.entries);
}

class PdfDivider extends PdfElement {}

class PdfSpacer extends PdfElement {
  final double height;
  PdfSpacer([this.height = 8]);
}

// =============================================================================
// Main PDF Builder
// =============================================================================

Future<Uint8List> buildCasePdf(CaseRecord record, FormDefinition def) async {
  final pdf = pw.Document();
  final instance = record.formInstance;

  final elements = _buildPdfElements(def, instance);

  // Extract deceased name and DOD for header
  final deceasedName = (instance.getValue<String>('deceased_name') ?? '').trim();
  final rawDod = (instance.getValue<String>('deceased_dod') ?? '').trim();
  final dodFormatted = _formatDateWithMonth(rawDod);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        // Primary header: Deceased name + DOD on same line
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              deceasedName.isNotEmpty ? deceasedName : record.title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            if (dodFormatted.isNotEmpty) ...[
              pw.SizedBox(width: 12),
              pw.Text(
                'DOD: $dodFormatted',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ],
            pw.Spacer(),
            pw.Text(
              'Generated ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
            ),
          ],
        ),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
        ...elements.map(_renderPdfElement),
      ],
    ),
  );

  return pdf.save();
}

// =============================================================================
// Block Ordering (matches single-column UI layout)
// =============================================================================

/// Orders blocks to match the single-column UI layout:
/// 1. Deceased, 2. Trustees, 3. Professionals, 4. Documents, 5. Tax History, 6. Assets
List<FormBlock> _orderBlocksForPdf(List<FormBlock> blocks) {
  final blockMap = {for (final b in blocks) b.id: b};
  
  // Define explicit order matching single-column UI
  final orderedIds = [
    'block_deceased_information',
    'block_trustee_contact_persons',
    'block_other_professionals',
    'block_documents',
    'block_tax_history',
    'block_asset_details',
  ];
  
  final result = <FormBlock>[];
  for (final id in orderedIds) {
    final block = blockMap.remove(id);
    if (block != null) result.add(block);
  }
  
  // Append any remaining blocks not in the explicit list (future-proofing)
  result.addAll(blockMap.values);
  
  return result;
}

// =============================================================================
// Build PDF Elements from Form Structure
// =============================================================================

List<PdfElement> _buildPdfElements(FormDefinition def, FormInstance instance) {
  final elements = <PdfElement>[];
  final renderedNodeIds = <String>{};

  // Order blocks to match single-column UI layout:
  // 1. Deceased, 2. Trustees, 3. Professionals, 4. Documents, 5. Tax History, 6. Assets
  final orderedBlocks = _orderBlocksForPdf(def.blocks);

  for (final block in orderedBlocks) {
    // Skip blocks with empty titles (shouldn't happen, but defensive)
    if (block.title.isEmpty) continue;
    
    // Convert Flutter Color to PDF Color
    PdfColor? blockColor;
    if (block.colorScheme != BlockColorScheme.none) {
      final flutterColor = block.getPrimaryColor();
      blockColor = PdfColor.fromInt(flutterColor.toARGB32());
    }
    
    elements.add(PdfSectionHeader(block.title, level: 1, color: blockColor));
    elements.addAll(_extractElementsFromLayout(
      [block.layout],
      def,
      instance,
      instance.values,
      renderedNodeIds,
    ));
    elements.add(PdfSpacer(6));
  }

  final remaining = _buildRemainingFieldEntries(def, instance, renderedNodeIds);
  if (remaining.isNotEmpty) {
    elements.add(PdfSectionHeader('Additional Fields', level: 1));
    elements.addAll(_packFieldsIntoRows(remaining));
    elements.add(PdfSpacer(12));
  }

  return elements;
}

/// Headers to suppress in PDF output (rendered inline instead)
const _suppressedHeaders = {'Partner Info', 'Professionals'};

/// Group IDs where dividers go at TOP of each instance (including first)
const _dividerAtTopGroups = {'trustee_group'};

/// Renders a LayoutGroup that references a named group (with groupId).
/// Handles both repeatable and non-repeatable (RRN) groups.
List<PdfElement> _renderGroupWithId(
  LayoutGroup item,
  FormDefinition def,
  FormInstance instance,
  Set<String> renderedNodeIds,
) {
  final elements = <PdfElement>[];
  final groupDef = def.groups[item.groupId];
  if (groupDef == null) return elements;

  if (groupDef.repeatable) {
    final instances = instance.getGroupInstances(item.groupId!);
    if (instances.isEmpty) return elements;

    final showLabel = item.label.isNotEmpty &&
        !_suppressedHeaders.contains(item.label);
    if (showLabel) {
      elements.add(PdfSectionHeader(item.label, level: 2));
    }

    final dividerAtTop = _dividerAtTopGroups.contains(item.groupId);
    for (var i = 0; i < instances.length; i++) {
      if (dividerAtTop) {
        elements.add(PdfDivider());
      } else if (i > 0) {
        elements.add(PdfDivider());
      }
      elements.addAll(_extractGroupInstanceElements(
        groupDef.children, def, instance, instances[i], renderedNodeIds,
      ));
    }
  } else {
    // Non-repeatable group (RRN-style)
    final instances = instance.getGroupInstances(item.groupId!);
    if (instances.isNotEmpty) {
      if (item.label.isNotEmpty) {
        elements.add(PdfSectionHeader(item.label, level: 2));
      }
      elements.addAll(_extractGroupInstanceElements(
        groupDef.children, def, instance, instances.first, renderedNodeIds,
      ));
    }
  }
  return elements;
}

List<PdfElement> _extractElementsFromLayout(
  List<LayoutItem> items,
  FormDefinition def,
  FormInstance instance,
  Map<String, Object?> scopeValues,
  Set<String> renderedNodeIds,
) {
  final fieldEntries = <FieldEntry>[];
  final elements = <PdfElement>[];

  void flushFields() {
    if (fieldEntries.isNotEmpty) {
      elements.addAll(_packFieldsIntoRows(fieldEntries));
      fieldEntries.clear();
    }
  }

  for (final item in items) {
    if (item.visibilityCondition != null &&
        !item.visibilityCondition!.evaluate(scopeValues) &&
        !_hasAnyRenderableValue(item, def, scopeValues)) {
      continue;
    }

    switch (item) {
      case LayoutNodeRef():
        final entry = _createFieldEntry(item, def, scopeValues, renderedNodeIds);
        if (entry != null) fieldEntries.add(entry);

      case LayoutRow():
        for (final child in item.children) {
          if (child.visibilityCondition != null &&
              !child.visibilityCondition!.evaluate(scopeValues) &&
              !_hasAnyRenderableValue(child, def, scopeValues)) {
            continue;
          }
          if (child is LayoutNodeRef) {
            final entry = _createFieldEntry(child, def, scopeValues, renderedNodeIds);
            if (entry != null) fieldEntries.add(entry);
          } else if (child is LayoutColumn) {
            flushFields();
            elements.addAll(_extractElementsFromLayout(
              child.children, def, instance, scopeValues, renderedNodeIds,
            ));
          } else if (child is LayoutGroup) {
            flushFields();
            if (child.groupId != null) {
              elements.addAll(_renderGroupWithId(child, def, instance, renderedNodeIds));
            } else {
              // Inline group without groupId (e.g. conditional sections)
              final showLabel = child.label.isNotEmpty &&
                  !_suppressedHeaders.contains(child.label);
              if (showLabel) {
                elements.add(PdfSectionHeader(child.label, level: 2));
              }
              elements.addAll(_extractElementsFromLayout(
                child.children, def, instance, scopeValues, renderedNodeIds,
              ));
            }
          }
        }

      case LayoutColumn():
        elements.addAll(_extractElementsFromLayout(
          item.children, def, instance, scopeValues, renderedNodeIds,
        ));

      case LayoutGroup():
        flushFields();
        if (item.groupId != null) {
          elements.addAll(_renderGroupWithId(item, def, instance, renderedNodeIds));
        } else {
          // Inline group without groupId
          final showLabel = item.label.isNotEmpty &&
              !_suppressedHeaders.contains(item.label);
          if (showLabel) {
            elements.add(PdfSectionHeader(item.label, level: 2));
          }
          elements.addAll(_extractElementsFromLayout(
            item.children, def, instance, scopeValues, renderedNodeIds,
          ));
        }
    }
  }

  flushFields();
  return elements;
}

List<PdfElement> _extractGroupInstanceElements(
  List<LayoutItem> items,
  FormDefinition def,
  FormInstance instance,
  GroupInstance groupInstance,
  Set<String> renderedNodeIds,
) {
  final scopeValues = {...instance.values, ...groupInstance.values};
  final fieldEntries = <FieldEntry>[];
  final elements = <PdfElement>[];

  void flushFields() {
    if (fieldEntries.isNotEmpty) {
      elements.addAll(_packFieldsIntoRows(fieldEntries));
      fieldEntries.clear();
    }
  }

  for (final item in items) {
    if (item.visibilityCondition != null &&
        !item.visibilityCondition!.evaluate(scopeValues) &&
        !_hasAnyRenderableValue(item, def, scopeValues)) {
      continue;
    }

    switch (item) {
      case LayoutNodeRef():
        final value = groupInstance.values[item.nodeId] ?? instance.values[item.nodeId];
        final entry = _createFieldEntryFromValue(item, value, def, renderedNodeIds);
        if (entry != null) fieldEntries.add(entry);

      case LayoutRow():
        for (final child in item.children) {
          if (child.visibilityCondition != null &&
              !child.visibilityCondition!.evaluate(scopeValues) &&
              !_hasAnyRenderableValue(child, def, scopeValues)) {
            continue;
          }
          if (child is LayoutNodeRef) {
            final value = groupInstance.values[child.nodeId] ?? instance.values[child.nodeId];
            final entry = _createFieldEntryFromValue(child, value, def, renderedNodeIds);
            if (entry != null) fieldEntries.add(entry);
          } else if (child is LayoutColumn) {
            flushFields();
            elements.addAll(_extractGroupInstanceElements(
              child.children, def, instance, groupInstance, renderedNodeIds,
            ));
          } else if (child is LayoutGroup) {
            flushFields();
            elements.addAll(_resolveGroupInInstance(
              child, def, instance, groupInstance, renderedNodeIds,
            ));
          }
        }

      case LayoutColumn():
        elements.addAll(_extractGroupInstanceElements(
          item.children, def, instance, groupInstance, renderedNodeIds,
        ));

      case LayoutGroup():
        flushFields();
        elements.addAll(_resolveGroupInInstance(
          item, def, instance, groupInstance, renderedNodeIds,
        ));
    }
  }

  flushFields();
  return elements;
}

/// Handles a LayoutGroup encountered inside a group instance.
/// If the group has a groupId, looks up the group definition and renders
/// its children (fixing the bug where nested RRN content was empty).
List<PdfElement> _resolveGroupInInstance(
  LayoutGroup item,
  FormDefinition def,
  FormInstance instance,
  GroupInstance parentGroupInstance,
  Set<String> renderedNodeIds,
) {
  final elements = <PdfElement>[];

  if (item.groupId != null) {
    // Named sub-group (e.g. RRN under assets like rrsp_liquidation)
    final groupDef = def.groups[item.groupId];
    if (groupDef == null) return elements;

    final instances = instance.getGroupInstances(item.groupId!);
    if (instances.isNotEmpty) {
      if (item.label.isNotEmpty) {
        elements.add(PdfSectionHeader(item.label, level: 2));
      }
      // Use the group definition's children (not the empty layout children)
      elements.addAll(_extractGroupInstanceElements(
        groupDef.children, def, instance, instances.first, renderedNodeIds,
      ));
    }
  } else {
    // Inline group without groupId (conditional sections)
    final showLabel = item.label.isNotEmpty &&
        !_suppressedHeaders.contains(item.label);
    if (showLabel) {
      elements.add(PdfSectionHeader(item.label, level: 2));
    }
    elements.addAll(_extractGroupInstanceElements(
      item.children, def, instance, parentGroupInstance, renderedNodeIds,
    ));
  }

  return elements;
}

// =============================================================================
// Field Entry Creation
// =============================================================================

/// Label overrides for PDF display
String _pdfLabel(String originalLabel, String nodeId) {
  // Rename date labels to abbreviated forms
  if (originalLabel == 'Date of Birth') return 'DOB';
  if (originalLabel == 'Date of Death') return 'DOD';
  // Normalize verbose RRN notes labels to just "Notes"
  if (nodeId.endsWith('_notes') && originalLabel.length > 20) return 'Notes';
  return originalLabel;
}

FieldEntry? _createFieldEntry(
  LayoutNodeRef nodeRef,
  FormDefinition def,
  Map<String, Object?> scopeValues,
  Set<String> renderedNodeIds,
) {
  final value = scopeValues[nodeRef.nodeId];
  return _createFieldEntryFromValue(nodeRef, value, def, renderedNodeIds);
}

FieldEntry? _createFieldEntryFromValue(
  LayoutNodeRef nodeRef,
  Object? value,
  FormDefinition def,
  Set<String> renderedNodeIds,
) {
  final node = def.nodes[nodeRef.nodeId];
  if (node == null) return null;

  final dataSpec = def.dataSpecs[nodeRef.nodeId];
  final displayValue = _formatValue(value, node, dataSpec);

  // Omit empty fields for compactness
  if (displayValue == null || displayValue.isEmpty) return null;

  renderedNodeIds.add(nodeRef.nodeId);

  // Determine if field prefers full width based on content length or type
  final preferFullWidth = _shouldPreferFullWidth(displayValue, nodeRef.widthFraction, dataSpec);

  // Apply label overrides for PDF display
  final label = _pdfLabel(node.label, nodeRef.nodeId);

  return FieldEntry(
    label: label,
    value: displayValue,
    weight: nodeRef.widthFraction,
    preferFullWidth: preferFullWidth,
  );
}

List<FieldEntry> _buildRemainingFieldEntries(
  FormDefinition def,
  FormInstance instance,
  Set<String> renderedNodeIds,
) {
  final entries = <FieldEntry>[];

  void addIfPresent(String nodeId, Object? value) {
    if (renderedNodeIds.contains(nodeId)) return;
    final node = def.nodes[nodeId];
    if (node == null) return;
    final spec = def.dataSpecs[nodeId];
    final displayValue = _formatValue(value, node, spec);
    if (displayValue == null || displayValue.isEmpty) return;

    renderedNodeIds.add(nodeId);
    final preferFullWidth = _shouldPreferFullWidth(displayValue, 1.0, spec);
    entries.add(
      FieldEntry(
        label: node.label,
        value: displayValue,
        weight: 1.0,
        preferFullWidth: preferFullWidth,
      ),
    );
  }

  for (final nodeId in def.dataSpecs.keys) {
    addIfPresent(nodeId, instance.values[nodeId]);
  }

  for (final entry in instance.values.entries) {
    addIfPresent(entry.key, entry.value);
  }

  return entries;
}

bool _shouldPreferFullWidth(String value, double widthFraction, DataSpec? dataSpec) {
  // Full width if explicitly set to 1.0
  if (widthFraction >= 0.9) return true;
  // Full width for long text (addresses, notes)
  if (value.length > 60) return true;
  // Full width for multi-line content
  if (value.contains('\n')) return true;
  return false;
}

// =============================================================================
// Row Packing Algorithm
// =============================================================================

List<PdfFieldRow> _packFieldsIntoRows(List<FieldEntry> entries) {
  final rows = <PdfFieldRow>[];
  var currentRow = <FieldEntry>[];
  var currentWeight = 0.0;

  for (final entry in entries) {
    if (entry.preferFullWidth) {
      // Flush current row first
      if (currentRow.isNotEmpty) {
        rows.add(PdfFieldRow(List.from(currentRow)));
        currentRow.clear();
        currentWeight = 0.0;
      }
      // Add full-width entry as its own row
      rows.add(PdfFieldRow([entry]));
    } else if (currentWeight + entry.weight > 1.05) {
      // Would overflow; start new row
      if (currentRow.isNotEmpty) {
        rows.add(PdfFieldRow(List.from(currentRow)));
        currentRow.clear();
        currentWeight = 0.0;
      }
      currentRow.add(entry);
      currentWeight = entry.weight;
    } else {
      // Fits in current row
      currentRow.add(entry);
      currentWeight += entry.weight;
    }
  }

  // Flush remaining
  if (currentRow.isNotEmpty) {
    rows.add(PdfFieldRow(currentRow));
  }

  return rows;
}

// =============================================================================
// PDF Element Rendering
// =============================================================================

pw.Widget _renderPdfElement(PdfElement element) {
  switch (element) {
    case PdfSectionHeader():
      if (element.level == 1) {
        // Level 1: Colored text section header (no background box)
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 8, bottom: 2),
          child: pw.Text(
            element.title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: element.color ?? PdfColors.black,
            ),
          ),
        );
      } else {
        // Level 2: Subsection headers (groups, repeatable instances)
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 3, bottom: 1),
          child: pw.Text(
            element.title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        );
      }

    case PdfFieldRow():
      return _renderFieldRow(element.entries);

    case PdfDivider():
      return pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Divider(thickness: 0.3, color: PdfColors.grey400),
      );

    case PdfSpacer():
      return pw.SizedBox(height: element.height);
  }
}

pw.Widget _renderFieldRow(List<FieldEntry> entries) {
  if (entries.length == 1 && entries.first.preferFullWidth) {
    // Full-width field
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            entries.first.label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            entries.first.value,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // Multi-column row
  final totalWeight = entries.fold(0.0, (sum, e) => sum + e.weight);

  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: entries.asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final entry = mapEntry.value;
        // Normalize flex to make row fill width
        final flex = ((entry.weight / totalWeight) * 100).round();

        return pw.Expanded(
          flex: flex,
          child: pw.Container(
            padding: pw.EdgeInsets.only(right: index < entries.length - 1 ? 8 : 0),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${entry.label}: ',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.TextSpan(
                    text: entry.value,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

String? _formatValue(Object? value, FormNode node, DataSpec? dataSpec) {
  if (value == null) return null;

  switch (node) {
    case TextInputNode():
      final profile = dataSpec?.profile ?? ValueProfile.plainText;
      return _formatTextValue(value, profile);

    case ChoiceInputNode():
      if (value is List<bool>) {
        // Single-checkbox style (e.g. Requested/Received with ['Yes'])
        // Always show Yes/No to keep RRN rows intact
        if (node.choiceLabels.length == 1 && node.choiceLabels.first == 'Yes') {
          return (value.isNotEmpty && value.first) ? 'Yes' : 'No';
        }
        // Yes/No binary choice — show as plain text
        if (node.choiceLabels.length == 2 &&
            node.choiceLabels[0] == 'Yes' && node.choiceLabels[1] == 'No') {
          final yesSelected = value.isNotEmpty && value[0];
          return yesSelected ? 'Yes' : 'No';
        }
        final selected = <String>[];
        for (var i = 0; i < value.length && i < node.choiceLabels.length; i++) {
          if (value[i]) selected.add(node.choiceLabels[i]);
        }
        return selected.isEmpty ? null : selected.join(', ');
      }
      return null;
  }
}

String? _formatTextValue(Object? value, ValueProfile profile) {
  if (value == null) return null;

  switch (profile) {
    case ValueProfile.moneyCents:
      if (value is int) {
        final isNegative = value < 0;
        final absValue = value.abs();
        final dollars = absValue ~/ 100;
        final cents = absValue % 100;
        final sign = isNegative ? '-' : '';
        final formatted = '$sign\$${_formatWithCommas(dollars)}.${cents.toString().padLeft(2, '0')}';
        return formatted;
      }
      return value.toString();

    case ValueProfile.dateDdMmYyyy:
      return _formatDateWithMonth(value.toString());

    case ValueProfile.sinCanada:
      final digits = value.toString().replaceAll(RegExp(r'\D'), '');
      if (digits.length == 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';
      }
      return value.toString();

    case ValueProfile.phoneNorthAmerica:
      final digits = value.toString().replaceAll(RegExp(r'\D'), '');
      if (digits.length == 10) {
        return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
      }
      return value.toString();

    case ValueProfile.plainText:
      final str = value.toString();
      return str.isEmpty ? null : str;
  }
}

String _formatWithCommas(int number) {
  final str = number.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

String _formatDateTime(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

const _monthNames = [
  'jan', 'feb', 'mar', 'apr', 'may', 'jun',
  'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
];

/// Formats a dd/mm/yyyy string to dd/mon/yyyy (e.g. 14/feb/2024)
String _formatDateWithMonth(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final parts = raw.replaceAll(RegExp(r'[^\d/]'), '').split('/');
  if (parts.length != 3) return raw;
  final day = parts[0];
  final monthIndex = int.tryParse(parts[1]);
  final year = parts[2];
  if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return raw;
  return '$day/${_monthNames[monthIndex - 1]}/$year';
}

Future<void> previewCasePdf(CaseRecord record, FormDefinition def) async {
  if (Platform.isWindows) {
    final path = await createCasePdfFileForWindows(record, def);
    await openPdfFileOnWindows(path);
    return;
  }

  await Printing.layoutPdf(
    onLayout: (format) => buildCasePdf(record, def),
    name: '${record.title}.pdf',
  );
}

Future<String> createCasePdfFileForWindows(CaseRecord record, FormDefinition def) async {
  final logger = AppLogger.instance;
  final bytes = await buildCasePdf(record, def);

  final baseDir = await getApplicationSupportDirectory();
  final reportsDir = Directory(p.join(baseDir.path, 'EstateIntake', 'reports'));
  if (!reportsDir.existsSync()) {
    reportsDir.createSync(recursive: true);
  }

  final deceasedName = (record.formInstance.getValue<String>('deceased_name') ?? '').trim();
  final dod = (record.formInstance.getValue<String>('deceased_dod') ?? '').trim();
  final filename = _safeFilename(_buildReportFilename(deceasedName, dod, record.id));
  final filePath = p.join(reportsDir.path, filename);

  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
  logger.info('report', 'PDF generated: case=${record.id} path=$filePath');
  return filePath;
}

Future<bool> openPdfFileOnWindows(String filePath) async {
  final logger = AppLogger.instance;
  try {
    // explorer.exe can return a non-zero exit code even when it successfully
    // hands the file off to the default PDF viewer. Treat a successful spawn
    // as success and only fail on exception.
    await Process.start('explorer', [filePath]);
    logger.debug('report', 'Requested open PDF: path=$filePath');
    return true;
  } catch (e, st) {
    logger.error('report', 'Failed to open PDF: ${e.runtimeType}', error: e, stackTrace: st);
    return false;
  }
}

Future<bool> openPdfFolderOnWindows(String filePath) async {
  final logger = AppLogger.instance;
  try {
    final folder = Directory(p.dirname(filePath));
    final result = await Process.run('explorer', [folder.path]);
    final ok = result.exitCode == 0;
    if (!ok) {
      logger.warn('report', 'Failed to open PDF folder: exitCode=${result.exitCode}');
    }
    return ok;
  } catch (e, st) {
    logger.error('report', 'Failed to open PDF folder: ${e.runtimeType}', error: e, stackTrace: st);
    return false;
  }
}

String _buildReportFilename(String deceasedName, String dod, String caseId) {
  final namePart = deceasedName.isEmpty ? 'Unknown' : deceasedName;
  final dodPart = dod.isEmpty ? 'UnknownDoD' : dod;
  return '$namePart - $dodPart - $caseId.pdf';
}

String _safeFilename(String input) {
  final sanitized = input
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (sanitized.isEmpty) return 'report.pdf';
  return sanitized;
}
