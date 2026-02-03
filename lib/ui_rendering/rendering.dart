import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/form_controllers.dart';
import '../logging/app_logger.dart';
import '../models/assembler.dart';
import '../models/form_block.dart';
import '../models/form_node.dart';
import '../models/group_instance.dart';
import '../state/form_state.dart';

/// Global state manager for block collapse states
class BlockCollapseState with ChangeNotifier {
  final Map<String, bool> _collapsedStates = {};
  
  bool isCollapsed(String blockId) {
    return _collapsedStates[blockId] ?? false;
  }
  
  void toggleBlock(String blockId) {
    _collapsedStates[blockId] = !(_collapsedStates[blockId] ?? false);
    notifyListeners();
  }
  
  void collapseAll() {
    for (final blockId in _collapsedStates.keys) {
      _collapsedStates[blockId] = true;
    }
    notifyListeners();
  }
  
  void expandAll() {
    for (final blockId in _collapsedStates.keys) {
      _collapsedStates[blockId] = false;
    }
    notifyListeners();
  }
  
  void initializeBlocks(List<String> blockIds) {
    for (final blockId in blockIds) {
      _collapsedStates.putIfAbsent(blockId, () => false);
    }
    notifyListeners();
  }
  
  bool allCollapsed() {
    return _collapsedStates.values.every((collapsed) => collapsed);
  }
  
  bool allExpanded() {
    return _collapsedStates.values.every((collapsed) => !collapsed);
  }
}

// Global instance
final _blockCollapseState = BlockCollapseState();

/// =======================
/// FORM ENTRY POINT
/// =======================

Widget renderForm(AssembledForm form, BuildContext context) {
  // Initialize block collapse states
  final blockIds = form.blocks.map((block) => block.id).toList();
  _blockCollapseState.initializeBlocks(blockIds);
  
  // Group blocks by column
  final column1Blocks = form.blocks.where((b) => b.formBlock.column == 1).toList();
  final column2Blocks = form.blocks.where((b) => b.formBlock.column == 2).toList();
  final column3Blocks = form.blocks.where((b) => b.formBlock.column == 3).toList();
  
  return ChangeNotifierProvider.value(
    value: _blockCollapseState,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(3),
            child: Column(
              children: column1Blocks.map((block) => renderBlock(block, context)).toList(),
            ),
          ),
        ),
        // Column 2
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(3),
            child: Column(
              children: column2Blocks.map((block) => renderBlock(block, context)).toList(),
            ),
          ),
        ),
        // Column 3
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(3),
            child: Column(
              children: column3Blocks.map((block) => renderBlock(block, context)).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

/// =======================
/// BLOCK RENDERING
/// =======================

class CollapsibleBlock extends StatelessWidget {
  final AssembledBlock block;
  final BuildContext context;

  const CollapsibleBlock({
    super.key,
    required this.block,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BlockCollapseState>(
      builder: (context, collapseState, child) {
        final isAssets = block.id == 'block_asset_details';
        final formBlock = block.formBlock;
        
        // Create border styling based on block configuration
        BorderSide? leftBorder;
        BorderSide? otherBorders;
        
        switch (formBlock.borderStyle) {
          case BlockBorderStyle.leftHeavy:
            leftBorder = BorderSide(color: formBlock.getPrimaryColor(), width: 4);
            otherBorders = BorderSide(color: formBlock.getLightColor(), width: 1);
            break;
          case BlockBorderStyle.allLight:
            leftBorder = BorderSide(color: formBlock.getLightColor(), width: 1);
            otherBorders = BorderSide(color: formBlock.getLightColor(), width: 1);
            break;
          case BlockBorderStyle.leftHeavyAllLight:
            leftBorder = BorderSide(color: formBlock.getPrimaryColor(), width: 4);
            otherBorders = BorderSide(color: formBlock.getLightColor(), width: 1);
            break;
          case BlockBorderStyle.none:
              leftBorder = null;
              otherBorders = null;
        }

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: otherBorders ?? BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: leftBorder != null
                  ? Border(
                      left: leftBorder,
                    )
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: formBlock.getPrimaryColor().withValues(alpha: 0.2),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Always show content (no headers)
                  isAssets
                      ? _renderAssetBlockLayout(block.layout, context, blockColor: formBlock.getPrimaryColor())
                      : renderLayout(block.layout, context, blockColor: formBlock.getPrimaryColor()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget renderBlock(AssembledBlock block, BuildContext context) {
  return CollapsibleBlock(block: block, context: context);
}

Widget _renderAssetBlockLayout(AssembledLayout layout, BuildContext context, {Color? blockColor}) {
  if (layout is AssembledColumn) {
    final children = layout.children;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          _renderLayoutScoped(children[i], context, groupId: null, instanceId: null, blockColor: blockColor),
          if (i != children.length - 1) ...[
            const SizedBox(height: 2),
            const Divider(thickness: 1, color: Colors.black12),
            const SizedBox(height: 2),
          ],
        ],
      ],
    );
  }

  return renderLayout(layout, context, blockColor: blockColor);
}

/// =======================
/// LAYOUT TREE RENDERER
/// =======================

Widget renderLayout(AssembledLayout layout, BuildContext context, {Color? blockColor}) {
  return _renderLayoutScoped(layout, context, groupId: null, instanceId: null, blockColor: blockColor);
}

Widget _renderLayoutScoped(
  AssembledLayout layout,
  BuildContext context, {
  String? groupId,
  String? instanceId,
  Color? blockColor,
}) {
  final formState = context.watch<FormStateProvider>();
  
  // Guard against null formInstance during navigation
  final formInstance = formState.formInstance;
  if (formInstance == null) {
    AppLogger.instance.debug('render', 'formInstance is null during render, returning empty widget');
    return const SizedBox.shrink();
  }
  
  final baseValues = formInstance.values;
  final formValues = (groupId != null && instanceId != null)
      ? {
          ...baseValues,
          ...formInstance
              .getGroupInstances(groupId)
              .firstWhere(
                (g) => g.instanceId == instanceId,
                orElse: () =>
                    GroupInstance(instanceId: '', groupId: groupId, values: const {}),
              )
              .values,
        }
      : baseValues;

  if (layout.visibilityCondition != null &&
      !layout.visibilityCondition!.evaluate(formValues)) {
    return const SizedBox.shrink();
  }

  switch (layout) {
    case AssembledRow():
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          if (maxWidth.isFinite && maxWidth < 500) {
            // Use Wrap on narrow widths so rows (notably RRN) don't collapse
            // into awkward spacing; still respects widthFraction.
            return Wrap(
              spacing: 6,
              runSpacing: 2,
              children: layout.children.map((child) {
                final fraction = child is AssembledNode ? child.widthFraction : 1.0;
                final width = (maxWidth * fraction).clamp(200.0, maxWidth);

                return SizedBox(
                  width: width,
                  child: _renderLayoutScoped(
                    child,
                    context,
                    groupId: groupId,
                    instanceId: instanceId,
                  ),
                );
              }).toList(),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: layout.children.map((child) {
              return Expanded(
                flex: _flexFromWidth(child),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _renderLayoutScoped(child, context,
                      groupId: groupId, instanceId: instanceId, blockColor: blockColor),
                ),
              );
            }).toList(),
          );
        },
      );

    case AssembledColumn():
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: layout.children
            .map(
              (child) => _renderLayoutScoped(child, context,
                    groupId: groupId, instanceId: instanceId, blockColor: blockColor),
            )
            .toList(),
      );

    case AssembledGroup():
      if (layout.repeatable && layout.groupId != null) {
        final formState = context.watch<FormStateProvider>();
        final def = formState.formDefinition.groups[layout.groupId!];
        final formInstance = context.watch<FormStateProvider>().formInstance;
        if (formInstance == null) return const SizedBox.shrink();
        final instances = formInstance.getGroupInstances(layout.groupId!);

        final addLabel = switch (layout.groupId) {
          'executor_other_info' => 'Add Executor',
          'professional_group' => 'Add Professional',
          'trustee_group' => 'Add Trustee',
          'share_certificate_group' => 'Add Share Certificate',
          'realestate_group' => 'Add Real Estate',
          'asset_group' => 'Add Other Asset',
          'rrsp_account_group' => 'Add RRSP / RIFF Account',
          'nonreg_account_group' => 'Add Non-Registered Account',
          _ => 'Add',
        };

        // Get icon for this group
        IconData groupIcon;
        switch (layout.groupId) {
          case 'executor_other_info':
            groupIcon = Icons.person;
            break;
          case 'rrsp_account_group':
            groupIcon = Icons.account_balance;
            break;
          case 'realestate_group':
            groupIcon = Icons.home;
            break;
          case 'nonreg_account_group':
            groupIcon = Icons.savings;
            break;
          default:
            // Don't show icon for unknown groups
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  layout.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...instances.asMap().entries.map((entry) {
              final inst = entry.value;
              final canDelete = def == null
                  ? true
                  : instances.length > def.minInstances;

              return _DeletableGroupContainer(
                layout: layout,
                inst: inst,
                canDelete: canDelete,
                groupId: layout.groupId!,
                blockColor: blockColor ?? Colors.grey.shade700,
              );
            }),
            TextButton.icon(
              onPressed: def != null &&
                      def.maxInstances != null &&
                      instances.length >= def.maxInstances!
                  ? null
                  : () => context
                      .read<FormStateProvider>()
                      .addGroupInstance(layout.groupId!),
              icon: const Icon(Icons.add),
              label: Text(addLabel),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: MaterialStateColor.resolveWith((states) {
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.transparent;
                  }
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.black.withOpacity(0.04);
                  }
                  return Colors.transparent;
                }),
              ),
            ),
          ],
        );
      }

      // Icon case for known groups
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                groupIcon,
                size: 20,
                color: layout.groupId == 'executor_other_info' 
                    ? const Color(0xFFFF9800)
                    : const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              Text(
                layout.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ...instances.asMap().entries.map((entry) {
            final inst = entry.value;
            final canDelete = def == null
                ? true
                : instances.length > def.minInstances;

            return _DeletableGroupContainer(
              layout: layout,
              inst: inst,
              canDelete: canDelete,
              groupId: layout.groupId!,
              blockColor: blockColor ?? Colors.grey.shade700,
            );
          }),
          TextButton.icon(
            onPressed: def != null &&
                    def.maxInstances != null &&
                    instances.length >= def.maxInstances!
                ? null
                : () => context
                    .read<FormStateProvider>()
                    .addGroupInstance(layout.groupId!),
            icon: const Icon(Icons.add),
            label: Text(addLabel),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              overlayColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.transparent;
                }
                if (states.contains(MaterialState.hovered)) {
                  return Colors.black.withOpacity(0.04);
                }
                return Colors.transparent;
              }),
            ),
          ),
        ],
      );
      } else {
        // Get icon for this group
        IconData? groupIcon;
        switch (layout.groupId) {
          case 'executor_other_info':
            groupIcon = Icons.person;
            break;
          case 'rrsp_account_group':
            groupIcon = Icons.account_balance;
            break;
          case 'realestate_group':
            groupIcon = Icons.home;
            break;
          case 'nonreg_account_group':
            groupIcon = Icons.savings;
            break;
          default:
            // Don't show icon for unknown groups
            // If label is empty, render children directly without wrapper
            if (layout.label.isEmpty) {
              if (layout.children.length == 1) {
                return _renderLayoutScoped(layout.children.first, context,
                    groupId: groupId, instanceId: instanceId, blockColor: blockColor);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: layout.children.map((child) => _renderLayoutScoped(child, context,
                    groupId: groupId, instanceId: instanceId, blockColor: blockColor)).toList(),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  layout.label,
                  style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                ),
                const SizedBox(height: 2),
                ...layout.children.map((child) => _renderLayoutScoped(child, context,
                    groupId: groupId, instanceId: instanceId, blockColor: blockColor)),
              ],
            );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (layout.label.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    groupIcon,  
                    size: 20,
                    color: layout.groupId == 'executor_other_info' 
                        ? const Color(0xFFFF9800)
                        : const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    layout.label,
                    style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 1),
            ],
            ...layout.children.map((child) => _renderLayoutScoped(child, context,
                groupId: groupId, instanceId: instanceId, blockColor: blockColor)),
          ],
        );
      }

    case AssembledNode():
      return renderNode(layout, context,
          groupId: groupId, instanceId: instanceId);
  }
}

/// =======================
/// NODE DISPATCH
/// =======================

Widget renderNode(AssembledNode assembled, BuildContext context,
    {String? groupId, String? instanceId}) {
  final node = assembled.node;

  return switch (node) {
    TextInputNode n => renderTextInput(
        n,
        assembled.dataSpec,
        context,
        groupId: groupId,
        instanceId: instanceId,
      ),
    ChoiceInputNode n => renderChoiceInput(n, context,
        groupId: groupId, instanceId: instanceId),
  };
}

/// Widget for a repeatable group container with delete functionality
class _DeletableGroupContainer extends StatefulWidget {
  final AssembledGroup layout;
  final GroupInstance inst;
  final bool canDelete;
  final String groupId;
  final Color blockColor;

  const _DeletableGroupContainer({
    required this.layout,
    required this.inst,
    required this.canDelete,
    required this.groupId,
    required this.blockColor,
  });

  @override
  State<_DeletableGroupContainer> createState() => _DeletableGroupContainerState();
}

class _DeletableGroupContainerState extends State<_DeletableGroupContainer> {
  bool isHovered = false;
  bool isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2), // Space for the X button
              ...widget.layout.children.map(
                (child) => _renderLayoutScoped(
                  child,
                  context,
                  groupId: widget.groupId,
                  instanceId: widget.inst.instanceId,
                ),
              ),
            ],
          ),
          if (widget.canDelete)
            Positioned(
              top: 0,
              right: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => isHovered = true),
                onExit: (_) => setState(() => isHovered = false),
                child: GestureDetector(
                  onTap: () {
                    if (isConfirming) {
                      context.read<FormStateProvider>().removeGroupInstance(
                        widget.groupId, widget.inst.instanceId);
                    } else {
                      setState(() => isConfirming = true);
                      // Auto-reset confirmation after 3 seconds
                      Future.delayed(const Duration(seconds: 3), () {
                        if (context.mounted) {
                          setState(() => isConfirming = false);
                        }
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isConfirming ? 32 : 24,
                    height: isConfirming ? 32 : 24,
                    decoration: BoxDecoration(
                      color: isConfirming ? const Color.fromARGB(255, 172, 52, 43): Colors.grey[300],
                      borderRadius: BorderRadius.circular(isConfirming ? 16 : 12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        size: isConfirming ? 20 : 16,
                        color: isConfirming ? Colors.black : (isHovered ? const Color.fromARGB(255, 172, 52, 43) : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// =======================
/// LEAF INPUTS
/// =======================

Widget renderTextInput(
  TextInputNode node,
  DataSpec dataSpec,
  BuildContext context, {
  String? groupId,
  String? instanceId,
}) {
  // Use read() for one-time access to avoid rebuilding on every state change
  final formState = context.read<FormStateProvider>();
  final controller = formState.controllerFor(
    nodeId: node.id,
    groupId: groupId,
    instanceId: instanceId,
  );

  final profile = dataSpec.profile;
  final formatting = formattingFor(profile);
  final fieldKey = FieldKey(node.id, groupId, instanceId);
  
  // Only watch the specific error for this field using Selector
  final errorText = context.select<FormStateProvider, String?>(
    (state) => state.errorFor(fieldKey)
  );

  // Ensure initial text uses the same formatting as live input.
  final initialText = controller.text;
  if (initialText.isNotEmpty) {
    var formattedValue = TextEditingValue(text: initialText);
    for (final formatter in formatting.formatters()) {
      formattedValue = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        formattedValue,
      );
    }
    if (formattedValue.text != initialText) {
      controller.value = formattedValue;
    }
  }

  final textField = TextField(
    controller: controller,
    maxLines: node.multiLine ? null : 1,
    keyboardType: formatting.keyboardType(),
    inputFormatters: formatting.formatters(),
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      labelText: node.label,
      labelStyle: const TextStyle(fontSize: 12),
      prefixText: formatting.prefixText(),
      hintText: profile == ValueProfile.dateDdMmYyyy ? 'dd/mm/yyyy' : null,
      errorText: null, // Disable built-in error text
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    onChanged: (text) {
      final canonical = parseCanonical(profile, text);
      if (groupId != null && instanceId != null) {
        context.read<FormStateProvider>().setGroupNodeValue(
            groupId, instanceId, node.id, canonical);
      } else {
        context.read<FormStateProvider>().setNodeValue(node.id, canonical);
      }

      // Live SIN validation
      if (profile == ValueProfile.sinCanada) {
        final digits = text.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 9) {
          // Clear error while typing (not yet 9 digits)
          context.read<FormStateProvider>().setError(fieldKey, null);
        } else {
          // Validate at 9 digits
          const validator = SinCanadaValidator();
          final error = validator.validate(text);
          context.read<FormStateProvider>().setError(fieldKey, error);
        }
      }

      // Live date validation
      if (profile == ValueProfile.dateDdMmYyyy) {
        if (text.length < 10) {
          // Clear error while typing (not yet full date)
          context.read<FormStateProvider>().setError(fieldKey, null);
        } else {
          // Validate at 10 characters (dd/mm/yyyy)
          const validator = DateDdMmYyyyValidator();
          final error = validator.validate(text);
          context.read<FormStateProvider>().setError(fieldKey, error);
        }
      }
    },
  );

  Widget input = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      textField,
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            errorText,
            style: const TextStyle(color: Colors.red, fontSize: 10),
          ),
        ),
    ],
  );

  // Apply visual width constraints based on profile
  // Align prevents Expanded parent from stretching child beyond maxWidth
  if (profile == ValueProfile.moneyCents) {
    input = Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: input,
      ),
    );
  } else if (profile == ValueProfile.dateDdMmYyyy) {
    input = Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: input,
      ),
    );
  } else if (profile == ValueProfile.sinCanada) {
    input = Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: input,
      ),
    );
  } else if (node.id.endsWith('_notes')) {
    // RRN notes fields - allow wrapping only at 200px minimum
    input = Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200),
        child: input,
      ),
    );
  }

  return input;
}

Widget renderChoiceInput(ChoiceInputNode node, BuildContext context,
    {String? groupId, String? instanceId}) {
  // Use select to only rebuild when this specific field's value changes
  final currentValue = context.select<FormStateProvider, dynamic>(
    (state) {
      final formInstance = state.formInstance;
      if (formInstance == null) return null;
      return groupId != null && instanceId != null
          ? formInstance.getGroupValue(groupId, instanceId, node.id)
          : formInstance.getValue(node.id);
    }
  );

  // Safely create values list with proper bounds checking
  final List<bool> values;
  if (currentValue is List<bool>) {
    // Log potential data inconsistency for debugging
    if (currentValue.length != node.choiceLabels.length) {
      AppLogger.instance.warn('render', 'Choice input data inconsistency: values.length=${currentValue.length}, choiceLabels.length=${node.choiceLabels.length}, nodeId=${node.id}');
    }
    
    values = List<bool>.filled(node.choiceLabels.length, false);
    for (int i = 0; i < currentValue.length && i < node.choiceLabels.length; i++) {
      values[i] = currentValue[i];
    }
  } else {
    values = List<bool>.filled(node.choiceLabels.length, false);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(node.label, style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 1),
      Wrap(
        spacing: 6,
        runSpacing: 1,
        children: List.generate(node.choiceLabels.length, (index) {
          return InkWell(
            onTap: () {
              final isChecked = !values[index];
              final List<bool> updated;

              if (node.choiceCardinality == ChoiceCardinality.single) {
                updated = List<bool>.filled(node.choiceLabels.length, false);
                if (isChecked) {
                  updated[index] = true;
                }
              } else {
                updated = List<bool>.from(values);
                updated[index] = isChecked;
              }

              if (groupId != null && instanceId != null) {
                context
                    .read<FormStateProvider>()
                    .setGroupNodeValue(groupId, instanceId, node.id, updated);
              } else {
                context.read<FormStateProvider>().setNodeValue(node.id, updated);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: values[index],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (checked) {
                    final isChecked = checked ?? false;
                    final List<bool> updated;

                    if (node.choiceCardinality == ChoiceCardinality.single) {
                      updated =
                          List<bool>.filled(node.choiceLabels.length, false);
                      if (isChecked) {
                        updated[index] = true;
                      }
                    } else {
                      updated = List<bool>.from(values);
                      updated[index] = isChecked;
                    }

                    if (groupId != null && instanceId != null) {
                      context
                          .read<FormStateProvider>()
                          .setGroupNodeValue(
                              groupId, instanceId, node.id, updated);
                    } else {
                      context
                          .read<FormStateProvider>()
                          .setNodeValue(node.id, updated);
                    }
                  },
                ),
                Text(node.choiceLabels[index]),
              ],
            ),
          );
        }),
      ),
    ],
  );
}

/// =======================
/// HELPERS
/// =======================


int _flexFromWidth(AssembledLayout layout) {
  if (layout is AssembledNode) {
    return (layout.widthFraction * 100).round();
  }
  return 100;
}
