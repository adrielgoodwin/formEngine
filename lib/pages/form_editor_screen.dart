import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/case_repository.dart';
import '../models/form_instance.dart';
import '../state/form_state.dart';
import '../ui_rendering/rendering.dart';

class FormEditorScreen extends StatefulWidget {
  const FormEditorScreen({super.key});

  @override
  State<FormEditorScreen> createState() => _FormEditorScreenState();
}

class _FormEditorScreenState extends State<FormEditorScreen> {
  bool _isNavigatingAway = false;
  Timer? _titleUpdateTimer;

  void _handleBack() {
    if (_isNavigatingAway) return;
    
    setState(() {
      _isNavigatingAway = true;
    });

    final formState = context.read<FormStateProvider>();
    final repository = context.read<CaseRepository>();
    final currentCase = formState.currentCase;

    // Update case before leaving - wrapped in try-catch to ensure navigation happens
    try {
      if (currentCase != null) {
        final formInstance = formState.formInstance;
        if (formInstance != null) {
          final nameValue = _deriveTitleFromInstance(formInstance);
          if (nameValue != null) {
            currentCase.title = nameValue;
          }
        }
        repository.update(currentCase);
      }
    } catch (e) {
      // Log but don't block navigation - file may be locked by another user
      debugPrint('Failed to save case on back: $e');
    }

    Navigator.of(context).pop();
    
    // Unload after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      formState.unloadCase();
    });
  }

  @override
  void initState() {
    super.initState();
    // Listen for form changes and update title in real-time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupTitleUpdates();
    });
  }

  @override
  void dispose() {
    _titleUpdateTimer?.cancel();
    super.dispose();
  }

  void _setupTitleUpdates() {
    final formState = context.read<FormStateProvider>();
    
    // Listen directly to the deceased_name text field controller
    final deceasedNameController = formState.controllerFor(nodeId: 'deceased_name');
    deceasedNameController.addListener(_onDeceasedNameChanged);
  }

  void _onDeceasedNameChanged() {
    // Immediate update for each keystroke
    _updateCaseTitle();
  }

  void _updateCaseTitle() {
    if (_isNavigatingAway || !mounted) return;
    
    final formState = context.read<FormStateProvider>();
    final repository = context.read<CaseRepository>();
    final currentCase = formState.currentCase;
    
    if (currentCase != null) {
      // Get name directly from the deceased_name controller
      final deceasedNameController = formState.controllerFor(nodeId: 'deceased_name');
      final nameValue = deceasedNameController.text.trim();
      
      if (nameValue.isNotEmpty && nameValue != currentCase.title) {
        currentCase.title = nameValue;
        repository.update(currentCase);
      }
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight - 20, // Reduce height by 20px
        title: Text(currentCase?.title ?? 'Edit Case'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: [],
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : renderForm(formState.assembledForm, context),
    );
  }
}

String? _deriveTitleFromInstance(FormInstance instance) {
  for (final entry in instance.values.entries) {
    if (entry.key.contains('name') && entry.value is String) {
      final name = entry.value as String;
      if (name.trim().isNotEmpty) {
        return name.trim();
      }
    }
  }
  return null;
}
