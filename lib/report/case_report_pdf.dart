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

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text(
            record.title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated: ${_formatDateTime(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),
        ...elements.map(_renderPdfElement),
      ],
    ),
  );

  return pdf.save();
}

// =============================================================================
// Build PDF Elements from Form Structure
// =============================================================================

List<PdfElement> _buildPdfElements(FormDefinition def, FormInstance instance) {
  final elements = <PdfElement>[];
  final renderedNodeIds = <String>{};

  for (final block in def.blocks) {
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
    elements.add(PdfSpacer(12));
  }

  final remaining = _buildRemainingFieldEntries(def, instance, renderedNodeIds);
  if (remaining.isNotEmpty) {
    elements.add(PdfSectionHeader('Additional Fields', level: 1));
    elements.addAll(_packFieldsIntoRows(remaining));
    elements.add(PdfSpacer(12));
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
        // Collect fields from row children, handling all child types
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
            // Recurse into nested columns
            flushFields();
            elements.addAll(_extractElementsFromLayout(
              child.children,
              def,
              instance,
              scopeValues,
              renderedNodeIds,
            ));
          } else if (child is LayoutGroup) {
            // Handle inline groups (like Partner Info, Lawyer, Advisor)
            flushFields();
            if (child.groupId != null) {
              final groupDef = def.groups[child.groupId];
              if (groupDef != null && groupDef.repeatable) {
                final instances = instance.getGroupInstances(child.groupId!);
                if (instances.isNotEmpty) {
                  // Add section header for repeatable groups
                  if (child.label.isNotEmpty) {
                    elements.add(PdfSectionHeader(
                      child.label,
                      level: 2,
                    ));
                  }
                  for (var i = 0; i < instances.length; i++) {
                    final groupInstance = instances[i];
                    if (i > 0) elements.add(PdfDivider());
                    elements.addAll(_extractGroupInstanceElements(
                      groupDef.children,
                      def,
                      instance,
                      groupInstance,
                      renderedNodeIds,
                    ));
                  }
                }
              } else if (groupDef != null) {
                final instances = instance.getGroupInstances(child.groupId!);
                if (instances.isNotEmpty) {
                  // Add the group's label as a section header for RRN groups
                  if (child.label.isNotEmpty) {
                    elements.add(PdfSectionHeader(
                      child.label, 
                      level: 2,
                    ));
                  }
                  elements.addAll(_extractGroupInstanceElements(
                    groupDef.children,
                    def,
                    instance,
                    instances.first,
                    renderedNodeIds,
                  ));
                }
              }
            } else {
              if (child.label.isNotEmpty) {
                elements.add(PdfSectionHeader(
                  child.label, 
                  level: 2,
                ));
              }
              elements.addAll(_extractElementsFromLayout(
                child.children,
                def,
                instance,
                scopeValues,
                renderedNodeIds,
              ));
            }
          }
        }

      case LayoutColumn():
        elements.addAll(_extractElementsFromLayout(
          item.children,
          def,
          instance,
          scopeValues,
          renderedNodeIds,
        ));

      case LayoutGroup():
        flushFields();
        if (item.groupId != null) {
          final groupDef = def.groups[item.groupId];
          if (groupDef != null && groupDef.repeatable) {
            final instances = instance.getGroupInstances(item.groupId!);
            if (instances.isNotEmpty) {
              // Add section header for repeatable groups (assets, executors, etc.)
              if (item.label.isNotEmpty) {
                elements.add(PdfSectionHeader(
                  item.label,
                  level: 2,
                ));
              }
              for (var i = 0; i < instances.length; i++) {
                final groupInstance = instances[i];
                if (i > 0) elements.add(PdfDivider());
                elements.addAll(_extractGroupInstanceElements(
                  groupDef.children,
                  def,
                  instance,
                  groupInstance,
                  renderedNodeIds,
                ));
              }
            }
          } else if (groupDef != null) {
            final instances = instance.getGroupInstances(item.groupId!);
            if (instances.isNotEmpty) {
              // Add the group's label as a section header for RRN groups
              if (item.label.isNotEmpty) {
                elements.add(PdfSectionHeader(
                  item.label, 
                  level: 2,
                ));
              }
              elements.addAll(_extractGroupInstanceElements(
                groupDef.children,
                def,
                instance,
                instances.first,
                renderedNodeIds,
              ));
            }
          }
        } else {
          if (item.label.isNotEmpty) {
            elements.add(PdfSectionHeader(item.label, level: 2));
          }
          elements.addAll(_extractElementsFromLayout(
            item.children,
            def,
            instance,
            scopeValues,
            renderedNodeIds,
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
              child.children,
              def,
              instance,
              groupInstance,
              renderedNodeIds,
            ));
          } else if (child is LayoutGroup) {
            flushFields();
            if (child.label.isNotEmpty) {
              elements.add(PdfSectionHeader(
                child.label, 
                level: 2,
              ));
            }
            elements.addAll(_extractGroupInstanceElements(
              child.children,
              def,
              instance,
              groupInstance,
              renderedNodeIds,
            ));
          }
        }

      case LayoutColumn():
        elements.addAll(_extractGroupInstanceElements(
          item.children,
          def,
          instance,
          groupInstance,
          renderedNodeIds,
        ));

      case LayoutGroup():
        flushFields();
        if (item.label.isNotEmpty) {
          elements.add(PdfSectionHeader(
            item.label, 
            level: 2,
          ));
        }
        elements.addAll(_extractGroupInstanceElements(
          item.children,
          def,
          instance,
          groupInstance,
          renderedNodeIds,
        ));
    }
  }

  flushFields();
  return elements;
}

// =============================================================================
// Field Entry Creation
// =============================================================================

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

  return FieldEntry(
    label: node.label,
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
      final textColor = element.level == 1 && element.color != null 
          ? element.color! 
          : (element.level == 1 ? PdfColors.black : PdfColors.grey800);
      
      return pw.Container(
        margin: pw.EdgeInsets.only(
          top: element.level == 1 ? 8 : 6,
          bottom: element.level == 1 ? 4 : 2,
        ),
        child: pw.Text(
          element.title,
          style: pw.TextStyle(
            fontSize: element.level == 1 ? 13 : 10,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
      );

    case PdfFieldRow():
      return _renderFieldRow(element.entries);

    case PdfDivider():
      return pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 4),
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
      return value.toString();

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
