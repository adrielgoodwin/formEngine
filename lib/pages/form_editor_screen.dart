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

  void _handleBack() {
    if (_isNavigatingAway) return;
    
    setState(() {
      _isNavigatingAway = true;
    });

    final formState = context.read<FormStateProvider>();
    final repository = context.read<CaseRepository>();
    final currentCase = formState.currentCase;

    // Update case before leaving
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

    Navigator.of(context).pop();
    
    // Unload after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      formState.unloadCase();
    });
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
        title: Text(currentCase?.title ?? 'Edit Case'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: [],
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: renderForm(formState.assembledForm, context),
            ),
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
