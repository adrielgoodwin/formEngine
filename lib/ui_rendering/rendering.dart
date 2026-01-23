import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/form_controllers.dart';
import '../data/case_repository.dart';
import '../data/load_form.dart';
import '../logging/app_logger.dart';
import '../models/assembler.dart';
import '../models/form_block.dart';
import '../models/form_instance.dart';
import '../models/form_node.dart';
import '../models/form_definition_validation.dart';
import '../models/group_instance.dart';
import '../state/form_state.dart';

/// =======================
/// FORM ENTRY POINT
/// =======================

Widget renderForm(AssembledForm form, BuildContext context) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(form.title, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 16),
        ...form.blocks.map((block) => renderBlock(block, context)),
      ],
    ),
  );
}

/// =======================
/// BLOCK RENDERING
/// =======================

Widget renderBlock(AssembledBlock block, BuildContext context) {
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
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: otherBorders ?? BorderSide.none,
    ),
    child: Container(
      decoration: leftBorder != null
          ? BoxDecoration(
              border: Border(
                left: leftBorder,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(block.title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            isAssets
                ? _renderAssetBlockLayout(block.layout, context)
                : renderLayout(block.layout, context),
          ],
        ),
      ),
    ),
  );
}

Widget _renderAssetBlockLayout(AssembledLayout layout, BuildContext context) {
  if (layout is AssembledColumn) {
    final children = layout.children;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          _renderLayoutScoped(children[i], context, groupId: null, instanceId: null),
          if (i != children.length - 1) ...[
            const SizedBox(height: 12),
            const Divider(thickness: 1, color: Colors.black12),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  return renderLayout(layout, context);
}

/// =======================
/// LAYOUT TREE RENDERER
/// =======================

Widget renderLayout(AssembledLayout layout, BuildContext context) {
  return _renderLayoutScoped(layout, context, groupId: null, instanceId: null);
}

Widget _renderLayoutScoped(
  AssembledLayout layout,
  BuildContext context, {
  String? groupId,
  String? instanceId,
}) {
  final formState = context.watch<FormStateProvider>();
  
  // Guard against null formInstance during navigation
  final formInstance = formState.formInstance;
  if (formInstance == null) {
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

          if (maxWidth.isFinite && maxWidth < 720) {
            // Use Wrap on narrow widths so rows (notably RRN) don't collapse
            // into awkward spacing; still respects widthFraction.
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: layout.children.map((child) {
                final fraction = child is AssembledNode ? child.widthFraction : 1.0;
                final width = (maxWidth * fraction).clamp(180.0, maxWidth);

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
                  padding: const EdgeInsets.only(right: 12),
                  child: _renderLayoutScoped(child, context,
                      groupId: groupId, instanceId: instanceId),
                ),
              );
            }).toList(),
          );
        },
      );

    case AssembledColumn():
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: layout.children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _renderLayoutScoped(child, context,
                    groupId: groupId, instanceId: instanceId),
              ),
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
          'real_estate_group' => 'Add Real Estate',
          'rrsp_account_group' => 'Add RRSP / RIFF Account',
          'non_registered_account_group' => 'Add Non-Registered Account',
          _ => 'Add more',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              layout.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
              );
            }),
            const SizedBox(height: 8),
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
            ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              layout.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...layout.children.map((child) => _renderLayoutScoped(child, context,
                groupId: groupId, instanceId: instanceId)),
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

  const _DeletableGroupContainer({
    required this.layout,
    required this.inst,
    required this.canDelete,
    required this.groupId,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8), // Space for the X button
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
    decoration: InputDecoration(
      labelText: node.label,
      prefixText: formatting.prefixText(),
      hintText: profile == ValueProfile.dateDdMmYyyy ? 'dd/mm/yyyy' : null,
      errorText: null, // Disable built-in error text
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
      SizedBox(
        height: 16,
        child: Visibility(
          visible: errorText != null,
          child: Text(
            errorText ?? '',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
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

  final List<bool> values = List<bool>.from(
    currentValue ?? List<bool>.filled(node.choiceLabels.length, false),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(node.label),
      const SizedBox(height: 6),
      Wrap(
        spacing: 16,
        runSpacing: 8,
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
