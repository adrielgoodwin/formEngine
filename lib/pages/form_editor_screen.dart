import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import '../state/form_state.dart';
import '../state/layout_preferences.dart';
import '../ui_rendering/rendering.dart';

class FormEditorScreen extends StatefulWidget {
  const FormEditorScreen({super.key});

  @override
  State<FormEditorScreen> createState() => _FormEditorScreenState();
}

class _FormEditorScreenState extends State<FormEditorScreen>
    with WidgetsBindingObserver {
  bool _isNavigatingAway = false;
  bool _dialogOpen = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep AppBar title in sync with deceased_name (in-memory only, no persist)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupTitleTracking();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Window close interception (macOS / Windows)
  // ---------------------------------------------------------------------------

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    final formState = context.read<FormStateProvider>();
    if (!formState.isDirty) return AppExitResponse.exit;

    // Prevent duplicate dialogs
    if (_dialogOpen) return AppExitResponse.cancel;

    final result = await _showSaveDialog(isWindowClose: true);
    if (result == _SaveDialogResult.save) {
      formState.saveNow();
      formState.unloadCase();
      return AppExitResponse.exit;
    } else if (result == _SaveDialogResult.discard) {
      formState.discardChanges();
      formState.unloadCase();
      return AppExitResponse.exit;
    }
    // cancel → stay in form
    return AppExitResponse.cancel;
  }

  // ---------------------------------------------------------------------------
  // Back navigation
  // ---------------------------------------------------------------------------

  Future<void> _handleBack() async {
    if (_isNavigatingAway) return;

    final formState = context.read<FormStateProvider>();

    if (formState.isDirty) {
      final result = await _showSaveDialog(isWindowClose: false);
      if (result == _SaveDialogResult.cancel) return; // stay in form

      if (result == _SaveDialogResult.save) {
        formState.saveNow();
      } else {
        formState.discardChanges();
      }
    }

    _navigateBackToDashboard();
  }

  void _navigateBackToDashboard() {
    if (_isNavigatingAway) return;
    setState(() => _isNavigatingAway = true);

    final formState = context.read<FormStateProvider>();
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      formState.unloadCase();
    });
  }

  // ---------------------------------------------------------------------------
  // Save / Discard / Cancel dialog
  // ---------------------------------------------------------------------------

  Future<_SaveDialogResult> _showSaveDialog({required bool isWindowClose}) async {
    _dialogOpen = true;
    final result = await showDialog<_SaveDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_SaveDialogResult.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_SaveDialogResult.discard),
            child: const Text('Discard Changes',
                style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(_SaveDialogResult.save),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    return result ?? _SaveDialogResult.cancel;
  }

  // ---------------------------------------------------------------------------
  // Title tracking (in-memory only — persisted on explicit save)
  // ---------------------------------------------------------------------------

  void _setupTitleTracking() {
    final formState = context.read<FormStateProvider>();
    final controller = formState.controllerFor(nodeId: 'deceased_name');
    controller.addListener(_onDeceasedNameChanged);
  }

  void _onDeceasedNameChanged() {
    if (_isNavigatingAway || !mounted) return;
    final formState = context.read<FormStateProvider>();
    final currentCase = formState.currentCase;
    if (currentCase == null) return;

    final name = formState.controllerFor(nodeId: 'deceased_name').text.trim();
    if (name.isNotEmpty && name != currentCase.title) {
      // Update in-memory only — will be persisted on explicit save
      currentCase.title = name;
      setState(() {}); // refresh AppBar title
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't rebuild from state changes while navigating away
    if (_isNavigatingAway) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final formState = context.watch<FormStateProvider>();
    final currentCase = formState.currentCase;

    final layoutPrefs = context.watch<LayoutPreferences>();
    final currentMode = layoutPrefs.layoutMode;
    final showColors = layoutPrefs.showBackgroundColors;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight - 20, // Reduce height by 20px
        title: Builder(
          builder: (context) {
            final formState = context.watch<FormStateProvider>();
            final dodController = formState.controllerFor(nodeId: 'deceased_dod');
            final dod = dodController.text;
            final name = currentCase?.title;
            return Text(_buildCaseTitleWithDod(name, dod));
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: [
          // Layout mode buttons
          _LayoutModeButton(
            icon: Icons.view_agenda,
            tooltip: '1 Column',
            isSelected: currentMode == LayoutMode.oneColumn,
            onPressed: () => layoutPrefs.setLayoutMode(LayoutMode.oneColumn),
          ),
          _LayoutModeButton(
            icon: Symbols.view_column_2,
            tooltip: '2 Columns',
            isSelected: currentMode == LayoutMode.twoColumn,
            onPressed: () => layoutPrefs.setLayoutMode(LayoutMode.twoColumn),
          ),
          _LayoutModeButton(
            icon: Icons.view_week,
            tooltip: '3 Columns',
            isSelected: currentMode == LayoutMode.threeColumn,
            onPressed: () => layoutPrefs.setLayoutMode(LayoutMode.threeColumn),
          ),
          const SizedBox(width: 8),
          // Spacing density buttons
          _LayoutModeButton(
            icon: Icons.density_small,
            tooltip: 'Tight spacing',
            isSelected: layoutPrefs.spacingDensity == SpacingDensity.tight,
            onPressed: () => layoutPrefs.setSpacingDensity(SpacingDensity.tight),
          ),
          _LayoutModeButton(
            icon: Icons.density_medium,
            tooltip: 'Normal spacing',
            isSelected: layoutPrefs.spacingDensity == SpacingDensity.normal,
            onPressed: () => layoutPrefs.setSpacingDensity(SpacingDensity.normal),
          ),
          _LayoutModeButton(
            icon: Icons.density_large,
            tooltip: 'Spacious',
            isSelected: layoutPrefs.spacingDensity == SpacingDensity.spacious,
            onPressed: () => layoutPrefs.setSpacingDensity(SpacingDensity.spacious),
          ),
          const SizedBox(width: 8),
          // Color toggle button
          _LayoutModeButton(
            icon: showColors ? Icons.palette : Icons.palette_outlined,
            tooltip: showColors ? 'Hide Colors' : 'Show Colors',
            isSelected: showColors,
            onPressed: () => layoutPrefs.toggleBackgroundColors(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : renderForm(formState.assembledForm, context),
    );
  }
}

/// Result of the save/discard/cancel dialog.
enum _SaveDialogResult { save, discard, cancel }

/// Formats a date string as dd/Month/yyyy (e.g., 04/February/2026)
/// Returns null if the date string is invalid or empty
String? _formatDodForTitle(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return null;
  
  // Try to parse common date formats
  DateTime? date;
  final trimmed = dateStr.trim();
  
  // Try parsing various formats
  final formats = [
    RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'), // dd/mm/yyyy or mm/dd/yyyy
    RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'), // yyyy-mm-dd
    RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$'), // dd-mm-yyyy
  ];
  
  for (final format in formats) {
    final match = format.firstMatch(trimmed);
    if (match != null) {
      try {
        if (format.pattern.startsWith('^(\\d{4})')) {
          // yyyy-mm-dd format
          date = DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          );
        } else {
          // Assume dd/mm/yyyy or dd-mm-yyyy
          date = DateTime(
            int.parse(match.group(3)!),
            int.parse(match.group(2)!),
            int.parse(match.group(1)!),
          );
        }
        break;
      } catch (_) {
        continue;
      }
    }
  }
  
  if (date == null) return null;
  
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  final year = date.year.toString();
  
  return '$day/$month/$year';
}

/// Builds the case title with optional DOD
String _buildCaseTitleWithDod(String? name, String? dod) {
  final formattedDod = _formatDodForTitle(dod);
  
  if (name == null || name.isEmpty) {
    if (formattedDod != null) {
      return 'New Case — DOD: $formattedDod';
    }
    return 'Edit Case';
  }
  
  if (formattedDod != null) {
    return '$name — DOD: $formattedDod';
  }
  
  return name;
}

/// AppBar button for layout mode and color toggle controls.
/// Shows selected state via background color and icon styling.
class _LayoutModeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _LayoutModeButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
